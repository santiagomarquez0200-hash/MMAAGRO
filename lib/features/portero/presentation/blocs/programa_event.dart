import 'package:equatable/equatable.dart';

abstract class ProgramaEvent extends Equatable {
  const ProgramaEvent();
  @override
  List<Object?> get props => [];
}

/// Baja el programa de una fecha y turno.
///
/// [turno] nulo son los dos del dia: el portero de la mañana necesita ver lo
/// suyo y tambien lo que quedo de la noche anterior sin salir.
class ProgramaRequested extends ProgramaEvent {
  final DateTime fecha;
  final String? turno;
  const ProgramaRequested({required this.fecha, this.turno});
  @override
  List<Object?> get props => [fecha, turno];
}
