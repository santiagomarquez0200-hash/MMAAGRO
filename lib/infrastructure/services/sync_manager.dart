import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/exceptions.dart';
import 'package:agro_aplicaciones/core/network/network_info.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/infrastructure/network/sp_contract.dart';

/// Resultado de una pasada de sincronización manual.
class SyncResult {
  final int succeeded;
  final int failed;
  final int permanentlyFailed;

  const SyncResult({
    this.succeeded = 0,
    this.failed = 0,
    this.permanentlyFailed = 0,
  });

  bool get hasPermFailed => permanentlyFailed > 0;

  @override
  String toString() =>
      'SyncResult(ok:$succeeded, failed:$failed, permFailed:$permanentlyFailed)';
}

// ─── Etiqueta de endpoint para logs legibles ──────────────────────────────────
String _labelEndpoint(String endpoint, String method) {
  if (method == 'POST' && endpoint == '/registros') return '🚜 TRACTOR — Crear registro (SP_MMA_SINCRONIZAR_OFFLINE)';
  if (method == 'POST' && endpoint == '/registros/vehiculo') return '🚛 VEHÍCULO — Crear registro (SP_MMA_SINCRONIZAR_OFFLINE)';
  if (method == 'PUT' && endpoint == 'PUT /registros/vehiculo') return '🚛 VEHÍCULO — Actualizar registro (SP_MMA_SINCRONIZAR_OFFLINE)';
  if (endpoint.contains('/cerrar')) return '🔒 TRACTOR — Cerrar turno (SP_MMA_CERRAR_TURNO)';
  if (endpoint.contains('/checklist')) return '✅ Guardar checklist (SP_MMA_GUARDAR_CHECKLIST)';
  if (endpoint.contains('/paros')) return '⏸️ Registrar paro (SP_MMA_REGISTRAR_PARO)';
  if (endpoint.contains('/bines')) return '📦 Registrar bin (SP_MMA_REGISTRAR_BIN)';
  if (endpoint.contains('/aprobar')) return '👤 Aprobar/rechazar (SP_MMA_APROBAR_REGISTRO)';
  if (endpoint.contains('portero') || endpoint.contains('lectura')) return '🔍 Lectura portería (SP_MMA_REGISTRAR_LECTURA_PORTERO)';
  if (endpoint.contains('jornada')) return '⏱️ Status jornada (SP_MMA_ACTUALIZAR_STATUS_JORNADA)';
  return '$method $endpoint';
}

/// SyncManager: Procesa la tabla Outbox en orden FIFO.
/// SOLO sincronización manual — no hay auto-sync por timer ni por conectividad.
///
/// ─── DIFERENCIA TRACTOR vs VEHÍCULO ─────────────────────────────────────────
/// VEHÍCULO: 2 entradas en el outbox por registro completo.
///   1. POST /registros/vehiculo  → SP_MMA_SINCRONIZAR_OFFLINE con TODO incluido
///      (paros_vehiculo, combustibles, checklist, tiempos) en un solo JSON.
///   2. POST /{id}/checklist      → SP_MMA_GUARDAR_CHECKLIST
///
/// TRACTOR: N entradas (varía según cuántos paros/bines tenga el registro).
///   1. POST /registros           → SP_MMA_SINCRONIZAR_OFFLINE (datos base)
///   2. POST /{id}/checklist      → SP_MMA_GUARDAR_CHECKLIST
///   3. POST /{id}/paros × N      → SP_MMA_REGISTRAR_PARO (uno por cada paro)
///   4. POST /{id}/bines × N      → SP_MMA_REGISTRAR_BIN (uno por cada franja horaria)
///   5. PUT  /{id}/cerrar         → SP_MMA_CERRAR_TURNO (horómetros finales, lotes, sublabores)
///
/// Por eso tractor puede tener 15-20 entradas y vehículo solo 2.
/// ─────────────────────────────────────────────────────────────────────────────
class SyncManager {
  final AppDatabase _db;
  final ErpApiClient _erp;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySub;

  SyncManager({
    required AppDatabase db,
    required ErpApiClient erp,
    required NetworkInfo networkInfo,
    Logger? logger,
  })  : _db = db,
        _erp = erp,
        _networkInfo = networkInfo,
        _logger = logger ??
            Logger(
              printer: PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 8,
                lineLength: 120,
                printEmojis: true,
              ),
            );

  /// Escucha la conectividad y dispara sync automático al recuperar red.
  /// Al iniciar también resetea entradas permanently_failed → failed para
  /// que sean reintentadas (política anterior tenía límite de 5, la nueva no).
  void start() {
    _resetPermFailedToFailed();
    _connectivitySub?.cancel();
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((isConnected) async {
      if (isConnected && !_isSyncing) {
        final pending = await _db.outboxDao.countPending();
        if (pending > 0) {
          _logger.i('📶 [SyncManager] Red recuperada — $pending entrada(s) pendiente(s). Iniciando auto-sync.');
          await processOutbox();
        }
      }
    });
  }

  Future<void> _resetPermFailedToFailed() async {
    try {
      final permFailed = await _db.outboxDao.getPermFailed();
      if (permFailed.isEmpty) return;
      _logger.i('🔄 [SyncManager] Reseteando ${permFailed.length} entrada(s) permanently_failed → failed (sin límite de reintentos).');
      for (final e in permFailed) {
        await _db.outboxDao.resetForRetry(e.id);
      }
    } catch (_) {}
  }

  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Procesa la tabla Outbox en orden FIFO (solo manual).
  Future<SyncResult> processOutbox() async {
    if (_isSyncing) {
      _logger.w('⚠️ [SyncManager] Ya hay un proceso de sync en curso. Ignorando solicitud duplicada.');
      return const SyncResult();
    }
    _isSyncing = true;

    int succeeded = 0;
    int failed = 0;
    int permanentlyFailed = 0;

    try {
      final entries = await _db.outboxDao.getPendingEntries();

      // ── CABECERA DEL PROCESO ──────────────────────────────────────────────────
      _logger.i('');
      _logger.i('╔══════════════════════════════════════════════════════════════╗');
      _logger.i('║         SYNC OUTBOX — INICIO DE PROCESO                     ║');
      _logger.i('╚══════════════════════════════════════════════════════════════╝');
      _logger.i('📋 Total de entradas en cola: ${entries.length}');

      if (entries.isEmpty) {
        _logger.i('✅ No hay entradas pendientes. Nada que sincronizar.');
        return const SyncResult();
      }

      // Mostrar resumen de lo que hay en la cola ANTES de procesar
      _logger.i('── COLA DE ENVÍO (en orden FIFO) ───────────────────────────────');
      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        _logger.i('  [${i + 1}/${entries.length}] ${_labelEndpoint(e.endpoint, e.method)}'
            ' | registroId: ${e.registroLocalId ?? "N/A"}'
            ' | intentos previos: ${e.retryCount}');
      }
      _logger.i('────────────────────────────────────────────────────────────────');

      // Mapa local→servidor para GUID mismatch dentro de esta sesión.
      final guidMap = <String, String>{};

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];

        // ── VERIFICAR CONECTIVIDAD ANTES DE CADA ENTRADA ──────────────────────
        if (!await _networkInfo.isConnected) {
          _logger.w('📵 [${i + 1}/${entries.length}] Sin conexión a internet. Deteniendo sync.');
          // Marcar la entrada actual como fallida y romper el loop
          await _db.outboxDao.markFailed(entry.id, 'Sin conexión', entry.retryCount + 1);
          failed++;
          break;
        }

        final label = _labelEndpoint(entry.endpoint, entry.method);
        _logger.i('');
        _logger.i('▶ [${i + 1}/${entries.length}] $label');
        _logger.i('   registroLocalId : ${entry.registroLocalId ?? "N/A"}');
        _logger.i('   método          : ${entry.method}');
        _logger.i('   endpoint        : ${entry.endpoint}');
        _logger.i('   intento #       : ${entry.retryCount + 1}');

        try {
          await _db.outboxDao.markSyncing(entry.id);
          final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;

          // Log del payload (truncado para no saturar logs)
          final payloadStr = jsonEncode(payload);
          _logger.d('   payload         : ${payloadStr.length > 500 ? '${payloadStr.substring(0, 500)}...' : payloadStr}');

          final localId = entry.registroLocalId;
          final effectiveId = (localId != null) ? (guidMap[localId] ?? localId) : null;
          if (effectiveId != localId) {
            _logger.i('   🔄 GUID resuelto : $localId → $effectiveId (mismatch de sesión)');
          }

          final newGuid = await _executeRequest(
            entry.endpoint,
            entry.method,
            payload,
            resolvedRegistroId: effectiveId,
            entryIndex: i + 1,
            totalEntries: entries.length,
          );

          // Propagar GUID mismatch si el servidor asignó un ID diferente
          final effectiveLocalId = entry.registroLocalId;
          if (newGuid != null && effectiveLocalId != null) {
            _logger.i('   🔄 GUID del servidor difiere del local:');
            _logger.i('      local  : $effectiveLocalId');
            _logger.i('      server : $newGuid');
            _logger.i('   Actualizando cascada en SQLite y outbox...');
            guidMap[effectiveLocalId] = newGuid;
            await _db.transaction(() async {
              await _db.registroDao.updateRegistroIdCascade(effectiveLocalId, newGuid);
              await _db.outboxDao.updateRegistroLocalId(effectiveLocalId, newGuid);
            });
            _logger.i('   ✅ Cascada aplicada.');
          }

          await _db.outboxDao.markDone(entry.id);
          _logger.i('   ✅ ÉXITO — entrada marcada como done en SQLite.');
          succeeded++;

          // Si no quedan pendientes para este registro, marcarlo como sincronizado
          final resolvedId = newGuid ?? effectiveLocalId;
          if (resolvedId != null) {
            final remaining = await _countPendingForRegistro(resolvedId);
            _logger.i('   📊 Entradas restantes para este registro: $remaining');
            if (remaining == 0) {
              await _db.registroDao.markSincronizado(resolvedId);
              _logger.i('   🏁 Registro $resolvedId marcado como sincronizado en SQLite.');
            }
          }

        } on SpValidationException catch (e) {
          // Bug de contrato — fallo permanente inmediato (no se reintenta)
          _logger.e('   ❌ ERROR DE CONTRATO (bug de código) → ${e.message}');
          _logger.e('   ⛔ Marcado como PERMANENTEMENTE FALLIDO. No se reintentará.');
          await _db.outboxDao.markPermFailed(entry.id, e.message, entry.retryCount + 1);
          permanentlyFailed++;

        } on ConflictException catch (e) {
          // El servidor ya tiene el dato → tratar como éxito
          _logger.w('   ⚠️ CONFLICTO (dato ya existe en servidor) → ${e.message}');
          _logger.w('   Tratando como éxito (idempotente).');
          await _db.outboxDao.markDone(entry.id);
          succeeded++;
          final conflictId = entry.registroLocalId;
          if (conflictId != null) {
            final remaining = await _countPendingForRegistro(conflictId);
            if (remaining == 0) await _db.registroDao.markSincronizado(conflictId);
          }

        } on NetworkException {
          // Sin red real → parar el loop (no tiene sentido continuar)
          _logger.e('   📵 SIN CONEXIÓN A INTERNET → deteniendo loop de sync.');
          _logger.e('   Los datos quedan en SQLite/outbox y se reintentarán en el próximo sync.');
          await _db.outboxDao.markFailed(entry.id, 'Sin conexión', entry.retryCount + 1);
          failed++;
          break;

        } on ErpTimeoutException {
          // Timeout del servidor → continuar con la siguiente entrada
          _logger.w('   ⏱️ TIMEOUT DEL SERVIDOR (>${AppEnvironment.erpReceiveTimeout.inSeconds}s).');
          _logger.w('   El dato PUEDE haber llegado al servidor (el SP puede seguir ejecutándose).');
          _logger.w('   Continuando con la siguiente entrada (dato queda en outbox para reintento).');
          await _db.outboxDao.markFailed(
            entry.id,
            'Timeout del servidor (>${AppEnvironment.erpReceiveTimeout.inSeconds}s)',
            entry.retryCount + 1,
          );
          failed++;

        } on ServerException catch (e) {
          final newCount = entry.retryCount + 1;
          _logger.e('   ❌ ERROR DEL SERVIDOR → ${e.message}');
          _logger.e('   El SP respondió con success=0 o HTTP error.');
          _logger.w('   🔁 Intento $newCount (sin límite). Se reintentará automáticamente al recuperar red.');
          await _db.outboxDao.markFailed(entry.id, e.message, newCount);
          failed++;

        } catch (e) {
          final newCount = entry.retryCount + 1;
          _logger.e('   ❌ ERROR INESPERADO → $e');
          _logger.w('   🔁 Intento $newCount (sin límite). Se reintentará automáticamente al recuperar red.');
          await _db.outboxDao.markFailed(entry.id, e.toString(), newCount);
          failed++;
        }
      }
    } finally {
      _isSyncing = false;
    }

    // ── REPORTE FINAL ─────────────────────────────────────────────────────────
    final result = SyncResult(
      succeeded: succeeded,
      failed: failed,
      permanentlyFailed: permanentlyFailed,
    );

    _logger.i('');
    _logger.i('╔══════════════════════════════════════════════════════════════╗');
    _logger.i('║         SYNC OUTBOX — REPORTE FINAL                         ║');
    _logger.i('╚══════════════════════════════════════════════════════════════╝');
    _logger.i('  ✅ Exitosos        : $succeeded');
    _logger.i('  🔁 Fallidos (temp) : $failed  ← se reintentarán automáticamente al recuperar red');
    _logger.i('  ⛔ Bug de contrato : $permanentlyFailed  ← requieren corrección de código');
    _logger.i('  ─────────────────────────────────────────────────────────────');
    if (failed == 0 && permanentlyFailed == 0) {
      _logger.i('  🎉 SINCRONIZACIÓN COMPLETA. Todos los datos están en el ERP.');
    } else if (failed > 0) {
      _logger.w('  ⚠️ Quedan $failed entradas en outbox. Se reintentarán solas cuando haya red.');
    }
    if (permanentlyFailed > 0) {
      _logger.e('  🆘 $permanentlyFailed entradas con error de contrato (SpValidationException). Revisar código.');
    }
    _logger.i('══════════════════════════════════════════════════════════════');
    return result;
  }

  Future<int> _countPendingForRegistro(String registroLocalId) async {
    final all = await _db.outboxDao.getPendingEntries();
    return all.where((e) => e.registroLocalId == registroLocalId).length;
  }

  /// Mapea endpoint+method → SP y ejecuta via ErpApiClient.
  /// Devuelve el GUID del servidor si difiere del local; null si son iguales.
  Future<String?> _executeRequest(
    String endpoint,
    String method,
    Map<String, dynamic> payload, {
    String? resolvedRegistroId,
    int entryIndex = 0,
    int totalEntries = 0,
  }) async {
    final segments = Uri.parse(endpoint).pathSegments;
    String resolveId() => resolvedRegistroId ?? segments[1];

    // Obtener numero_registro desde SQLite para mayor resiliencia
    String? numeroRegistro;
    if (resolvedRegistroId != null || segments.length > 1) {
      final rid = resolveId();
      final reg = await _db.registroDao.getRegistroById(rid);
      numeroRegistro = reg?.numeroRegistro;
      _logger.d('   registroId→numero: $rid → ${numeroRegistro ?? "NO ENCONTRADO en SQLite"}');
    }

    if (method == 'POST') {
      // ── TRACTOR: registro principal ─────────────────────────────────────────
      if (endpoint == '/registros') {
        _logger.i('   🚜 Llamando SP_MMA_SINCRONIZAR_OFFLINE (tipo=tractor)');
        _logger.i('      El payload incluye: datos base, horómetros inicio, sublabores.');
        _logger.i('      Los paros, bines y cerrar turno van en entradas separadas del outbox.');
        final localId = payload['id']?.toString();
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spSincronizarOffline,
          parametros: [jsonEncode(payload)],
        );
        return _assertSyncSuccess(result, endpoint, localId);

      // ── VEHÍCULO: registro principal ────────────────────────────────────────
      } else if (endpoint == 'POST /registros/vehiculo') {
        _logger.i('   🚛 Llamando SP_MMA_SINCRONIZAR_OFFLINE (tipo=vehiculo)');
        _logger.i('      El payload incluye TODO en una sola llamada:');
        _logger.i('      paros_vehiculo + combustibles + checklist + tiempos.');
        _logger.i('      Solo queda el checklist como entrada separada.');
        final localId = payload['id']?.toString();
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spSincronizarOffline,
          parametros: [jsonEncode(payload)],
        );
        final serverId = _assertSyncSuccess(result, endpoint, localId);
        if (serverId != null && serverId != localId) return serverId;
        return null;

      // ── VEHÍCULO: actualización ─────────────────────────────────────────────
      } else if (endpoint == 'PUT /registros/vehiculo') {
        _logger.i('   🚛 Llamando SP_MMA_SINCRONIZAR_OFFLINE (actualizar vehículo)');
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spSincronizarOffline,
          parametros: [jsonEncode(payload)],
        );
        _assertSyncSuccess(result, endpoint, null);

      // ── PORTERO ─────────────────────────────────────────────────────────────
      } else if (endpoint == 'POST /portero/lecturas') {
        _logger.i('   🔍 Llamando SP_MMA_REGISTRAR_LECTURA_PORTERO');
        await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spRegistrarLecturaPortero,
          parametros: [jsonEncode(payload)],
        );

      // ── JORNADA ─────────────────────────────────────────────────────────────
      // ⚠️ CLI547_AGMSP_MMA_REGISTRAR_JORNADA no está en la lista de SPs activos
      // del servidor (implementacion.txt). Verificar si fue eliminado o absorbido
      // por SINCRONIZAR_OFFLINE antes de reconectar este bloque.
      } else if (endpoint == 'POST /jornada') {
        _logger.w('   ⚠️ POST /jornada: SP REGISTRAR_JORNADA no disponible en servidor actualizado. Entrada saltada.');
        // No lanzar excepción — dejar que el outbox marque como done
        // para no bloquear la cola. Revisar con DBA el SP correspondiente.

      // ── CHECKLIST (vehículo — tractor usa payload consolidado) ──────────────
      } else if (endpoint.contains('/checklist')) {
        final registroId = resolveId();
        final resultados = payload['resultados'] as List;
        _logger.i('   ✅ Llamando SP_MMA_GUARDAR_CHECKLIST');
        _logger.i('      registroId    : $registroId');
        _logger.i('      numero_registro: $numeroRegistro');
        _logger.i('      items a guardar: ${resultados.length}');
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spGuardarChecklist,
          parametros: [registroId, numeroRegistro, jsonEncode(resultados)],
        );
        _logSpResult('SP_MMA_GUARDAR_CHECKLIST', result);

      // ── BINES (legacy — tractor usa payload consolidado desde v7.2) ──────────
      } else if (endpoint.contains('/bines')) {
        final registroId = resolveId();
        _logger.i('   📦 Llamando SP_MMA_REGISTRAR_BIN');
        _logger.i('      registroId    : $registroId');
        _logger.i('      franja        : ${payload['franja_horaria']} (${payload['turno']})');
        _logger.i('      cantidad      : ${payload['cantidad']}');
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spRegistrarBin,
          parametros: [
            registroId,
            numeroRegistro,
            payload['franja_horaria'],
            payload['turno'],
            payload['cantidad'],
          ],
        );
        _logSpResult('SP_MMA_REGISTRAR_BIN', result);

      // ── PAROS (legacy — tractor usa payload consolidado desde v7.2) ─────────
      } else if (endpoint.contains('/paros')) {
        final registroId = resolveId();
        _logger.i('   ⏸️ Llamando SP_MMA_REGISTRAR_PARO');
        _logger.i('      registroId    : $registroId');
        _logger.i('      tipo_paro_id  : ${payload['tipo_paro_id']}');
        _logger.i('      hora_inicio   : ${payload['hora_inicio']} → ${payload['hora_final']}');
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spRegistrarParo,
          parametros: [
            registroId,
            numeroRegistro,
            payload['tipo_paro_id'],
            payload['motivo'],
            payload['equipo'],
            payload['hora_inicio'],
            payload['hora_final'],
            payload['galones'],
          ],
        );
        _logSpResult('SP_MMA_REGISTRAR_PARO', result);
      }

    } else if (method == 'PUT') {
      // ── CERRAR TURNO (legacy — tractor usa payload consolidado desde v7.2) ──
      if (endpoint.contains('/cerrar')) {
        final registroId = resolveId();
        _logger.i('   🔒 Llamando SP_MMA_CERRAR_TURNO');
        _logger.i('      registroId      : $registroId');
        _logger.i('      numero_registro  : $numeroRegistro');
        _logger.i('      tractor_final   : ${payload['tractor_final']}');
        _logger.i('      implemento_final: ${payload['implemento_final']}');
        _logger.i('      hora_salida_pto : ${payload['hora_salida_punto']}');
        _logger.i('      hora_llg_taller : ${payload['hora_llegada_taller']}');
        _logger.i('      hora_refrigerio : ${payload['hora_refrigerio']}');
        _logger.i('      tiene_lotes     : ${payload['lotes_json'] != null}');
        _logger.i('      tiene_sublabores: ${payload['sublabores_json'] != null}');
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spCerrarTurno,
          parametros: [
            registroId,
            numeroRegistro,
            payload['tractor_final'],
            payload['implemento_final'],
            payload['hora_salida_punto'],
            payload['hora_llegada_taller'],
            payload['hora_refrigerio'],
            payload['lotes_json'],
            payload['sublabores_json'],
            payload['marchas_json'],
            payload['observaciones_maq'],
          ],
        );
        // Verificar resultado (antes no se chequeaba — ahora sí)
        _assertCerrarSuccess(result);

      // ── APROBAR / RECHAZAR ───────────────────────────────────────────────────
      } else if (endpoint.contains('/aprobar')) {
        final registroId = resolveId();
        _logger.i('   👤 Llamando SP_MMA_APROBAR_REGISTRO');
        _logger.i('      accion: ${payload['accion']}');
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spAprobarRegistro,
          parametros: [
            registroId,
            payload['supervisor_id_erp'],
            payload['accion'],
            payload['motivo'],
          ],
        );
        if (result.isEmpty) {
          throw const ServerException(
              message: 'SP_MMA_APROBAR_REGISTRO no retornó ningún resultado');
        }
        final row = result.first;
        final successVal = row['success'];
        final isSuccess = successVal == true ||
            successVal == 1 ||
            successVal?.toString() == '1' ||
            successVal?.toString().toLowerCase() == 'true';
        if (!isSuccess) {
          throw ServerException(
              message: row['mensaje']?.toString() ?? 'Error al aprobar registro');
        }
        _logger.i('   ✅ SP_MMA_APROBAR_REGISTRO OK → ${row['mensaje']}');
      }
    }
    return null;
  }

  /// Verifica que SP_MMA_SINCRONIZAR_OFFLINE retornó success=1.
  /// Lanza [ServerException] si success=0 o result vacío.
  /// Retorna el GUID del servidor (puede diferir del local en case/formato).
  String? _assertSyncSuccess(
    List<Map<String, dynamic>> result,
    String endpoint,
    String? localId,
  ) {
    if (result.isEmpty) {
      throw const ServerException(
        message: 'SP_MMA_SINCRONIZAR_OFFLINE no retornó ningún resultado. '
            'Verificar que el SP esté actualizado en la BD.',
      );
    }
    final row = result[0];
    final successVal = row['success'];
    final isSuccess = successVal == true ||
        successVal == 1 ||
        successVal?.toString() == '1' ||
        successVal?.toString().toLowerCase() == 'true';

    _logger.i('   📨 Respuesta del SP:');
    _logger.i('      success     : $successVal → ${isSuccess ? "✅ OK" : "❌ FALLÓ"}');
    _logger.i('      mensaje     : ${row['mensaje']}');
    _logger.i('      registro_id : ${row['registro_id']}');
    _logger.i('      ya_existia  : ${row['ya_existia']}');

    if (!isSuccess) {
      final msg = row['mensaje']?.toString() ??
          'El SP reportó error sin mensaje (endpoint: $endpoint)';
      _logger.e('   ❌ El SP rechazó el dato → $msg');
      _logger.e('   El registro permanece en SQLite/outbox para reintento.');
      throw ServerException(message: msg);
    }

    final serverId = row['registro_id']?.toString();
    if (serverId != null && localId != null &&
        serverId.toUpperCase() != localId.toUpperCase()) {
      _logger.i('   ℹ️ GUID mismatch detectado (diferencia de case/formato):');
      _logger.i('      local : $localId');
      _logger.i('      server: $serverId');
    }
    return serverId;
  }

  /// Verifica el resultado de SP_MMA_CERRAR_TURNO.
  void _assertCerrarSuccess(List<Map<String, dynamic>> result) {
    if (result.isEmpty) {
      _logger.w('   ⚠️ SP_MMA_CERRAR_TURNO no retornó result set (puede estar OK igual).');
      return;
    }
    final row = result[0];
    final successVal = row['success'];
    final isSuccess = successVal == true ||
        successVal == 1 ||
        successVal?.toString() == '1' ||
        successVal?.toString().toLowerCase() == 'true';

    _logger.i('   📨 Respuesta SP_MMA_CERRAR_TURNO:');
    _logger.i('      success : $successVal → ${isSuccess ? "✅ OK" : "❌ FALLÓ"}');
    _logger.i('      mensaje : ${row['mensaje']}');

    if (!isSuccess) {
      final msg = row['mensaje']?.toString() ?? 'Error al cerrar turno';
      _logger.e('   ❌ SP_MMA_CERRAR_TURNO falló → $msg');
      throw ServerException(message: msg);
    }
  }

  /// Log y validación de resultado de SP secundarios (checklist, paros, bines).
  /// Lanza [ServerException] si el SP reporta success=0 para que el outbox
  /// marque la entrada como failed y la reintente — nunca marcar done en falso.
  void _logSpResult(String spName, List<Map<String, dynamic>> result) {
    if (result.isEmpty) {
      _logger.w('   ⚠️ $spName no retornó result set.');
      return;
    }
    final row = result[0];
    final successVal = row['success'];
    final isSuccess = successVal == true ||
        successVal == 1 ||
        successVal?.toString() == '1' ||
        successVal?.toString().toLowerCase() == 'true';
    _logger.i('   📨 $spName → success: ${isSuccess ? "✅" : "❌"} | ${row['mensaje'] ?? ""}');
    if (!isSuccess) {
      final msg = row['mensaje']?.toString() ?? '$spName reportó error sin mensaje';
      _logger.e('   ❌ $spName rechazó los datos → $msg');
      _logger.e('   Entrada marcada como failed para reintento automático.');
      throw ServerException(message: msg);
    }
  }
}
