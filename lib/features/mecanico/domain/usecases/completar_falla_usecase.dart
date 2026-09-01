import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/repositories/mecanico_repository.dart';

class CompletarFallaUseCase implements UseCase<void, CompletarFallaParams> {
  final MecanicoRepository _repository;
  const CompletarFallaUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(CompletarFallaParams params) =>
      _repository.completarFalla(params);
}
