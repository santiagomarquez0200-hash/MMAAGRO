// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registro_dao.dart';

// ignore_for_file: type=lint
mixin _$RegistroDaoMixin on DatabaseAccessor<AppDatabase> {
  $RegistrosDiariosLocalTable get registrosDiariosLocal =>
      attachedDatabase.registrosDiariosLocal;
  $HorometrosLocalTable get horometrosLocal => attachedDatabase.horometrosLocal;
  $TiemposTurnoLocalTable get tiemposTurnoLocal =>
      attachedDatabase.tiemposTurnoLocal;
  $RegistrosSectoresLocalTable get registrosSectoresLocal =>
      attachedDatabase.registrosSectoresLocal;
  $CosechaBinesLocalTable get cosechaBinesLocal =>
      attachedDatabase.cosechaBinesLocal;
  $ParosEquiposLocalTable get parosEquiposLocal =>
      attachedDatabase.parosEquiposLocal;
  $ChecklistResultadosLocalTable get checklistResultadosLocal =>
      attachedDatabase.checklistResultadosLocal;
  RegistroDaoManager get managers => RegistroDaoManager(this);
}

class RegistroDaoManager {
  final _$RegistroDaoMixin _db;
  RegistroDaoManager(this._db);
  $$RegistrosDiariosLocalTableTableManager get registrosDiariosLocal =>
      $$RegistrosDiariosLocalTableTableManager(
          _db.attachedDatabase, _db.registrosDiariosLocal);
  $$HorometrosLocalTableTableManager get horometrosLocal =>
      $$HorometrosLocalTableTableManager(
          _db.attachedDatabase, _db.horometrosLocal);
  $$TiemposTurnoLocalTableTableManager get tiemposTurnoLocal =>
      $$TiemposTurnoLocalTableTableManager(
          _db.attachedDatabase, _db.tiemposTurnoLocal);
  $$RegistrosSectoresLocalTableTableManager get registrosSectoresLocal =>
      $$RegistrosSectoresLocalTableTableManager(
          _db.attachedDatabase, _db.registrosSectoresLocal);
  $$CosechaBinesLocalTableTableManager get cosechaBinesLocal =>
      $$CosechaBinesLocalTableTableManager(
          _db.attachedDatabase, _db.cosechaBinesLocal);
  $$ParosEquiposLocalTableTableManager get parosEquiposLocal =>
      $$ParosEquiposLocalTableTableManager(
          _db.attachedDatabase, _db.parosEquiposLocal);
  $$ChecklistResultadosLocalTableTableManager get checklistResultadosLocal =>
      $$ChecklistResultadosLocalTableTableManager(
          _db.attachedDatabase, _db.checklistResultadosLocal);
}
