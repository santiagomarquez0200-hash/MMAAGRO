import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/repositories/mecanico_repository.dart';

abstract class MecanicoEvent extends Equatable {
  const MecanicoEvent();
  @override
  List<Object?> get props => [];
}

class MecanicoParosRequested extends MecanicoEvent {
  final DateTime fecha;
  final String? estado;
  const MecanicoParosRequested({required this.fecha, this.estado});
  @override
  List<Object?> get props => [fecha, estado];
}

class MecanicoFallaCompletarRequested extends MecanicoEvent {
  final CompletarFallaParams params;
  const MecanicoFallaCompletarRequested({required this.params});
  @override
  List<Object?> get props => [params];
}
