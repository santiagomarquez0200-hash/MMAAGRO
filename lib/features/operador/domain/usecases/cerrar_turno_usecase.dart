import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

class CerrarTurnoUseCase
    implements UseCase<RegistroDiario, CerrarTurnoParams> {
  final RegistroRepository _repository;
  const CerrarTurnoUseCase(this._repository);

  @override
  Future<Either<Failure, RegistroDiario>> call(CerrarTurnoParams params) {
    return _repository.cerrarTurno(params);
  }
}
