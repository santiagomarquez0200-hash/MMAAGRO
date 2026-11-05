import 'package:equatable/equatable.dart';

/// UNA MAQUINA ASIGNADA AL TRACTORISTA PARA HOY.
///
/// Contesta las cuatro preguntas que tiene al llegar: QUE MAQUINA me toca, QUE
/// trabajo hago, DONDE, y A QUE HORA me la entregan. Viene del SP
/// CLI547_AGMSP_MMA_OPERADOR_MI_DIA.
///
/// Modalidad, marcha, presion y mojamiento son de la orden de trabajo de
/// Sanidad, no de este modulo: si la linea se cargo a mano no hay OT y esos
/// campos vienen vacios. La asignacion sigue siendo valida, solo que sin el
/// detalle de aplicacion.
class AsignacionDia extends Equatable {
  final String idProgramacion;
  final DateTime fecha;
  final String turno;

  // ── Que maquina ─────────────────────────────────────────────────────────
  final int? idImplemento;
  final String implemento;
  final String? descripcionImplemento;
  final String? marca;
  final String? modelo;
  final String? tipologia;
  final int? idTractor;
  final String? tractor;

  // ── A que hora ──────────────────────────────────────────────────────────
  final String? horaPrevista;

  /// Si ya salio, la hora real. Verlas juntas le dice si llego a tiempo o si
  /// la maquina todavia no paso por garita.
  final String? horaSalida;
  final String estado;

  // ── Que trabajo ─────────────────────────────────────────────────────────
  final String? actividad;
  final String? cultivo;
  final String? area;

  // ── Donde ───────────────────────────────────────────────────────────────
  final String? sublote;
  final double? hectareas;
  final String? nroOt;

  // ── Como (de la orden de Sanidad) ───────────────────────────────────────
  final String? modalidad;
  final String? marcha;
  final String? presion;
  final String? mojamiento;
  final String? observacionOrden;

  // ── Quien lo pidio ──────────────────────────────────────────────────────
  final String? solicitud;
  final String? solicitante;
  final String? observacion;

  const AsignacionDia({
    required this.idProgramacion,
    required this.fecha,
    required this.turno,
    this.idImplemento,
    required this.implemento,
    this.descripcionImplemento,
    this.marca,
    this.modelo,
    this.tipologia,
    this.idTractor,
    this.tractor,
    this.horaPrevista,
    this.horaSalida,
    required this.estado,
    this.actividad,
    this.cultivo,
    this.area,
    this.sublote,
    this.hectareas,
    this.nroOt,
    this.modalidad,
    this.marcha,
    this.presion,
    this.mojamiento,
    this.observacionOrden,
    this.solicitud,
    this.solicitante,
    this.observacion,
  });

  bool get yaSalio => estado == 'ENTREGADA';

  /// true cuando la linea vino de una orden de trabajo y hay detalle de
  /// aplicacion que mostrar.
  bool get tieneDetalleAplicacion =>
      (modalidad ?? '').isNotEmpty ||
      (marcha ?? '').isNotEmpty ||
      (presion ?? '').isNotEmpty ||
      (mojamiento ?? '').isNotEmpty;

  String get detalleMaquina {
    final partes = <String>[
      if ((marca ?? '').trim().isNotEmpty) marca!.trim(),
      if ((modelo ?? '').trim().isNotEmpty) modelo!.trim(),
    ];
    if (partes.isNotEmpty) return partes.join(' · ');
    final desc = (descripcionImplemento ?? '').trim();
    return desc.isNotEmpty ? desc : (tipologia ?? '').trim();
  }

  @override
  List<Object?> get props => [idProgramacion, estado, horaSalida];
}
