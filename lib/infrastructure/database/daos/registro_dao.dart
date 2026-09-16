import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/registros_tables.dart';

part 'registro_dao.g.dart';

@DriftAccessor(tables: [
  RegistrosDiariosLocal,
  HorometrosLocal,
  TiemposTurnoLocal,
  RegistrosSectoresLocal,
  CosechaBinesLocal,
  ParosEquiposLocal,
  ChecklistResultadosLocal,
])
class RegistroDao extends DatabaseAccessor<AppDatabase>
    with _$RegistroDaoMixin {
  RegistroDao(super.db);

  // ─── Registros diarios ───────────────────────────────────────────────────

  Future<void> insertRegistro(RegistrosDiariosLocalCompanion row) =>
      into(registrosDiariosLocal).insertOnConflictUpdate(row);

  Future<void> updateRegistro(RegistrosDiariosLocalCompanion row) =>
      (update(registrosDiariosLocal)..where((t) => t.id.equals(row.id.value)))
          .write(row);

  /// Actualiza el GUID de un registro en TODAS las tablas relacionadas
  /// dentro de una sola transacción SQLite para garantizar atomicidad.
  /// El Outbox también se actualiza — llama desde _db.transaction() en el repo.
  Future<void> updateRegistroIdCascade(String oldId, String newId) =>
      transaction(() async {
        await (update(registrosDiariosLocal)
              ..where((t) => t.id.equals(oldId)))
            .write(RegistrosDiariosLocalCompanion(id: Value(newId)));

        await (update(horometrosLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(HorometrosLocalCompanion(registroId: Value(newId)));

        await (update(tiemposTurnoLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(TiemposTurnoLocalCompanion(registroId: Value(newId)));

        await (update(registrosSectoresLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(RegistrosSectoresLocalCompanion(registroId: Value(newId)));

        await (update(cosechaBinesLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(CosechaBinesLocalCompanion(registroId: Value(newId)));

        await (update(parosEquiposLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(ParosEquiposLocalCompanion(registroId: Value(newId)));

        await (update(checklistResultadosLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(ChecklistResultadosLocalCompanion(registroId: Value(newId)));

        // Tablas MMA v3 — via attachedDatabase (no listadas en @DriftAccessor)
        await (update(attachedDatabase.subLaboresLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(SubLaboresLocalCompanion(registroId: Value(newId)));

        await (update(attachedDatabase.marchasLocal)
              ..where((t) => t.registroId.equals(oldId)))
            .write(MarchasLocalCompanion(registroId: Value(newId)));
      });

  Future<RegistrosDiariosLocalData?> getRegistroById(String id) =>
      (select(registrosDiariosLocal)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<List<RegistrosDiariosLocalData>> watchAllRegistros({
    int? operadorIdErp,
    DateTime? fechaDesde,
  }) {
    final query = select(registrosDiariosLocal)
      ..orderBy([(t) => OrderingTerm.desc(t.fecha)]);
    if (operadorIdErp != null) {
      query.where((t) => t.operadorIdErp.equals(operadorIdErp));
    }
    if (fechaDesde != null) {
      query.where((t) => t.fecha.isBiggerOrEqualValue(fechaDesde));
    }
    return query.watch();
  }

  /// Stream que re-emite cuando cambia la tabla de checklist.
  /// Úsalo para hacer reactivo el watch principal ante guardados de checklist.
  Stream<void> watchChecklistChanges() =>
      select(checklistResultadosLocal).watch().map((_) {});

  /// Stream que re-emite cuando cambia la tabla de paros.
  /// Úsalo para hacer reactivo el watch principal ante guardados de paros.
  Stream<void> watchParosChanges() =>
      select(parosEquiposLocal).watch().map((_) {});

  Future<List<RegistrosDiariosLocalData>> getRegistros({
    int? operadorIdErp,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
  }) {
    final query = select(registrosDiariosLocal)
      ..orderBy([(t) => OrderingTerm.desc(t.fecha)]);
    if (operadorIdErp != null) {
      query.where((t) => t.operadorIdErp.equals(operadorIdErp));
    }
    if (estado != null) {
      query.where((t) => t.estado.equals(estado));
    }
    if (fechaDesde != null) {
      query.where((t) => t.fecha.isBiggerOrEqualValue(fechaDesde));
    }
    if (fechaHasta != null) {
      query.where((t) => t.fecha.isSmallerOrEqualValue(fechaHasta));
    }
    return query.get();
  }

  Future<void> markSincronizado(String id) =>
      (update(registrosDiariosLocal)..where((t) => t.id.equals(id))).write(
        RegistrosDiariosLocalCompanion(
          sincronizado: const Value(true),
          sincronizadoAt: Value(DateTime.now()),
        ),
      );

  /// Elimina un registro y TODAS sus tablas relacionadas en una sola
  /// transacción atómica.
  ///
  /// **Por qué transaction()**: `watchRegistros` en el repositorio observa
  /// tres streams secundarios (registros, checklist, paros). Sin transacción,
  /// cada `delete().go()` notifica a sus watchers de forma independiente;
  /// el watcher de paros dispara cuando se borran los paros (paso 6/12)
  /// pero el registro principal todavía existe, por lo que `emit()` lee la DB
  /// y re-emite `RegistrosLoaded` CON el registro — haciéndolo reaparecer en
  /// la UI hasta que el siguiente ciclo lo elimina definitivamente.
  /// Con una transacción, Drift agrupa todas las notificaciones y las dispara
  /// UNA SOLA VEZ al commitear, con el estado final correcto (sin registro).
  Future<void> deleteRegistroCascade(String registroId) =>
      transaction(() async {
        // Registros MMA v3 — acceso via attachedDatabase (tablas no listadas en @DriftAccessor)
        await (delete(attachedDatabase.combustibleVehiculoLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(attachedDatabase.registrosVehiculoLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(attachedDatabase.subLaboresLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(attachedDatabase.marchasLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();

        // Registros Comunes
        await (delete(checklistResultadosLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(parosEquiposLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(cosechaBinesLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(registrosSectoresLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(tiemposTurnoLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(horometrosLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        await (delete(registrosDiariosLocal)
              ..where((t) => t.id.equals(registroId)))
            .go();

        // Limpiar entradas huérfanas en outbox para este registro
        await (delete(attachedDatabase.outboxEntries)
              ..where((t) => t.registroLocalId.equals(registroId)))
            .go();

        // Puntos GPS de trazabilidad (tabla con nombre físico del cliente)
        await attachedDatabase.customStatement(
          'DELETE FROM "CLI547_AGM_Ruta_maquinaria" WHERE registro_id = ?',
          [registroId],
        );
      });

  Stream<int> watchCountPendientesSync() {
    final count = registrosDiariosLocal.id.count();
    final query = selectOnly(registrosDiariosLocal)
      ..addColumns([count])
      ..where(registrosDiariosLocal.sincronizado.equals(false));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  // ─── Horómetros ──────────────────────────────────────────────────────────

  Future<void> upsertHorometro(HorometrosLocalCompanion row) =>
      into(horometrosLocal).insertOnConflictUpdate(row);

  Future<HorometrosLocalData?> getHorometroByRegistro(String registroId) =>
      (select(horometrosLocal)..where((t) => t.registroId.equals(registroId)))
          .getSingleOrNull();

  // ─── Tiempos turno ───────────────────────────────────────────────────────

  Future<void> upsertTiempoTurno(TiemposTurnoLocalCompanion row) =>
      into(tiemposTurnoLocal).insertOnConflictUpdate(row);

  Future<TiemposTurnoLocalData?> getTiempoTurnoByRegistro(String registroId) =>
      (select(tiemposTurnoLocal)..where((t) => t.registroId.equals(registroId)))
          .getSingleOrNull();

  // ─── Sectores trabajados ─────────────────────────────────────────────────

  Future<void> upsertSector(RegistrosSectoresLocalCompanion row) =>
      into(registrosSectoresLocal).insertOnConflictUpdate(row);

  Future<List<RegistrosSectoresLocalData>> getSectoresByRegistro(
          String registroId) =>
      (select(registrosSectoresLocal)
            ..where((t) => t.registroId.equals(registroId)))
          .get();

  Future<void> deleteSectoresByRegistro(String registroId) =>
      (delete(registrosSectoresLocal)
            ..where((t) => t.registroId.equals(registroId)))
          .go();

  // ─── Cosecha bines ───────────────────────────────────────────────────────

  Future<void> upsertBin(CosechaBinesLocalCompanion row) =>
      into(cosechaBinesLocal).insertOnConflictUpdate(row);

  Future<List<CosechaBinesLocalData>> getBinesByRegistro(String registroId) =>
      (select(cosechaBinesLocal)
            ..where((t) => t.registroId.equals(registroId))
            ..orderBy([(t) => OrderingTerm.asc(t.franjaHoraria)]))
          .get();

  // ─── Paros equipos ───────────────────────────────────────────────────────

  Future<void> insertParo(ParosEquiposLocalCompanion row) =>
      into(parosEquiposLocal).insert(row);

  Future<List<ParosEquiposLocalData>> getParosByRegistro(String registroId) =>
      (select(parosEquiposLocal)..where((t) => t.registroId.equals(registroId)))
          .get();

  Future<void> deleteParo(String paroId) =>
      (delete(parosEquiposLocal)..where((t) => t.id.equals(paroId))).go();

  // ─── Checklist resultados ────────────────────────────────────────────────

  Future<void> upsertChecklistResultado(
          ChecklistResultadosLocalCompanion row) =>
      into(checklistResultadosLocal).insertOnConflictUpdate(row);

  /// Elimina todos los ítems de checklist de un registro.
  /// Usar antes de reinsertar para garantizar no duplicados por (registroId, itemId).
  Future<void> deleteChecklistByRegistro(String registroId) =>
      (delete(checklistResultadosLocal)
            ..where((t) => t.registroId.equals(registroId)))
          .go();

  Future<List<ChecklistResultadosLocalData>> getChecklistByRegistro(
          String registroId) =>
      (select(checklistResultadosLocal)
            ..where((t) => t.registroId.equals(registroId)))
          .get();

  Future<int> countChecklistPendiente(String registroId, int totalItems) async {
    final count = checklistResultadosLocal.id.count();
    final query = selectOnly(checklistResultadosLocal)
      ..addColumns([count])
      ..where(checklistResultadosLocal.registroId.equals(registroId));
    final row = await query.getSingle();
    final completed = row.read(count) ?? 0;
    return totalItems - completed;
  }
}
