import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'gps_service_prompt.dart';

// ─── Constantes de configuración ─────────────────────────────────────────────

/// Nombre físico de la tabla GPS en SQLite.
const _kGpsTable = 'CLI547_AGM_Ruta_maquinaria';

/// SharedPreferences key para persistir el registro activo entre sesiones.
const _kPrefKeyRegistroActivo = 'gps_tracking_registro_id';

/// Cada cuánto graba el TIMER un punto en SQLite.
/// El stream interno corre más rápido para recolectar candidatos.
const _kInterval = Duration(seconds: 5);

/// Frecuencia del stream interno de posición (alimenta el buffer de candidatos).
/// Más rápido que _kInterval para tener varias lecturas por ventana.
const _kInternalInterval = Duration(seconds: 1);

/// Cuántas lecturas iniciales descartar para que el receptor GPS se estabilice.
/// Con stream a 1s: 3 lecturas = 3 segundos de warm-up.
const _kWarmupPuntos = 3;

/// Máximo de candidatos que guarda el buffer por ventana de grabación.
const _kBufferSize = 8;

/// Accuracy máxima aceptable en metros.
/// En campo abierto con buena señal el GPS puede dar 2-5 m.
/// Puntos con error mayor se descartan y se espera un mejor candidato en el buffer.
const _kMaxAccuracyMetros = 5.0;

/// Velocidad máxima en m/s que puede alcanzar la maquinaria (36 km/h).
/// Puntos que impliquen velocidades superiores son errores GPS y se descartan.
const _kMaxVelocidadMs = 10.0;

/// Cada cuánto el watchdog revisa que el rastreo siga vivo.
const _kWatchdogInterval = Duration(minutes: 1);

/// Si el stream no entrega NINGUNA lectura durante este tiempo teniendo el
/// servicio de ubicación activo, se asume que murió en silencio y se recrea.
///
/// Se mide sobre las lecturas crudas, ANTES de los filtros de accuracy: con
/// mala señal el stream sigue vivo aunque todos los puntos se descarten, y
/// reiniciarlo ahí solo empeoraría las cosas (vuelve a perder el warm-up).
const _kMaxMinutosSinLectura = 2;

/// Espera tras reactivarse el servicio antes de recrear el stream. El receptor
/// GPS necesita un momento para volver a fijar posición.
const _kEsperaTrasReactivar = Duration(seconds: 3);

// ─── Modelo interno de sublote con geometría ──────────────────────────────────

class _SubloteGeom {
  final int id;
  final String nombre;
  final String? cultivo;
  final double bboxMinLat;
  final double bboxMaxLat;
  final double bboxMinLon;
  final double bboxMaxLon;
  final List<List<double>> vertices; // [(lon, lat), ...] — orden WKT Geography

  const _SubloteGeom({
    required this.id,
    required this.nombre,
    this.cultivo,
    required this.bboxMinLat,
    required this.bboxMaxLat,
    required this.bboxMinLon,
    required this.bboxMaxLon,
    required this.vertices,
  });
}

// ─── Servicio ─────────────────────────────────────────────────────────────────

/// Servicio singleton de rastreo GPS con precisión mejorada.
///
/// Estrategia "Best-of-Window":
///   - Un stream interno a 1 s alimenta un buffer rodante de posiciones.
///   - Cada [_kInterval] (5 s) se elige la posición con MENOR error de accuracy
///     del buffer y se graba en SQLite — en lugar de tomar ciegamente la lectura
///     que cae en ese instante.
///   - Se aplican tres filtros adicionales:
///       1. Warm-up: descarta las primeras [_kWarmupPuntos] lecturas.
///       2. Accuracy: descarta lecturas con error > [_kMaxAccuracyMetros].
///       3. Speed check: descarta puntos que impliquen velocidades imposibles
///          para maquinaria agrícola (> [_kMaxVelocidadMs]).
///
/// Resiliencia ante cierres:
///   - [startTracking] persiste el registroId en SharedPreferences.
///   - [resumeIfActive] recupera MAX(secuencia) de SQLite y reactiva el rastreo.
///   - [stopTracking] borra la clave de SharedPreferences.
class GpsTrackingService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  StreamSubscription<Position>? _positionSub;
  Timer? _recordTimer;
  String? _activeRegistroId;
  int _sequence = 0;

  // Watchdog: vigila que el rastreo siga vivo durante toda la jornada.
  StreamSubscription<ServiceStatus>? _serviceSub;
  Timer? _watchdogTimer;

  /// Momento de la última lectura recibida del stream, con filtros o sin ellos.
  /// Es la señal de "el stream está vivo".
  DateTime? _ultimaLecturaAt;

  /// Evita repetir el log de servicio caído en cada ciclo del watchdog.
  bool _servicioCaido = false;

  /// Impide que dos recuperaciones se pisen entre sí.
  bool _recuperando = false;

  // Buffer de candidatos para la ventana actual
  final List<Position> _windowBuffer = [];
  int _warmupCount = 0;

  // Último punto grabado — usado para el speed sanity check
  Position? _lastRecordedPos;
  DateTime? _lastRecordedTime;

  // Geometrías de sublote cargadas al iniciar el tracking
  List<_SubloteGeom> _sublotes = [];

  GpsTrackingService({required AppDatabase db}) : _db = db;

  bool get isTracking => _positionSub != null;
  String? get activeRegistroId => _activeRegistroId;

  // ─── API pública ─────────────────────────────────────────────────────────

  Future<void> startTracking(String registroId, {int initialSequence = 0}) async {
    try {
      await stopTracking(_activeRegistroId);

      final granted = await _checkPermissions();
      if (!granted) {
        developer.log(
          'GPS: permiso no otorgado — rastreo omitido para $registroId',
          name: 'GpsTrackingService',
        );
        return;
      }

      _activeRegistroId = registroId;
      _sequence = initialSequence;
      _warmupCount = 0;
      _windowBuffer.clear();
      _lastRecordedPos = null;
      _lastRecordedTime = null;

      // Cargar geometrías de sublote para point-in-polygon offline
      await _cargarSublotes();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKeyRegistroActivo, registroId);

      // Stream rápido (1 s) → alimenta el buffer de candidatos
      _positionSub = Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).listen(
        _updateBuffer,
        onError: (dynamic e) => developer.log(
          'GPS stream error: $e',
          name: 'GpsTrackingService',
        ),
        cancelOnError: false,
      );

      // Timer de grabación (5 s) → elige el mejor candidato del buffer
      _recordTimer = Timer.periodic(_kInterval, (_) {
        if (_activeRegistroId != null) {
          _grabarMejorDelBuffer(_activeRegistroId!);
        }
      });

      // Watchdog 1: el operador apaga o enciende la ubicación del teléfono.
      _ultimaLecturaAt = DateTime.now();
      _servicioCaido = false;
      _serviceSub = Geolocator.getServiceStatusStream().listen(
        _onServiceStatus,
        onError: (dynamic e) => developer.log(
          'GPS: error en el stream de estado del servicio: $e',
          name: 'GpsTrackingService',
        ),
        cancelOnError: false,
      );

      // Watchdog 2: el stream muere en silencio (batería, permiso revocado).
      _watchdogTimer = Timer.periodic(_kWatchdogInterval, (_) => _verificarSalud());

      developer.log(
        'GPS: rastreo iniciado para $registroId (seq inicial: $initialSequence)',
        name: 'GpsTrackingService',
      );
    } catch (e) {
      developer.log('GPS: error al iniciar — $e', name: 'GpsTrackingService', error: e);
    }
  }

  Future<void> stopTracking(String? registroId) async {
    if (registroId != null && registroId != _activeRegistroId) return;
    try {
      _recordTimer?.cancel();
      _recordTimer = null;
      _watchdogTimer?.cancel();
      _watchdogTimer = null;
      await _positionSub?.cancel();
      _positionSub = null;
      await _serviceSub?.cancel();
      _serviceSub = null;
      _activeRegistroId = null;
      _sequence = 0;
      _windowBuffer.clear();
      _lastRecordedPos = null;
      _lastRecordedTime = null;
      _ultimaLecturaAt = null;
      _sublotes = [];

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefKeyRegistroActivo);

      developer.log('GPS: rastreo detenido', name: 'GpsTrackingService');
    } catch (e) {
      developer.log('GPS: error al detener — $e', name: 'GpsTrackingService');
    }
  }

  Future<void> resumeIfActive(String registroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefKeyRegistroActivo);
      if (saved != null && saved != registroId) {
        developer.log(
          'GPS resumeIfActive: saved=$saved != $registroId — limpiando',
          name: 'GpsTrackingService',
        );
        await prefs.remove(_kPrefKeyRegistroActivo);
      }

      final rows = await _db.customSelect(
        'SELECT MAX(secuencia) AS max_seq FROM "$_kGpsTable" WHERE registro_id = ?',
        variables: [Variable.withString(registroId)],
      ).get();
      final maxSeq = rows.isEmpty ? 0 : (rows.first.readNullable<int>('max_seq') ?? 0);

      developer.log(
        'GPS resumeIfActive: registro=$registroId, secuencia actual=$maxSeq',
        name: 'GpsTrackingService',
      );

      await startTracking(registroId, initialSequence: maxSeq);
    } catch (e) {
      developer.log('GPS: error en resumeIfActive — $e', name: 'GpsTrackingService', error: e);
    }
  }

  // ─── Internos ─────────────────────────────────────────────────────────────

  /// Recibe cada lectura del stream (cada 1 s) y la agrega al buffer
  /// si pasa los filtros de warm-up y accuracy.
  void _updateBuffer(Position pos) {
    if (_activeRegistroId == null) return;

    // Se marca ANTES de los filtros: lo que prueba que el stream sigue vivo es
    // que llegan lecturas, no que pasen los filtros de calidad.
    _ultimaLecturaAt = DateTime.now();

    // 1. Warm-up: ignorar las primeras N lecturas
    if (_warmupCount < _kWarmupPuntos) {
      _warmupCount++;
      developer.log(
        'GPS warm-up $_warmupCount/$_kWarmupPuntos '
        '(accuracy: ${pos.accuracy.toStringAsFixed(0)} m) — descartado',
        name: 'GpsTrackingService',
      );
      return;
    }

    // 2. Filtro de accuracy
    if (pos.accuracy > _kMaxAccuracyMetros) {
      developer.log(
        'GPS descartado — accuracy ${pos.accuracy.toStringAsFixed(0)} m '
        '> umbral ${_kMaxAccuracyMetros.toStringAsFixed(0)} m',
        name: 'GpsTrackingService',
      );
      return;
    }

    // Agregar al buffer (rodante: máximo _kBufferSize lecturas)
    _windowBuffer.add(pos);
    if (_windowBuffer.length > _kBufferSize) {
      _windowBuffer.removeAt(0);
    }
  }

  /// Llamado cada [_kInterval]. Elige la posición con MENOR accuracy del
  /// buffer actual, aplica el speed sanity check y la graba en SQLite.
  Future<void> _grabarMejorDelBuffer(String registroId) async {
    if (_windowBuffer.isEmpty) {
      developer.log(
        'GPS: sin candidatos en el buffer — ciclo omitido',
        name: 'GpsTrackingService',
      );
      return;
    }

    // Elegir la lectura con menor valor de accuracy (= más precisa)
    final mejor = _windowBuffer.reduce(
      (a, b) => a.accuracy <= b.accuracy ? a : b,
    );

    // 3. Speed sanity check: velocidad imposible para maquinaria agrícola
    if (_lastRecordedPos != null && _lastRecordedTime != null) {
      final dtSeg = DateTime.now().difference(_lastRecordedTime!).inMilliseconds / 1000.0;
      if (dtSeg > 0) {
        final distanciaM = Geolocator.distanceBetween(
          _lastRecordedPos!.latitude,
          _lastRecordedPos!.longitude,
          mejor.latitude,
          mejor.longitude,
        );
        final velocidadMs = distanciaM / dtSeg;
        if (velocidadMs > _kMaxVelocidadMs) {
          developer.log(
            'GPS descartado — velocidad imposible '
            '${(velocidadMs * 3.6).toStringAsFixed(1)} km/h '
            '(máx: ${(_kMaxVelocidadMs * 3.6).toStringAsFixed(0)} km/h)',
            name: 'GpsTrackingService',
          );
          _windowBuffer.clear();
          return;
        }
      }
    }

    // Limpiar buffer — evitar reutilizar los mismos puntos en el próximo ciclo
    _windowBuffer.clear();

    try {
      _sequence++;
      final id = _uuid.v4();
      final ahora = DateTime.now().millisecondsSinceEpoch;

      // Analytics por punto
      final velKmh    = mejor.speed * 3.6;          // m/s → km/h
      final rumbo     = mejor.heading >= 0 ? mejor.heading : null; // -1 = inválido
      final sublote   = _subloteDelPunto(mejor.latitude, mejor.longitude);
      final tipoMov   = _clasificarMovimiento(velKmh, sublote);

      await _db.customStatement(
        'INSERT INTO "$_kGpsTable" '
        '(id, registro_id, latitud, longitud, precision, altitud, '
        ' velocidad, secuencia, captured_at, '
        ' rumbo, velocidad_kmh, tipo_movimiento, sublote_id) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          registroId,
          mejor.latitude,
          mejor.longitude,
          mejor.accuracy,
          mejor.altitude,
          mejor.speed.round(),
          _sequence,
          ahora,
          rumbo,
          velKmh,
          tipoMov,
          sublote?.id,
        ],
      );

      _lastRecordedPos = mejor;
      _lastRecordedTime = DateTime.now();

      developer.log(
        'GPS #$_sequence grabado → '
        '${mejor.latitude.toStringAsFixed(6)}, ${mejor.longitude.toStringAsFixed(6)} '
        '(±${mejor.accuracy.toStringAsFixed(1)} m) '
        '[$tipoMov${sublote != null ? " · ${sublote.nombre}" : ""}]',
        name: 'GpsTrackingService',
      );
    } catch (e) {
      developer.log(
        'GPS: error al grabar punto #$_sequence — $e',
        name: 'GpsTrackingService',
        error: e,
      );
    }
  }

  // ─── Watchdog ──────────────────────────────────────────────────────────────

  /// El operador apagó o encendió la ubicación del teléfono a media jornada.
  ///
  /// Al reactivarse NO se confía en que el stream anterior reviva: cuando el
  /// servicio se apaga, la capa nativa lanza LocationServiceDisabledException y
  /// normalmente desmonta el listener para siempre. Se recrea todo desde cero
  /// con [resumeIfActive], que además recupera MAX(secuencia) de SQLite para no
  /// pisar los puntos ya grabados.
  Future<void> _onServiceStatus(ServiceStatus status) async {
    final registroId = _activeRegistroId;
    if (registroId == null) return;

    if (status == ServiceStatus.disabled) {
      _servicioCaido = true;
      developer.log(
        'GPS: el operador APAGÓ la ubicación — rastreo interrumpido. '
        'Los puntos de este período no se pueden recuperar.',
        name: 'GpsTrackingService',
      );
      return;
    }

    developer.log(
      'GPS: ubicación reactivada — recreando el stream en '
      '${_kEsperaTrasReactivar.inSeconds} s',
      name: 'GpsTrackingService',
    );
    _servicioCaido = false;

    // Fuera del callback y con margen para que el receptor fije posición.
    await Future<void>.delayed(_kEsperaTrasReactivar);
    if (_activeRegistroId == registroId) await _recuperar(registroId);
  }

  /// Revisa cada [_kWatchdogInterval] que el stream siga entregando lecturas.
  ///
  /// Cubre las muertes silenciosas que no emiten ningún evento de servicio:
  /// optimización de batería que congela la app, permiso revocado desde los
  /// ajustes, o el propio stream que deja de emitir sin lanzar error.
  Future<void> _verificarSalud() async {
    final registroId = _activeRegistroId;
    if (registroId == null || _recuperando) return;

    final ultima = _ultimaLecturaAt;
    if (ultima == null) return;

    final minutosSinLectura = DateTime.now().difference(ultima).inMinutes;
    if (minutosSinLectura < _kMaxMinutosSinLectura) return;

    try {
      // Si el servicio está apagado no hay nada que reiniciar: el listener de
      // estado se encargará cuando el operador lo vuelva a encender.
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!_servicioCaido) {
          _servicioCaido = true;
          developer.log(
            'GPS: sin lecturas hace $minutosSinLectura min — la ubicación del '
            'teléfono está apagada.',
            name: 'GpsTrackingService',
          );
        }
        return;
      }

      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        developer.log(
          'GPS: sin lecturas hace $minutosSinLectura min — el permiso de '
          'ubicación fue revocado ($permiso). Reiniciar no ayuda.',
          name: 'GpsTrackingService',
        );
        return;
      }

      // Servicio activo y permiso concedido, pero no llegan lecturas: el stream
      // murió en silencio.
      developer.log(
        'GPS: $minutosSinLectura min sin lecturas con el servicio activo — '
        'reiniciando el stream',
        name: 'GpsTrackingService',
      );
      await _recuperar(registroId);
    } catch (e) {
      developer.log('GPS: error en el watchdog — $e',
          name: 'GpsTrackingService', error: e);
    }
  }

  /// Recrea el rastreo conservando la secuencia ya grabada.
  Future<void> _recuperar(String registroId) async {
    if (_recuperando) return;
    _recuperando = true;
    try {
      await resumeIfActive(registroId);
    } catch (e) {
      developer.log('GPS: falló la recuperación — $e',
          name: 'GpsTrackingService', error: e);
    } finally {
      _recuperando = false;
    }
  }

  // ─── Geometrías de sublote ─────────────────────────────────────────────────

  /// Carga las geometrías WKT de lotes_local y construye el índice en memoria.
  /// Best-effort — si falla, _sublotes queda vacío (sin PIP, tipo = TRASLADO).
  Future<void> _cargarSublotes() async {
    try {
      final rows = await _db.customSelect(
        'SELECT id_erp, lote_nombre, nombre_cultivo, geometria_wkt '
        'FROM lotes_local '
        'WHERE geometria_wkt IS NOT NULL AND geometria_wkt != ""',
      ).get();

      _sublotes = [];
      for (final r in rows) {
        final wkt = r.read<String>('geometria_wkt');
        final vertices = _parsearPoligono(wkt);
        if (vertices == null || vertices.length < 3) continue;
        final bbox = _bboxDeVertices(vertices);
        _sublotes.add(_SubloteGeom(
          id: r.read<int>('id_erp'),
          nombre: r.read<String>('lote_nombre'),
          cultivo: r.readNullable<String>('nombre_cultivo'),
          bboxMinLat: bbox[0],
          bboxMaxLat: bbox[1],
          bboxMinLon: bbox[2],
          bboxMaxLon: bbox[3],
          vertices: vertices,
        ));
      }

      developer.log(
        'GPS: ${_sublotes.length} sublotes con geometría cargados para PIP',
        name: 'GpsTrackingService',
      );
    } catch (e) {
      developer.log(
        'GPS: error cargando sublotes — PIP desactivado: $e',
        name: 'GpsTrackingService',
      );
      _sublotes = [];
    }
  }

  /// Parsea un WKT POLYGON o MULTIPOLYGON y devuelve los vértices del primer anillo.
  /// WKT Geography de SQL Server: coordenadas en orden (longitud latitud).
  /// Devuelve null si el WKT no puede parsearse.
  List<List<double>>? _parsearPoligono(String wkt) {
    try {
      // Acepta POLYGON((...)) y MULTIPOLYGON(((...)))
      final match = RegExp(
        r'(?:MULTI)?POLYGON\s*\(\s*\(\s*([^)]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(wkt);
      if (match == null) return null;

      final coordStr = match.group(1)!;
      final vertices = <List<double>>[];
      for (final pair in coordStr.split(',')) {
        final parts = pair.trim().split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final lon = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        if (lon != null && lat != null) {
          vertices.add([lon, lat]); // orden WKT Geography: lon, lat
        }
      }
      return vertices.length >= 3 ? vertices : null;
    } catch (_) {
      return null;
    }
  }

  /// Calcula el bounding box de un conjunto de vértices.
  /// Devuelve [minLat, maxLat, minLon, maxLon].
  List<double> _bboxDeVertices(List<List<double>> vertices) {
    double minLat = vertices[0][1], maxLat = vertices[0][1];
    double minLon = vertices[0][0], maxLon = vertices[0][0];
    for (final v in vertices) {
      if (v[1] < minLat) minLat = v[1];
      if (v[1] > maxLat) maxLat = v[1];
      if (v[0] < minLon) minLon = v[0];
      if (v[0] > maxLon) maxLon = v[0];
    }
    return [minLat, maxLat, minLon, maxLon];
  }

  /// Ray casting point-in-polygon.
  /// point: (lon, lat) — vértices del polígono: [(lon, lat), ...]
  bool _puntoEnPoligono(double lon, double lat, List<List<double>> vertices) {
    bool inside = false;
    final n = vertices.length;
    int j = n - 1;
    for (int i = 0; i < n; i++) {
      final xi = vertices[i][0]; // lon
      final yi = vertices[i][1]; // lat
      final xj = vertices[j][0];
      final yj = vertices[j][1];
      if ((yi > lat) != (yj > lat) &&
          lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  /// Determina en qué sublote está el punto (null = fuera de todos).
  _SubloteGeom? _subloteDelPunto(double lat, double lon) {
    if (_sublotes.isEmpty) return null;
    for (final s in _sublotes) {
      // Pre-filtro rápido por bounding box antes de correr el PIP completo
      if (lat < s.bboxMinLat || lat > s.bboxMaxLat ||
          lon < s.bboxMinLon || lon > s.bboxMaxLon) {
        continue;
      }
      if (_puntoEnPoligono(lon, lat, s.vertices)) return s;
    }
    return null;
  }

  /// Clasifica el tipo de movimiento del punto GPS.
  /// TRABAJO  : vel 1–12 km/h y dentro de un sublote
  /// TRASLADO : vel > 1 km/h pero fuera de sublotes (o vel > 12 km/h)
  /// PARADO   : vel < 1 km/h
  String _clasificarMovimiento(double velKmh, _SubloteGeom? sublote) {
    if (velKmh < 1.0) return 'PARADO';
    if (velKmh <= 12.0 && sublote != null) return 'TRABAJO';
    return 'TRASLADO';
  }

  Future<bool> _checkPermissions() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Diálogo del sistema para encenderla sin salir de la app. Si el operador
      // lo rechaza, la jornada se registra igual pero sin ruta.
      serviceEnabled = await GpsServicePrompt.solicitarActivacion();
    }
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: _kInternalInterval, // 1 s — stream interno de candidatos
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Jornada en curso — ruta GPS activa',
          notificationTitle: 'MMA Agro',
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }
  }
}
