import 'package:drift/drift.dart';

// ─── Portero Lecturas (MMA v3) ────────────────────────────────────────────────

/// Lecturas de control de ingreso por el portero.
/// Se sincronizan vía Outbox → SP_MMA_REGISTRAR_LECTURA_PORTERO.
class PorteroLecturasLocal extends Table {
  TextColumn get id => text()();
  IntColumn get porteroIdErp => integer()();
  IntColumn get tractorIdErp => integer().nullable()();
  TextColumn get tractorCodigo => text().nullable()();
  DateTimeColumn get tractorLeidoAt => dateTime().nullable()();
  IntColumn get implementoIdErp => integer().nullable()();
  TextColumn get implementoCodigo => text().nullable()();
  DateTimeColumn get implementoLeidoAt => dateTime().nullable()();
  IntColumn get trabajadorIdErp => integer().nullable()();
  TextColumn get trabajadorCodigo => text().nullable()();
  DateTimeColumn get operadorLeidoAt => dateTime().nullable()();
  IntColumn get cultivoIdErp => integer().nullable()();
  TextColumn get cultivoNombre => text().nullable()();
  TextColumn get comentario => text().nullable()();
  TextColumn get dispositivoId => text().nullable()();
  BoolColumn get sincronizado =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
