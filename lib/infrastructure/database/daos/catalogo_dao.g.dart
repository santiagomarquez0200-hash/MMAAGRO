// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalogo_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogoDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProcesosLocalTable get procesosLocal => attachedDatabase.procesosLocal;
  $CultivosLocalTable get cultivosLocal => attachedDatabase.cultivosLocal;
  $TractoresLocalTable get tractoresLocal => attachedDatabase.tractoresLocal;
  $ImplementosLocalTable get implementosLocal =>
      attachedDatabase.implementosLocal;
  $SectoresLocalTable get sectoresLocal => attachedDatabase.sectoresLocal;
  $LotesLocalTable get lotesLocal => attachedDatabase.lotesLocal;
  $CajasCambiosLocalTable get cajasCambiosLocal =>
      attachedDatabase.cajasCambiosLocal;
  $TiposParoLocalTable get tiposParoLocal => attachedDatabase.tiposParoLocal;
  $ChecklistCategoriasLocalTable get checklistCategoriasLocal =>
      attachedDatabase.checklistCategoriasLocal;
  $ChecklistItemsLocalTable get checklistItemsLocal =>
      attachedDatabase.checklistItemsLocal;
  $TrabajadoresLocalTable get trabajadoresLocal =>
      attachedDatabase.trabajadoresLocal;
  $SubprocesosLocalTable get subprocesosLocal =>
      attachedDatabase.subprocesosLocal;
  CatalogoDaoManager get managers => CatalogoDaoManager(this);
}

class CatalogoDaoManager {
  final _$CatalogoDaoMixin _db;
  CatalogoDaoManager(this._db);
  $$ProcesosLocalTableTableManager get procesosLocal =>
      $$ProcesosLocalTableTableManager(_db.attachedDatabase, _db.procesosLocal);
  $$CultivosLocalTableTableManager get cultivosLocal =>
      $$CultivosLocalTableTableManager(_db.attachedDatabase, _db.cultivosLocal);
  $$TractoresLocalTableTableManager get tractoresLocal =>
      $$TractoresLocalTableTableManager(
          _db.attachedDatabase, _db.tractoresLocal);
  $$ImplementosLocalTableTableManager get implementosLocal =>
      $$ImplementosLocalTableTableManager(
          _db.attachedDatabase, _db.implementosLocal);
  $$SectoresLocalTableTableManager get sectoresLocal =>
      $$SectoresLocalTableTableManager(_db.attachedDatabase, _db.sectoresLocal);
  $$LotesLocalTableTableManager get lotesLocal =>
      $$LotesLocalTableTableManager(_db.attachedDatabase, _db.lotesLocal);
  $$CajasCambiosLocalTableTableManager get cajasCambiosLocal =>
      $$CajasCambiosLocalTableTableManager(
          _db.attachedDatabase, _db.cajasCambiosLocal);
  $$TiposParoLocalTableTableManager get tiposParoLocal =>
      $$TiposParoLocalTableTableManager(
          _db.attachedDatabase, _db.tiposParoLocal);
  $$ChecklistCategoriasLocalTableTableManager get checklistCategoriasLocal =>
      $$ChecklistCategoriasLocalTableTableManager(
          _db.attachedDatabase, _db.checklistCategoriasLocal);
  $$ChecklistItemsLocalTableTableManager get checklistItemsLocal =>
      $$ChecklistItemsLocalTableTableManager(
          _db.attachedDatabase, _db.checklistItemsLocal);
  $$TrabajadoresLocalTableTableManager get trabajadoresLocal =>
      $$TrabajadoresLocalTableTableManager(
          _db.attachedDatabase, _db.trabajadoresLocal);
  $$SubprocesosLocalTableTableManager get subprocesosLocal =>
      $$SubprocesosLocalTableTableManager(
          _db.attachedDatabase, _db.subprocesosLocal);
}
