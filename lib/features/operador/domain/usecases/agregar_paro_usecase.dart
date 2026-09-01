import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

class AgregarParoUseCase implements UseCase<ParoEquipo, AgregarParoParams> {
  final RegistroRepository _repository;
  const AgregarParoUseCase(this._repository);

  @override
  Future<Either<Failure, ParoEquipo>> call(AgregarParoParams params) {
    return _repository.agregarParo(params);
  }
}
