import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/mi_dia_repository.dart';

class GetMiDiaParams extends Equatable {
  final int? idTrabajador;
  final int? idUsuario;
  final DateTime fecha;

  const GetMiDiaParams({
    this.idTrabajador,
    this.idUsuario,
    required this.fecha,
  });

  @override
  List<Object?> get props => [idTrabajador, idUsuario, fecha];
}

class GetMiDiaUseCase implements UseCase<MiDia, GetMiDiaParams> {
  final MiDiaRepository _repository;
  const GetMiDiaUseCase(this._repository);

  @override
  Future<Either<Failure, MiDia>> call(GetMiDiaParams params) =>
      _repository.getMiDia(
        idTrabajador: params.idTrabajador,
        idUsuario: params.idUsuario,
        fecha: params.fecha,
      );
}
