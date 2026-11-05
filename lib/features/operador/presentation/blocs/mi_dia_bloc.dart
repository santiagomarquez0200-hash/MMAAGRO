import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/mi_dia_repository.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/get_mi_dia_usecase.dart';

// ─── Eventos ─────────────────────────────────────────────────────────────────

abstract class MiDiaEvent extends Equatable {
  const MiDiaEvent();
  @override
  List<Object?> get props => [];
}

class MiDiaRequested extends MiDiaEvent {
  final int? idTrabajador;
  final int? idUsuario;
  final DateTime fecha;
  const MiDiaRequested({
    this.idTrabajador,
    this.idUsuario,
    required this.fecha,
  });
  @override
  List<Object?> get props => [idTrabajador, idUsuario, fecha];
}

// ─── Estados ─────────────────────────────────────────────────────────────────

abstract class MiDiaState extends Equatable {
  const MiDiaState();
  @override
  List<Object?> get props => [];
}

class MiDiaInitial extends MiDiaState {
  const MiDiaInitial();
}

class MiDiaLoading extends MiDiaState {
  const MiDiaLoading();
}

class MiDiaLoaded extends MiDiaState {
  final MiDia miDia;
  final DateTime fecha;
  const MiDiaLoaded({required this.miDia, required this.fecha});
  @override
  List<Object?> get props => [miDia.asignaciones, fecha];
}

class MiDiaError extends MiDiaState {
  final String message;
  const MiDiaError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class MiDiaBloc extends Bloc<MiDiaEvent, MiDiaState> {
  final GetMiDiaUseCase _getMiDia;

  MiDiaBloc({required GetMiDiaUseCase getMiDia})
      : _getMiDia = getMiDia,
        super(const MiDiaInitial()) {
    on<MiDiaRequested>(_onRequested);
  }

  Future<void> _onRequested(
      MiDiaRequested event, Emitter<MiDiaState> emit) async {
    emit(const MiDiaLoading());
    final result = await _getMiDia(GetMiDiaParams(
      idTrabajador: event.idTrabajador,
      idUsuario: event.idUsuario,
      fecha: event.fecha,
    ));
    result.fold(
      (f) => emit(MiDiaError(message: f.message)),
      (miDia) => emit(MiDiaLoaded(miDia: miDia, fecha: event.fecha)),
    );
  }
}
