import 'package:equatable/equatable.dart';

class RegistroDiario extends Equatable {
  final String id;
  final String numeroRegistro;
  final DateTime fecha;
  final String turno;

  // ── Proceso (PostgreSQL) ──
  final int procesoId;
  final String procesoNombre;
  final String procesoCodigo;

  // ── Cultivo (ERP) — snapshot ──
  final int cultivoIdErp;
  final String cultivoNombreEspecie;
  final String cultivoCodigoEspecie;

  // ── Operador (ERP) — snapshot ──
  final int operadorIdErp;
  final String operadorCodigo;
  final String operadorNombre;

  // ── Supervisor (ERP) — snapshot ──
  final int? supervisorIdErp;
  final String? supervisorCodigo;
  final String? supervisorNombre;

  // ── Tractor (ERP) — snapshot ──
  final int tractorIdErp;
  final String tractorCodigo;
  final String tractorDescripcion;

  // ── Implemento (ERP) — snapshot ──
  final int? implementoIdErp;
  final String? implementoCodigo;
  final String? implementoDescripcion;
  final String? implementoCodigoInterno;

  // ── Caja de cambios (PostgreSQL) ──
  final int? cajaCambiosId;
  final String? cajaCambiosNombre;

  // ── Subproceso (MMA v3, opcional) ──
  final int? subprocesoId;
  final String? subprocesoNombre;

  final String estado;
  final String tipoRegistro; // 'tractor' | 'vehiculo'
  final String? observacionesMaq;
  final String? motivoRechazo;
  final String? firmaOperador;
  final String? dispositivoId;
  final bool sincronizado;
  final DateTime? sincronizadoAt;
  final DateTime createdAt;

  // Datos relacionados (cargados bajo demanda)
  final Horometro? horometro;
  final TiempoTurno? tiempoTurno;
  final List<RegistroSector> sectores;
  final List<CosechaBin> bines;
  final List<ParoEquipo> paros;
  final List<ChecklistResultado> checklist;
  final VehiculoDetalle? vehiculoDetalle;
  final List<CombustibleVehiculoDetalle> combustiblesVehiculo;
  final List<ParoVehiculoDetalle> parosVehiculo;

  const RegistroDiario({
    required this.id,
    required this.numeroRegistro,
    required this.fecha,
    required this.turno,
    required this.procesoId,
    required this.procesoNombre,
    required this.procesoCodigo,
    required this.cultivoIdErp,
    required this.cultivoNombreEspecie,
    required this.cultivoCodigoEspecie,
    required this.operadorIdErp,
    required this.operadorCodigo,
    required this.operadorNombre,
    this.supervisorIdErp,
    this.supervisorCodigo,
    this.supervisorNombre,
    required this.tractorIdErp,
    required this.tractorCodigo,
    required this.tractorDescripcion,
    this.implementoIdErp,
    this.implementoCodigo,
    this.implementoDescripcion,
    this.implementoCodigoInterno,
    this.cajaCambiosId,
    this.cajaCambiosNombre,
    this.subprocesoId,
    this.subprocesoNombre,
    required this.estado,
    this.tipoRegistro = 'tractor',
    this.observacionesMaq,
    this.motivoRechazo,
    this.firmaOperador,
    this.dispositivoId,
    required this.sincronizado,
    this.sincronizadoAt,
    required this.createdAt,
    this.horometro,
    this.tiempoTurno,
    this.sectores = const [],
    this.bines = const [],
    this.paros = const [],
    this.checklist = const [],
    this.vehiculoDetalle,
    this.combustiblesVehiculo = const [],
    this.parosVehiculo = const [],
  });

  bool get esBorrador => estado == 'borrador';
  bool get esCompletado => estado == 'completado';
  bool get esAprobado => estado == 'aprobado';
  bool get esRechazado => estado == 'rechazado';
  bool get pendienteSincronizar => !sincronizado;

  int get totalBines => bines.fold(0, (sum, b) => sum + b.cantidad);
  int get totalMinParos =>
      paros.fold(0, (sum, p) => sum + (p.duracionMin ?? 0));

  @override
  List<Object?> get props => [
    id,
    numeroRegistro,
    fecha,
    turno,
    procesoId,
    procesoNombre,
    procesoCodigo,
    cultivoIdErp,
    cultivoNombreEspecie,
    cultivoCodigoEspecie,
    operadorIdErp,
    operadorCodigo,
    operadorNombre,
    supervisorIdErp,
    supervisorCodigo,
    supervisorNombre,
    tractorIdErp,
    tractorCodigo,
    tractorDescripcion,
    implementoIdErp,
    implementoCodigo,
    implementoDescripcion,
    implementoCodigoInterno,
    estado,
    sincronizado,
  ];
}

// ─── Subentidades ─────────────────────────────────────────────────────────────

class Horometro extends Equatable {
  final String id;
  final String registroId;
  final double? tractorInicio;
  final double? tractorFinal;
  final double? implementoInicio;
  final double? implementoFinal;

  const Horometro({
    required this.id,
    required this.registroId,
    this.tractorInicio,
    this.tractorFinal,
    this.implementoInicio,
    this.implementoFinal,
  });

  double? get horasTractor => (tractorFinal != null && tractorInicio != null)
      ? tractorFinal! - tractorInicio!
      : null;

  double? get horasImplemento =>
      (implementoFinal != null && implementoInicio != null)
          ? implementoFinal! - implementoInicio!
          : null;

  @override
  List<Object?> get props => [id];
}

class TiempoTurno extends Equatable {
  final String id;
  final String registroId;
  final String? horaSalidaTaller;
  final String? horaLlegadaPunto;
  final String? horaSalidaPunto;
  final String? horaLlegadaTaller;
  final String? horaRefrigerio;

  const TiempoTurno({
    required this.id,
    required this.registroId,
    this.horaSalidaTaller,
    this.horaLlegadaPunto,
    this.horaSalidaPunto,
    this.horaLlegadaTaller,
    this.horaRefrigerio,
  });

  @override
  List<Object?> get props => [id];
}

class RegistroSector extends Equatable {
  final String id;
  final String registroId;
  final int loteIdErp;
  final String loteCodigo;
  final String loteNombre;
  final String fincaNombre;
  final double? areaTrabajada;
  final String? observacion;

  const RegistroSector({
    required this.id,
    required this.registroId,
    required this.loteIdErp,
    required this.loteCodigo,
    required this.loteNombre,
    required this.fincaNombre,
    this.areaTrabajada,
    this.observacion,
  });

  @override
  List<Object?> get props => [id, loteIdErp];
}

class CosechaBin extends Equatable {
  final String id;
  final String registroId;
  final String franjaHoraria;
  final String turno;
  final int cantidad;

  const CosechaBin({
    required this.id,
    required this.registroId,
    required this.franjaHoraria,
    required this.turno,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [registroId, franjaHoraria];
}

class ParoEquipo extends Equatable {
  final String id;
  final String registroId;
  final int tipoParoId;
  final String tipoParoCodigo;
  final String tipoParoNombre;
  final String? motivo;
  final String? equipo;
  final String horaInicio;
  final String? horaFinal;
  final double? galones;
  final int? duracionMin;
  final int? fallaMecanicaId;
  final String? fallaMecanicaNombre;

  const ParoEquipo({
    required this.id,
    required this.registroId,
    required this.tipoParoId,
    required this.tipoParoCodigo,
    required this.tipoParoNombre,
    this.motivo,
    this.equipo,
    required this.horaInicio,
    this.horaFinal,
    this.galones,
    this.duracionMin,
    this.fallaMecanicaId,
    this.fallaMecanicaNombre,
  });

  @override
  List<Object?> get props => [id];
}

class ChecklistResultado extends Equatable {
  final String id;
  final String registroId;
  final int itemId;
  final String itemNombre;
  final String categoriaNombre;
  final String resultado; // 'bien' | 'mal' | 'na'
  final String? observacion;
  final String? fotoUrl;

  const ChecklistResultado({
    required this.id,
    required this.registroId,
    required this.itemId,
    required this.itemNombre,
    required this.categoriaNombre,
    required this.resultado,
    this.observacion,
    this.fotoUrl,
  });

  bool get esBien => resultado == 'bien';
  bool get esMal => resultado == 'mal';
  bool get esNa => resultado == 'na';

  @override
  List<Object?> get props => [registroId, itemId];
}

class VehiculoDetalle extends Equatable {
  final double? kmCamionInicio;
  final double? kmCamionFinal;
  final double? kmImplementoInicio;
  final double? kmImplementoFinal;
  final String? horaSalidaBase;
  final String? horaLlegadaZona;
  final String? horaRetornoBase;
  final String? horaLlegadaTaller;
  final String? horaRefrigerio;
  final int? cantidadTancadas;

  const VehiculoDetalle({
    this.kmCamionInicio,
    this.kmCamionFinal,
    this.kmImplementoInicio,
    this.kmImplementoFinal,
    this.horaSalidaBase,
    this.horaLlegadaZona,
    this.horaRetornoBase,
    this.horaLlegadaTaller,
    this.horaRefrigerio,
    this.cantidadTancadas,
  });

  @override
  List<Object?> get props => [
        kmCamionInicio,
        kmCamionFinal,
        kmImplementoInicio,
        kmImplementoFinal,
        horaSalidaBase,
        horaLlegadaZona,
        horaRetornoBase,
        horaLlegadaTaller,
        horaRefrigerio,
        cantidadTancadas,
      ];
}

class CombustibleVehiculoDetalle extends Equatable {
  final double? glns;
  final String? horaInicio;
  final String? horaFinal;

  const CombustibleVehiculoDetalle({
    this.glns,
    this.horaInicio,
    this.horaFinal,
  });

  @override
  List<Object?> get props => [glns, horaInicio, horaFinal];
}

class ParoVehiculoDetalle extends Equatable {
  final String? motivo;
  final String? horaInicio;
  final String? horaFinal;

  const ParoVehiculoDetalle({
    this.motivo,
    this.horaInicio,
    this.horaFinal,
  });

  @override
  List<Object?> get props => [motivo, horaInicio, horaFinal];
}

class OutboxEntry extends Equatable {
  final int id;
  final String? registroLocalId;
  final String endpoint;
  final String method;
  final String payloadJson;
  final DateTime timestamp;
  final String status;
  final int retryCount;
  final String? errorMessage;

  const OutboxEntry({
    required this.id,
    this.registroLocalId,
    required this.endpoint,
    required this.method,
    required this.payloadJson,
    required this.timestamp,
    required this.status,
    required this.retryCount,
    this.errorMessage,
  });

  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  @override
  List<Object?> get props => [id, endpoint, status];
}
