import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

class CrearRegistroUseCase
    implements UseCase<RegistroDiario, CrearRegistroParams> {
  final RegistroRepository _repository;
  const CrearRegistroUseCase(this._repository);

  @override
  Future<Either<Failure, RegistroDiario>> call(CrearRegistroParams params) {
    return _repository.crearRegistro(params);
  }
}
