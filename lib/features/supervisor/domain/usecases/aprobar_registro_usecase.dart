import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

class AprobarRegistroUseCase
    implements UseCase<RegistroDiario, AprobarRegistroParams> {
  final RegistroRepository _repository;
  const AprobarRegistroUseCase(this._repository);

  @override
  Future<Either<Failure, RegistroDiario>> call(AprobarRegistroParams params) {
    return _repository.aprobarRegistro(params);
  }
}
