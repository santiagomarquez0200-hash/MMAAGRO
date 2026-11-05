import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/asignacion_dia.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/mi_dia_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';

class MiDiaRepositoryImpl implements MiDiaRepository {
  final ErpApiClient _erp;
  final AppDatabase _db;

  MiDiaRepositoryImpl({required ErpApiClient erp, required AppDatabase db})
      : _erp = erp,
        _db = db;

  @override
  Future<Either<Failure, MiDia>> getMiDia({
    int? idTrabajador,
    int? idUsuario,
    required DateTime fecha,
  }) async {
    if (idTrabajador == null && idUsuario == null) {
      return const Left(ValidationFailure(
        message: 'No se pudo identificar al operador. Vuelva a iniciar sesión.',
      ));
    }

    final fechaStr = _fechaIso(fecha);

    try {
      final rows = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spOperadorMiDia,
        parametros: [idTrabajador, idUsuario, fechaStr],
      );
      final asignaciones = rows.map(_fromRow).toList();
      await _guardarEnCache(fechaStr, rows);
      return Right(MiDia(
        asignaciones: asignaciones,
        sincronizadoAt: DateTime.now(),
      ));
    } on SocketException catch (_) {
      return _desdeCache(fechaStr);
    } on TimeoutException catch (_) {
      return _desdeCache(fechaStr);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('network')) {
        return _desdeCache(fechaStr);
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ── Cache local ─────────────────────────────────────────────────────────

  Future<void> _ensureTabla() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS mma_mi_dia_local (
        id_programacion TEXT PRIMARY KEY,
        fecha TEXT,
        payload_json TEXT,
        sincronizado_at TEXT
      )
    ''');
  }

  /// Se borra lo de esa fecha antes de insertar: si una asignacion se anulo o
  /// se le paso a otro operador, dejarla cacheada mandaria al tractorista a
  /// buscar una maquina que ya no es suya.
  Future<void> _guardarEnCache(
    String fechaStr,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      await _ensureTabla();
      final ahora = DateTime.now().toIso8601String();
      await _db.customStatement(
        'DELETE FROM mma_mi_dia_local WHERE fecha = ?',
        [fechaStr],
      );
      for (final r in rows) {
        final id = _texto(r['IdProgramacion']);
        if (id.isEmpty) continue;
        await _db.customStatement(
          'INSERT OR REPLACE INTO mma_mi_dia_local ('
          '  id_programacion, fecha, payload_json, sincronizado_at'
          ') VALUES (?, ?, ?, ?)',
          [id, fechaStr, jsonEncode(r), ahora],
        );
      }
    } catch (_) {
      // Que falle el cacheo no debe tumbar la consulta.
    }
  }

  Future<Either<Failure, MiDia>> _desdeCache(String fechaStr) async {
    try {
      await _ensureTabla();
      final filas = await _db.customSelect(
        'SELECT payload_json, sincronizado_at FROM mma_mi_dia_local '
        'WHERE fecha = ?',
        variables: [Variable.withString(fechaStr)],
      ).get();

      if (filas.isEmpty) {
        return const Left(CacheFailure(
          message: 'Sin conexión y sin asignaciones descargadas para esta '
              'fecha. Conéctese una vez para bajarlas.',
        ));
      }

      final asignaciones = <AsignacionDia>[];
      DateTime? sincronizadoAt;
      for (final f in filas) {
        final crudo = f.data['payload_json'] as String? ?? '';
        if (crudo.isEmpty) continue;
        asignaciones.add(_fromRow(jsonDecode(crudo) as Map<String, dynamic>));
        sincronizadoAt ??=
            DateTime.tryParse((f.data['sincronizado_at'] ?? '').toString());
      }

      // El SP ordena por turno y hora; SQLite no lo conserva.
      asignaciones.sort((a, b) {
        final porTurno = a.turno.compareTo(b.turno);
        if (porTurno != 0) return porTurno;
        final ha = a.horaPrevista ?? '99:99';
        final hb = b.horaPrevista ?? '99:99';
        final porHora = ha.compareTo(hb);
        if (porHora != 0) return porHora;
        return a.implemento.compareTo(b.implemento);
      });

      return Right(MiDia(
        asignaciones: asignaciones,
        desdeCache: true,
        sincronizadoAt: sincronizadoAt,
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ── Mapeo ───────────────────────────────────────────────────────────────

  AsignacionDia _fromRow(Map<String, dynamic> r) => AsignacionDia(
        idProgramacion: _texto(r['IdProgramacion']),
        fecha: DateTime.tryParse(_texto(r['Fecha'])) ?? DateTime.now(),
        turno: _texto(r['Turno']),
        idImplemento: _entero(r['IdImplemento']),
        implemento: _texto(r['Implemento']),
        descripcionImplemento: _opcional(r['DescripcionImplemento']),
        marca: _opcional(r['Marca']),
        modelo: _opcional(r['Modelo']),
        tipologia: _opcional(r['Tipologia']),
        idTractor: _entero(r['IdTractor']),
        tractor: _opcional(r['Tractor']),
        horaPrevista: _hora(r['HoraPrevista']),
        horaSalida: _hora(r['HoraSalida']),
        estado: _texto(r['Estado']),
        actividad: _opcional(r['Actividad']),
        cultivo: _opcional(r['Cultivo']),
        area: _opcional(r['Area']),
        sublote: _opcional(r['Sublote']),
        hectareas: _decimal(r['Hectareas']),
        nroOt: _opcional(r['NroOt']),
        modalidad: _opcional(r['Modalidad']),
        marcha: _opcional(r['Marcha']),
        presion: _opcional(r['Presion']),
        mojamiento: _opcional(r['Mojamiento']),
        observacionOrden: _opcional(r['ObservacionOrden']),
        solicitud: _opcional(r['Solicitud']),
        solicitante: _opcional(r['Solicitante']),
        observacion: _opcional(r['Observacion']),
      );

  static String _fechaIso(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';

  static String _texto(dynamic v) => v?.toString().trim() ?? '';

  static String? _opcional(dynamic v) {
    final s = _texto(v);
    return s.isEmpty ? null : s;
  }

  static int? _entero(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double? _decimal(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim().replaceAll(',', '.'));
  }

  /// Un TIME de SQL Server puede llegar como "06:15:00" o dentro de un
  /// datetime completo. Se normaliza a HH:mm.
  static String? _hora(dynamic v) {
    final s = _texto(v);
    if (s.isEmpty) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
    if (m == null) return s;
    return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  }
}
