import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';

abstract class MecanicoState extends Equatable {
  const MecanicoState();
  @override
  List<Object?> get props => [];
}

class MecanicoInitial extends MecanicoState {
  const MecanicoInitial();
}

class MecanicoLoading extends MecanicoState {
  const MecanicoLoading();
}

class MecanicoLoaded extends MecanicoState {
  final List<ParoMecanico> paros;
  const MecanicoLoaded({required this.paros});
  @override
  List<Object?> get props => [paros];
}

class MecanicoError extends MecanicoState {
  final String message;
  const MecanicoError({required this.message});
  @override
  List<Object?> get props => [message];
}

class MecanicoCompletandoFalla extends MecanicoState {
  final List<ParoMecanico> paros;
  const MecanicoCompletandoFalla({required this.paros});
  @override
  List<Object?> get props => [paros];
}

class MecanicoFallaCompletada extends MecanicoState {
  final List<ParoMecanico> paros;
  const MecanicoFallaCompletada({required this.paros});
  @override
  List<Object?> get props => [paros];
}
