import 'package:drift/drift.dart';

// ─── Catálogos PostgreSQL (backend propio) ────────────────────────────────────

class ProcesosLocal extends Table {
  IntColumn get id => integer()();
  TextColumn get nombre => text()();
  TextColumn get codigo => text()();
  BoolColumn get requiereBines =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  // tipo_registro se maneja via customStatement/customSelect para no requerir
  // regenerar build_runner. La columna sí existe en SQLite (migración v9).

  @override
  Set<Column> get primaryKey => {id};
}

class CajasCambiosLocal extends Table {
  IntColumn get id => integer()();
  TextColumn get nombre => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class TiposParoLocal extends Table {
  IntColumn get id => integer()();
  TextColumn get codigo => text()();
  TextColumn get nombre => text()();
  BoolColumn get requiereGalones =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get requiereEquipo =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistCategoriasLocal extends Table {
  IntColumn get id => integer()();
  TextColumn get nombre => text()();
  IntColumn get orden => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistItemsLocal extends Table {
  IntColumn get id => integer()();
  IntColumn get categoriaId => integer()();
  TextColumn get categoriaNombre => text().withDefault(const Constant(''))();
  TextColumn get nombre => text()();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  TextColumn get tipoRegistro =>
      text().withDefault(const Constant('tractor'))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Catálogos ERP SQL Server ─────────────────────────────────────────────────

/// Cultivos (EspeciesBotanicas ERP).
class CultivosLocal extends Table {
  /// ID entero del ERP SQL Server.
  IntColumn get idErp => integer()();
  TextColumn get codigoEspecie => text()();
  TextColumn get nombreEspecie => text()();
  TextColumn get nombreCultivo => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sincronizadoAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {idErp};
}

/// Tractores (Maquinaria tipo T% ERP).
class TractoresLocal extends Table {
  IntColumn get idErp => integer()();
  TextColumn get codigoTractor => text()();
  TextColumn get descripcion => text()();
  TextColumn get marca => text().nullable()();
  TextColumn get modelo => text().nullable()();
  TextColumn get matricula => text().nullable()();
  TextColumn get codigoInterno => text().nullable()();
  TextColumn get zona => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sincronizadoAt =>
      dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {idErp};
}

/// Implementos (Maquinaria tipo I% ERP).
class ImplementosLocal extends Table {
  IntColumn get idErp => integer()();
  TextColumn get codigoImplemento => text()();
  TextColumn get descripcion => text()();
  TextColumn get marca => text().nullable()();
  TextColumn get modelo => text().nullable()();
  TextColumn get codigoInterno => text().nullable()();
  TextColumn get zona => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sincronizadoAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {idErp};
}

/// Trabajadores (sujetos + Zonas ERP) — reemplaza a UsuariosLocal.
class TrabajadoresLocal extends Table {
  IntColumn get idErp => integer()();

  /// Usuarios.Id del ERP — es el que se envía al SP de jornada.
  IntColumn get usuarioErpId => integer().nullable()();

  /// Usuarios.Codigo del ERP — código de login (ej. "PCORZO", "MVILLENA").
  /// Usado para lookup en auth y en la pantalla de bienvenida.
  TextColumn get codTrabajador => text()();

  /// Código físico/barcode del trabajador (ej. "468834").
  /// Viene de SUBSTRING(t.Codigo, 6, ...) en el SP de sync.
  /// Usado por el portero al escanear y como fallback en login PIN.
  TextColumn get codigoBarra => text().nullable()();

  TextColumn get nombres => text()();
  TextColumn get apellidos => text()();
  TextColumn get dni => text().nullable()();

  /// 'operador' | 'supervisor'
  TextColumn get rolApk => text().withDefault(const Constant('operador'))();

  /// SHA-256 del PIN — seteado al momento del primer login con PIN.
  TextColumn get pinHash => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sincronizadoAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {idErp};
}

/// Lotes (Cultivos + Fincas + Zonas ERP — sublotes).
/// v21+: incluye geometrías de sublote (lotes_kmz del catálogo ERP) para
///        point-in-polygon offline en el servicio GPS.
class LotesLocal extends Table {
  IntColumn get idErp => integer()();
  TextColumn get loteCodigo => text()();
  TextColumn get loteNombre => text()();
  IntColumn get fincaIdErp => integer()();
  TextColumn get fincaNombre => text()();
  TextColumn get sublote => text().nullable()();
  RealColumn get areaHa => real().nullable()();
  TextColumn get zona => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sincronizadoAt =>
      dateTime().withDefault(currentDateAndTime)();
  // Geometría del sublote — poblada desde el catálogo lotes_kmz
  TextColumn get geometriaWkt => text().nullable()();   // WKT POLYGON (lon lat order)
  RealColumn get latitudCentro => real().nullable()();  // centroide lat
  RealColumn get longitudCentro => real().nullable()(); // centroide lng
  TextColumn get nombreCultivo => text().nullable()();  // UVA, PALTO, ESPARRAGO…
  TextColumn get colorCultivo => text().nullable()();   // hex #RRGGBB para mapa

  @override
  Set<Column> get primaryKey => {idErp};
}

/// Sectores (fincas agrupadas — derivadas de datos ERP para UI).
class SectoresLocal extends Table {
  IntColumn get id => integer()();
  TextColumn get nombre => text()();
  TextColumn get codigo => text()();
  RealColumn get areaHa => real().nullable()();
  TextColumn get zona => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Subprocesos (dependientes de un proceso — MMA v3).
class SubprocesosLocal extends Table {
  IntColumn get id => integer()();
  IntColumn get procesoId => integer()();
  TextColumn get nombre => text()();
  TextColumn get codigo => text()();
  TextColumn get descripcion => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Menús por rol — sincronizados desde el ERP (MMA v3).
class MenusLocal extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get titulo => text()();
  TextColumn get icono => text().nullable()();
  TextColumn get ruta => text().nullable()();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  TextColumn get rol => text()();

  @override
  Set<Column> get primaryKey => {id};
}
