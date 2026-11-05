import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/portero/domain/entities/maquina_programada.dart';

abstract class PorteroProgramaRepository {
  /// El programa de entrega de una fecha y turno.
  ///
  /// [turno] nulo trae los dos del dia: el portero de la mañana necesita ver
  /// lo suyo y tambien lo que quedo de la noche anterior sin salir.
  ///
  /// Si no hay red devuelve lo ultimo que se bajo para esa fecha. La garita es
  /// el peor punto de señal de la empresa: quedarse sin lista por eso seria
  /// dejar al portero sin con que trabajar.
  Future<Either<Failure, ProgramaTurno>> getProgramaTurno({
    required DateTime fecha,
    String? turno,
  });
}

/// El programa mas el dato de si salio del servidor o de la cache local.
class ProgramaTurno {
  final List<MaquinaProgramada> maquinas;

  /// true cuando la lista vino de SQLite por falta de red. La pantalla lo
  /// avisa: una lista vieja sin aviso es peor que no tener lista.
  final bool desdeCache;

  /// Cuando se bajo del servidor por ultima vez.
  final DateTime? sincronizadoAt;

  const ProgramaTurno({
    required this.maquinas,
    this.desdeCache = false,
    this.sincronizadoAt,
  });

  int get total => maquinas.length;
  int get pendientes => maquinas.where((m) => m.estaPendiente).length;
  int get salidas => maquinas.where((m) => m.yaSalio).length;
  int get sinOperador =>
      maquinas.where((m) => m.sinOperador && m.estaPendiente).length;
}
