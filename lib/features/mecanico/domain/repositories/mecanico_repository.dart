import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';

abstract class MecanicoRepository {
  Future<Either<Failure, List<ParoMecanico>>> getParosMecanico({
    required DateTime fecha,
    String? estado,
  });

  Future<Either<Failure, void>> completarFalla(CompletarFallaParams params);
}

class CompletarFallaParams {
  final String paroId;
  final String horaInicioReal;
  final String horaFinReal;
  final int mecanicoIdErp;
  final String trabajoRealizado;
  final String estadoFalla; // 'resuelto' | 'en_proceso'
  final String? mecanicoNombre;

  const CompletarFallaParams({
    required this.paroId,
    required this.horaInicioReal,
    required this.horaFinReal,
    required this.mecanicoIdErp,
    required this.trabajoRealizado,
    this.estadoFalla = 'resuelto',
    this.mecanicoNombre,
  });
}
