import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/repositories/mecanico_repository.dart';

class GetParosMecanicoParams extends Equatable {
  final DateTime fecha;
  final String? estado;

  const GetParosMecanicoParams({required this.fecha, this.estado});

  @override
  List<Object?> get props => [fecha, estado];
}

class GetParosMecanicoUseCase implements UseCase<List<ParoMecanico>, GetParosMecanicoParams> {
  final MecanicoRepository _repository;
  const GetParosMecanicoUseCase(this._repository);

  @override
  Future<Either<Failure, List<ParoMecanico>>> call(GetParosMecanicoParams params) =>
      _repository.getParosMecanico(fecha: params.fecha, estado: params.estado);
}
