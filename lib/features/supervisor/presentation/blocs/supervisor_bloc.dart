import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/repositories/supervisor_repository.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/usecases/get_registros_supervisor_usecase.dart';
import 'supervisor_event.dart';
import 'supervisor_state.dart';

class SupervisorBloc extends Bloc<SupervisorEvent, SupervisorState> {
  final GetRegistrosSupervisorUseCase _getRegistros;
  final SupervisorRepository _supervisorRepository;

  SupervisorBloc({
    required GetRegistrosSupervisorUseCase getRegistros,
    required SupervisorRepository supervisorRepository,
  })  : _getRegistros = getRegistros,
        _supervisorRepository = supervisorRepository,
        super(const SupervisorInitial()) {
    on<SupervisorLoadRegistros>(_onLoad);
    on<SupervisorAprobarRegistro>(_onAprobar);
  }

  Future<void> _onLoad(
    SupervisorLoadRegistros event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(const SupervisorLoading());
    try {
      final result = await _getRegistros(
        GetRegistrosSupervisorParams(fecha: event.fecha, turno: event.turno),
      ).timeout(const Duration(seconds: 30));
      result.fold(
        (failure) => emit(SupervisorError(mensaje: failure.message)),
        (registros) => emit(SupervisorRegistrosLoaded(
          registros: registros,
          fecha: event.fecha,
          turno: event.turno,
        )),
      );
    } on TimeoutException {
      emit(const SupervisorError(
          mensaje: 'El servidor tardó demasiado. Verifica la conexión y reintenta.'));
    } catch (e) {
      emit(SupervisorError(mensaje: e.toString()));
    }
  }

  Future<void> _onAprobar(
    SupervisorAprobarRegistro event,
    Emitter<SupervisorState> emit,
  ) async {
    // Preservar la lista actual durante la operación para que la UI no parpadee.
    // NO emitir SupervisorLoading aquí: causaba dos flashes de pantalla de carga
    // (uno interno + uno del _cargarRegistros() posterior en el listener).
    final currentRegistros = state is SupervisorRegistrosLoaded
        ? (state as SupervisorRegistrosLoaded).registros
        : state is SupervisorOperacionExitosa
            ? (state as SupervisorOperacionExitosa).registros
            : <RegistroDiario>[];

    try {
    final result =
        await _supervisorRepository.aprobarRegistro(event.params)
            .timeout(const Duration(seconds: 30));

    result.fold(
      (failure) => emit(SupervisorError(mensaje: failure.message)),
      (_) {
        final accion =
            event.params.accion == 'aprobar' ? 'aprobado' : 'rechazado';
        emit(SupervisorOperacionExitosa(
          mensaje: 'Registro $accion correctamente',
          registros: List<RegistroDiario>.from(currentRegistros),
          registroId: event.params.registroId,
        ));
      },
    );
    } on TimeoutException {
      emit(const SupervisorError(mensaje: 'Tiempo de espera agotado. Intente de nuevo.'));
    }
  }
}
