import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/constants/app_constants.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/utils/date_utils.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/infrastructure/services/backup_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/gps_event_builder_service.dart';

class RegistroRepositoryImpl implements RegistroRepository {
  final AppDatabase _db;
  final ErpApiClient _erp;
  final _uuid = const Uuid();

  const RegistroRepositoryImpl({
    required AppDatabase db,
    required ErpApiClient erp,
  })  : _db = db,
        _erp = erp;

  // ─── Crear registro (offline-first) ──────────────────────────────────────
  @override
  Future<Either<Failure, RegistroDiario>> crearRegistro(
      CrearRegistroParams params) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final seq =
          await _nextSequenceForDate(params.fecha, params.operadorIdErp);
      final numeroRegistro = AppDateUtils.generateRegistroNumber(
          params.fecha, seq, params.operadorIdErp);

      // Todas las inserciones en una sola transacción: si cualquiera falla,
      // ninguna queda persistida — evita datos parciales e inconsistentes.
      await _db.transaction(() async {
        await _db.registroDao.insertRegistro(RegistrosDiariosLocalCompanion(
          id: Value(id),
          numeroRegistro: Value(numeroRegistro),
          fecha: Value(params.fecha),
          turno: Value(params.turno),
          procesoId: Value(params.procesoId),
          procesoNombre: Value(params.procesoNombre),
          procesoCodigo: Value(params.procesoCodigo),
          cultivoIdErp: Value(params.cultivoIdErp),
          cultivoNombreEspecie: Value(params.cultivoNombreEspecie),
          cultivoCodigoEspecie: Value(params.cultivoCodigoEspecie),
          operadorIdErp: Value(params.operadorIdErp),
          operadorCodigo: Value(params.operadorCodigo),
          operadorNombre: Value(params.operadorNombre),
          supervisorIdErp: Value(params.supervisorIdErp),
          supervisorCodigo: Value(params.supervisorCodigo),
          supervisorNombre: Value(params.supervisorNombre),
          tractorIdErp: Value(params.tractorIdErp),
          tractorCodigo: Value(params.tractorCodigo),
          tractorDescripcion: Value(params.tractorDescripcion),
          implementoIdErp: Value(params.implementoIdErp),
          implementoCodigo: Value(params.implementoCodigo),
          implementoDescripcion: Value(params.implementoDescripcion),
          cajaCambiosId: Value(params.cajaCambiosId),
          cajaCambiosNombre: Value(params.cajaCambiosNombre),
          subprocesoId: Value(params.subprocesoId),
          subprocesoNombre: Value(params.subprocesoNombre),
          estado: const Value(AppConstants.estadoBorrador),
          dispositivoId: Value(params.dispositivoId),
          sincronizado: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));

        if (params.tractorInicio != null || params.implementoInicio != null) {
          await _db.registroDao.upsertHorometro(HorometrosLocalCompanion(
            id: Value(_uuid.v4()),
            registroId: Value(id),
            tractorInicio: Value(params.tractorInicio),
            implementoInicio: Value(params.implementoInicio),
          ));
        }

        if (params.horaSalidaTaller != null || params.horaLlegadaPunto != null) {
          await _db.registroDao.upsertTiempoTurno(TiemposTurnoLocalCompanion(
            id: Value(_uuid.v4()),
            registroId: Value(id),
            horaSalidaTaller: Value(params.horaSalidaTaller),
            horaLlegadaPunto: Value(params.horaLlegadaPunto),
          ));
        }

        for (final nombre in params.sublaboresSeleccionadas) {
          await _db.into(_db.subLaboresLocal).insertOnConflictUpdate(
                SubLaboresLocalCompanion.insert(
                  id: _uuid.v4(),
                  registroId: id,
                  sublaborNombre: nombre,
                ),
              );
        }
      });

      // Datos guardados en SQLite. El outbox se crea al cerrar el turno (payload consolidado).
      final entity = await _buildRegistroEntity(id);

      if (entity == null) {
        return const Left(
            CacheFailure(message: 'No se pudo construir la entidad del registro'));
      }

      return Right(entity);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RegistroDiario>> actualizarRegistroBasico(
      String registroId, CrearRegistroParams params) async {
    try {
      final now = DateTime.now();
      final current = await _db.registroDao.getRegistroById(registroId);
      if (current == null) {
        return const Left(CacheFailure(message: 'Registro no encontrado'));
      }

      // Leer sub-entidades ANTES de la transacción para evitar queries anidadas
      final h = await _db.registroDao.getHorometroByRegistro(registroId);
      final tt = await _db.registroDao.getTiempoTurnoByRegistro(registroId);

      await _db.transaction(() async {
        await _db.registroDao.updateRegistro(RegistrosDiariosLocalCompanion(
          id: Value(registroId),
          fecha: Value(params.fecha),
          turno: Value(params.turno),
          procesoId: Value(params.procesoId),
          procesoNombre: Value(params.procesoNombre),
          procesoCodigo: Value(params.procesoCodigo),
          cultivoIdErp: Value(params.cultivoIdErp),
          cultivoNombreEspecie: Value(params.cultivoNombreEspecie),
          cultivoCodigoEspecie: Value(params.cultivoCodigoEspecie),
          operadorIdErp: Value(params.operadorIdErp),
          operadorCodigo: Value(params.operadorCodigo),
          operadorNombre: Value(params.operadorNombre),
          // supervisor_id_erp y supervisor_codigo se preservan de SQLite
          // (no hay picker ERP para el supervisor en admin mode — solo nombre libre).
          // Solo actualizamos el nombre si el admin lo editó.
          supervisorNombre: Value(params.supervisorNombre),
          tractorIdErp: Value(params.tractorIdErp),
          tractorCodigo: Value(params.tractorCodigo),
          tractorDescripcion: Value(params.tractorDescripcion),
          implementoIdErp: Value(params.implementoIdErp),
          implementoCodigo: Value(params.implementoCodigo),
          implementoDescripcion: Value(params.implementoDescripcion),
          cajaCambiosId: Value(params.cajaCambiosId),
          cajaCambiosNombre: Value(params.cajaCambiosNombre),
          subprocesoId: Value(params.subprocesoId),
          subprocesoNombre: Value(params.subprocesoNombre),
          dispositivoId: Value(params.dispositivoId),
          sincronizado: const Value(false),
          updatedAt: Value(now),
        ));

        if (h != null || params.tractorInicio != null || params.implementoInicio != null) {
          await _db.registroDao.upsertHorometro(HorometrosLocalCompanion(
            id: Value(h?.id ?? _uuid.v4()),
            registroId: Value(registroId),
            tractorInicio: Value(params.tractorInicio),
            implementoInicio: Value(params.implementoInicio),
            updatedAt: Value(now),
          ));
        }
        if (tt != null) {
          await _db.registroDao.upsertTiempoTurno(TiemposTurnoLocalCompanion(
            id: Value(tt.id),
            registroId: Value(registroId),
            horaSalidaTaller: Value(params.horaSalidaTaller),
            horaLlegadaPunto: Value(params.horaLlegadaPunto),
            updatedAt: Value(now),
          ));
        }

        // Sublabores: delete+reinsert atómico para evitar estado intermedio vacío
        await (_db.delete(_db.subLaboresLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        for (final nombre in params.sublaboresSeleccionadas) {
          await _db.into(_db.subLaboresLocal).insertOnConflictUpdate(
                SubLaboresLocalCompanion.insert(
                  id: _uuid.v4(),
                  registroId: registroId,
                  sublaborNombre: nombre,
                ),
              );
        }
      });

      final entity = await _buildRegistroEntity(registroId);
      if (entity == null) {
        return const Left(
            CacheFailure(message: 'No se encontró el registro tras actualizar'));
      }
      return Right(entity);
    } catch (e) {
      developer.log('actualizarRegistroBasico error', name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> eliminarRegistro(String registroId) async {
    try {
      await _db.registroDao.deleteRegistroCascade(registroId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ─── Cerrar turno — payload consolidado ──────────────────────────────────
  // Un solo JSON con todo el registro se envía a SP_MMA_SINCRONIZAR_OFFLINE.
  // No se usa SP_MMA_CERRAR_TURNO. Todo o nada (transacción atómica en el SP).

  @override
  Future<Either<Failure, RegistroDiario>> cerrarTurno(
      CerrarTurnoParams params) async {
    try {
      final now = DateTime.now();
      final rid = params.registroId;

      // Leer sub-entidades ANTES de la transacción
      final h = await _db.registroDao.getHorometroByRegistro(rid);
      final tt = await _db.registroDao.getTiempoTurnoByRegistro(rid);

      // 1. Actualizar estado y datos de cierre en SQLite — atómico ──────────
      await _db.transaction(() async {
        await _db.registroDao.updateRegistro(RegistrosDiariosLocalCompanion(
          id: Value(rid),
          estado: const Value(AppConstants.estadoCompletado),
          observacionesMaq: Value(params.observacionesMaq),
          firmaOperador: Value(params.firmaOperador),
          updatedAt: Value(now),
          sincronizado: const Value(false),
        ));

        if (params.tractorFinal != null || params.implementoFinal != null) {
          await _db.registroDao.upsertHorometro(HorometrosLocalCompanion(
            id: Value(h?.id ?? _uuid.v4()),
            registroId: Value(rid),
            tractorFinal: Value(params.tractorFinal),
            implementoFinal: Value(params.implementoFinal),
            updatedAt: Value(now),
          ));
        }

        if (tt != null) {
          await _db.registroDao.upsertTiempoTurno(TiemposTurnoLocalCompanion(
            id: Value(tt.id),
            registroId: Value(rid),
            horaSalidaPunto: Value(params.horaSalidaPunto),
            horaLlegadaTaller: Value(params.horaLlegadaTaller),
            horaRefrigerio: Value(params.horaRefrigerio),
            updatedAt: Value(now),
          ));
        }
      });

      // 2. Actualizar último horómetro local por tractor para que el próximo
      //    registro del mismo tractor/implemento ya use el mínimo correcto.
      if (params.tractorFinal != null) {
        final reg = await _db.registroDao.getRegistroById(rid);
        if (reg != null) {
          await _db.customStatement(
            '''INSERT OR REPLACE INTO ultimo_horometro_tractores_local
               (tractor_id_erp, horometro_final, implemento_final,
                implemento_id_erp, codigo_implemento, ultima_fecha, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, strftime('%s','now') * 1000)''',
            [
              reg.tractorCodigo,
              params.tractorFinal,
              params.implementoFinal,
              reg.implementoIdErp,
              reg.implementoCodigo,
              now.toIso8601String().substring(0, 10),
            ],
          );
        }
      }

      // 3. Sincronizar lotes en RegistrosSectoresLocal desde params.lotesJson ──
      // Esto garantiza que _buildFullPayloadFromSQLite (usado en el re-sync del
      // supervisor) tenga los lotes actualizados, incluyendo lotes nuevos
      // agregados en el cierre. Sin esto, el re-sync del editor admin envía los
      // lotes viejos y el MERGE los borra del servidor.
      if (params.lotesJson != null && params.lotesJson!.isNotEmpty) {
        try {
          final rawLotes = jsonDecode(params.lotesJson!) as List;
          final lotesDb = await _db.catalogoDao.getLotes();
          final lotesCat = {for (final l in lotesDb) l.idErp: l};
          await _db.transaction(() async {
            await _db.registroDao.deleteSectoresByRegistro(rid);
            for (final item in rawLotes) {
              final m = Map<String, dynamic>.from(item as Map);
              final loteIdErp = (m['lote_id_erp'] as num?)?.toInt() ?? 0;
              if (loteIdErp == 0) continue;
              final cat = lotesCat[loteIdErp];
              final areaRaw = m['area_ha'] ?? m['area_trabajada_ha'];
              await _db.registroDao.upsertSector(RegistrosSectoresLocalCompanion(
                id: Value(_uuid.v4()),
                registroId: Value(rid),
                loteIdErp: Value(loteIdErp),
                loteCodigo: Value(
                    (m['lote_codigo_snapshot'] ?? m['lote_codigo'] ?? cat?.loteCodigo ?? '') as String),
                loteNombre: Value(cat?.loteNombre ?? ''),
                fincaNombre: Value(cat?.fincaNombre ?? ''),
                areaTrabajada: Value(areaRaw != null ? (areaRaw as num).toDouble() : null),
                observacion: Value(m['observacion'] as String?),
              ));
            }
          });
        } catch (e) {
          developer.log('cerrarTurno: actualizar sectores SQLite falló (no crítico): $e',
              name: 'RegistroRepo');
        }
      }

      // 4. Leer TODO de SQLite para construir el payload completo ────────────
      final payload = await _buildPayloadConsolidado(params);

      // 4b. Guardar copia de respaldo local del payload (best-effort) ─────────
      final usuarioCodigo =
          (payload['operador_codigo'] as String?) ?? 'desconocido';
      await BackupService.savePayload(
        registroId: rid,
        usuarioCodigo: usuarioCodigo,
        payload: payload,
      );

      // 4c. Backup específico de la ruta GPS con SQL listo para inserción manual
      await BackupService.saveRutaGps(
        registroId: rid,
        usuarioCodigo: usuarioCodigo,
        rutaWkt: payload['ruta_wkt'] as String?,
        meta: {
          'registro_id':     rid,
          'operador_id_erp': payload['operador_id_erp'],
          'tractor_id_erp':  payload['tractor_id_erp'],
          'proceso_id':      payload['proceso_id'],
          'fecha':           payload['fecha'],
        },
      );

      // 5. Una sola entrada en el outbox — POST /registros ───────────────────
      await _addToOutbox(rid, '/registros', 'POST', payload);

      final entity = await _buildRegistroEntity(rid);
      if (entity == null) {
        return const Left(
            CacheFailure(message: 'No se encontró el registro tras cerrar turno'));
      }
      return Right(entity);
    } catch (e) {
      developer.log('cerrarTurno error', name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Lee todos los datos del registro desde SQLite y construye el JSON completo
  /// para SP_MMA_SINCRONIZAR_OFFLINE. Se llama únicamente al cerrar el turno.
  Future<Map<String, dynamic>> _buildPayloadConsolidado(
      CerrarTurnoParams params) async {
    final rid = params.registroId;

    // Datos base del registro
    final reg = await _db.registroDao.getRegistroById(rid);
    if (reg == null) throw Exception('Registro $rid no encontrado en SQLite');

    // Horómetros actualizados (ya incluye los valores finales guardados arriba)
    final h = await _db.registroDao.getHorometroByRegistro(rid);

    // Tiempos de turno actualizados
    final tt = await _db.registroDao.getTiempoTurnoByRegistro(rid);

    // Checklist: {item_id, resultado, observacion, foto_url}
    // Deduplicar por itemId — garantía extra contra filas duplicadas en SQLite.
    final checklistRows = await _db.registroDao.getChecklistByRegistro(rid);
    final checklistDedup = <int, ChecklistResultadosLocalData>{};
    for (final c in checklistRows) {
      checklistDedup[c.itemId] = c;
    }
    final checklistJson = checklistDedup.values
        .map((c) => {
              'item_id': c.itemId,
              'resultado': c.resultado,
              'observacion': c.observacion,
              'foto_url': c.fotoUrl,
            })
        .toList();

    // Paros: incluye falla_mecanica_id para SPs ERP
    final parosRows = await _db.customSelect(
      'SELECT tipo_paro_id, motivo, equipo, hora_inicio, hora_final, galones, '
      'falla_mecanica_id, falla_mecanica_nombre '
      'FROM paros_equipos_local WHERE registro_id = ? ORDER BY hora_inicio',
      variables: [Variable.withString(rid)],
    ).get();
    final parosJson = parosRows
        .map((p) => {
              'tipo_paro_id': p.read<int>('tipo_paro_id'),
              'motivo': p.readNullable<String>('motivo'),
              'equipo': p.readNullable<String>('equipo'),
              'hora_inicio': p.read<String>('hora_inicio'),
              'hora_final': p.readNullable<String>('hora_final'),
              'galones': p.readNullable<double>('galones'),
              if (p.readNullable<int>('falla_mecanica_id') != null)
                'falla_mecanica_id': p.read<int>('falla_mecanica_id'),
              if (p.readNullable<String>('falla_mecanica_nombre') != null)
                'falla_mecanica_nombre': p.read<String>('falla_mecanica_nombre'),
            })
        .toList();

    // Bines: SP espera 'turno_franja' (no 'turno')
    final binesRows = await _db.registroDao.getBinesByRegistro(rid);
    final binesJson = binesRows
        .map((b) => {
              'franja_horaria': b.franjaHoraria,
              'turno_franja': b.turno,
              'cantidad': b.cantidad,
            })
        .toList();

    // Lotes: vienen de params.lotesJson (ya tiene finca_id_erp del catálogo).
    // Remapear area_ha → area_trabajada_ha para SP_MMA_SINCRONIZAR_OFFLINE.
    List<dynamic> lotesJson = [];
    if (params.lotesJson != null && params.lotesJson!.isNotEmpty) {
      final raw = jsonDecode(params.lotesJson!) as List;
      lotesJson = raw.map((l) {
        final m = Map<String, dynamic>.from(l as Map);
        if (m.containsKey('area_ha') && !m.containsKey('area_trabajada_ha')) {
          m['area_trabajada_ha'] = m.remove('area_ha');
        }
        return m;
      }).toList();
    }

    // Sublabores: primero params, si no → SQLite
    List<dynamic> sublaboresJson = [];
    if (params.sublaboresJson != null && params.sublaboresJson!.isNotEmpty) {
      sublaboresJson = jsonDecode(params.sublaboresJson!) as List;
    } else {
      final rows = await (_db.select(_db.subLaboresLocal)
            ..where((t) => t.registroId.equals(rid)))
          .get();
      sublaboresJson =
          rows.map((s) => {'sublabor_nombre': s.sublaborNombre}).toList();
    }

    // Marchas: siempre desde SQLite (no vienen por params)
    final marchasRows = await (_db.select(_db.marchasLocal)
          ..where((t) => t.registroId.equals(rid)))
        .get();
    final marchasJson = marchasRows
        .map((m) => {
              'marcha_codigo': m.marchaCodigo,
              if (m.horasUso != null) 'horas_uso': m.horasUso,
            })
        .toList();

    // Ruta GPS → WKT LineString (v3).
    // SQL Server GEOGRAPHY::STGeomFromText espera LONGITUD primero, luego LATITUD.
    // ≥ 2 puntos → LINESTRING; 1 punto → POINT; 0 puntos → null (campo omitido).
    final gpsRows = await _db.customSelect(
      'SELECT p.longitud, p.latitud, p.velocidad_kmh, p.tipo_movimiento, '
      '       p.sublote_id, p.captured_at, l.lote_nombre '
      'FROM "CLI547_AGM_Ruta_maquinaria" p '
      'LEFT JOIN lotes_local l ON l.id_erp = p.sublote_id '
      'WHERE p.registro_id = ? ORDER BY p.secuencia',
      variables: [Variable.withString(rid)],
    ).get();
    String? rutaWkt;
    if (gpsRows.length >= 2) {
      final coords = gpsRows
          .map((p) =>
              '${p.read<double>('longitud').toStringAsFixed(7)} '
              '${p.read<double>('latitud').toStringAsFixed(7)}')
          .join(', ');
      rutaWkt = 'LINESTRING($coords)';
    } else if (gpsRows.length == 1) {
      final p = gpsRows.first;
      rutaWkt = 'POINT(${p.read<double>('longitud').toStringAsFixed(7)} '
          '${p.read<double>('latitud').toStringAsFixed(7)})';
    }

    // ── Analytics GPS — calculados desde los puntos locales ───────────────────
    // Cada punto representa ~_kInterval segundos (5 s). Usamos captured_at real
    // para calcular deltas de tiempo precisos entre puntos consecutivos.
    double kmTrabajo = 0, kmTraslado = 0;
    int tiempoTrabajoSeg = 0, tiempoParadoSeg = 0;
    double velSuma = 0;
    int velCount = 0, totalParadas = 0;
    double velMax = 0;
    String? prevTipo;
    int? prevAt;
    double? prevLat, prevLon;
    final Map<int, Map<String, dynamic>> subloteMap = {};

    for (final row in gpsRows) {
      final tipo   = row.readNullable<String>('tipo_movimiento') ?? 'TRASLADO';
      final velKmh = row.readNullable<double>('velocidad_kmh') ?? 0.0;
      final lat    = row.read<double>('latitud');
      final lon    = row.read<double>('longitud');
      final at     = row.readNullable<int>('captured_at') ?? 0;
      final sublId = row.readNullable<int>('sublote_id');
      final sublNm = row.readNullable<String>('lote_nombre') ?? '';

      // Hueco de GPS (apagado, sin señal, app cerrada): el punto anterior y el
      // actual quedan contiguos en la secuencia pero los separan minutos u
      // horas. La recta entre ambos no es un recorrido real, así que no se
      // acumula: de lo contrario aparecen kilómetros que nadie hizo.
      final hayHueco = prevAt != null &&
          at > 0 &&
          (at - prevAt) > GpsEventBuilderService.kMaxGapSeg * 1000;

      // Distancia desde el punto anterior
      if (prevLat != null && prevLon != null && !hayHueco) {
        final distM = Geolocator.distanceBetween(prevLat, prevLon, lat, lon);
        if (tipo == 'TRABAJO')   kmTrabajo  += distM / 1000.0;
        if (tipo == 'TRASLADO')  kmTraslado += distM / 1000.0;
      }
      // Tiempo desde el punto anterior
      if (prevAt != null && prevAt > 0 && at > 0) {
        final dtSeg = ((at - prevAt) / 1000.0).clamp(0, 60).toInt();
        if (tipo == 'TRABAJO')  tiempoTrabajoSeg += dtSeg;
        if (tipo == 'PARADO')   tiempoParadoSeg  += dtSeg;
      }
      // Estadísticas de velocidad (solo TRABAJO)
      if (tipo == 'TRABAJO' && velKmh > 0) {
        velSuma += velKmh;
        velCount++;
        if (velKmh > velMax) velMax = velKmh;
      }
      // Contar transiciones hacia PARADO
      if (prevTipo != null && prevTipo != 'PARADO' && tipo == 'PARADO') {
        totalParadas++;
      }
      // Tiempo por sublote
      if (sublId != null && tipo == 'TRABAJO') {
        subloteMap.putIfAbsent(sublId, () => {'nombre': sublNm, 'seg': 0});
        if (prevAt != null && prevAt > 0 && at > 0 && prevTipo == 'TRABAJO') {
          final dtSeg = ((at - prevAt) / 1000.0).clamp(0, 60).toInt();
          subloteMap[sublId]!['seg'] = (subloteMap[sublId]!['seg'] as int) + dtSeg;
        }
      }

      prevLat = lat; prevLon = lon; prevAt = at; prevTipo = tipo;
    }

    final tiempoTrabajoMin = tiempoTrabajoSeg ~/ 60;
    final tiempoParadoMin  = tiempoParadoSeg  ~/ 60;
    final velProm  = velCount > 0 ? velSuma / velCount : 0.0;
    final totalMin = tiempoTrabajoMin + tiempoParadoMin +
        (kmTraslado > 0 ? ((kmTraslado / 25.0) * 60).round() : 0);
    final eficiencia = totalMin > 0
        ? (tiempoTrabajoMin / totalMin * 100.0).clamp(0.0, 100.0)
        : 0.0;
    // JSON de sublotes trabajados: [{sublote_id, nombre, minutos}]
    final sublotesJson = subloteMap.isNotEmpty
        ? jsonEncode(subloteMap.entries.map((e) => {
              'sublote_id': e.key,
              'nombre': e.value['nombre'],
              'minutos': (e.value['seg'] as int) ~/ 60,
            }).toList())
        : null;

    // Eventos derivados: visitas a sublote, paradas y tramos. Si falla devuelve
    // un mapa vacío y la jornada sincroniza igual con la ruta consolidada.
    final eventos =
        await GpsEventBuilderService(db: _db).construirEventos(rid);

    return {
      // ── Identificación ───────────────────────────────────────────────────
      'id': reg.id,
      'numero_registro': reg.numeroRegistro,
      'tipo_registro': 'tractor',
      'fecha': AppDateUtils.toApiDate(reg.fecha),
      'turno': reg.turno,
      // ── Proceso / Cultivo ─────────────────────────────────────────────────
      'proceso_id': reg.procesoId,
      if (reg.subprocesoId != null) 'subproceso_id': reg.subprocesoId,
      if (reg.subprocesoNombre != null) 'subproceso_nombre': reg.subprocesoNombre,
      'cultivo_id_erp': reg.cultivoIdErp,
      'cultivo_nombre': reg.cultivoNombreEspecie,
      'cultivo_codigo_especie': reg.cultivoCodigoEspecie,
      // ── Personas ──────────────────────────────────────────────────────────
      'operador_id_erp': reg.operadorIdErp,
      'operador_codigo': reg.operadorCodigo,
      'operador_nombre': reg.operadorNombre,
      'supervisor_id_erp': reg.supervisorIdErp,
      'supervisor_codigo': reg.supervisorCodigo,
      'supervisor_nombre': reg.supervisorNombre,
      // ── Equipos ───────────────────────────────────────────────────────────
      'tractor_id_erp': reg.tractorIdErp,
      'tractor_codigo': reg.tractorCodigo,
      'tractor_descripcion': reg.tractorDescripcion,
      'implemento_id_erp': reg.implementoIdErp,
      'implemento_codigo': reg.implementoCodigo,
      'implemento_descripcion': reg.implementoDescripcion,
      'caja_cambios_id': reg.cajaCambiosId,
      // ── Horómetros (inicio + final) ────────────────────────────────────────
      'tractor_inicio': h?.tractorInicio,
      'tractor_final': h?.tractorFinal,
      'implemento_inicio': h?.implementoInicio,
      'implemento_final': h?.implementoFinal,
      // ── Tiempos de turno ──────────────────────────────────────────────────
      'hora_salida_taller': tt?.horaSalidaTaller,
      'hora_llegada_punto': tt?.horaLlegadaPunto,
      'hora_salida_punto': tt?.horaSalidaPunto,
      'hora_llegada_taller': tt?.horaLlegadaTaller,
      'hora_refrigerio': tt?.horaRefrigerio,
      // ── Observaciones ─────────────────────────────────────────────────────
      'observaciones_maq': reg.observacionesMaq,
      // ── Dispositivo / auditoría ───────────────────────────────────────────
      'dispositivo_id': reg.dispositivoId,
      'created_by_erp': reg.operadorIdErp,
      // ── Sub-entidades (arrays) ────────────────────────────────────────────
      if (checklistJson.isNotEmpty) 'checklist': checklistJson,
      if (parosJson.isNotEmpty) 'paros': parosJson,
      if (binesJson.isNotEmpty) 'bines': binesJson,
      if (lotesJson.isNotEmpty) 'lotes': lotesJson,
      if (sublaboresJson.isNotEmpty) 'sublabores': sublaboresJson,
      if (marchasJson.isNotEmpty) 'marchas': marchasJson,
      if (reg.firmaOperador != null) 'firma_operador': reg.firmaOperador,
      // ── Ruta GPS — WKT LineString/Point para CLI547_AGM_Ruta_maquinaria ──
      if (rutaWkt != null) 'ruta_wkt': rutaWkt,
      // ── Analytics GPS (v4+) — calculados desde puntos locales ────────────
      if (gpsRows.isNotEmpty) ...{
        'gps_km_trabajo':         double.parse(kmTrabajo.toStringAsFixed(3)),
        'gps_km_traslado':        double.parse(kmTraslado.toStringAsFixed(3)),
        'gps_tiempo_trabajo_min': tiempoTrabajoMin,
        'gps_tiempo_parado_min':  tiempoParadoMin,
        'gps_velocidad_prom_kmh': double.parse(velProm.toStringAsFixed(2)),
        'gps_velocidad_max_kmh':  double.parse(velMax.toStringAsFixed(2)),
        'gps_total_paradas':      totalParadas,
        'gps_eficiencia_pct':     double.parse(eficiencia.toStringAsFixed(2)),
        if (sublotesJson != null) 'gps_sublotes': jsonDecode(sublotesJson),
      },
      // ── Eventos derivados (v5+) ──────────────────────────────────────────
      ...eventos,
    };
  }

  // ─── Aprobar / Rechazar ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, RegistroDiario>> aprobarRegistro(
      AprobarRegistroParams params) async {
    try {
      final nuevoEstado = params.accion == 'aprobar'
          ? AppConstants.estadoAprobado
          : AppConstants.estadoRechazado;

      await _db.registroDao.updateRegistro(RegistrosDiariosLocalCompanion(
        id: Value(params.registroId),
        estado: Value(nuevoEstado),
        supervisorIdErp: Value(params.supervisorIdErp),
        motivoRechazo: Value(params.motivo),
        sincronizado: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

      final payload = {
        'supervisor_id_erp': params.supervisorIdErp,
        'accion': params.accion,
        'motivo': params.motivo,
      };

      await _enqueueOutbox(
        params.registroId,
        '/registros/${params.registroId}/aprobar',
        'PUT',
        payload,
      );

      final entity = await _buildRegistroEntity(params.registroId);
      if (entity == null) {
        return const Left(
            CacheFailure(message: 'No se encontró el registro tras aprobar'));
      }
      return Right(entity);
    } catch (e) {
      developer.log('aprobarRegistro error', name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Checklist ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ChecklistResultado>>> getChecklist(
      String registroId) async {
    try {
      final rows = await _db.registroDao.getChecklistByRegistro(registroId);
      return Right(rows.map(_checklistResultadoFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> guardarChecklist(
      String registroId, List<ChecklistResultadoInput> resultados) async {
    try {
      // Delete+reinsert atómico: si cualquier inserción falla,
      // el checklist anterior se restaura (rollback automático de la transacción).
      await _db.transaction(() async {
        await _db.registroDao.deleteChecklistByRegistro(registroId);
        for (final r in resultados) {
          await _db.registroDao.upsertChecklistResultado(
            ChecklistResultadosLocalCompanion(
              id: Value(_uuid.v4()),
              registroId: Value(registroId),
              itemId: Value(r.itemId),
              itemNombre: Value(r.itemNombre),
              categoriaNombre: Value(r.categoriaNombre),
              resultado: Value(r.resultado),
              observacion: Value(r.observacion),
              fotoUrl: Value(r.fotoUrl),
            ),
          );
        }
      });
      return const Right(null);
    } catch (e) {
      developer.log('guardarChecklist error', name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Paros ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ParoEquipo>> agregarParo(
      AgregarParoParams params) async {
    try {
      final id = _uuid.v4();
      await _db.transaction(() async {
        await _db.registroDao.insertParo(ParosEquiposLocalCompanion(
          id: Value(id),
          registroId: Value(params.registroId),
          tipoParoId: Value(params.tipoParoId),
          tipoParoCodigo: Value(params.tipoParoCodigo),
          tipoParoNombre: Value(params.tipoParoNombre),
          motivo: Value(params.motivo),
          equipo: Value(params.equipo),
          horaInicio: Value(params.horaInicio),
          horaFinal: Value(params.horaFinal),
          galones: Value(params.galones),
        ));

        if (params.fallaMecanicaId != null) {
          await _db.customStatement(
            'UPDATE paros_equipos_local '
            'SET falla_mecanica_id = ?, falla_mecanica_nombre = ? '
            'WHERE id = ?',
            [params.fallaMecanicaId, params.fallaMecanicaNombre, id],
          );
        }
      });

      // Guardado solo en SQLite. Se incluirá en el payload consolidado al cerrar turno.
      return Right(ParoEquipo(
        id: id,
        registroId: params.registroId,
        tipoParoId: params.tipoParoId,
        tipoParoCodigo: params.tipoParoCodigo,
        tipoParoNombre: params.tipoParoNombre,
        motivo: params.motivo,
        equipo: params.equipo,
        horaInicio: params.horaInicio,
        horaFinal: params.horaFinal,
        galones: params.galones,
        fallaMecanicaId: params.fallaMecanicaId,
        fallaMecanicaNombre: params.fallaMecanicaNombre,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> eliminarParo(String paroId) async {
    try {
      await _db.registroDao.deleteParo(paroId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ─── Bines ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> registrarBin(RegistrarBinParams params) async {
    try {
      await _db.transaction(() async {
        // Elimina fila previa para evitar duplicados por UUID diferente.
        // BUG-17: when cantidad == 0 we only delete — no INSERT — so the row
        // is removed from the DB instead of being persisted as a 0-count entry.
        await _db.customStatement(
          'DELETE FROM cosecha_bines_local WHERE registro_id = ? AND franja_horaria = ?',
          [params.registroId, params.franjaHoraria],
        );
        if (params.cantidad > 0) {
          await _db.registroDao.upsertBin(CosechaBinesLocalCompanion(
            id: Value(_uuid.v4()),
            registroId: Value(params.registroId),
            franjaHoraria: Value(params.franjaHoraria),
            turno: Value(params.turno),
            cantidad: Value(params.cantidad),
          ));
        }
      });

      // Guardado solo en SQLite. Se incluirá en el payload consolidado al cerrar turno.
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registrarJornada(
      String registroId, String tipo) async {
    try {
      await _addToOutbox(
        registroId,
        '/jornada',
        'POST',
        {
          'registro_id': registroId,
          'tipo': tipo,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Sectores ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> guardarSectores(
      String registroId, List<RegistroSectorInput> sectores) async {
    try {
      await _db.transaction(() async {
        await _db.registroDao.deleteSectoresByRegistro(registroId);
        for (final s in sectores) {
          await _db.registroDao.upsertSector(RegistrosSectoresLocalCompanion(
            id: Value(_uuid.v4()),
            registroId: Value(registroId),
            loteIdErp: Value(s.loteIdErp),
            loteCodigo: Value(s.loteCodigo),
            loteNombre: Value(s.loteNombre),
            fincaNombre: Value(s.fincaNombre),
            areaTrabajada: Value(s.areaTrabajada),
            observacion: Value(s.observacion),
          ));
        }
      });
      return const Right(null);
    } catch (e) {
      developer.log('guardarSectores error', name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, RegistroDiario>> getRegistro(String id) async {
    try {
      final r = await _buildRegistroEntity(id);
      if (r == null) {
        return const Left(CacheFailure(message: 'Registro no encontrado'));
      }
      return Right(r);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<RegistroDiario>> watchRegistros({
    int? operadorIdErp,
    DateTime? fechaDesde,
  }) {
    // StreamController que re-emite cuando cambian registros, checklist O paros.
    // Drift solo re-emite el stream principal cuando cambia registrosDiariosLocal;
    // las tablas secundarias (checklist, paros) requieren sus propios listeners.
    late StreamController<List<RegistroDiario>> ctrl;
    final subs = <StreamSubscription<dynamic>>[];

    Future<void> emit() async {
      if (ctrl.isClosed) return;
      try {
        final rows = await _db.registroDao.getRegistros(
          operadorIdErp: operadorIdErp,
          fechaDesde: fechaDesde,
        );
        final result = <RegistroDiario>[];
        for (final row in rows) {
          result.add(await _buildRegistroEntityFromRow(row));
        }
        if (!ctrl.isClosed) ctrl.add(result);
      } catch (e, s) {
        if (!ctrl.isClosed) ctrl.addError(e, s);
      }
    }

    ctrl = StreamController<List<RegistroDiario>>(
      onListen: () {
        emit(); // emisión inicial
        subs
          ..add(_db.registroDao
              .watchAllRegistros(
                  operadorIdErp: operadorIdErp, fechaDesde: fechaDesde)
              .listen((_) => emit()))
          ..add(_db.registroDao.watchChecklistChanges().listen((_) => emit()))
          ..add(_db.registroDao.watchParosChanges().listen((_) => emit()));
      },
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
      },
    );

    return ctrl.stream;
  }

  @override
  Future<Either<Failure, List<RegistroDiario>>> getRegistros({
    int? operadorIdErp,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
  }) async {
    try {
      final rows = await _db.registroDao.getRegistros(
        operadorIdErp: operadorIdErp,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        estado: estado,
      );
      final result = <RegistroDiario>[];
      for (final row in rows) {
        result.add(await _buildRegistroEntityFromRow(row));
      }
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getPendientesSincronizacion() async {
    try {
      return Right(await _db.outboxDao.countPending());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Stream<int> watchPendientesSincronizacion() =>
      _db.outboxDao.watchCountPending();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Encola la operación en Outbox para sincronización manual.
  /// El servidor NUNCA se llama desde aquí — solo SyncManager ejecuta SPs.
  /// Esto garantiza que el usuario controla exactamente cuándo suben los datos.
  Future<void> _enqueueOutbox(
    String localId,
    String endpoint,
    String method,
    Map<String, dynamic> payload,
  ) async {
    await _addToOutbox(localId, endpoint, method, payload);
  }

  Future<void> _addToOutbox(String localId, String endpoint, String method,
          Map<String, dynamic> payload) =>
      _db.outboxDao.insertEntry(OutboxEntriesCompanion(
        registroLocalId: Value(localId),
        endpoint: Value(endpoint),
        method: Value(method),
        payloadJson: Value(jsonEncode(payload)),
      ));

  /// Serializa llamadas concurrentes para evitar race conditions al leer/
  /// incrementar/escribir el contador de secuencia en SharedPreferences.
  static Future<int>? _pendingSeq;

  /// Retorna el próximo número de secuencia para la fecha+operador dados.
  /// La clave incluye el operadorIdErp para evitar colisiones entre distintos
  /// operadores que usen dispositivos diferentes el mismo día agrícola.
  Future<int> _nextSequenceForDate(DateTime fecha, int operadorIdErp) async {
    // Esperar a que cualquier llamada en vuelo termine antes de continuar.
    while (_pendingSeq != null) {
      await _pendingSeq;
    }
    final completer = Completer<int>();
    _pendingSeq = completer.future;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateFormat('yyyyMMdd').format(fecha);
      final key = 'reg_seq_${dateStr}_$operadorIdErp';
      // Respaldo: contar registros del mismo operador en SQLite por si se
      // reinstaló la app y SharedPreferences quedó vacío.
      final sqliteCount = await _db.registroDao
          .getRegistros(
            fechaDesde: DateTime(fecha.year, fecha.month, fecha.day),
            fechaHasta:
                DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59),
          )
          .then((r) => r.where((x) => x.operadorIdErp == operadorIdErp).length);
      final storedSeq = prefs.getInt(key) ?? 0;
      final next = (storedSeq > sqliteCount ? storedSeq : sqliteCount) + 1;
      await prefs.setInt(key, next);
      completer.complete(next);
      return next;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingSeq = null;
    }
  }

  Future<RegistroDiario?> _buildRegistroEntity(String id) async {
    final row = await _db.registroDao.getRegistroById(id);
    if (row == null) return null;
    return _buildRegistroEntityFromRow(row);
  }

  Future<RegistroDiario> _buildRegistroEntityFromRow(
      RegistrosDiariosLocalData row) async {
    final horometro = await _db.registroDao.getHorometroByRegistro(row.id);
    final tiempoTurno = await _db.registroDao.getTiempoTurnoByRegistro(row.id);
    final sectores = await _db.registroDao.getSectoresByRegistro(row.id);
    final bines = await _db.registroDao.getBinesByRegistro(row.id);
    final parosRaw = await _db.customSelect(
      'SELECT id, registro_id, tipo_paro_id, tipo_paro_codigo, tipo_paro_nombre, '
      'motivo, equipo, hora_inicio, hora_final, galones, '
      'falla_mecanica_id, falla_mecanica_nombre '
      'FROM paros_equipos_local WHERE registro_id = ? ORDER BY hora_inicio',
      variables: [Variable.withString(row.id)],
    ).get();
    final paros = parosRaw;
    final checklist = await _db.registroDao.getChecklistByRegistro(row.id);
    final combustiblesVehiculo = await (_db.select(_db.combustibleVehiculoLocal)
          ..where((t) => t.registroId.equals(row.id)))
        .get();

    return RegistroDiario(
      id: row.id,
      numeroRegistro: row.numeroRegistro,
      fecha: row.fecha,
      turno: row.turno,
      procesoId: row.procesoId,
      procesoNombre: row.procesoNombre,
      procesoCodigo: row.procesoCodigo,
      cultivoIdErp: row.cultivoIdErp,
      cultivoNombreEspecie: row.cultivoNombreEspecie,
      cultivoCodigoEspecie: row.cultivoCodigoEspecie,
      operadorIdErp: row.operadorIdErp,
      operadorCodigo: row.operadorCodigo,
      operadorNombre: row.operadorNombre,
      supervisorIdErp: row.supervisorIdErp,
      supervisorCodigo: row.supervisorCodigo,
      supervisorNombre: row.supervisorNombre,
      tractorIdErp: row.tractorIdErp,
      tractorCodigo: row.tractorCodigo,
      tractorDescripcion: row.tractorDescripcion,
      implementoIdErp: row.implementoIdErp,
      implementoCodigo: row.implementoCodigo,
      implementoCodigoInterno: row.implementoCodigo,
      implementoDescripcion: row.implementoDescripcion,
      cajaCambiosId: row.cajaCambiosId,
      cajaCambiosNombre: row.cajaCambiosNombre,
      subprocesoId: row.subprocesoId,
      subprocesoNombre: row.subprocesoNombre,
      estado: row.estado,
      tipoRegistro: row.tipoRegistro,
      observacionesMaq: row.observacionesMaq,
      motivoRechazo: row.motivoRechazo,
      firmaOperador: row.firmaOperador,
      dispositivoId: row.dispositivoId,
      sincronizado: row.sincronizado,
      sincronizadoAt: row.sincronizadoAt,
      createdAt: row.createdAt,
      horometro: horometro != null
          ? Horometro(
              id: horometro.id,
              registroId: horometro.registroId,
              tractorInicio: horometro.tractorInicio,
              tractorFinal: horometro.tractorFinal,
              implementoInicio: horometro.implementoInicio,
              implementoFinal: horometro.implementoFinal,
            )
          : null,
      tiempoTurno: tiempoTurno != null
          ? TiempoTurno(
              id: tiempoTurno.id,
              registroId: tiempoTurno.registroId,
              horaSalidaTaller: tiempoTurno.horaSalidaTaller,
              horaLlegadaPunto: tiempoTurno.horaLlegadaPunto,
              horaSalidaPunto: tiempoTurno.horaSalidaPunto,
              horaLlegadaTaller: tiempoTurno.horaLlegadaTaller,
              horaRefrigerio: tiempoTurno.horaRefrigerio,
            )
          : null,
      sectores: sectores
          .map((s) => RegistroSector(
                id: s.id,
                registroId: s.registroId,
                loteIdErp: s.loteIdErp,
                loteCodigo: s.loteCodigo,
                loteNombre: s.loteNombre,
                fincaNombre: s.fincaNombre,
                areaTrabajada: s.areaTrabajada,
                observacion: s.observacion,
              ))
          .toList(),
      bines: bines
          .map((b) => CosechaBin(
                id: b.id,
                registroId: b.registroId,
                franjaHoraria: b.franjaHoraria,
                turno: b.turno,
                cantidad: b.cantidad,
              ))
          .toList(),
      paros: paros
          .map((p) => ParoEquipo(
                id: p.read<String>('id'),
                registroId: p.read<String>('registro_id'),
                tipoParoId: p.read<int>('tipo_paro_id'),
                tipoParoCodigo: p.read<String>('tipo_paro_codigo'),
                tipoParoNombre: p.read<String>('tipo_paro_nombre'),
                motivo: p.readNullable<String>('motivo'),
                equipo: p.readNullable<String>('equipo'),
                horaInicio: p.read<String>('hora_inicio'),
                horaFinal: p.readNullable<String>('hora_final'),
                galones: p.readNullable<double>('galones'),
                fallaMecanicaId: p.readNullable<int>('falla_mecanica_id'),
                fallaMecanicaNombre: p.readNullable<String>('falla_mecanica_nombre'),
              ))
          .toList(),
      checklist: checklist.map(_checklistResultadoFromRow).toList(),
      vehiculoDetalle: row.tipoRegistro == 'vehiculo'
          ? VehiculoDetalle(
              kmCamionInicio: horometro?.tractorInicio,
              kmCamionFinal: horometro?.tractorFinal,
              kmImplementoInicio: horometro?.implementoInicio,
              kmImplementoFinal: horometro?.implementoFinal,
              horaSalidaBase: tiempoTurno?.horaSalidaTaller,
              horaLlegadaZona: tiempoTurno?.horaLlegadaPunto,
              horaRetornoBase: tiempoTurno?.horaSalidaPunto,
              horaLlegadaTaller: tiempoTurno?.horaLlegadaTaller,
              horaRefrigerio: tiempoTurno?.horaRefrigerio,
            )
          : null,
      combustiblesVehiculo: combustiblesVehiculo
          .map((c) => CombustibleVehiculoDetalle(
                glns: c.glns,
                horaInicio: c.horaInicio,
                horaFinal: c.horaFinal,
              ))
          .toList(),
      parosVehiculo: row.tipoRegistro == 'vehiculo'
          ? paros
              .map((p) => ParoVehiculoDetalle(
                    motivo: p.readNullable<String>('motivo'),
                    horaInicio: p.read<String>('hora_inicio'),
                    horaFinal: p.readNullable<String>('hora_final'),
                  ))
              .toList()
          : const [],
    );
  }

  ChecklistResultado _checklistResultadoFromRow(
          ChecklistResultadosLocalData r) =>
      ChecklistResultado(
        id: r.id,
        registroId: r.registroId,
        itemId: r.itemId,
        itemNombre: r.itemNombre,
        categoriaNombre: r.categoriaNombre,
        resultado: r.resultado,
        observacion: r.observacion,
        fotoUrl: r.fotoUrl,
      );

  // ─── Admin: upsert from remote SP data ───────────────────────────────────

  @override
  Future<Either<Failure, void>> upsertRegistroFromRemote(
      RegistroDiario r) async {
    try {
      final now = DateTime.now();
      await _db.transaction(() async {
        // 1. Main row — insert or replace
        await _db.into(_db.registrosDiariosLocal).insertOnConflictUpdate(
              RegistrosDiariosLocalCompanion(
                id: Value(r.id),
                numeroRegistro: Value(r.numeroRegistro),
                fecha: Value(r.fecha),
                turno: Value(r.turno),
                procesoId: Value(r.procesoId),
                procesoNombre: Value(r.procesoNombre),
                procesoCodigo: Value(r.procesoCodigo),
                cultivoIdErp: Value(r.cultivoIdErp),
                cultivoNombreEspecie: Value(r.cultivoNombreEspecie),
                cultivoCodigoEspecie: Value(r.cultivoCodigoEspecie),
                operadorIdErp: Value(r.operadorIdErp),
                operadorCodigo: Value(r.operadorCodigo),
                operadorNombre: Value(r.operadorNombre),
                supervisorIdErp: Value(r.supervisorIdErp),
                supervisorCodigo: Value(r.supervisorCodigo),
                supervisorNombre: Value(r.supervisorNombre),
                tractorIdErp: Value(r.tractorIdErp),
                tractorCodigo: Value(r.tractorCodigo),
                tractorDescripcion: Value(r.tractorDescripcion),
                implementoIdErp: Value(r.implementoIdErp),
                implementoCodigo: Value(r.implementoCodigo),
                implementoDescripcion: Value(r.implementoDescripcion),
                cajaCambiosId: Value(r.cajaCambiosId),
                cajaCambiosNombre: Value(r.cajaCambiosNombre),
                subprocesoId: Value(r.subprocesoId),
                subprocesoNombre: Value(r.subprocesoNombre),
                estado: Value(r.estado),
                tipoRegistro: Value(r.tipoRegistro),
                observacionesMaq: Value(r.observacionesMaq),
                motivoRechazo: Value(r.motivoRechazo),
                firmaOperador: Value(r.firmaOperador),
                dispositivoId: Value(r.dispositivoId),
                sincronizado: const Value(true),
                createdAt: Value(r.createdAt),
                updatedAt: Value(now),
              ),
            );

        // 2. Horómetros — delete + reinsert
        await _db.customStatement(
            'DELETE FROM horometros_local WHERE registro_id = ?', [r.id]);
        if (r.horometro != null) {
          final h = r.horometro!;
          await _db.into(_db.horometrosLocal).insertOnConflictUpdate(
                HorometrosLocalCompanion(
                  id: Value(h.id.isEmpty ? _uuid.v4() : h.id),
                  registroId: Value(r.id),
                  tractorInicio: Value(h.tractorInicio),
                  tractorFinal: Value(h.tractorFinal),
                  implementoInicio: Value(h.implementoInicio),
                  implementoFinal: Value(h.implementoFinal),
                  updatedAt: Value(now),
                ),
              );
        }

        // 3. Tiempos turno — delete + reinsert
        await _db.customStatement(
            'DELETE FROM tiempos_turno_local WHERE registro_id = ?', [r.id]);
        if (r.tiempoTurno != null) {
          final tt = r.tiempoTurno!;
          await _db.into(_db.tiemposTurnoLocal).insertOnConflictUpdate(
                TiemposTurnoLocalCompanion(
                  id: Value(tt.id.isEmpty ? _uuid.v4() : tt.id),
                  registroId: Value(r.id),
                  horaSalidaTaller: Value(tt.horaSalidaTaller),
                  horaLlegadaPunto: Value(tt.horaLlegadaPunto),
                  horaSalidaPunto: Value(tt.horaSalidaPunto),
                  horaLlegadaTaller: Value(tt.horaLlegadaTaller),
                  horaRefrigerio: Value(tt.horaRefrigerio),
                  updatedAt: Value(now),
                ),
              );
        }

        // 4. Checklist — delete + reinsert
        await _db.registroDao.deleteChecklistByRegistro(r.id);
        for (final c in r.checklist) {
          await _db.registroDao.upsertChecklistResultado(
            ChecklistResultadosLocalCompanion(
              id: Value(c.id.isEmpty ? _uuid.v4() : c.id),
              registroId: Value(r.id),
              itemId: Value(c.itemId),
              itemNombre: Value(c.itemNombre),
              categoriaNombre: Value(c.categoriaNombre),
              resultado: Value(c.resultado),
              observacion: Value(c.observacion),
              fotoUrl: Value(c.fotoUrl),
            ),
          );
        }

        // 5. Paros — delete + reinsert
        await _db.customStatement(
            'DELETE FROM paros_equipos_local WHERE registro_id = ?', [r.id]);
        for (final p in r.paros) {
          await _db.registroDao.insertParo(ParosEquiposLocalCompanion(
            id: Value(p.id.isEmpty ? _uuid.v4() : p.id),
            registroId: Value(r.id),
            tipoParoId: Value(p.tipoParoId),
            tipoParoCodigo: Value(p.tipoParoCodigo),
            tipoParoNombre: Value(p.tipoParoNombre),
            motivo: Value(p.motivo),
            equipo: Value(p.equipo),
            horaInicio: Value(p.horaInicio),
            horaFinal: Value(p.horaFinal),
            galones: Value(p.galones),
          ));
          if (p.fallaMecanicaId != null) {
            await _db.customStatement(
              'UPDATE paros_equipos_local SET falla_mecanica_id = ?, '
              'falla_mecanica_nombre = ? WHERE registro_id = ? AND hora_inicio = ?',
              [p.fallaMecanicaId, p.fallaMecanicaNombre, r.id, p.horaInicio],
            );
          }
        }

        // 6. Sectores (lotes) — delete + reinsert
        await _db.registroDao.deleteSectoresByRegistro(r.id);
        for (final s in r.sectores) {
          await _db.registroDao.upsertSector(RegistrosSectoresLocalCompanion(
            id: Value(s.id.isEmpty ? _uuid.v4() : s.id),
            registroId: Value(r.id),
            loteIdErp: Value(s.loteIdErp),
            loteCodigo: Value(s.loteCodigo),
            loteNombre: Value(s.loteNombre),
            fincaNombre: Value(s.fincaNombre),
            areaTrabajada: Value(s.areaTrabajada),
            observacion: Value(s.observacion),
          ));
        }
      });
      return const Right(null);
    } catch (e) {
      developer.log('upsertRegistroFromRemote error',
          name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Admin: sincronización directa al servidor (sin outbox) ─────────────

  @override
  Future<Either<Failure, String>> resyncAdminEdit(String registroId) =>
      syncRegistroDirecto(registroId);

  @override
  Future<Either<Failure, String>> syncRegistroDirecto(String registroId) async {
    try {
      // Cancelar entradas pendientes del outbox para este registro antes de
      // la sincronización directa. Sin esto, el SyncManager procesaría el outbox
      // después del sync directo, duplicando la llamada al SP (inofensivo por ser
      // idempotente, pero genera tráfico innecesario y puede causar confusión en logs).
      await _db.outboxDao.markAllDoneForRegistro(registroId);

      final payload = await _buildFullPayloadFromSQLite(registroId);
      final result = await actualizarRegistroDirecto(payload);
      // Marcar sincronizado en SQLite para que el operador no vea
      // el indicador de "pendiente" después de un re-sync del supervisor.
      if (result.isRight()) {
        await _db.registroDao.markSincronizado(registroId);
      }
      return result;
    } catch (e) {
      developer.log('syncRegistroDirecto error', name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> actualizarRegistroDirecto(
      Map<String, dynamic> payload) async {
    try {
      final rows = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spSincronizarOffline,
        parametros: [jsonEncode(payload)],
      );
      final out = rows.isNotEmpty ? rows.first : <String, dynamic>{};
      final successVal = out['success'];
      final isSuccess = successVal == true ||
          successVal == 1 ||
          successVal?.toString() == '1' ||
          successVal?.toString().toLowerCase() == 'true';
      // Capturar mensaje real del SP para mostrarlo en la UI (no usar texto hardcodeado).
      final msg = out['mensaje']?.toString() ?? '';
      if (!isSuccess) {
        developer.log('actualizarRegistroDirecto SP error: $msg',
            name: 'RegistroRepo');
        return Left(ServerFailure(
            message: msg.isNotEmpty ? msg : 'Error al sincronizar registro'));
      }
      developer.log('actualizarRegistroDirecto OK: ${out['registro_id']}',
          name: 'RegistroRepo');
      // Retornar mensaje real del SP para que la UI lo muestre al supervisor.
      return Right(msg);
    } catch (e) {
      developer.log('actualizarRegistroDirecto error',
          name: 'RegistroRepo', error: e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>> _buildFullPayloadFromSQLite(
      String registroId) async {
    final reg = await _db.registroDao.getRegistroById(registroId);
    if (reg == null) throw Exception('Registro $registroId no encontrado');

    final h = await _db.registroDao.getHorometroByRegistro(registroId);
    final tt = await _db.registroDao.getTiempoTurnoByRegistro(registroId);

    final checklistRows =
        await _db.registroDao.getChecklistByRegistro(registroId);
    final checklistDedup = <int, ChecklistResultadosLocalData>{};
    for (final c in checklistRows) {
      checklistDedup[c.itemId] = c;
    }
    final checklistJson = checklistDedup.values
        .map((c) => {
              'item_id': c.itemId,
              'resultado': c.resultado,
              'observacion': c.observacion,
              'foto_url': c.fotoUrl,
            })
        .toList();

    final parosRows = await _db.customSelect(
      'SELECT tipo_paro_id, motivo, equipo, hora_inicio, hora_final, galones, '
      'falla_mecanica_id, falla_mecanica_nombre '
      'FROM paros_equipos_local WHERE registro_id = ? ORDER BY hora_inicio',
      variables: [Variable.withString(registroId)],
    ).get();
    final parosJson = parosRows
        .map((p) => {
              'tipo_paro_id': p.read<int>('tipo_paro_id'),
              'motivo': p.readNullable<String>('motivo'),
              'equipo': p.readNullable<String>('equipo'),
              'hora_inicio': p.read<String>('hora_inicio'),
              'hora_final': p.readNullable<String>('hora_final'),
              'galones': p.readNullable<double>('galones'),
              if (p.readNullable<int>('falla_mecanica_id') != null)
                'falla_mecanica_id': p.read<int>('falla_mecanica_id'),
              if (p.readNullable<String>('falla_mecanica_nombre') != null)
                'falla_mecanica_nombre': p.read<String>('falla_mecanica_nombre'),
            })
        .toList();

    final binesRows = await _db.registroDao.getBinesByRegistro(registroId);
    final binesJson = binesRows
        .map((b) => {
              'franja_horaria': b.franjaHoraria,
              'turno_franja': b.turno,
              'cantidad': b.cantidad,
            })
        .toList();

    final sublaboresRows = await (_db.select(_db.subLaboresLocal)
          ..where((t) => t.registroId.equals(registroId)))
        .get();
    final sublaboresJson = sublaboresRows
        .map((s) => {'sublabor_nombre': s.sublaborNombre})
        .toList();

    final marchasRows = await (_db.select(_db.marchasLocal)
          ..where((t) => t.registroId.equals(registroId)))
        .get();
    final marchasJson = marchasRows
        .map((m) => {
              'marcha_codigo': m.marchaCodigo,
              if (m.horasUso != null) 'horas_uso': m.horasUso,
            })
        .toList();

    // Lotes/sectores — leídos desde registros_sectores_local.
    // Se enriquece con finca_id_erp del catálogo local porque
    // RegistrosSectoresLocal no almacena ese campo. El SP MERGE necesita
    // finca_id_erp para poder insertar lotes nuevos (WHEN NOT MATCHED BY TARGET
    // AND src.finca_id_erp IS NOT NULL). Sin esto, el re-sync del admin
    // solo actualiza lotes existentes y nunca inserta los nuevos.
    final sectoresRows =
        await _db.registroDao.getSectoresByRegistro(registroId);
    final lotesDbCat = await _db.catalogoDao.getLotes();
    final lotesCatMap = {for (final l in lotesDbCat) l.idErp: l};
    final lotesJson = sectoresRows.map((s) {
      final cat = lotesCatMap[s.loteIdErp];
      return {
        'lote_id_erp': s.loteIdErp,
        'lote_codigo': s.loteCodigo,
        'lote_nombre': s.loteNombre,
        'finca_nombre': s.fincaNombre,
        'area_trabajada_ha': s.areaTrabajada,
        if (cat != null) 'finca_id_erp': cat.fincaIdErp,
        if (s.observacion != null) 'observacion': s.observacion,
      };
    }).toList();

    // Ruta GPS — construir WKT LineString para enviar como una sola fila.
    // SQL Server GEOGRAPHY usa orden LONGITUD LATITUD (no lat/lon).
    // Con ≥ 2 puntos → LINESTRING; con 1 punto → POINT; con 0 → null (no se envía).
    // El SP v3 lo inserta en CLI547_AGM_Ruta_maquinaria vía GEOGRAPHY::STGeomFromText.
    final gpsRows2 = await _db.customSelect(
      'SELECT longitud, latitud '
      'FROM "CLI547_AGM_Ruta_maquinaria" '
      'WHERE registro_id = ? ORDER BY secuencia',
      variables: [Variable.withString(registroId)],
    ).get();
    final eventos =
        await GpsEventBuilderService(db: _db).construirEventos(registroId);
    String? rutaWkt;
    if (gpsRows2.length >= 2) {
      final coords = gpsRows2
          .map((p) =>
              '${p.read<double>('longitud').toStringAsFixed(7)} '
              '${p.read<double>('latitud').toStringAsFixed(7)}')
          .join(', ');
      rutaWkt = 'LINESTRING($coords)';
    } else if (gpsRows2.length == 1) {
      final p = gpsRows2.first;
      rutaWkt = 'POINT(${p.read<double>('longitud').toStringAsFixed(7)} '
          '${p.read<double>('latitud').toStringAsFixed(7)})';
    }

    return {
      'id': reg.id,
      'numero_registro': reg.numeroRegistro,
      'tipo_registro': reg.tipoRegistro,
      'fecha': AppDateUtils.toApiDate(reg.fecha),
      'turno': reg.turno,
      'proceso_id': reg.procesoId,
      if (reg.subprocesoId != null) 'subproceso_id': reg.subprocesoId,
      if (reg.subprocesoNombre != null) 'subproceso_nombre': reg.subprocesoNombre,
      'cultivo_id_erp': reg.cultivoIdErp,
      'cultivo_nombre': reg.cultivoNombreEspecie,
      'cultivo_codigo_especie': reg.cultivoCodigoEspecie,
      'operador_id_erp': reg.operadorIdErp,
      'operador_codigo': reg.operadorCodigo,
      'operador_nombre': reg.operadorNombre,
      'supervisor_id_erp': reg.supervisorIdErp,
      'supervisor_codigo': reg.supervisorCodigo,
      'supervisor_nombre': reg.supervisorNombre,
      'tractor_id_erp': reg.tractorIdErp,
      'tractor_codigo': reg.tractorCodigo,
      'tractor_descripcion': reg.tractorDescripcion,
      'implemento_id_erp': reg.implementoIdErp,
      'implemento_codigo': reg.implementoCodigo,
      'implemento_descripcion': reg.implementoDescripcion,
      'caja_cambios_id': reg.cajaCambiosId,
      'tractor_inicio': h?.tractorInicio,
      'tractor_final': h?.tractorFinal,
      'implemento_inicio': h?.implementoInicio,
      'implemento_final': h?.implementoFinal,
      'hora_salida_taller': tt?.horaSalidaTaller,
      'hora_llegada_punto': tt?.horaLlegadaPunto,
      'hora_salida_punto': tt?.horaSalidaPunto,
      'hora_llegada_taller': tt?.horaLlegadaTaller,
      'hora_refrigerio': tt?.horaRefrigerio,
      'observaciones_maq': reg.observacionesMaq,
      'dispositivo_id': reg.dispositivoId,
      'created_by_erp': reg.operadorIdErp,
      if (checklistJson.isNotEmpty) 'checklist': checklistJson,
      if (parosJson.isNotEmpty) 'paros': parosJson,
      if (binesJson.isNotEmpty) 'bines': binesJson,
      if (lotesJson.isNotEmpty) 'lotes': lotesJson,
      if (sublaboresJson.isNotEmpty) 'sublabores': sublaboresJson,
      if (marchasJson.isNotEmpty) 'marchas': marchasJson,
      if (reg.firmaOperador != null) 'firma_operador': reg.firmaOperador,
      if (rutaWkt != null) 'ruta_wkt': rutaWkt,
      // ── Eventos derivados (v5+) ──────────────────────────────────────────
      ...eventos,
    };
  }
}
