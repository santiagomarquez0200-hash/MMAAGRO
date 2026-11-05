import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';

import '../database/app_database.dart';

/// Un punto GPS local ya enriquecido, listo para derivar eventos.
class GpsPunto {
  final double lat;
  final double lon;
  final int at; // epoch ms
  final double velKmh;
  final String tipo; // TRABAJO | TRASLADO | PARADO
  final int? subloteId;
  final String? subloteNombre;

  const GpsPunto({
    required this.lat,
    required this.lon,
    required this.at,
    required this.velKmh,
    required this.tipo,
    this.subloteId,
    this.subloteNombre,
  });
}

/// Visita a un sublote: desde que la máquina entró al polígono hasta que salió.
class GpsVisita {
  final int subloteId;
  final String? nombre;
  final int entradaAt;
  final int salidaAt;
  final int minutos;
  final double km;
  final double velPromKmh;
  final double velMaxKmh;
  final int puntos;

  const GpsVisita({
    required this.subloteId,
    required this.nombre,
    required this.entradaAt,
    required this.salidaAt,
    required this.minutos,
    required this.km,
    required this.velPromKmh,
    required this.velMaxKmh,
    required this.puntos,
  });

  Map<String, dynamic> toJson() => {
        'sublote_id': subloteId,
        'nombre': nombre ?? '',
        'entrada_at': entradaAt,
        'salida_at': salidaAt,
        'minutos': minutos,
        'km': double.parse(km.toStringAsFixed(3)),
        'vel_prom_kmh': double.parse(velPromKmh.toStringAsFixed(2)),
        'vel_max_kmh': double.parse(velMaxKmh.toStringAsFixed(2)),
        'puntos': puntos,
      };
}

/// Parada: la máquina estuvo detenida en un mismo sitio.
/// `subloteId` nulo significa que paró fuera de todo lote — el indicador de
/// tiempo muerto más útil del modelo.
class GpsParada {
  final int orden;
  final double lat;
  final double lon;
  final int inicioAt;
  final int finAt;
  final int minutos;
  final int? subloteId;

  const GpsParada({
    required this.orden,
    required this.lat,
    required this.lon,
    required this.inicioAt,
    required this.finAt,
    required this.minutos,
    this.subloteId,
  });

  Map<String, dynamic> toJson() => {
        'orden': orden,
        'lat': double.parse(lat.toStringAsFixed(7)),
        'lon': double.parse(lon.toStringAsFixed(7)),
        'inicio_at': inicioAt,
        'fin_at': finAt,
        'minutos': minutos,
        if (subloteId != null) 'sublote_id': subloteId,
      };
}

/// Tramo: puntos consecutivos con el mismo tipo de movimiento.
/// Es la unidad que permite pintar el recorrido coloreado por actividad.
class GpsTramo {
  final int orden;
  final String tipo;
  final String wkt;
  final int inicioAt;
  final int finAt;
  final int minutos;
  final double km;
  final double velPromKmh;
  final double velMaxKmh;
  final int puntos;
  final int? subloteId;

  const GpsTramo({
    required this.orden,
    required this.tipo,
    required this.wkt,
    required this.inicioAt,
    required this.finAt,
    required this.minutos,
    required this.km,
    required this.velPromKmh,
    required this.velMaxKmh,
    required this.puntos,
    this.subloteId,
  });

  Map<String, dynamic> toJson() => {
        'orden': orden,
        'tipo': tipo,
        'wkt': wkt,
        'inicio_at': inicioAt,
        'fin_at': finAt,
        'minutos': minutos,
        'km': double.parse(km.toStringAsFixed(3)),
        'vel_prom_kmh': double.parse(velPromKmh.toStringAsFixed(2)),
        'vel_max_kmh': double.parse(velMaxKmh.toStringAsFixed(2)),
        'puntos': puntos,
        if (subloteId != null) 'sublote_id': subloteId,
      };
}

/// Deriva eventos (visitas a sublote, paradas y tramos) a partir de los puntos
/// GPS que el dispositivo ya grabó durante la jornada.
///
/// Se ejecuta al cerrar turno, junto con el armado del payload. No toca el GPS
/// ni la red: es post-procesamiento sobre SQLite.
///
/// Las tres funciones de derivación son estáticas y puras sobre una lista de
/// [GpsPunto], para poder probarlas sin base de datos.
class GpsEventBuilderService {
  static const _kGpsTable = 'CLI547_AGM_Ruta_maquinaria';
  static const _tag = 'GpsEventBuilder';

  /// Duración mínima para que un paso por un polígono cuente como visita.
  ///
  /// Sin este umbral el ruido del GPS en el borde del lote genera decenas de
  /// entradas/salidas falsas: la máquina "entra y sale" cada pocos segundos
  /// mientras trabaja pegada al límite.
  static const kMinSegundosVisita = 60;

  /// Duración mínima de una parada. Por debajo de esto suele ser una maniobra
  /// normal (girar al final del surco), no un evento operativo.
  static const kMinMinutosParada = 3;

  /// Tope del salto de tiempo entre puntos consecutivos al sumar duraciones.
  /// Si el GPS se cayó 20 minutos, no se cuentan esos 20 minutos como trabajo
  /// ni como parada.
  static const kMaxDeltaSeg = 60;

  /// Salto de tiempo a partir del cual se considera que hubo un HUECO de GPS
  /// (apagado, sin señal, app cerrada) y se corta el grupo.
  ///
  /// Es la corrección más importante del servicio. Sin cortar, dos puntos
  /// separados por horas quedan contiguos en la secuencia y provocan dos
  /// errores graves:
  ///   · la distancia en línea recta entre ambos se suma como recorrido real
  ///     (si apagó el GPS en el lote y lo encendió en la base, aparecen
  ///     kilómetros que nadie recorrió);
  ///   · el LINESTRING dibuja una recta que atraviesa el hueco, que en el mapa
  ///     se ve como si la máquina hubiera volado.
  ///
  /// Con el corte, cada lado del hueco es un tramo independiente: la distancia
  /// no se inventa y el mapa muestra la discontinuidad tal como ocurrió.
  ///
  /// 120 s son 24 ciclos perdidos con el intervalo normal de 5 s: lo bastante
  /// alto para no fragmentar por una pérdida breve de señal.
  static const kMaxGapSeg = 120;

  final AppDatabase _db;

  GpsEventBuilderService({required AppDatabase db}) : _db = db;

  /// Lee los puntos de la jornada y devuelve los tres arrays listos para
  /// embeberse en el payload de sincronización.
  ///
  /// Devuelve un mapa vacío si no hay puntos suficientes — el SP omite los
  /// bloques de eventos cuando no llegan.
  Future<Map<String, dynamic>> construirEventos(String registroId) async {
    try {
      final puntos = await _leerPuntos(registroId);
      if (puntos.length < 2) {
        developer.log(
          'Sin puntos suficientes para derivar eventos ($registroId): ${puntos.length}',
          name: _tag,
        );
        return const {};
      }

      final visitas = derivarVisitas(puntos);
      final paradas = derivarParadas(puntos);
      final tramos = derivarTramos(puntos);

      developer.log(
        'Eventos derivados ($registroId): ${visitas.length} visita(s), '
        '${paradas.length} parada(s), ${tramos.length} tramo(s) '
        'desde ${puntos.length} punto(s)',
        name: _tag,
      );

      return {
        if (visitas.isNotEmpty)
          'gps_visitas': visitas.map((v) => v.toJson()).toList(),
        if (paradas.isNotEmpty)
          'gps_paradas': paradas.map((p) => p.toJson()).toList(),
        if (tramos.isNotEmpty)
          'gps_tramos': tramos.map((t) => t.toJson()).toList(),
      };
    } catch (e) {
      // Los eventos son valor agregado: si fallan, la jornada debe sincronizar
      // igual con la ruta consolidada.
      developer.log('Error derivando eventos — se omiten: $e', name: _tag, error: e);
      return const {};
    }
  }

  Future<List<GpsPunto>> _leerPuntos(String registroId) async {
    // El LEFT JOIN a lotes_local resuelve el nombre del sublote, que en la
    // tabla GPS solo se guarda como id.
    final rows = await _db.customSelect(
      'SELECT g.latitud, g.longitud, g.captured_at, g.velocidad_kmh, '
      '       g.tipo_movimiento, g.sublote_id, l.lote_nombre '
      'FROM "$_kGpsTable" g '
      'LEFT JOIN lotes_local l ON l.id_erp = g.sublote_id '
      'WHERE g.registro_id = ? '
      'ORDER BY g.secuencia',
      variables: [Variable.withString(registroId)],
    ).get();

    return rows
        .map((r) => GpsPunto(
              lat: r.read<double>('latitud'),
              lon: r.read<double>('longitud'),
              at: r.readNullable<int>('captured_at') ?? 0,
              velKmh: r.readNullable<double>('velocidad_kmh') ?? 0.0,
              tipo: r.readNullable<String>('tipo_movimiento') ?? 'TRASLADO',
              subloteId: r.readNullable<int>('sublote_id'),
              subloteNombre: r.readNullable<String>('lote_nombre'),
            ))
        .where((p) => p.at > 0)
        .toList();
  }

  // ─── Derivación (puras, testeables sin base de datos) ──────────────────────

  /// Agrupa puntos consecutivos por sublote y produce una visita por estadía.
  ///
  /// Tres pasos, en este orden:
  ///   1. Agrupar consecutivos con el mismo `subloteId`.
  ///   2. Descartar grupos más cortos que [kMinSegundosVisita] (ruido de borde).
  ///   3. Fusionar grupos contiguos del mismo sublote que quedaron separados
  ///      justamente por ese ruido descartado.
  static List<GpsVisita> derivarVisitas(List<GpsPunto> puntos) {
    final grupos = _agruparConsecutivos(puntos, (p) => p.subloteId);

    // Solo estadías dentro de un lote, con duración suficiente
    final candidatos = grupos
        .where((g) => g.first.subloteId != null)
        .where((g) => _duracionSeg(g) >= kMinSegundosVisita)
        .toList();

    // Fusionar estadías consecutivas del mismo sublote.
    // No se fusionan a través de un hueco de GPS: si dejamos de ver la máquina
    // media hora, no podemos afirmar que se quedó dentro del lote. Dos visitas
    // separadas es la lectura honesta del dato.
    final fusionados = <List<GpsPunto>>[];
    for (final g in candidatos) {
      final previo = fusionados.isEmpty ? null : fusionados.last;
      final continua = previo != null &&
          previo.first.subloteId == g.first.subloteId &&
          (g.first.at - previo.last.at) <= kMaxGapSeg * 1000;

      if (continua) {
        previo.addAll(g);
      } else {
        fusionados.add([...g]);
      }
    }

    return fusionados.map((g) {
      final m = _metricas(g);
      return GpsVisita(
        subloteId: g.first.subloteId!,
        nombre: g.first.subloteNombre,
        entradaAt: g.first.at,
        salidaAt: g.last.at,
        minutos: (_duracionSeg(g) / 60).round(),
        km: m.km,
        velPromKmh: m.velProm,
        velMaxKmh: m.velMax,
        puntos: g.length,
      );
    }).toList();
  }

  /// Agrupa puntos consecutivos marcados como PARADO y conserva los grupos que
  /// superan [kMinMinutosParada]. La ubicación es el centroide del grupo.
  static List<GpsParada> derivarParadas(List<GpsPunto> puntos) {
    final grupos = _agruparConsecutivos(puntos, (p) => p.tipo)
        .where((g) => g.first.tipo == 'PARADO')
        .where((g) => _duracionSeg(g) >= kMinMinutosParada * 60)
        .toList();

    var orden = 0;
    return grupos.map((g) {
      orden++;
      final lat = g.map((p) => p.lat).reduce((a, b) => a + b) / g.length;
      final lon = g.map((p) => p.lon).reduce((a, b) => a + b) / g.length;
      // Sublote de la parada: el primero no nulo del grupo. Si la máquina paró
      // fuera de todo lote queda nulo, que es justo lo que interesa detectar.
      final sublote = g
          .map((p) => p.subloteId)
          .firstWhere((id) => id != null, orElse: () => null);

      return GpsParada(
        orden: orden,
        lat: lat,
        lon: lon,
        inicioAt: g.first.at,
        finAt: g.last.at,
        minutos: (_duracionSeg(g) / 60).round(),
        subloteId: sublote,
      );
    }).toList();
  }

  /// Parte el recorrido en tramos contiguos del mismo tipo de movimiento.
  /// Cada tramo lleva su propia geometría WKT para poder pintarlo por color.
  static List<GpsTramo> derivarTramos(List<GpsPunto> puntos) {
    final grupos = _agruparConsecutivos(puntos, (p) => p.tipo);

    var orden = 0;
    return grupos.map((g) {
      orden++;
      final m = _metricas(g);
      return GpsTramo(
        orden: orden,
        tipo: g.first.tipo,
        wkt: _wkt(g),
        inicioAt: g.first.at,
        finAt: g.last.at,
        minutos: (_duracionSeg(g) / 60).round(),
        km: m.km,
        velPromKmh: m.velProm,
        velMaxKmh: m.velMax,
        puntos: g.length,
        subloteId: g.first.subloteId,
      );
    }).toList();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Parte la lista en grupos de puntos consecutivos con la misma clave.
  ///
  /// Corta también cuando entre dos puntos hay más de [kMaxGapSeg] segundos,
  /// aunque la clave no cambie: ese salto es un hueco de GPS y unir sus
  /// extremos inventaría distancia y geometría inexistentes.
  static List<List<GpsPunto>> _agruparConsecutivos(
    List<GpsPunto> puntos,
    Object? Function(GpsPunto) clave,
  ) {
    final grupos = <List<GpsPunto>>[];
    for (final p in puntos) {
      final anterior = grupos.isEmpty ? null : grupos.last.last;
      final hayHueco =
          anterior != null && (p.at - anterior.at) > kMaxGapSeg * 1000;

      if (grupos.isEmpty || hayHueco || clave(grupos.last.first) != clave(p)) {
        grupos.add([p]);
      } else {
        grupos.last.add(p);
      }
    }
    return grupos;
  }

  /// Duración de un grupo, sumando los deltas entre puntos consecutivos y
  /// topando cada delta en [kMaxDeltaSeg] para no contar huecos de señal.
  static int _duracionSeg(List<GpsPunto> g) {
    var total = 0;
    for (var i = 1; i < g.length; i++) {
      final d = ((g[i].at - g[i - 1].at) / 1000).round();
      total += d.clamp(0, kMaxDeltaSeg);
    }
    return total;
  }

  static ({double km, double velProm, double velMax}) _metricas(
      List<GpsPunto> g) {
    var metros = 0.0;
    for (var i = 1; i < g.length; i++) {
      metros += Geolocator.distanceBetween(
          g[i - 1].lat, g[i - 1].lon, g[i].lat, g[i].lon);
    }

    // El promedio solo considera puntos en movimiento: incluir los detenidos
    // hundiría la velocidad de trabajo hacia cero.
    final enMovimiento = g.where((p) => p.velKmh > 0).toList();
    final velProm = enMovimiento.isEmpty
        ? 0.0
        : enMovimiento.map((p) => p.velKmh).reduce((a, b) => a + b) /
            enMovimiento.length;
    final velMax = g.isEmpty
        ? 0.0
        : g.map((p) => p.velKmh).reduce((a, b) => a > b ? a : b);

    return (km: metros / 1000.0, velProm: velProm, velMax: velMax);
  }

  /// WKT en el orden que espera SQL Server GEOGRAPHY: longitud primero.
  static String _wkt(List<GpsPunto> g) {
    String par(GpsPunto p) =>
        '${p.lon.toStringAsFixed(7)} ${p.lat.toStringAsFixed(7)}';
    if (g.length == 1) return 'POINT(${par(g.first)})';
    return 'LINESTRING(${g.map(par).join(', ')})';
  }
}
