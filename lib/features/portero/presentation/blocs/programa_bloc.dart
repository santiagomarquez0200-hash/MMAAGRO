import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/features/portero/domain/usecases/get_programa_turno_usecase.dart';
import 'programa_event.dart';
import 'programa_state.dart';

class ProgramaBloc extends Bloc<ProgramaEvent, ProgramaState> {
  final GetProgramaTurnoUseCase _getPrograma;

  ProgramaBloc({required GetProgramaTurnoUseCase getPrograma})
      : _getPrograma = getPrograma,
        super(const ProgramaInitial()) {
    on<ProgramaRequested>(_onRequested);
  }

  Future<void> _onRequested(
      ProgramaRequested event, Emitter<ProgramaState> emit) async {
    emit(const ProgramaLoading());
    final result = await _getPrograma(
      GetProgramaTurnoParams(fecha: event.fecha, turno: event.turno),
    );
    result.fold(
      (f) => emit(ProgramaError(message: f.message)),
      (programa) => emit(ProgramaLoaded(
        programa: programa,
        fecha: event.fecha,
        turno: event.turno,
      )),
    );
  }
}
