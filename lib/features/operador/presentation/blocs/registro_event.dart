import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

abstract class RegistroEvent extends Equatable {
  const RegistroEvent();
  @override
  List<Object?> get props => [];
}

class RegistrosWatchRequested extends RegistroEvent {
  final int? operadorIdErp;
  /// Si se pasa, el stream solo emite registros a partir de esa fecha.
  /// null = sin filtro (historial completo).
  final DateTime? fechaDesde;
  const RegistrosWatchRequested({this.operadorIdErp, this.fechaDesde});
  @override
  List<Object?> get props => [operadorIdErp, fechaDesde];
}

class RegistroCrearRequested extends RegistroEvent {
  final CrearRegistroParams params;
  const RegistroCrearRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

class RegistroActualizarBasicoRequested extends RegistroEvent {
  final String registroId;
  final CrearRegistroParams params;
  const RegistroActualizarBasicoRequested({
    required this.registroId,
    required this.params,
  });
  @override
  List<Object?> get props => [registroId, params];
}

class RegistroEliminarRequested extends RegistroEvent {
  final String registroId;
  const RegistroEliminarRequested({required this.registroId});
  @override
  List<Object?> get props => [registroId];
}

class RegistroCerrarTurnoRequested extends RegistroEvent {
  final CerrarTurnoParams params;
  const RegistroCerrarTurnoRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

class RegistroAprobarRequested extends RegistroEvent {
  final AprobarRegistroParams params;
  const RegistroAprobarRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

class RegistroParoAgregarRequested extends RegistroEvent {
  final AgregarParoParams params;
  const RegistroParoAgregarRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

class RegistroBinRequested extends RegistroEvent {
  final RegistrarBinParams params;
  const RegistroBinRequested({required this.params});
  @override
  List<Object?> get props => [params];
}

class RegistroChecklistGuardarRequested extends RegistroEvent {
  final String registroId;
  final List<ChecklistResultadoInput> resultados;
  /// true = auto-guardado silencioso (sin Loading ni navegación).
  /// false (default) = guardado final que emite RegistroChecklistGuardadoExitoso.
  final bool isAutoSave;
  const RegistroChecklistGuardarRequested({
    required this.registroId,
    required this.resultados,
    this.isAutoSave = false,
  });
  @override
  List<Object?> get props => [registroId, isAutoSave];
}
