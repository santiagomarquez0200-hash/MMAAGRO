import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';

/// Limpia todos los datos operativos locales (Drift + outbox) al inicio de
/// cada día agrícola.
///
/// El día agrícola comienza a las **04:00 h** (antes del turno día 06:00).
/// Si la hora actual es < 04:00, el límite se trata como el día anterior para
/// no limpiar datos de operadores del turno noche (14:00–22:00) que aún no
/// cerraron su jornada.
///
/// La clave [_kResetKey] persiste la última fecha agrícola reseteada. Si
/// difiere de la fecha actual, se ejecuta el reset y se actualiza la clave.
class DailyResetService {
  final AppDatabase _db;

  static const String _kResetKey = 'daily_reset_date_v1';

  DailyResetService({required AppDatabase db}) : _db = db;

  // ─── Fecha agrícola ───────────────────────────────────────────────────────

  /// Devuelve 'YYYY-MM-DD' del día agrícola en curso.
  /// Antes de las 04:00 se retrocede un día para no cortar la jornada noche.
  static String get _agricultureDateKey {
    final now = DateTime.now();
    final agDay = now.hour < 4 ? now.subtract(const Duration(days: 1)) : now;
    return '${agDay.year}-'
        '${agDay.month.toString().padLeft(2, '0')}-'
        '${agDay.day.toString().padLeft(2, '0')}';
  }

  // ─── API pública ──────────────────────────────────────────────────────────

  Future<bool> needsReset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kResetKey) != _agricultureDateKey;
  }

  /// Ejecuta el reset solo si no se realizó aún para el día agrícola actual.
  /// Silencioso: nunca lanza excepción al caller.
  Future<void> runIfNeeded() async {
    try {
      if (!await needsReset()) return;
      await _performReset();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kResetKey, _agricultureDateKey);
      await prefs.remove('jornada_activa_id');
    } catch (e, st) {
      // No interrumpir el arranque de la app si falla el reset,
      // pero sí registrar el error para que sea detectable en logs.
      developer.log('DailyReset falló', name: 'DailyReset', error: e, stackTrace: st);
    }
  }

  // ─── Reset interno ────────────────────────────────────────────────────────

  Future<void> _performReset() async {
    // ── Ventana de 7 días ────────────────────────────────────────────────────
    // Solo se eliminan registros YA SINCRONIZADOS con más de 7 días de antigüedad.
    // Los registros NO sincronizados nunca se borran aquí: podrían reintentarse.
    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    // Tablas hijas que referencian registros_diarios_local.id via registro_id
    const childTables = [
      'checklist_resultados_local',
      'paros_equipos_local',
      'cosecha_bines_local',
      'tiempos_turno_local',
      'horometros_local',
      'registros_sectores_local',
      'combustible_vehiculo_local',
      'sub_labores_local',
      'marchas_local',
    ];

    // 1. Eliminar hijos de registros antiguos sincronizados
    for (final table in childTables) {
      await _db.customUpdate(
        'DELETE FROM $table WHERE registro_id IN '
        '(SELECT id FROM registros_diarios_local '
        ' WHERE sincronizado = 1 AND fecha < ?)',
        variables: [Variable.withDateTime(cutoff)],
      );
    }

    // 2. Eliminar datos de vehículo asociados al mismo conjunto
    await _db.customUpdate(
      'DELETE FROM registros_vehiculo_local WHERE registro_id IN '
      '(SELECT id FROM registros_diarios_local '
      ' WHERE sincronizado = 1 AND fecha < ?)',
      variables: [Variable.withDateTime(cutoff)],
    );

    // 3. Eliminar los registros diarios sincronizados fuera de la ventana
    await _db.customUpdate(
      'DELETE FROM registros_diarios_local WHERE sincronizado = 1 AND fecha < ?',
      variables: [Variable.withDateTime(cutoff)],
    );

    // ── Efímeros: siempre limpiar ────────────────────────────────────────────
    await _db.customUpdate('DELETE FROM portero_lecturas_local', variables: []);
    await _db.customUpdate('DELETE FROM status_jornada_local', variables: []);

    // Outbox: completadas y fallidas permanentes. Pendientes se conservan.
    await _db.customUpdate(
      "DELETE FROM outbox_entries WHERE status IN ('done', 'permanently_failed')",
      variables: [],
    );

    // status_jornada_pendiente: NO se elimina en el reset diario.
    // processPending() borra cada entrada al confirmarla en el servidor.
    // Las entradas supervivientes son jornadas sin confirmar → persisten
    // indefinidamente hasta que el servidor las acepte (reintentos infinitos).
  }
}
