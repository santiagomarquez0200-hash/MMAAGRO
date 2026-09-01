import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/outbox_table.dart';

part 'outbox_dao.g.dart';

/// Sin límite de reintentos — el outbox reintenta indefinidamente hasta
/// que el servidor confirme. Solo SpValidationException (bug de código)
/// marca permanently_failed. Los errores de red/server se reintentan siempre.

@DriftAccessor(tables: [OutboxEntries])
class OutboxDao extends DatabaseAccessor<AppDatabase>
    with _$OutboxDaoMixin {
  OutboxDao(super.db);

  // ─── Insertar ────────────────────────────────────────────────────────────

  Future<int> insertEntry(OutboxEntriesCompanion entry) =>
      into(outboxEntries).insert(entry);

  // ─── Lectura — stream en tiempo real (todas las activas, excepto done) ──

  /// Emite cada vez que cualquier entrada no-done cambia de estado.
  /// Úsalo en el diálogo de sync para que la UI refleje cambios en tiempo real
  /// (sync manual, sync automático por conectividad, retries, etc.).
  Stream<List<OutboxEntry>> watchAllActive() {
    return (select(outboxEntries)
          ..where((t) => t.status.isNotIn(['done']))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  // ─── Lectura — pendientes (reintentos disponibles) ───────────────────────

  Stream<List<OutboxEntry>> watchPending() {
    return (select(outboxEntries)
          ..where((t) => t.status.isIn(['pending', 'failed']))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  Future<List<OutboxEntry>> getPendingEntries() {
    return (select(outboxEntries)
          ..where((t) => t.status.isIn(['pending', 'failed']))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<int> countPending() async {
    final count = outboxEntries.id.count();
    final query = selectOnly(outboxEntries)
      ..addColumns([count])
      ..where(outboxEntries.status.isIn(['pending', 'failed']));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchCountPending() {
    final count = outboxEntries.id.count();
    final query = selectOnly(outboxEntries)
      ..addColumns([count])
      ..where(outboxEntries.status.isIn(['pending', 'failed']));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  // ─── Lectura — fallidas permanentes ─────────────────────────────────────

  Future<List<OutboxEntry>> getPermFailed() {
    return (select(outboxEntries)
          ..where((t) => t.status.equals('permanently_failed'))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<int> countPermFailed() async {
    final count = outboxEntries.id.count();
    final query = selectOnly(outboxEntries)
      ..addColumns([count])
      ..where(outboxEntries.status.equals('permanently_failed'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchCountPermFailed() {
    final count = outboxEntries.id.count();
    final query = selectOnly(outboxEntries)
      ..addColumns([count])
      ..where(outboxEntries.status.equals('permanently_failed'));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  // ─── Actualizaciones de estado ───────────────────────────────────────────

  Future<void> markSyncing(int id) async {
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      const OutboxEntriesCompanion(status: Value('syncing')),
    );
  }

  Future<void> markDone(int id) async {
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      const OutboxEntriesCompanion(status: Value('done')),
    );
  }

  Future<void> markFailed(int id, String error, int retryCount) async {
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      OutboxEntriesCompanion(
        status: const Value('failed'),
        errorMessage: Value(error),
        retryCount: Value(retryCount),
      ),
    );
  }

  /// Marca la entrada como fallo permanente cuando supera [_kMaxRetries].
  Future<void> markPermFailed(int id, String error, int retryCount) async {
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      OutboxEntriesCompanion(
        status: const Value('permanently_failed'),
        errorMessage: Value(error),
        retryCount: Value(retryCount),
      ),
    );
  }

  /// Restablece una entrada permanentemente fallida para que pueda reintentarse.
  Future<void> resetForRetry(int id) async {
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      const OutboxEntriesCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        errorMessage: Value(null),
      ),
    );
  }

  /// Elimina todas las entradas permanentemente fallidas.
  Future<void> clearPermFailed() async {
    await (delete(outboxEntries)
          ..where((t) => t.status.equals('permanently_failed')))
        .go();
  }

  // ─── Cascada GUID ────────────────────────────────────────────────────────

  /// Actualiza registroLocalId Y el endpoint cuando el servidor asigna un GUID distinto.
  /// Usa REPLACE en SQL para actualizar el GUID dentro de URLs como /registros/OLD/cerrar.
  Future<void> updateRegistroLocalId(String oldId, String newId) async {
    await customStatement(
      'UPDATE outbox_entries'
      ' SET registro_local_id = ?1,'
      '     endpoint = REPLACE(endpoint, ?2, ?3)'
      ' WHERE registro_local_id = ?2',
      [newId, oldId, newId],
    );
  }

  // ─── Eliminar ────────────────────────────────────────────────────────────

  Future<void> deleteEntry(int id) async {
    await (delete(outboxEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Marca como 'done' todas las entradas pendientes/fallidas de un registro.
  /// Úsalo antes de insertar una nueva entrada completa para ese registro,
  /// evitando que entradas viejas fallidas bloqueen el marcado de sincronizado.
  Future<void> markAllDoneForRegistro(String registroId) async {
    await (update(outboxEntries)
          ..where((t) => t.registroLocalId.equals(registroId))
          ..where((t) => t.status.isIn(['pending', 'failed'])))
        .write(const OutboxEntriesCompanion(status: Value('done')));
  }

  /// Restablece a 'failed' las entradas que quedaron en estado 'syncing' (en vuelo)
  /// porque la app fue cerrada o crasheó a mitad de un ciclo de sync.
  /// Se llama en beforeOpen para limpiar el estado al arrancar.
  Future<void> resetStuckSyncing() async {
    await customStatement(
      "UPDATE outbox_entries SET status = 'failed' WHERE status = 'syncing'",
    );
  }
}
