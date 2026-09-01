import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

class RegistrarBinUseCase implements UseCase<void, RegistrarBinParams> {
  final RegistroRepository _repository;
  const RegistrarBinUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(RegistrarBinParams params) {
    return _repository.registrarBin(params);
  }
}
