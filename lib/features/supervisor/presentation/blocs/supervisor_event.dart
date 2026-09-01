import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

abstract class SupervisorEvent extends Equatable {
  const SupervisorEvent();
  @override
  List<Object?> get props => [];
}

class SupervisorLoadRegistros extends SupervisorEvent {
  final DateTime fecha;
  final String? turno;
  const SupervisorLoadRegistros({required this.fecha, this.turno});
  @override
  List<Object?> get props => [fecha, turno];
}

class SupervisorAprobarRegistro extends SupervisorEvent {
  final AprobarRegistroParams params;
  const SupervisorAprobarRegistro({required this.params});
  @override
  List<Object?> get props => [params.registroId];
}
