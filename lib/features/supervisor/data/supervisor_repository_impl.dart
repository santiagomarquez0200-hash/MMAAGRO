import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/exceptions.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/repositories/supervisor_repository.dart';

class SupervisorRepositoryImpl implements SupervisorRepository {
  final ErpApiClient _erp;

  const SupervisorRepositoryImpl({required ErpApiClient erp}) : _erp = erp;

  @override
  Future<Either<Failure, List<RegistroDiario>>> getRegistros({
    required DateTime fecha,
    String? turno,
  }) async {
    try {
      final rows = await _erp.getRegistrosSupervisor(
        fecha: '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}',
        turno: turno,
      );
      return Right(rows.map(_rowToRegistroDiario).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> aprobarRegistro(
      AprobarRegistroParams params) async {
    try {
      final rows = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spAprobarRegistro,
        parametros: [
          params.registroId,
          params.supervisorIdErp,
          params.accion,
          params.motivo,
        ],
      );
      final row = rows.isNotEmpty ? rows.first : const <String, dynamic>{};
      final success = row['success'];
      if (success == null || success == 0 || success == false || success == '0') {
        final msg =
            row['mensaje']?.toString() ?? 'Error al procesar registro';
        return Left(ServerFailure(message: msg));
      }
      return const Right(null);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  RegistroDiario _rowToRegistroDiario(Map<String, dynamic> row) {
    final registroId = row['registro_id']?.toString() ?? '';

    final horometroData = _parseObject(row['horometro_json']);
    final tiemposTurnoData = _parseObject(row['tiempos_turno_json']);
    final vehiculoData = _parseObject(row['vehiculo_json']);
    final parosList = _parseList(row['paros_json']);
    final checklistList = _parseList(row['checklist_json']);
    final binesList = _parseList(row['bines_json']);
    final sectoresList = _parseList(row['sectores_json']);
    final combustiblesVehiculoList =
        _parseList(row['combustible_vehiculo_json']);
    final parosVehiculoList = _parseList(row['paros_vehiculo_json']);

    final horometro = horometroData == null
        ? null
        : Horometro(
            id: registroId,
            registroId: registroId,
            tractorInicio: _toDouble(horometroData['tractor_inicio']),
            tractorFinal: _toDouble(horometroData['tractor_final']),
            implementoInicio: _toDouble(horometroData['implemento_inicio']),
            implementoFinal: _toDouble(horometroData['implemento_final']),
          );

    final tiempoTurno = tiemposTurnoData == null
        ? null
        : TiempoTurno(
            id: registroId,
            registroId: registroId,
            horaSalidaTaller:
                tiemposTurnoData['hora_salida_taller']?.toString(),
            horaLlegadaPunto:
                tiemposTurnoData['hora_llegada_punto']?.toString(),
            horaSalidaPunto: tiemposTurnoData['hora_salida_punto']?.toString(),
            horaLlegadaTaller:
                tiemposTurnoData['hora_llegada_taller']?.toString(),
            horaRefrigerio: tiemposTurnoData['hora_refrigerio']?.toString(),
          );

    final paros = parosList
        .map((p) => ParoEquipo(
              id: p['paro_id']?.toString() ?? '',
              registroId: registroId,
              tipoParoId: _toInt(p['tipo_paro_id']) ?? 0,
              tipoParoCodigo: p['tipo_paro_codigo']?.toString() ?? '',
              tipoParoNombre: p['tipo_paro_nombre']?.toString() ?? '',
              motivo: p['motivo']?.toString(),
              equipo: p['equipo']?.toString(),
              horaInicio: p['hora_inicio']?.toString() ?? '00:00:00',
              horaFinal: p['hora_final']?.toString(),
              galones: _toDouble(p['galones']),
              duracionMin: _toInt(p['duracion_min']),
            ))
        .toList();

    final checklist = <ChecklistResultado>[];
    for (final c in checklistList) {
      final itemId = c['item_id'];
      if (itemId == null) continue;
      checklist.add(ChecklistResultado(
        id: '${registroId}_$itemId',
        registroId: registroId,
        itemId: _toInt(itemId) ?? 0,
        itemNombre: c['item_nombre']?.toString() ?? '',
        categoriaNombre: c['categoria_nombre']?.toString() ?? '',
        resultado: c['resultado']?.toString() ?? 'na',
        observacion: c['observacion']?.toString(),
      ));
    }

    final bines = binesList
        .map((b) => CosechaBin(
              id: '${registroId}_${b['franja_horaria']}',
              registroId: registroId,
              franjaHoraria: b['franja_horaria']?.toString() ?? '',
              turno: b['turno_franja']?.toString() ?? '',
              cantidad: _toInt(b['cantidad']) ?? 0,
            ))
        .toList();

    final sectores = <RegistroSector>[];
    for (final s in sectoresList) {
      final loteId = s['lote_id_erp'];
      if (loteId == null) continue;
      sectores.add(RegistroSector(
        id: '${registroId}_$loteId',
        registroId: registroId,
        loteIdErp: _toInt(loteId) ?? 0,
        loteCodigo: s['lote_codigo']?.toString() ?? '',
        loteNombre: s['lote_nombre']?.toString() ?? '',
        // El SP no devuelve finca_nombre. lote_codigo contiene el código
        // de finca (e.g. "U-001"), que es el identificador más informativo.
        fincaNombre: s['lote_codigo']?.toString() ?? '',
        areaTrabajada: _toDouble(s['area_trabajada_ha']),
      ));
    }

    final supId = _toInt(row['supervisor_id_erp']);

    return RegistroDiario(
      id: registroId,
      numeroRegistro: row['numero_registro']?.toString() ?? '',
      fecha: _parseDate(row['fecha']?.toString()),
      turno: row['turno']?.toString() ?? 'dia',
      procesoId: _toInt(row['proceso_id']) ?? 0,
      procesoNombre: row['proceso_nombre']?.toString() ?? '',
      procesoCodigo: row['proceso_codigo']?.toString() ?? '',
      subprocesoId: _toInt(row['subproceso_id']),
      subprocesoNombre: row['subproceso_nombre']?.toString(),
      cultivoIdErp: _toInt(row['cultivo_id_erp']) ?? 0,
      cultivoNombreEspecie: row['nombre_cultivo']?.toString() ?? '',
      cultivoCodigoEspecie: '',
      operadorIdErp: _toInt(row['operador_id_erp']) ?? 0,
      operadorCodigo: '',
      operadorNombre: row['nombre_operador']?.toString() ?? '',
      supervisorIdErp: (supId == null || supId == 0) ? null : supId,
      supervisorCodigo: null,
      supervisorNombre: row['nombre_supervisor']?.toString(),
      tractorIdErp: _toInt(row['tractor_id_erp']) ?? 0,
      tractorCodigo: row['codigo_tractor']?.toString() ?? '',
      // El SP solo retorna el código snapshot; no hay descripción separada.
      // Se deja vacío para evitar mostrar "T-010-T-010" en la vista de detalle.
      tractorDescripcion: '',
      implementoIdErp: _toInt(row['implemento_id_erp']),
      implementoCodigo: row['codigo_implemento']?.toString(),
      implementoDescripcion: row['codigo_implemento']?.toString(),
      cajaCambiosId: _toInt(row['caja_cambios_id']),
      cajaCambiosNombre: row['caja_cambios_nombre']?.toString(),
      estado: row['estado']?.toString() ?? 'borrador',
      tipoRegistro: row['tipo_registro']?.toString() ?? 'tractor',
      observacionesMaq: row['observaciones_maq']?.toString(),
      motivoRechazo: row['motivo_rechazo']?.toString(),
      firmaOperador: row['firma_operador']?.toString(),
      dispositivoId: row['dispositivo_id']?.toString(),
      sincronizado: _toBool(row['sincronizado_erp']),
      sincronizadoAt: _parseDateTime(row['sincronizado_at']?.toString()),
      createdAt:
          _parseDateTime(row['created_at']?.toString()) ?? DateTime.now(),
      horometro: horometro,
      tiempoTurno: tiempoTurno,
      paros: paros,
      checklist: checklist,
      bines: bines,
      sectores: sectores,
      vehiculoDetalle: vehiculoData == null
          ? null
          : VehiculoDetalle(
              kmCamionInicio: _toDouble(vehiculoData['km_camion_inicio']),
              kmCamionFinal: _toDouble(vehiculoData['km_camion_final']),
              kmImplementoInicio:
                  _toDouble(vehiculoData['km_implemento_inicio']),
              kmImplementoFinal: _toDouble(vehiculoData['km_implemento_final']),
              horaSalidaBase: vehiculoData['hora_salida_base_td']?.toString(),
              horaLlegadaZona: vehiculoData['hora_llegada_zona']?.toString(),
              horaRetornoBase: vehiculoData['hora_retorno_base']?.toString(),
              horaLlegadaTaller:
                  vehiculoData['hora_llegada_taller']?.toString(),
              horaRefrigerio: vehiculoData['hora_refrigerio']?.toString(),
              cantidadTancadas: _toInt(vehiculoData['cantidad_tancadas']),
            ),
      combustiblesVehiculo: combustiblesVehiculoList
          .map((c) => CombustibleVehiculoDetalle(
                glns: _toDouble(c['glns']),
                horaInicio: c['hora_inicio']?.toString(),
                horaFinal: c['hora_final']?.toString(),
              ))
          .toList(),
      parosVehiculo: parosVehiculoList
          .map((p) => ParoVehiculoDetalle(
                motivo: p['motivo']?.toString(),
                horaInicio: p['hora_inicio']?.toString(),
                horaFinal: p['hora_final']?.toString(),
              ))
          .toList(),
    );
  }

  // ── JSON helpers ────────────────────────────────────────────────────────────

  Map<String, dynamic>? _parseObject(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        return d is Map<String, dynamic> ? d : null;
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _parseList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is List) {
          return d
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  // ── Type coercion helpers ────────────────────────────────────────────────────

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  DateTime _parseDate(String? s) {
    if (s == null || s.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(s);
    if (parsed == null) {
      developer.log(
        '_parseDate: no se pudo parsear la fecha "$s", usando DateTime.now()',
        name: 'SupervisorRepositoryImpl',
      );
    }
    return parsed ?? DateTime.now();
  }

  DateTime? _parseDateTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
