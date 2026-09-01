import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

abstract class SupervisorRepository {
  Future<Either<Failure, List<RegistroDiario>>> getRegistros({
    required DateTime fecha,
    String? turno,
  });

  Future<Either<Failure, void>> aprobarRegistro(AprobarRegistroParams params);
}
