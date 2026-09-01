import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/shared/auth/domain/entities/usuario.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthPinValidated extends AuthState {
  final String codigo;
  final String pin;
  final String rol; // 'operador' | 'supervisor'
  const AuthPinValidated({
    required this.codigo,
    required this.pin,
    required this.rol,
  });
  @override
  List<Object?> get props => [codigo, pin, rol];
}

class AuthAuthenticated extends AuthState {
  final Usuario usuario;
  const AuthAuthenticated({required this.usuario});
  @override
  List<Object?> get props => [usuario];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState({required this.message});
  @override
  List<Object?> get props => [message];
}
