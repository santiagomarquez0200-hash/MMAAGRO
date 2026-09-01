import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';

abstract class SupervisorState extends Equatable {
  const SupervisorState();
  @override
  List<Object?> get props => [];
}

class SupervisorInitial extends SupervisorState {
  const SupervisorInitial();
}

class SupervisorLoading extends SupervisorState {
  const SupervisorLoading();
}

class SupervisorRegistrosLoaded extends SupervisorState {
  final List<RegistroDiario> registros;
  final DateTime fecha;
  final String? turno;
  const SupervisorRegistrosLoaded({
    required this.registros,
    required this.fecha,
    this.turno,
  });
  @override
  List<Object?> get props => [registros, fecha, turno];
}

class SupervisorOperacionExitosa extends SupervisorState {
  final String mensaje;
  final List<RegistroDiario> registros;
  final String? registroId;
  const SupervisorOperacionExitosa({
    required this.mensaje,
    required this.registros,
    this.registroId,
  });
  @override
  List<Object?> get props => [mensaje, registros, registroId];
}

class SupervisorError extends SupervisorState {
  final String mensaje;
  const SupervisorError({required this.mensaje});
  @override
  List<Object?> get props => [mensaje];
}
