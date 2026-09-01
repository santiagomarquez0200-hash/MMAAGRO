import 'package:equatable/equatable.dart';

class ParoMecanico extends Equatable {
  final String paroId;
  final String operadorNombre;
  final String tractorCodigo;
  final DateTime fecha;
  final String horaInicio;
  final String? horaFinal;
  final int fallaMecanicaId;
  final String fallaMecanicaNombre;
  final String? motivo;
  final String? equipo;
  final String estadoFalla; // 'pendiente' | 'en_proceso' | 'resuelto'
  final String? trabajoRealizado;
  final String? horaInicioReal;
  final String? horaFinReal;
  final String? mecanicoNombre;

  const ParoMecanico({
    required this.paroId,
    required this.operadorNombre,
    required this.tractorCodigo,
    required this.fecha,
    required this.horaInicio,
    this.horaFinal,
    required this.fallaMecanicaId,
    required this.fallaMecanicaNombre,
    this.motivo,
    this.equipo,
    required this.estadoFalla,
    this.trabajoRealizado,
    this.horaInicioReal,
    this.horaFinReal,
    this.mecanicoNombre,
  });

  bool get esPendiente => estadoFalla == 'pendiente';
  bool get esEnProceso => estadoFalla == 'en_proceso';
  bool get esCompletado => estadoFalla == 'resuelto';

  @override
  List<Object?> get props => [paroId, estadoFalla];
}
