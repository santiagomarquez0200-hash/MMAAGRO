import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/usecases/get_paros_mecanico_usecase.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/usecases/completar_falla_usecase.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';
import 'mecanico_event.dart';
import 'mecanico_state.dart';

class MecanicoBloc extends Bloc<MecanicoEvent, MecanicoState> {
  final GetParosMecanicoUseCase _getParos;
  final CompletarFallaUseCase _completarFalla;

  List<ParoMecanico> _parosActuales = [];

  MecanicoBloc({
    required GetParosMecanicoUseCase getParos,
    required CompletarFallaUseCase completarFalla,
  })  : _getParos = getParos,
        _completarFalla = completarFalla,
        super(const MecanicoInitial()) {
    on<MecanicoParosRequested>(_onParosRequested);
    on<MecanicoFallaCompletarRequested>(_onCompletarFalla);
  }

  Future<void> _onParosRequested(
      MecanicoParosRequested event, Emitter<MecanicoState> emit) async {
    // Don't refresh while completing a falla
    if (state is MecanicoCompletandoFalla) return;
    emit(const MecanicoLoading());
    final result =
        await _getParos(GetParosMecanicoParams(fecha: event.fecha, estado: event.estado));
    result.fold(
      (f) => emit(MecanicoError(message: f.message)),
      (paros) {
        _parosActuales = paros;
        emit(MecanicoLoaded(paros: paros));
      },
    );
  }

  Future<void> _onCompletarFalla(
      MecanicoFallaCompletarRequested event, Emitter<MecanicoState> emit) async {
    emit(MecanicoCompletandoFalla(paros: _parosActuales));
    final result = await _completarFalla(event.params);
    result.fold(
      (f) => emit(MecanicoError(message: f.message)),
      (_) => emit(MecanicoFallaCompletada(paros: _parosActuales)),
    );
  }
}
