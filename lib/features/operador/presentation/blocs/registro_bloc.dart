import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/crear_registro_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/cerrar_turno_usecase.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/usecases/aprobar_registro_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/agregar_paro_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/registrar_bin_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/guardar_checklist_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'registro_event.dart';
import 'registro_state.dart';

class RegistroBloc extends Bloc<RegistroEvent, RegistroState> {
  final CrearRegistroUseCase _crearRegistro;
  final CerrarTurnoUseCase _cerrarTurno;
  final AprobarRegistroUseCase _aprobarRegistro;
  final AgregarParoUseCase _agregarParo;
  final RegistrarBinUseCase _registrarBin;
  final GuardarChecklistUseCase _guardarChecklist;
  final RegistroRepository _registroRepository;

  RegistroBloc({
    required CrearRegistroUseCase crearRegistro,
    required CerrarTurnoUseCase cerrarTurno,
    required AprobarRegistroUseCase aprobarRegistro,
    required AgregarParoUseCase agregarParo,
    required RegistrarBinUseCase registrarBin,
    required GuardarChecklistUseCase guardarChecklist,
    required RegistroRepository registroRepository,
  })  : _crearRegistro = crearRegistro,
        _cerrarTurno = cerrarTurno,
        _aprobarRegistro = aprobarRegistro,
        _agregarParo = agregarParo,
        _registrarBin = registrarBin,
        _guardarChecklist = guardarChecklist,
        _registroRepository = registroRepository,
        super(const RegistroInitial()) {
    on<RegistrosWatchRequested>(_onWatch, transformer: restartable());
    on<RegistroCrearRequested>(_onCrear);
    on<RegistroActualizarBasicoRequested>(_onActualizarBasico);
    on<RegistroEliminarRequested>(_onEliminar);
    on<RegistroCerrarTurnoRequested>(_onCerrarTurno);
    on<RegistroAprobarRequested>(_onAprobar);
    on<RegistroParoAgregarRequested>(_onAgregarParo);
    on<RegistroBinRequested>(_onRegistrarBin);
    on<RegistroChecklistGuardarRequested>(_onGuardarChecklist);
  }

  // Escucha stream de BD local → latencia cero para el usuario
  Future<void> _onWatch(
      RegistrosWatchRequested event, Emitter<RegistroState> emit) async {
    await emit.forEach(
      _registroRepository.watchRegistros(
        operadorIdErp: event.operadorIdErp,
        fechaDesde: event.fechaDesde,
      ),
      onData: (registros) => RegistrosLoaded(registros: registros),
      onError: (_, __) =>
          const RegistroError(message: 'Error al cargar registros'),
    );
  }

  Future<void> _onCrear(
      RegistroCrearRequested event, Emitter<RegistroState> emit) async {
    emit(const RegistroLoading());
    final result = await _crearRegistro(event.params);
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (registro) => emit(RegistroOperacionExitosa(
        registro: registro,
        mensaje: 'Registro creado: ${registro.numeroRegistro}',
      )),
    );
  }

  Future<void> _onCerrarTurno(
      RegistroCerrarTurnoRequested event, Emitter<RegistroState> emit) async {
    emit(const RegistroLoading());
    final result = await _cerrarTurno(event.params);
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (registro) => emit(RegistroOperacionExitosa(
        registro: registro,
        mensaje: 'Turno cerrado correctamente',
      )),
    );
  }

  Future<void> _onActualizarBasico(
      RegistroActualizarBasicoRequested event,
      Emitter<RegistroState> emit) async {
    emit(const RegistroLoading());
    final result = await _registroRepository.actualizarRegistroBasico(
      event.registroId,
      event.params,
    );
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (registro) => emit(RegistroOperacionExitosa(
        registro: registro,
        mensaje: 'Registro actualizado',
      )),
    );
  }

  Future<void> _onEliminar(
      RegistroEliminarRequested event, Emitter<RegistroState> emit) async {
    final result = await _registroRepository.eliminarRegistro(event.registroId);
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (_) => emit(RegistroEliminadoExitoso(registroId: event.registroId)),
    );
  }

  Future<void> _onAprobar(
      RegistroAprobarRequested event, Emitter<RegistroState> emit) async {
    emit(const RegistroLoading());
    final result = await _aprobarRegistro(event.params);
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (registro) => emit(RegistroOperacionExitosa(
        registro: registro,
        mensaje: 'Registro ${event.params.accion == 'aprobar' ? 'aprobado' : 'rechazado'}',
      )),
    );
  }

  Future<void> _onAgregarParo(
      RegistroParoAgregarRequested event, Emitter<RegistroState> emit) async {
    emit(const RegistroLoading());
    final result = await _agregarParo(event.params);
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      // Emitir éxito para liberar los BlocBuilders del estado Loading.
      (_) => emit(const RegistroSubOperacionExitosa()),
    );
  }

  Future<void> _onRegistrarBin(
      RegistroBinRequested event, Emitter<RegistroState> emit) async {
    emit(const RegistroLoading());
    final result = await _registrarBin(event.params);
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (_) => emit(const RegistroSubOperacionExitosa()),
    );
  }

  Future<void> _onGuardarChecklist(
      RegistroChecklistGuardarRequested event,
      Emitter<RegistroState> emit) async {
    // Auto-save silencioso: no emite Loading ni navega — evita congelar la UI
    // o disparar el BlocListener de navegación en cada item marcado.
    if (event.isAutoSave) {
      await _guardarChecklist(GuardarChecklistParams(
        registroId: event.registroId,
        resultados: event.resultados,
      ));
      return;
    }
    // Guardado final (botón SIGUIENTE): emite Loading y estado de éxito.
    emit(const RegistroLoading());
    final result = await _guardarChecklist(GuardarChecklistParams(
      registroId: event.registroId,
      resultados: event.resultados,
    ));
    result.fold(
      (failure) => emit(RegistroError(message: failure.message)),
      (_) => emit(const RegistroChecklistGuardadoExitoso()),
    );
  }


}
