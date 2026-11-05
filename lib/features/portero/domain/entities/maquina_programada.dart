import 'package:equatable/equatable.dart';

/// Una maquina que DEBE SALIR por garita en una fecha y turno.
///
/// Hasta ahora el portero solo registraba lo que pasaba: podia decir "salio la
/// FAG-03", pero no "la FAG-03 tenia que salir". Esta entidad es la otra mitad
/// — el programa de entrega contra el cual compara — y viene del SP
/// CLI547_AGMSP_MMA_GARITA_TURNO.
class MaquinaProgramada extends Equatable {
  final String idProgramacion;
  final DateTime fecha;
  final String turno; // 'DIA' | 'NOCHE'

  // ── Que maquina buscar ──────────────────────────────────────────────────
  /// El codigo es lo que el portero lee del fierro; descripcion y marca estan
  /// para confirmar que es la correcta cuando dos se parecen.
  final int? idImplemento;
  final String implemento;
  final String? descripcionImplemento;
  final String? identificacion;
  final String? marca;
  final String? modelo;
  final String? tipologia;
  final int? idTractor;
  final String? tractor;

  // ── Quien se la lleva ───────────────────────────────────────────────────
  final int? idOperador;
  final String? operador;

  /// Sin operador el portero no tiene a quien entregarsela. Lo marca el SP
  /// para que la fila se destaque en vez de mostrar un guion mas.
  final bool sinOperador;

  // ── Cuando ──────────────────────────────────────────────────────────────
  final String? horaPrevista;
  final String? horaSalida;
  final String? puntoSalida;
  final double? horometro;

  // ── En que estado esta ──────────────────────────────────────────────────
  final String estado;
  final bool yaSalio;
  final String? motivoIncumplimiento;

  // ── Para que / de quien ─────────────────────────────────────────────────
  /// Contexto para discutir en la garita sin llamar a nadie.
  final String? actividad;
  final String? cultivo;
  final String? area;
  final String? sublote;
  final String? solicitud;
  final String? solicitante;
  final String? observacion;

  const MaquinaProgramada({
    required this.idProgramacion,
    required this.fecha,
    required this.turno,
    this.idImplemento,
    required this.implemento,
    this.descripcionImplemento,
    this.identificacion,
    this.marca,
    this.modelo,
    this.tipologia,
    this.idTractor,
    this.tractor,
    this.idOperador,
    this.operador,
    required this.sinOperador,
    this.horaPrevista,
    this.horaSalida,
    this.puntoSalida,
    this.horometro,
    required this.estado,
    required this.yaSalio,
    this.motivoIncumplimiento,
    this.actividad,
    this.cultivo,
    this.area,
    this.sublote,
    this.solicitud,
    this.solicitante,
    this.observacion,
  });

  bool get estaPendiente => !yaSalio;

  /// Lo que se muestra como identificacion secundaria de la maquina. Se arma
  /// aca y no en la pantalla para que el detalle y la lista digan lo mismo.
  String get detalleMaquina {
    final partes = <String>[
      if ((marca ?? '').trim().isNotEmpty) marca!.trim(),
      if ((modelo ?? '').trim().isNotEmpty) modelo!.trim(),
    ];
    if (partes.isNotEmpty) return partes.join(' · ');
    final desc = (descripcionImplemento ?? '').trim();
    return desc.isNotEmpty ? desc : (tipologia ?? '').trim();
  }

  /// Texto contra el que filtra el buscador de la pantalla. Incluye operador y
  /// sublote porque en garita tambien preguntan por el nombre del tractorista.
  String get textoBusqueda => [
        implemento,
        identificacion ?? '',
        tractor ?? '',
        operador ?? '',
        tipologia ?? '',
        area ?? '',
        cultivo ?? '',
        sublote ?? '',
        actividad ?? '',
      ].join(' ').toUpperCase();

  @override
  List<Object?> get props => [idProgramacion, estado, yaSalio, horaSalida];
}
