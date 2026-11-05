import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/portero/domain/repositories/portero_programa_repository.dart';

class GetProgramaTurnoParams extends Equatable {
  final DateTime fecha;

  /// Nulo trae los dos turnos del dia.
  final String? turno;

  const GetProgramaTurnoParams({required this.fecha, this.turno});

  @override
  List<Object?> get props => [fecha, turno];
}

class GetProgramaTurnoUseCase
    implements UseCase<ProgramaTurno, GetProgramaTurnoParams> {
  final PorteroProgramaRepository _repository;
  const GetProgramaTurnoUseCase(this._repository);

  @override
  Future<Either<Failure, ProgramaTurno>> call(GetProgramaTurnoParams params) =>
      _repository.getProgramaTurno(fecha: params.fecha, turno: params.turno);
}
