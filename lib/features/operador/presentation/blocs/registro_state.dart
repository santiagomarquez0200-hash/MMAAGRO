import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';

abstract class RegistroState extends Equatable {
  const RegistroState();
  @override
  List<Object?> get props => [];
}

class RegistroInitial extends RegistroState {
  const RegistroInitial();
}

class RegistroLoading extends RegistroState {
  const RegistroLoading();
}

// Lista de registros (stream de BD local)
class RegistrosLoaded extends RegistroState {
  final List<RegistroDiario> registros;
  const RegistrosLoaded({required this.registros});
  @override
  List<Object?> get props => [registros];
}

// Operación exitosa (crear, cerrar, aprobar, etc.)
class RegistroOperacionExitosa extends RegistroState {
  final RegistroDiario registro;
  final String mensaje;
  const RegistroOperacionExitosa({
    required this.registro,
    required this.mensaje,
  });
  @override
  List<Object?> get props => [registro, mensaje];
}

class RegistroEliminadoExitoso extends RegistroState {
  final String registroId;
  const RegistroEliminadoExitoso({required this.registroId});
  @override
  List<Object?> get props => [registroId];
}

// Emitido cuando el checklist se guarda exitosamente (usado por ChecklistPage
// para navegar solo después de confirmar el guardado).
class RegistroChecklistGuardadoExitoso extends RegistroState {
  const RegistroChecklistGuardadoExitoso();
}

/// Estado genérico para operaciones secundarias exitosas que no producen
/// un RegistroDiario completo (p.ej. agregar paro, registrar bin).
/// Permite que los BlocBuilders salgan del estado RegistroLoading.
class RegistroSubOperacionExitosa extends RegistroState {
  const RegistroSubOperacionExitosa();
}

class RegistroError extends RegistroState {
  final String message;
  const RegistroError({required this.message});
  @override
  List<Object?> get props => [message];
}
