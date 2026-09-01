import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String codigo;
  final String pin;
  final String username;
  final String password;
  final String rol; // 'operador' | 'supervisor'
  const AuthLoginRequested({
    required this.codigo,
    required this.pin,
    required this.username,
    required this.password,
    required this.rol,
  });
  @override
  List<Object?> get props => [codigo, pin, username, password, rol];
}

class AuthPinGateRequested extends AuthEvent {
  final String codigo;
  final String pin;
  final String rol; // 'operador' | 'supervisor'
  const AuthPinGateRequested({
    required this.codigo,
    required this.pin,
    required this.rol,
  });
  @override
  List<Object?> get props => [codigo, pin, rol];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUserUpdated extends AuthEvent {
  final dynamic usuario; // Use dynamic to avoid importing Usuario if not needed, or import it.
  const AuthUserUpdated(this.usuario);
  @override
  List<Object?> get props => [usuario];
}
