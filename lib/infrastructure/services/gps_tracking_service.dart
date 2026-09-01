import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

// ─── Constantes de configuración ─────────────────────────────────────────────

/// Nombre físico de la tabla GPS en SQLite.
const _kGpsTable = 'CLI547_AGM_Punto_gps_maquinaria';

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
      await _positionSub?.cancel();
      _positionSub = null;
      _activeRegistroId = null;
      _sequence = 0;
      _windowBuffer.clear();
      _lastRecordedPos = null;
      _lastRecordedTime = null;
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
          lon < s.bboxMinLon || lon > s.bboxMaxLon) continue;
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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
      return LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }
  }
}
