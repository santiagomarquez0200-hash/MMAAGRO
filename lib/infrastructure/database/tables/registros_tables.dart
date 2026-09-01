import 'package:drift/drift.dart';

// ─── Tabla central ─────────────────────────────────────────────────────────────

class RegistrosDiariosLocal extends Table {
  /// UUID local generado en el dispositivo.
  TextColumn get id => text()();
  TextColumn get numeroRegistro =>
      text().withDefault(const Constant(''))();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get turno => text().withDefault(const Constant('dia'))();

  // ── Proceso (PostgreSQL) ──
  IntColumn get procesoId => integer()();
  TextColumn get procesoNombre =>
      text().withDefault(const Constant(''))();
  TextColumn get procesoCodigo =>
      text().withDefault(const Constant(''))();

  // ── Cultivo (ERP) — snapshot ──
  IntColumn get cultivoIdErp => integer()();
  TextColumn get cultivoNombreEspecie =>
      text().withDefault(const Constant(''))();
  TextColumn get cultivoCodigoEspecie =>
      text().withDefault(const Constant(''))();

  // ── Operador (ERP) — snapshot ──
  IntColumn get operadorIdErp => integer()();
  TextColumn get operadorCodigo =>
      text().withDefault(const Constant(''))();
  TextColumn get operadorNombre =>
      text().withDefault(const Constant(''))();

  // ── Supervisor (ERP) — snapshot, opcional ──
  IntColumn get supervisorIdErp => integer().nullable()();
  TextColumn get supervisorCodigo => text().nullable()();
  TextColumn get supervisorNombre => text().nullable()();

  // ── Tractor (ERP) — snapshot ──
  IntColumn get tractorIdErp => integer()();
  TextColumn get tractorCodigo =>
      text().withDefault(const Constant(''))();
  TextColumn get tractorDescripcion =>
      text().withDefault(const Constant(''))();

  // ── Implemento (ERP) — snapshot, opcional ──
  IntColumn get implementoIdErp => integer().nullable()();
  TextColumn get implementoCodigo => text().nullable()();
  TextColumn get implementoDescripcion => text().nullable()();

  // ── Caja de cambios (PostgreSQL) ──
  IntColumn get cajaCambiosId => integer().nullable()();
  TextColumn get cajaCambiosNombre => text().nullable()();

  // ── Subproceso (MMA v3) ──
  IntColumn get subprocesoId => integer().nullable()();
  TextColumn get subprocesoNombre => text().nullable()();

  // ── Jornada timestamps (MMA v3) ──
  DateTimeColumn get jornadaInicioAt => dateTime().nullable()();
  DateTimeColumn get jornadaFinAt => dateTime().nullable()();

  // ── Tipo de registro (MMA v3): 'tractor' | 'vehiculo' ──
  TextColumn get tipoRegistro =>
      text().withDefault(const Constant('tractor'))();

  // ── Estado y metadatos ──
  TextColumn get estado =>
      text().withDefault(const Constant('borrador'))();
  TextColumn get observacionesMaq => text().nullable()();
  TextColumn get motivoRechazo => text().nullable()();
  TextColumn get firmaOperador => text().nullable()();
  TextColumn get dispositivoId => text().nullable()();

  // ── Sync ──
  BoolColumn get sincronizado =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get sincronizadoAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Horómetros ───────────────────────────────────────────────────────────────

class HorometrosLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();
  RealColumn get tractorInicio => real().nullable()();
  RealColumn get tractorFinal => real().nullable()();
  RealColumn get implementoInicio => real().nullable()();
  RealColumn get implementoFinal => real().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Tiempos de turno ─────────────────────────────────────────────────────────

class TiemposTurnoLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();
  TextColumn get horaSalidaTaller => text().nullable()();
  TextColumn get horaLlegadaPunto => text().nullable()();
  TextColumn get horaSalidaPunto => text().nullable()();
  TextColumn get horaLlegadaTaller => text().nullable()();
  TextColumn get horaRefrigerio => text().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Sectores trabajados ──────────────────────────────────────────────────────

class RegistrosSectoresLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();

  // Snapshot del lote ERP
  IntColumn get loteIdErp => integer()();
  TextColumn get loteCodigo =>
      text().withDefault(const Constant(''))();
  TextColumn get loteNombre =>
      text().withDefault(const Constant(''))();
  TextColumn get fincaNombre =>
      text().withDefault(const Constant(''))();

  RealColumn get areaTrabajada => real().nullable()();
  TextColumn get observacion => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Cosecha bines ────────────────────────────────────────────────────────────

class CosechaBinesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();
  TextColumn get franjaHoraria => text()();
  TextColumn get turno => text()();
  IntColumn get cantidad =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Paros de equipos ─────────────────────────────────────────────────────────

class ParosEquiposLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();

  // Snapshot del tipo de paro
  IntColumn get tipoParoId => integer()();
  TextColumn get tipoParoCodigo =>
      text().withDefault(const Constant(''))();
  TextColumn get tipoParoNombre =>
      text().withDefault(const Constant(''))();

  TextColumn get motivo => text().nullable()();
  TextColumn get equipo => text().nullable()();
  TextColumn get horaInicio => text()();
  TextColumn get horaFinal => text().nullable()();
  RealColumn get galones => real().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Checklist resultados ─────────────────────────────────────────────────────

class ChecklistResultadosLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();
  IntColumn get itemId => integer()();
  TextColumn get itemNombre =>
      text().withDefault(const Constant(''))();
  TextColumn get categoriaNombre =>
      text().withDefault(const Constant(''))();

  /// 'bien' | 'mal' | 'na'
  TextColumn get resultado => text()();
  TextColumn get observacion => text().nullable()();
  TextColumn get fotoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Registros de vehículo (MMA-FR-013) ──────────────────────────────────────

class RegistrosVehiculoLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();
  RealColumn get kmCamionInicio => real().nullable()();
  RealColumn get kmCamionFinal => real().nullable()();
  RealColumn get kmImplementoInicio => real().nullable()();
  RealColumn get kmImplementoFinal => real().nullable()();
  TextColumn get horaSalidaBaseTd => text().nullable()();
  TextColumn get horaLlegadaZona => text().nullable()();
  TextColumn get horaRetornoBase => text().nullable()();
  TextColumn get horaLlegadaTaller => text().nullable()();
  TextColumn get horaRefrigerio => text().nullable()();
  IntColumn get cantidadTancadas => integer().nullable()();
  TextColumn get observacionesMaq => text().nullable()();
  BoolColumn get sincronizado =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Combustible vehículo ─────────────────────────────────────────────────────

class CombustibleVehiculoLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();
  RealColumn get glns => real().nullable()();
  TextColumn get horaInicio => text().nullable()();
  TextColumn get horaFinal => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Sub-labores (MMA v8) ─────────────────────────────────────────────────────

class SubLaboresLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();

  /// Nombre de la sub-labor: 'Aplicación de cianamida' | 'Aplicación de chanchito' | 'Aplicación Sanitaria'
  TextColumn get sublaborNombre => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Marchas de trabajo (MMA v8) ──────────────────────────────────────────────

class MarchasLocal extends Table {
  TextColumn get id => text()();
  TextColumn get registroId => text()();

  /// Código de marcha: T-1..T-4, H-1..H-4, L-1..L-4
  TextColumn get marchaCodigo => text()();
  RealColumn get horasUso => real().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Incumplimientos de jornada (MMA v8) ─────────────────────────────────────

class IncumplimientosLocal extends Table {
  TextColumn get id => text()();
  IntColumn get usuarioErpId => integer()();
  TextColumn get nombreUsuario => text().withDefault(const Constant(''))();
  DateTimeColumn get fechaJornada => dateTime()();

  /// 'dia' | 'noche'
  TextColumn get turno => text().withDefault(const Constant('dia'))();

  /// 'cierre_sin_sincronizar' | 'jornada_100_pct' | 'retraso_excesivo'
  TextColumn get tipoIncumplimiento => text()();
  TextColumn get detalle => text().nullable()();
  TextColumn get dispositivoId => text().nullable()();
  TextColumn get firestoreDocId => text().nullable()();
  BoolColumn get sincronizado =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
