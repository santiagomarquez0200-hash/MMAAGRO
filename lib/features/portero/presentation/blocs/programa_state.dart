import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/portero/domain/repositories/portero_programa_repository.dart';

abstract class ProgramaState extends Equatable {
  const ProgramaState();
  @override
  List<Object?> get props => [];
}

class ProgramaInitial extends ProgramaState {
  const ProgramaInitial();
}

class ProgramaLoading extends ProgramaState {
  const ProgramaLoading();
}

class ProgramaLoaded extends ProgramaState {
  final ProgramaTurno programa;
  final DateTime fecha;
  final String? turno;
  const ProgramaLoaded({
    required this.programa,
    required this.fecha,
    this.turno,
  });
  @override
  List<Object?> get props => [programa.maquinas, fecha, turno];
}

class ProgramaError extends ProgramaState {
  final String message;
  const ProgramaError({required this.message});
  @override
  List<Object?> get props => [message];
}
