import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/shared/auth/domain/entities/usuario.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';

class LoginUseCase implements UseCase<Usuario, LoginParams> {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  @override
  Future<Either<Failure, Usuario>> call(LoginParams params) {
    return _repository.loginConAPI(params.username, params.password, params.rol);
  }
}

class LoginParams extends Equatable {
  final String username;
  final String password;
  final String rol; // 'operador' | 'supervisor'

  const LoginParams({
    required this.username,
    required this.password,
    required this.rol,
  });

  @override
  List<Object?> get props => [username, password, rol];
}
