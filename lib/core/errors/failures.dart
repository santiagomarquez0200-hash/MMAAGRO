import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super(message: 'Sin conexión a internet');
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class ConflictFailure extends Failure {
  final Map<String, dynamic>? serverData;
  const ConflictFailure({required super.message, this.serverData});
  @override
  List<Object?> get props => [message, serverData];
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
