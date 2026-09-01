import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/repositories/supervisor_repository.dart';

class GetRegistrosSupervisorParams {
  final DateTime fecha;
  final String? turno;
  const GetRegistrosSupervisorParams({required this.fecha, this.turno});
}

class GetRegistrosSupervisorUseCase {
  final SupervisorRepository _repository;
  const GetRegistrosSupervisorUseCase(this._repository);

  Future<Either<Failure, List<RegistroDiario>>> call(
      GetRegistrosSupervisorParams params) {
    return _repository.getRegistros(
      fecha: params.fecha,
      turno: params.turno,
    );
  }
}
