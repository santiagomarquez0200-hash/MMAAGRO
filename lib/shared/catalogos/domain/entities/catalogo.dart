import 'package:equatable/equatable.dart';

// ─── Catálogos desde Backend PostgreSQL ───────────────────────────────────────

/// Subproceso dependiente de un proceso (MMA v3).
class Subproceso extends Equatable {
  final int id;
  final int procesoId;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final bool activo;

  const Subproceso({
    required this.id,
    required this.procesoId,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.activo,
  });

  @override
  List<Object?> get props => [id, codigo];
}

class Proceso extends Equatable {
  final int id;
  final String nombre;
  final String codigo;
  final bool requiereBines;
  final bool activo;
  // 'tractor' | 'vehiculo' — viene del campo tipo_registro del ERP.
  // Si el servidor todavía no tiene la columna, llega vacío y se trata como tractor.
  final String tipoRegistro;

  const Proceso({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.requiereBines,
    required this.activo,
    this.tipoRegistro = 'tractor',
  });

  /// Detectado en base al nombre/código del proceso (coherente con la BD).
  bool get requiereSublabores =>
      nombre.toUpperCase().contains('APLICAC') ||
      codigo.toUpperCase().contains('APLIC');

  @override
  List<Object?> get props => [id, codigo];
}

class CajaCambios extends Equatable {
  final int id;
  final String nombre;

  const CajaCambios({required this.id, required this.nombre});

  @override
  List<Object?> get props => [id];
}

class TipoParo extends Equatable {
  final int id;
  final String codigo;
  final String nombre;
  final bool requiereGalones;
  final bool requiereEquipo;
  final bool activo;

  const TipoParo({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.requiereGalones = false,
    this.requiereEquipo = false,
    required this.activo,
  });

  @override
  List<Object?> get props => [id, codigo];
}

class ChecklistItem extends Equatable {
  final int id;
  final int categoriaId;
  final String categoriaNombre;
  final String nombre;
  final int orden;
  final String tipoRegistro;
  final bool activo;

  const ChecklistItem({
    required this.id,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.nombre,
    required this.orden,
    required this.tipoRegistro,
    required this.activo,
  });

  @override
  List<Object?> get props => [id, tipoRegistro];
}

// ─── Catálogos desde ERP SQL Server ──────────────────────────────────────────

/// Cultivo (especie botánica) proveniente del ERP.
class Cultivo extends Equatable {
  final int idErp;
  final String codigoEspecie;
  final String nombreEspecie;
  final String? nombreCultivo;
  final bool activo;

  const Cultivo({
    required this.idErp,
    required this.codigoEspecie,
    required this.nombreEspecie,
    this.nombreCultivo,
    required this.activo,
  });

  String get displayName => nombreCultivo ?? nombreEspecie;

  @override
  List<Object?> get props => [idErp, codigoEspecie];
}

/// Tractor (maquinaria tipo T%) proveniente del ERP.
class Tractor extends Equatable {
  final int idErp;
  final String codigoTractor;
  final String descripcion;
  final String? marca;
  final String? modelo;
  final String? matricula;
  final String? codigoInterno;
  final String? zona;
  final bool activo;

  const Tractor({
    required this.idErp,
    required this.codigoTractor,
    required this.descripcion,
    this.marca,
    this.modelo,
    this.matricula,
    this.codigoInterno,
    this.zona,
    required this.activo,
  });

  @override
  List<Object?> get props => [idErp, codigoTractor];
}

/// Implemento (maquinaria tipo I%) proveniente del ERP.
class Implemento extends Equatable {
  final int idErp;
  final String codigoImplemento;
  final String descripcion;
  final String? marca;
  final String? modelo;
  final String? codigoInterno;
  final String? zona;
  final bool activo;

  const Implemento({
    required this.idErp,
    required this.codigoImplemento,
    required this.descripcion,
    this.marca,
    this.modelo,
    this.codigoInterno,
    this.zona,
    required this.activo,
  });

  @override
  List<Object?> get props => [idErp, codigoImplemento];
}

/// Trabajador (operador/supervisor) proveniente del ERP.
class Trabajador extends Equatable {
  final int idErp;
  final String codTrabajador;
  final String nombres;
  final String apellidos;
  final String? dni;
  final String rolApk; // 'operador' | 'supervisor'
  final String? pinHash;
  final bool activo;

  const Trabajador({
    required this.idErp,
    required this.codTrabajador,
    required this.nombres,
    required this.apellidos,
    this.dni,
    required this.rolApk,
    this.pinHash,
    required this.activo,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();
  bool get esOperador => rolApk == 'operador';
  bool get esSupervisor => rolApk == 'supervisor';

  @override
  List<Object?> get props => [idErp, codTrabajador];
}

/// Lote (finca + sublote) proveniente del ERP.
class Lote extends Equatable {
  final int idErp;
  final String loteCodigo;
  final String loteNombre;
  final int fincaIdErp;
  final String fincaNombre;
  final String? sublote;
  final double? areaHa;
  final String? zona;
  final bool activo;

  const Lote({
    required this.idErp,
    required this.loteCodigo,
    required this.loteNombre,
    required this.fincaIdErp,
    required this.fincaNombre,
    this.sublote,
    this.areaHa,
    this.zona,
    required this.activo,
  });

  String get displayName =>
      sublote != null ? '$loteNombre - $sublote' : loteNombre;

  @override
  List<Object?> get props => [idErp, loteCodigo];
}

/// Vehículo (maquinaria tipo V%) proveniente del ERP.
class Vehiculo extends Equatable {
  final int idErp;
  final String codigoVehiculo;
  final String descripcion;
  final String? marca;
  final String? modelo;
  final String? matricula;
  final String? codigoInterno;
  final bool activo;

  const Vehiculo({
    required this.idErp,
    required this.codigoVehiculo,
    required this.descripcion,
    this.marca,
    this.modelo,
    this.matricula,
    this.codigoInterno,
    required this.activo,
  });

  @override
  List<Object?> get props => [idErp, codigoVehiculo];
}

/// Tipo de falla mecánica — catálogo descargado del ERP.
class FallaMecanica extends Equatable {
  final int id;
  final String codigo;
  final String nombre;
  /// Categoría de la falla: MECANICO, ELECTRICO, HIDRAULICO, LUBRICACION, FISICOQUIMICO.
  final String categoria;
  /// Componentes típicamente afectados (texto libre del ERP).
  final String? componentesAfectados;

  const FallaMecanica({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.categoria = 'MECANICO',
    this.componentesAfectados,
  });

  @override
  List<Object?> get props => [id, codigo];
}

/// Sector agrupador de lotes (sólo para UI — derivado de finca ERP).
class Sector extends Equatable {
  final int id;
  final String nombre;
  final String codigo;
  final double? areaHa;
  final String? zona;
  final bool activo;
  final List<Lote> lotes;

  const Sector({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.areaHa,
    this.zona,
    required this.activo,
    this.lotes = const [],
  });

  @override
  List<Object?> get props => [id, codigo];
}
