import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/asignacion_dia.dart';

abstract class MiDiaRepository {
  /// Las maquinas asignadas al operador para una fecha.
  ///
  /// Se acepta cualquiera de los dos identificadores del ERP y el SP resuelve:
  /// la programacion guarda el de Trabajadores, asi que ese es el camino
  /// directo; el de Usuarios queda como respaldo.
  ///
  /// Si no hay red devuelve lo ultimo que se bajo para esa fecha.
  Future<Either<Failure, MiDia>> getMiDia({
    int? idTrabajador,
    int? idUsuario,
    required DateTime fecha,
  });
}

class MiDia {
  final List<AsignacionDia> asignaciones;

  /// true cuando la lista vino de SQLite por falta de red. La pantalla lo
  /// avisa: una asignacion vieja sin aviso manda al tractorista al lote
  /// equivocado.
  final bool desdeCache;
  final DateTime? sincronizadoAt;

  const MiDia({
    required this.asignaciones,
    this.desdeCache = false,
    this.sincronizadoAt,
  });

  bool get vacio => asignaciones.isEmpty;
}
