import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/catalogos_tables.dart';

part 'catalogo_dao.g.dart';

@DriftAccessor(tables: [
  ProcesosLocal,
  CultivosLocal,
  TractoresLocal,
  ImplementosLocal,
  SectoresLocal,
  LotesLocal,
  CajasCambiosLocal,
  TiposParoLocal,
  ChecklistCategoriasLocal,
  ChecklistItemsLocal,
  TrabajadoresLocal,
  SubprocesosLocal,
])
class CatalogoDao extends DatabaseAccessor<AppDatabase>
    with _$CatalogoDaoMixin {
  CatalogoDao(super.db);

  // ─── Procesos (PostgreSQL) ───────────────────────────────────────────────

  Future<List<ProcesosLocalData>> getProcesos() =>
      (select(procesosLocal)..where((t) => t.activo.equals(true))).get();

  Future<void> deleteAllProcesos() => delete(procesosLocal).go();

  Future<void> upsertProcesos(List<ProcesosLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(procesosLocal, rows));

  // ─── Cultivos (ERP) ──────────────────────────────────────────────────────

  Future<List<CultivosLocalData>> getCultivos() =>
      (select(cultivosLocal)..where((t) => t.activo.equals(true))).get();

  Future<void> upsertCultivos(List<CultivosLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(cultivosLocal, rows));

  // ─── Tractores (ERP) ─────────────────────────────────────────────────────

  Future<List<TractoresLocalData>> getTractores() =>
      (select(tractoresLocal)..where((t) => t.activo.equals(true))).get();

  Future<void> upsertTractores(List<TractoresLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(tractoresLocal, rows));

  // ─── Implementos (ERP) ───────────────────────────────────────────────────

  Future<List<ImplementosLocalData>> getImplementos() =>
      (select(implementosLocal)..where((t) => t.activo.equals(true))).get();

  Future<void> upsertImplementos(List<ImplementosLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(implementosLocal, rows));

  // ─── Sectores (derivados de fincas ERP) ──────────────────────────────────

  Future<List<SectoresLocalData>> getSectores() =>
      (select(sectoresLocal)..where((t) => t.activo.equals(true))).get();

  Future<void> upsertSectores(List<SectoresLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(sectoresLocal, rows));

  // ─── Lotes (ERP) ─────────────────────────────────────────────────────────

  Future<List<LotesLocalData>> getLotes({int? fincaIdErp}) {
    final query = select(lotesLocal)
      ..where((t) => t.activo.equals(true));
    if (fincaIdErp != null) {
      query.where((t) => t.fincaIdErp.equals(fincaIdErp));
    }
    return query.get();
  }

  Future<void> upsertLotes(List<LotesLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(lotesLocal, rows));

  // ─── Cajas de cambios (PostgreSQL) ───────────────────────────────────────

  Future<List<CajasCambiosLocalData>> getCajasCambios() =>
      select(cajasCambiosLocal).get();

  Future<void> upsertCajasCambios(List<CajasCambiosLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(cajasCambiosLocal, rows));

  // ─── Tipos de paro (PostgreSQL) ──────────────────────────────────────────

  Future<List<TiposParoLocalData>> getTiposParo() =>
      (select(tiposParoLocal)..where((t) => t.activo.equals(true))).get();

  Future<void> upsertTiposParo(List<TiposParoLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(tiposParoLocal, rows));

  // ─── Checklist items (PostgreSQL) ────────────────────────────────────────

  Future<List<ChecklistItemsLocalData>> getChecklistItems() =>
      (select(checklistItemsLocal)
            ..where((t) => t.activo.equals(true))
            ..orderBy([
              (t) => OrderingTerm.asc(t.categoriaId),
              (t) => OrderingTerm.asc(t.orden),
            ]))
          .get();

  Future<void> deleteAllChecklistItems() => delete(checklistItemsLocal).go();

  Future<void> upsertChecklistItems(
          List<ChecklistItemsLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(checklistItemsLocal, rows));

  // ─── Trabajadores (ERP) ──────────────────────────────────────────────────

  Future<List<TrabajadoresLocalData>> getTrabajadores() =>
      (select(trabajadoresLocal)..where((t) => t.activo.equals(true)))
          .get();

  /// Busca por CodigoUsuario (codTrabajador). Si no encuentra, intenta con el
  /// código físico/barcode (codigoBarra) como fallback. Esto cubre el caso en
  /// que un usuario teclea su barcode ("468834") en vez de su código de login
  /// ("PCORZO") en la pantalla de PIN.
  Future<TrabajadoresLocalData?> getTrabajadorByCodigo(String codigo) async {
    final byLogin = await (select(trabajadoresLocal)
          ..where((t) => t.codTrabajador.equals(codigo)))
        .getSingleOrNull();
    if (byLogin != null) return byLogin;
    // Fallback: busca por barcode físico (puede ser null — la columna es nullable)
    return (select(trabajadoresLocal)
          ..where((t) => t.codigoBarra.equals(codigo)))
        .getSingleOrNull();
  }

  Future<TrabajadoresLocalData?> getTrabajadorByIdErp(int idErp) =>
      (select(trabajadoresLocal)..where((t) => t.idErp.equals(idErp)))
          .getSingleOrNull();

  Future<void> upsertTrabajadores(
          List<TrabajadoresLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(trabajadoresLocal, rows));

  /// Guarda solo el hash del PIN para un trabajador existente.
  Future<void> savePinHash(int idErp, String pinHash) =>
      (update(trabajadoresLocal)..where((t) => t.idErp.equals(idErp)))
          .write(TrabajadoresLocalCompanion(pinHash: Value(pinHash)));

  // ─── Búsqueda por código escaneado (QR / barras) ─────────────────────────
  // SQLite LIKE sin comodines = comparación case-insensitive para ASCII.

  /// Busca un trabajador por barcode físico escaneado (codigoBarra).
  /// Si no hay coincidencia (ej. primera sync sin codigoBarra), cae a codTrabajador.
  Future<TrabajadoresLocalData?> getTrabajadorByCodigoScanner(
      String codigo) async {
    final trimmed = codigo.trim();
    final byBarra = await (select(trabajadoresLocal)
          ..where((t) => t.codigoBarra.like(trimmed)))
        .getSingleOrNull();
    if (byBarra != null) return byBarra;
    return (select(trabajadoresLocal)
          ..where((t) => t.codTrabajador.like(trimmed)))
        .getSingleOrNull();
  }

  /// Busca un tractor por [codigo] (codigo_tractor) ignorando mayúsculas.
  Future<TractoresLocalData?> getTractorByCodigoScanner(String codigo) =>
      (select(tractoresLocal)
            ..where((t) => t.codigoTractor.like(codigo.trim())))
          .getSingleOrNull();

  /// Busca un implemento por [codigo] (codigo_implemento) ignorando mayúsculas.
  Future<ImplementosLocalData?> getImplementoByCodigoScanner(String codigo) =>
      (select(implementosLocal)
            ..where((t) => t.codigoImplemento.like(codigo.trim())))
          .getSingleOrNull();

  // ─── Subprocesos (MMA v3) ─────────────────────────────────────────────────

  Future<List<SubprocesosLocalData>> getSubprocesos({int? procesoId}) {
    final query = select(subprocesosLocal)
      ..where((t) => t.activo.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.nombre)]);
    if (procesoId != null) {
      query.where((t) => t.procesoId.equals(procesoId));
    }
    return query.get();
  }

  Future<void> upsertSubprocesos(List<SubprocesosLocalCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(subprocesosLocal, rows));
}
