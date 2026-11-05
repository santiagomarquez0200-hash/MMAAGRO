import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/portero/domain/entities/maquina_programada.dart';
import 'package:agro_aplicaciones/features/portero/domain/repositories/portero_programa_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';

class PorteroProgramaRepositoryImpl implements PorteroProgramaRepository {
  final ErpApiClient _erp;
  final AppDatabase _db;

  PorteroProgramaRepositoryImpl({
    required ErpApiClient erp,
    required AppDatabase db,
  })  : _erp = erp,
        _db = db;

  @override
  Future<Either<Failure, ProgramaTurno>> getProgramaTurno({
    required DateTime fecha,
    String? turno,
  }) async {
    final fechaStr = _fechaIso(fecha);

    // La sede sale del perfil del usuario, no de la pantalla: el portero no
    // tiene por que elegirla y equivocarse, y asi tambien funciona sin red.
    final sede = await _sedeDelPerfil();
    if (sede == null || sede.isEmpty) {
      return const Left(ValidationFailure(
        message: 'No se pudo determinar la sede del usuario. '
            'Abra su perfil para sincronizarlo e intente de nuevo.',
      ));
    }

    try {
      final rows = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spGaritaTurno,
        parametros: [sede, fechaStr, turno],
      );
      final maquinas = rows.map(_fromRow).toList();
      await _guardarEnCache(fechaStr, turno, rows);
      return Right(ProgramaTurno(
        maquinas: maquinas,
        sincronizadoAt: DateTime.now(),
      ));
    } on SocketException catch (_) {
      return _desdeCache(fechaStr, turno);
    } on TimeoutException catch (_) {
      return _desdeCache(fechaStr, turno);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      // Mismo criterio que el repositorio del mecanico: el proxy REST no
      // siempre deja pasar la excepcion tipada, asi que tambien se mira el
      // texto antes de decidir que es un problema de red.
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('network')) {
        return _desdeCache(fechaStr, turno);
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ── Sede ────────────────────────────────────────────────────────────────

  /// Lee la sede del perfil profesional guardado en el login.
  ///
  /// El SP acepta el codigo ('PCO') o el nombre ('PISCO') y resuelve contra
  /// dbo.Zonas, asi que alcanza con mandar lo que el perfil tenga. Si la sede
  /// viene vacia se cae al fundo, que en el ERP es el dato mas cercano.
  Future<String?> _sedeDelPerfil() async {
    try {
      final row = await _db
          .customSelect('SELECT sede, fundo FROM mma_perfil_usuario_local LIMIT 1')
          .getSingleOrNull();
      if (row == null) return null;
      final sede = (row.data['sede'] as String? ?? '').trim();
      if (sede.isNotEmpty) return sede;
      return (row.data['fundo'] as String? ?? '').trim();
    } catch (_) {
      // La tabla la crea el repositorio de auth al sincronizar el perfil. Si
      // todavia no existe, no es un error: es que no hubo login con perfil.
      return null;
    }
  }

  // ── Cache local ─────────────────────────────────────────────────────────

  Future<void> _ensureTabla() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS mma_programa_garita_local (
        id_programacion TEXT PRIMARY KEY,
        fecha TEXT,
        turno TEXT,
        payload_json TEXT,
        sincronizado_at TEXT
      )
    ''');
  }

  /// Guarda el programa recien bajado, reemplazando el de esa fecha y turno.
  ///
  /// Se borra antes de insertar porque una maquina puede desaparecer del
  /// programa (se anulo): si solo se insertara, quedaria para siempre en la
  /// lista del portero.
  Future<void> _guardarEnCache(
    String fechaStr,
    String? turno,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      await _ensureTabla();
      final ahora = DateTime.now().toIso8601String();
      if (turno == null) {
        await _db.customStatement(
          'DELETE FROM mma_programa_garita_local WHERE fecha = ?',
          [fechaStr],
        );
      } else {
        await _db.customStatement(
          'DELETE FROM mma_programa_garita_local WHERE fecha = ? AND turno = ?',
          [fechaStr, turno],
        );
      }
      for (final r in rows) {
        final id = _texto(r['IdProgramacion']);
        if (id.isEmpty) continue;
        await _db.customStatement(
          'INSERT OR REPLACE INTO mma_programa_garita_local ('
          '  id_programacion, fecha, turno, payload_json, sincronizado_at'
          ') VALUES (?, ?, ?, ?, ?)',
          [id, fechaStr, _texto(r['Turno']), jsonEncode(r), ahora],
        );
      }
    } catch (_) {
      // Que falle el cacheo no debe tumbar la consulta: el portero ya tiene
      // la lista en pantalla, que es lo que importa en ese momento.
    }
  }

  Future<Either<Failure, ProgramaTurno>> _desdeCache(
    String fechaStr,
    String? turno,
  ) async {
    try {
      await _ensureTabla();
      final filas = turno == null
          ? await _db.customSelect(
              'SELECT payload_json, sincronizado_at FROM mma_programa_garita_local '
              'WHERE fecha = ?',
              variables: [Variable.withString(fechaStr)],
            ).get()
          : await _db.customSelect(
              'SELECT payload_json, sincronizado_at FROM mma_programa_garita_local '
              'WHERE fecha = ? AND turno = ?',
              variables: [
                Variable.withString(fechaStr),
                Variable.withString(turno),
              ],
            ).get();

      if (filas.isEmpty) {
        // CacheFailure y no NetworkFailure: el problema no es solo que no haya
        // red, es que tampoco hay nada guardado de antes. El portero necesita
        // saber que le falta bajar el programa, no solo que esta sin señal.
        return const Left(CacheFailure(
          message: 'Sin conexión y sin programa descargado para esta fecha. '
              'Conéctese una vez para bajarlo.',
        ));
      }

      final maquinas = <MaquinaProgramada>[];
      DateTime? sincronizadoAt;
      for (final f in filas) {
        final crudo = f.data['payload_json'] as String? ?? '';
        if (crudo.isEmpty) continue;
        maquinas.add(_fromRow(jsonDecode(crudo) as Map<String, dynamic>));
        sincronizadoAt ??=
            DateTime.tryParse((f.data['sincronizado_at'] ?? '').toString());
      }

      // El orden lo decide el SP (pendientes primero, luego por hora); SQLite
      // no lo conserva, asi que se reaplica el mismo criterio.
      maquinas.sort(_ordenGarita);

      return Right(ProgramaTurno(
        maquinas: maquinas,
        desdeCache: true,
        sincronizadoAt: sincronizadoAt,
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// Pendientes primero — es contra lo que el portero trabaja — y dentro de
  /// ellos por hora de entrega, que es el orden en que van a aparecer.
  static int _ordenGarita(MaquinaProgramada a, MaquinaProgramada b) {
    if (a.yaSalio != b.yaSalio) return a.yaSalio ? 1 : -1;
    final ha = a.horaPrevista ?? '99:99';
    final hb = b.horaPrevista ?? '99:99';
    final porHora = ha.compareTo(hb);
    if (porHora != 0) return porHora;
    final porTurno = a.turno.compareTo(b.turno);
    if (porTurno != 0) return porTurno;
    return a.implemento.compareTo(b.implemento);
  }

  // ── Mapeo ───────────────────────────────────────────────────────────────

  MaquinaProgramada _fromRow(Map<String, dynamic> r) => MaquinaProgramada(
        idProgramacion: _texto(r['IdProgramacion']),
        fecha: DateTime.tryParse(_texto(r['Fecha'])) ?? DateTime.now(),
        turno: _texto(r['Turno']),
        idImplemento: _entero(r['IdImplemento']),
        implemento: _texto(r['Implemento']),
        descripcionImplemento: _opcional(r['DescripcionImplemento']),
        identificacion: _opcional(r['Identificacion']),
        marca: _opcional(r['Marca']),
        modelo: _opcional(r['Modelo']),
        tipologia: _opcional(r['Tipologia']),
        idTractor: _entero(r['IdTractor']),
        tractor: _opcional(r['Tractor']),
        idOperador: _entero(r['IdOperador']),
        operador: _opcional(r['Operador']),
        sinOperador: _bit(r['SinOperador']),
        horaPrevista: _hora(r['HoraPrevista']),
        horaSalida: _hora(r['HoraSalida']),
        puntoSalida: _opcional(r['PuntoSalida']),
        horometro: _decimal(r['Horometro']),
        estado: _texto(r['Estado']),
        yaSalio: _bit(r['YaSalio']),
        motivoIncumplimiento: _opcional(r['MotivoIncumplimiento']),
        actividad: _opcional(r['Actividad']),
        cultivo: _opcional(r['Cultivo']),
        area: _opcional(r['Area']),
        sublote: _opcional(r['Sublote']),
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

  /// El proxy REST devuelve los BIT de SQL Server de varias formas segun como
  /// serialice: bool, 1/0, o el texto "true". Se aceptan las tres.
  static bool _bit(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true';
  }

  /// Un TIME de SQL Server puede llegar como "06:15:00" o dentro de un
  /// datetime completo. Se normaliza a HH:mm, que es lo unico que se muestra.
  static String? _hora(dynamic v) {
    final s = _texto(v);
    if (s.isEmpty) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
    if (m == null) return s;
    return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  }
}
