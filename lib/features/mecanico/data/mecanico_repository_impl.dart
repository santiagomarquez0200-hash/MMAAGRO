import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/repositories/mecanico_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';

class MecanicoRepositoryImpl implements MecanicoRepository {
  final ErpApiClient _erp;
  final AppDatabase _db;

  MecanicoRepositoryImpl({required ErpApiClient erp, required AppDatabase db})
      : _erp = erp,
        _db = db;

  @override
  Future<Either<Failure, List<ParoMecanico>>> getParosMecanico({
    required DateTime fecha,
    String? estado,
  }) async {
    try {
      final fechaStr =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final rows = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spGetParosMecanico,
        parametros: [fechaStr, estado],
      );
      final paros = rows.map(_fromRow).toList();
      return Right(paros);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completarFalla(
      CompletarFallaParams params) async {
    try {
      await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spCompletarFallaMecanica,
        parametros: [
          params.paroId,
          params.horaInicioReal,
          params.horaFinReal,
          params.mecanicoIdErp,
          params.trabajoRealizado,
          params.estadoFalla,
          params.mecanicoNombre,
        ],
      );
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } on SocketException catch (_) {
      await _enqueueOffline(params);
      return const Right(null);
    } on TimeoutException catch (_) {
      await _enqueueOffline(params);
      return const Right(null);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('network')) {
        await _enqueueOffline(params);
        return const Right(null);
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<void> _enqueueOffline(CompletarFallaParams params) async {
    final payload = {
      'paro_id': params.paroId,
      'hora_inicio_real': params.horaInicioReal,
      'hora_fin_real': params.horaFinReal,
      'mecanico_id_erp': params.mecanicoIdErp,
      'trabajo_realizado': params.trabajoRealizado,
      'estado_falla': params.estadoFalla,
      'mecanico_nombre': params.mecanicoNombre,
    };
    await _db.outboxDao.insertEntry(OutboxEntriesCompanion(
      registroLocalId: Value(params.paroId),
      endpoint: Value('/mecanico/completar-falla'),
      method: Value('POST'),
      payloadJson: Value(jsonEncode(payload)),
    ));
  }

  ParoMecanico _fromRow(Map<String, dynamic> r) => ParoMecanico(
        paroId: r['paro_id']?.toString() ?? '',
        operadorNombre: r['operador_nombre'] as String? ?? '',
        tractorCodigo: r['tractor_codigo'] as String? ?? '',
        fecha: DateTime.tryParse(r['fecha'] as String? ?? '') ?? DateTime.now(),
        horaInicio: r['hora_inicio_operador'] as String? ?? '',
        horaFinal: (r['hora_fin_operador'] ??
                r['hora_final_operador'] ??
                r['hora_fin_mecanico'] ??
                r['hora_fin']) as String?,
        equipo: r['equipo'] as String?,
        fallaMecanicaId: (r['falla_mecanica_id'] as num?)?.toInt() ?? 0,
        fallaMecanicaNombre: r['falla_mecanica_nombre'] as String? ?? '',
        motivo: r['motivo_operador'] as String?,
        estadoFalla: r['estado_falla'] as String? ?? 'pendiente',
        trabajoRealizado: r['trabajo_realizado'] as String?,
        horaInicioReal: r['hora_inicio_real'] as String?,
        horaFinReal: r['hora_fin_real'] as String?,
        mecanicoNombre: r['mecanico_nombre'] as String?,
      );
}
