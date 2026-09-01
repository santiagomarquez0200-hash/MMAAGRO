import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/network/network_info.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';

class StatusSyncManager {
  final NetworkInfo _networkInfo;
  final ErpApiClient _erp;
  final AppDatabase _db;

  StreamSubscription<bool>? _connectivitySub;
  bool _isPendingRunning = false;

  StatusSyncManager({
    required NetworkInfo networkInfo,
    required ErpApiClient erp,
    required AppDatabase db,
  })  : _networkInfo = networkInfo,
        _erp = erp,
        _db = db;

  void startListening() {
    // Procesar backlog pendiente inmediatamente en caso de que el dispositivo
    // ya tenga conexión al iniciar (no hay evento de cambio que lo dispare).
    _safePending();
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((connected) {
      if (connected) _safePending();
    });
  }

  // Wrapper que evita llamadas concurrentes a processPending().
  // Si ya hay un ciclo corriendo, el nuevo evento de conectividad se descarta.
  void _safePending() {
    if (_isPendingRunning) return;
    processPending();
  }

  void stopListening() => _connectivitySub?.cancel();

  Future<void> processPending() async {
    if (_isPendingRunning) return;
    _isPendingRunning = true;
    try {
      final rows = await _db
          .customSelect(
            'SELECT * FROM status_jornada_pendiente ORDER BY id ASC LIMIT 50',
          )
          .get();

      for (final row in rows) {
        final id = row.read<int>('id');
        final intentos = row.read<int>('intentos');
        try {
          final payloadJson = row.read<String>('payload_json');
          final result = await _erp.ejecutarSP(
            nombreSP: AppEnvironment.spActualizarStatusJornada,
            parametros: [payloadJson],
          );
          final spOk = result.isNotEmpty && result[0]['success'] == true;
          if (!spOk) {
            final spMsg = result.isNotEmpty
                ? result[0]['mensaje']?.toString() ?? 'Sin mensaje'
                : 'SP sin respuesta';
            throw Exception('SP rechazó pendiente id=$id: $spMsg');
          }
          await _db.customUpdate(
            'DELETE FROM status_jornada_pendiente WHERE id = ?',
            variables: [Variable.withInt(id)],
          );
        } catch (e) {
          developer.log(
            'processPending: fallo en id=$id intento=${intentos + 1} — $e',
            name: 'StatusSync',
            error: e,
          );
          // Sin límite de reintentos: política idéntica al outbox principal.
          // El status de jornada es dato crítico — nunca se descarta aunque
          // el servidor esté caído durante horas. Se reintentará en cada
          // reconexión hasta que el SP lo confirme.
          await _db.customUpdate(
            'UPDATE status_jornada_pendiente SET intentos = intentos + 1 WHERE id = ?',
            variables: [Variable.withInt(id)],
          );
        }
      }
    } finally {
      _isPendingRunning = false;
    }
  }

  /// Guarda la jornada localmente y la envía al ERP si hay conexión.
  /// Devuelve `true` si el ERP la recibió correctamente, `false` si quedó
  /// en cola pendiente (sin conexión o error de red).
  Future<bool> guardarYEnviar({
    required int usuarioId,
    required String dispositivoId,
    required String turno,
    required DateTime jornadaInicioAt,
    DateTime? jornadaFinAt,
  }) async {
    if (usuarioId <= 0) {
      throw ArgumentError(
        'usuarioId inválido ($usuarioId): el usuario no tiene ID de ERP configurado. '
        'No se puede registrar la jornada.',
      );
    }
    // Todas las operaciones de red/BD están protegidas internamente.
    // Solo un ArgumentError (validación) debe propagarse al llamador.
    final inicioMs = jornadaInicioAt.millisecondsSinceEpoch;
    final finMs = jornadaFinAt?.millisecondsSinceEpoch;

    // Upsert en local: si ya existe registro para el mismo dispositivo+turno+día, actualizar
    final existing = await _db.customSelect(
      '''SELECT id FROM status_jornada_local
         WHERE dispositivo_id = ?
           AND turno = ?
           AND jornada_inicio_at >= ?
           AND jornada_inicio_at < ?
         LIMIT 1''',
      variables: [
        Variable.withString(dispositivoId),
        Variable.withString(turno),
        Variable.withInt(
            DateTime(jornadaInicioAt.year, jornadaInicioAt.month,
                    jornadaInicioAt.day)
                .millisecondsSinceEpoch),
        Variable.withInt(
            DateTime(jornadaInicioAt.year, jornadaInicioAt.month,
                    jornadaInicioAt.day, 23, 59, 59)
                .millisecondsSinceEpoch),
      ],
    ).get();

    if (existing.isNotEmpty) {
      await _db.customUpdate(
        '''UPDATE status_jornada_local
           SET jornada_fin_at = ?, sincronizado = 0
           WHERE id = ?''',
        variables: [
          Variable<int>(finMs),
          Variable.withInt(existing.first.read<int>('id')),
        ],
      );
    } else {
      await _db.customInsert(
        '''INSERT INTO status_jornada_local
           (usuario_id, dispositivo_id, turno, jornada_inicio_at, jornada_fin_at, sincronizado)
           VALUES (?, ?, ?, ?, ?, 0)''',
        variables: [
          Variable.withInt(usuarioId),
          Variable.withString(dispositivoId),
          Variable.withString(turno),
          Variable.withInt(inicioMs),
          Variable<int>(finMs),
        ],
      );
    }

    // Se envía hora local (sin conversión UTC) para que el SP pueda comparar
    // CAST(jornada_inicio_at AS DATE) contra la fecha local del día.
    // Si se enviara UTC, usuarios en UTC-5 generarían fechas incorrectas
    // para jornadas iniciadas después de las 19:00 local.
    final payload = {
      'usuario_id': usuarioId,
      'dispositivo_id': dispositivoId,
      'turno': turno,
      'jornada_inicio_at': jornadaInicioAt.toIso8601String(),
      if (jornadaFinAt != null)
        'jornada_fin_at': jornadaFinAt.toIso8601String(),
    };
    final payloadJson = jsonEncode(payload);

    if (await _networkInfo.isConnected) {
      try {
        final result = await _erp.ejecutarSP(
          nombreSP: AppEnvironment.spActualizarStatusJornada,
          parametros: [payloadJson],
        );
        // HTTP 200 no garantiza éxito: el SP devuelve {success, mensaje}.
        // success puede venir como bool (true/false) o int (1/0) según el API.
        final rawSuccess = result.isNotEmpty ? result[0]['success'] : null;
        final spOk = rawSuccess == true || rawSuccess == 1;
        if (!spOk) {
          final spMsg = result.isNotEmpty
              ? result[0]['mensaje']?.toString() ?? 'Sin mensaje del SP'
              : 'SP sin filas de respuesta';
          debugPrint('[StatusSync] SP rechazó jornada: $spMsg | raw=$rawSuccess | result=$result');
          throw Exception('SP rechazó jornada: $spMsg');
        }
        await _db.customUpdate(
          '''UPDATE status_jornada_local SET sincronizado = 1
             WHERE dispositivo_id = ? AND turno = ? AND jornada_inicio_at = ?''',
          variables: [
            Variable.withString(dispositivoId),
            Variable.withString(turno),
            Variable.withInt(inicioMs),
          ],
        );
        return true;
      } catch (e) {
        developer.log(
          'guardarYEnviar: SP falló, jornada encolada — $e',
          name: 'StatusSync',
          error: e,
        );
        await _encolarPendiente(payloadJson);
        return false;
      }
    } else {
      await _encolarPendiente(payloadJson);
      return false;
    }
  }

  /// Returns turno and jornadaInicioAt for the active jornada today on this
  /// device for the given user, or null.
  /// [usuarioId] must be provided to avoid returning another user's jornada
  /// when multiple users share the same device (switch de sesión).
  Future<Map<String, dynamic>?> obtenerDatosJornadaActiva(
      String dispositivoId, {int? usuarioId}) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final whereUsuario = usuarioId != null ? 'AND usuario_id = ?' : '';
    final rows = await _db.customSelect(
      '''SELECT turno, jornada_inicio_at FROM status_jornada_local
         WHERE dispositivo_id = ?
           AND jornada_inicio_at >= ?
           AND jornada_inicio_at <= ?
           AND (jornada_fin_at IS NULL OR jornada_fin_at = 0)
           $whereUsuario
         ORDER BY jornada_inicio_at DESC LIMIT 1''',
      variables: [
        Variable.withString(dispositivoId),
        Variable.withInt(startOfDay),
        Variable.withInt(endOfDay),
        if (usuarioId != null) Variable.withInt(usuarioId),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return {
      'turno': rows.first.read<String>('turno'),
      'jornada_inicio_at': DateTime.fromMillisecondsSinceEpoch(
          rows.first.read<int>('jornada_inicio_at')),
    };
  }

  /// Devuelve true si hay una jornada iniciada (sin fin) para hoy en este
  /// dispositivo Y para este usuario. El filtro por usuarioId evita que la
  /// jornada abierta de un usuario bloquee a otro usuario en el mismo celular.
  Future<bool> tieneJornadaActiva(String dispositivoId,
      {int? usuarioId}) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    final whereUsuario = usuarioId != null ? 'AND usuario_id = ?' : '';
    final variables = [
      Variable.withString(dispositivoId),
      Variable.withInt(startOfDay),
      Variable.withInt(endOfDay),
      if (usuarioId != null) Variable.withInt(usuarioId),
    ];

    final rows = await _db.customSelect(
      '''SELECT id FROM status_jornada_local
         WHERE dispositivo_id = ?
           AND jornada_inicio_at >= ?
           AND jornada_inicio_at <= ?
           AND (jornada_fin_at IS NULL OR jornada_fin_at = 0)
           $whereUsuario
         LIMIT 1''',
      variables: variables,
    ).get();
    return rows.isNotEmpty;
  }

  /// Limpia solo el estado efímero de la jornada: lecturas de portero, tracking
  /// de jornada del dispositivo y entradas de outbox completadas.
  ///
  /// Los registros diarios y sus tablas hijas NO se eliminan aquí — se acumulan
  /// hasta 7 días en SQLite para que el backup siempre tenga datos históricos.
  /// El barrido de registros antiguos lo ejecuta [DailyResetService._performReset].
  Future<void> limpiarDatosJornada(String dispositivoId) async {
    // Lecturas del portero (efímeras, no se necesitan entre jornadas)
    await _db.customUpdate(
        'DELETE FROM portero_lecturas_local', variables: []);
    // Jornada local de este dispositivo únicamente
    await _db.customUpdate(
      'DELETE FROM status_jornada_local WHERE dispositivo_id = ?',
      variables: [Variable.withString(dispositivoId)],
    );
    // Outbox: solo eliminar las entradas ya completadas ('done').
    // Las entradas pendientes/fallidas se conservan para que el próximo
    // ciclo de sync las reintente — nunca descartar datos no confirmados.
    await _db.customUpdate(
      "DELETE FROM outbox_entries WHERE status = 'done'",
      variables: [],
    );
  }

  Future<void> _encolarPendiente(String payloadJson) async {
    await _db.customInsert(
      'INSERT INTO status_jornada_pendiente (payload_json, intentos) VALUES (?, 0)',
      variables: [Variable.withString(payloadJson)],
    );
  }

  // ─── Validación de 1 jornada por usuario por turno ──────────────────────────
  // Clave SharedPreferences: "jornada_{usuarioId}_{turno}_{yyyyMMdd}"
  // Esta clave persiste aunque el usuario cierre y vuelva a abrir sesión,
  // garantizando que no pueda iniciar un segundo turno del mismo tipo en el mismo día.

  static String _jornadaKey(int usuarioId, String turno) {
    final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'jornada_${usuarioId}_${turno}_$hoy';
  }

  /// Marca que el usuario ya inició (o tiene) una jornada para este turno hoy.
  /// Se llama justo antes de navegar al home tras _iniciarJornada().
  Future<void> marcarJornadaIniciada(int usuarioId, String turno) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_jornadaKey(usuarioId, turno), true);
    // Contador persistente de jornadas abiertas hoy.
    // Solo lo borra el reset diario de las 4am; limpiarDatosJornada NO lo toca.
    final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
    final countKey = 'jornadas_iniciadas_${usuarioId}_$hoy';
    final prev = prefs.getInt(countKey) ?? 0;
    await prefs.setInt(countKey, prev + 1);
  }

  /// Devuelve true si el usuario ya tiene una jornada registrada para este
  /// turno hoy, independientemente del dispositivo o si hizo logout.
  /// Consulta primero SharedPreferences (persiste entre sesiones) y luego
  /// la BD local como respaldo.
  Future<bool> tieneJornadaParaUsuarioYTurno(
      int usuarioId, String turno) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    // 1. Si el flag persistente está activo, verificar que haya jornada
    //    realmente ACTIVA (sin fin) en la BD. Si la jornada ya fue cerrada,
    //    el flag es un residuo y se limpia para permitir un nuevo inicio.
    if (prefs.getBool(_jornadaKey(usuarioId, turno)) == true) {
      final rowsActivas = await _db.customSelect(
        '''SELECT id FROM status_jornada_local
           WHERE usuario_id = ?
             AND turno = ?
             AND jornada_inicio_at >= ?
             AND jornada_inicio_at <= ?
             AND (jornada_fin_at IS NULL OR jornada_fin_at = 0)
           LIMIT 1''',
        variables: [
          Variable.withInt(usuarioId),
          Variable.withString(turno),
          Variable.withInt(startOfDay),
          Variable.withInt(endOfDay),
        ],
      ).get();
      if (rowsActivas.isNotEmpty) return true;
      // Jornada cerrada o limpiada: purgar flag obsoleto
      await prefs.remove(_jornadaKey(usuarioId, turno));
    }

    // 2. Verificar tabla local como respaldo (solo jornadas aún abiertas)
    final rows = await _db.customSelect(
      '''SELECT id FROM status_jornada_local
         WHERE usuario_id = ?
           AND turno = ?
           AND jornada_inicio_at >= ?
           AND jornada_inicio_at <= ?
           AND (jornada_fin_at IS NULL OR jornada_fin_at = 0)
         LIMIT 1''',
      variables: [
        Variable.withInt(usuarioId),
        Variable.withString(turno),
        Variable.withInt(startOfDay),
        Variable.withInt(endOfDay),
      ],
    ).get();

    if (rows.isNotEmpty) {
      await prefs.setBool(_jornadaKey(usuarioId, turno), true);
      return true;
    }
    return false;
  }

  /// Devuelve la cantidad de jornadas (iniciadas) para el usuario en el día actual.
  /// Usa el contador de SharedPreferences como fuente principal porque SQLite
  /// se limpia al cerrar la jornada (limpiarDatosJornada) y el count caería a 0.
  Future<int> contarJornadasHoy(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
    final countKey = 'jornadas_iniciadas_${usuarioId}_$hoy';
    final spCount = prefs.getInt(countKey) ?? 0;
    if (spCount > 0) return spCount;

    // Fallback a SQLite (instalaciones sin contador SP aún, o primer arranque)
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await _db.customSelect(
      '''SELECT COUNT(id) as c FROM status_jornada_local
         WHERE usuario_id = ?
           AND jornada_inicio_at >= ?
           AND jornada_inicio_at <= ?''',
      variables: [
        Variable.withInt(usuarioId),
        Variable.withInt(startOfDay),
        Variable.withInt(endOfDay),
      ],
    ).get();
    return rows.isEmpty ? 0 : rows.first.read<int>('c');
  }
}
