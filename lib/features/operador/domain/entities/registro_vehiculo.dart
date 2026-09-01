import 'package:equatable/equatable.dart';

class RegistroVehiculo extends Equatable {
  final String id;
  final String numeroRegistro;
  final DateTime fecha;
  final String turno;
  final String procesoNombre;
  final String procesoCodigo;
  final String operadorNombre;
  final String? supervisorNombre;
  final String tractorCodigo;
  final String tractorDescripcion;
  final String estado;

  // KM
  final double? kmCamionInicio;
  final double? kmCamionFinal;
  final double? kmImplementoInicio;
  final double? kmImplementoFinal;

  // Tiempos
  final String? horaSalidaBase;
  final String? horaLlegadaZona;
  final String? horaRetornoBase;
  final String? horaLlegadaTaller;
  final String? horaRefrigerio;
  final int? cantidadTancadas;

  final String? observacionesMaq;

  final List<CombustibleVehiculo> combustibles;
  final List<ParoVehiculo> paros;

  const RegistroVehiculo({
    required this.id,
    required this.numeroRegistro,
    required this.fecha,
    required this.turno,
    required this.procesoNombre,
    required this.procesoCodigo,
    required this.operadorNombre,
    this.supervisorNombre,
    required this.tractorCodigo,
    required this.tractorDescripcion,
    required this.estado,
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
    this.observacionesMaq,
    this.combustibles = const [],
    this.paros = const [],
  });

  @override
  List<Object?> get props => [id, numeroRegistro, estado];
}

class CombustibleVehiculo extends Equatable {
  final double? glns;
  final String? horaInicio;
  final String? horaFinal;

  const CombustibleVehiculo({this.glns, this.horaInicio, this.horaFinal});

  @override
  List<Object?> get props => [glns, horaInicio, horaFinal];
}

class ParoVehiculo extends Equatable {
  final String? motivo;
  final String horaInicio;
  final String? horaFinal;

  const ParoVehiculo({
    this.motivo,
    required this.horaInicio,
    this.horaFinal,
  });

  @override
  List<Object?> get props => [motivo, horaInicio];
}
