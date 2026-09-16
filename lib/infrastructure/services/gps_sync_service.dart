import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/infrastructure/services/connectivity_service.dart';

/// Servicio singleton de sincronización automática de puntos GPS.
///
/// Responsabilidad única: leer puntos GPS pendientes (enviado = 0) de SQLite
/// y enviarlos al SP [CLI547_AGMSP_MMA_REGISTRAR_PUNTOS_GPS] en SQL Server.
///
/// Disparadores de envío:
///   1. Restauración de cobertura: [ConnectivityService.onConnectivityChanged] → flush inmediato.
///   2. Timer periódico cada [_kFlushInterval]: cubre el caso "ya había cobertura".
///   3. [flushNow]: llamada explícita (ej: al crear un registro con cobertura activa).
///
/// Comportamiento offline:
///   — Los puntos permanecen en SQLite con enviado = 0.
///   — Al recuperar cobertura, el listener los envía automáticamente.
///   — Si el APK estaba minimizado (Foreground Service GPS activo), el listener
///     y el timer siguen vivos → el envío ocurre sin que el usuario intervenga.
///   — Si el APK fue cerrado completamente: los puntos quedan en SQLite y se
///     envían en el siguiente arranque cuando hay cobertura (init → flush inicial).
///
/// Resiliencia:
///   — Cada lote de puntos por registro se envía en una transacción independiente.
///   — Si falla el envío de un lote, se reintenta en el próximo flush.
///   — Solo se marcan como enviados los puntos confirmados por el SP (@p_success = 1).
class GpsSyncService {
  final AppDatabase _db;
  final ErpApiClient _erp;
  final ConnectivityService _connectivity;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _flushTimer;
  bool _isSyncing = false;

  /// Tabla GPS en SQLite — nombre físico definido por el cliente.
  static const _kGpsTable = '"CLI547_AGM_Ruta_maquinaria"';

  /// Intervalo del timer periódico de flush.
  /// 5 min cubre: GPS registra c/2 min → puntos llegan al servidor en ≤ 5 min.
  static const _kFlushInterval = Duration(minutes: 5);

  /// Retardo inicial tras arranque de la app antes del primer flush.
  /// Deja tiempo para que la BD termine de abrirse y el token ERP esté disponible.
  static const _kInitialDelay = Duration(seconds: 4);

  GpsSyncService({
    required AppDatabase db,
    required ErpApiClient erp,
    required ConnectivityService connectivity,
  })  : _db = db,
        _erp = erp,
        _connectivity = connectivity;

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Inicializar el servicio. Llamar UNA sola vez desde [initDependencies].
  void init() {
    // ① Listener de conectividad: envío inmediato al recuperar cobertura.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        developer.log(
          'GpsSync: cobertura restaurada → disparando flush de puntos pendientes',
          name: 'GpsSyncService',
        );
        _flushPendingPoints();
      }
    });

    // ② Timer periódico: envío continuo mientras hay cobertura.
    _flushTimer = Timer.periodic(_kFlushInterval, (_) {
      if (_connectivity.isOnline) _flushPendingPoints();
    });

    // ③ Flush inicial con retardo (arranca la app con cobertura activa).
    if (_connectivity.isOnline) {
      Future.delayed(_kInitialDelay, () {
        if (_connectivity.isOnline) _flushPendingPoints();
      });
    }

    developer.log('GpsSync: servicio iniciado', name: 'GpsSyncService');
  }

  /// Dispara un flush inmediato si hay cobertura.
  /// Llamar desde [HomePage] al crear un nuevo registro (por si había puntos
  /// pendientes de sesiones anteriores no enviados por falta de cobertura).
  Future<void> flushNow() async {
    if (!_connectivity.isOnline) return;
    await _flushPendingPoints();
  }

  void dispose() {
    _connectivitySub?.cancel();
    _flushTimer?.cancel();
    developer.log('GpsSync: servicio detenido', name: 'GpsSyncService');
  }

  // ─── Internos ─────────────────────────────────────────────────────────────

  /// Guard re-entrante: impide que un flush lento sea interrumpido por el timer.
  Future<void> _flushPendingPoints() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _doFlush();
    } catch (e) {
      developer.log(
        'GpsSync: error inesperado en flush — $e',
        name: 'GpsSyncService',
        error: e,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _doFlush() async {
    // 1. Leer TODOS los puntos aún no enviados, en orden de registro + secuencia.
    final rows = await _db.customSelect(
      'SELECT id, registro_id, latitud, longitud, precision, altitud, '
      '       velocidad, secuencia, captured_at '
      'FROM $_kGpsTable '
      'WHERE enviado = 0 '
      'ORDER BY registro_id, secuencia',
    ).get();

    if (rows.isEmpty) {
      developer.log('GpsSync: sin puntos GPS pendientes', name: 'GpsSyncService');
      return;
    }

    developer.log(
      'GpsSync: ${rows.length} punto(s) pendiente(s) — agrupando por registro',
      name: 'GpsSyncService',
    );

    // 2. Agrupar por registro_id.
    final Map<String, List<Map<String, dynamic>>> byRegistro = {};
    for (final row in rows) {
      final rid = row.read<String>('registro_id');
      byRegistro.putIfAbsent(rid, () => []).add({
        'id':          row.read<String>('id'),
        'latitud':     row.read<double>('latitud'),
        'longitud':    row.read<double>('longitud'),
        'precision':   row.readNullable<double>('precision'),
        'altitud':     row.readNullable<double>('altitud'),
        'velocidad':   row.readNullable<int>('velocidad'),
        'secuencia':   row.read<int>('secuencia'),
        'captured_at': row.read<int>('captured_at'),
      });
    }

    // 3. Enviar cada lote de forma independiente.
    //    Un fallo en un registro no bloquea a los demás.
    for (final entry in byRegistro.entries) {
      if (!_connectivity.isOnline) {
        developer.log('GpsSync: conexión perdida durante flush — abortando',
            name: 'GpsSyncService');
        break;
      }
      await _sendBatch(entry.key, entry.value);
    }
  }

  /// Envía los puntos de un registro al SP y los marca como enviados en SQLite.
  Future<void> _sendBatch(
      String registroId, List<Map<String, dynamic>> puntos) async {
    try {
      final puntosJson = jsonEncode(puntos);

      final result = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spRegistrarPuntosGps,
        parametros: [registroId, puntosJson],
      );

      final success = _extractBool(result, 'p_success');
      final mensaje = _extractString(result, 'p_mensaje');

      if (!success) {
        // El SP devolvió error de negocio — no marcar como enviados; reintentar.
        developer.log(
          'GpsSync: SP rechazó lote [$registroId] — $mensaje',
          name: 'GpsSyncService',
        );
        return;
      }

      // Marcar todos los puntos del lote como enviados en SQLite.
      // Los IDs son UUIDs hexadecimales sin riesgo de inyección SQL.
      final ids = puntos.map((p) => "'${p['id']}'").join(',');
      await _db.customStatement(
        'UPDATE $_kGpsTable SET enviado = 1 WHERE id IN ($ids)',
      );

      final total = _extractInt(result, 'p_total_insertados');
      developer.log(
        'GpsSync ✓ [$registroId] → $total punto(s) GPS enviados al servidor',
        name: 'GpsSyncService',
      );
    } on Exception catch (e) {
      // Error de red o token expirado — se reintentará en el próximo flush.
      developer.log(
        'GpsSync: error de red al enviar lote [$registroId] — $e',
        name: 'GpsSyncService',
        error: e,
      );
    }
  }

  // ─── Helpers de extracción de OUTPUT params del SP ────────────────────────

  bool _extractBool(List<Map<String, dynamic>> rows, String keyFragment) {
    for (final row in rows) {
      for (final entry in row.entries) {
        if (entry.key.toLowerCase().contains(keyFragment.toLowerCase())) {
          final v = entry.value;
          if (v == null) return false;
          if (v is bool) return v;
          return v.toString() == '1' || v.toString().toLowerCase() == 'true';
        }
      }
    }
    return false;
  }

  String _extractString(List<Map<String, dynamic>> rows, String keyFragment) {
    for (final row in rows) {
      for (final entry in row.entries) {
        if (entry.key.toLowerCase().contains(keyFragment.toLowerCase())) {
          return entry.value?.toString() ?? '';
        }
      }
    }
    return '';
  }

  int _extractInt(List<Map<String, dynamic>> rows, String keyFragment) {
    for (final row in rows) {
      for (final entry in row.entries) {
        if (entry.key.toLowerCase().contains(keyFragment.toLowerCase())) {
          final v = entry.value;
          if (v == null) return 0;
          return int.tryParse(v.toString()) ?? 0;
        }
      }
    }
    return 0;
  }
}
