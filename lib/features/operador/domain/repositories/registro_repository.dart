import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';

abstract class RegistroRepository {
  Future<Either<Failure, RegistroDiario>> crearRegistro(
      CrearRegistroParams params);
  Future<Either<Failure, RegistroDiario>> actualizarRegistroBasico(
      String registroId, CrearRegistroParams params);
  Future<Either<Failure, void>> eliminarRegistro(String registroId);
  Future<Either<Failure, RegistroDiario>> getRegistro(String id);

  /// [operadorIdErp] filtra por ID entero del operador en ERP.
  /// [fechaDesde] opcional: oculta registros anteriores a esa fecha (útil en home).
  Stream<List<RegistroDiario>> watchRegistros({
    int? operadorIdErp,
    DateTime? fechaDesde,
  });

  Future<Either<Failure, List<RegistroDiario>>> getRegistros({
    int? operadorIdErp,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
  });

  Future<Either<Failure, RegistroDiario>> cerrarTurno(CerrarTurnoParams params);
  Future<Either<Failure, RegistroDiario>> aprobarRegistro(
      AprobarRegistroParams params);

  Future<Either<Failure, List<ChecklistResultado>>> getChecklist(
      String registroId);
  Future<Either<Failure, void>> guardarChecklist(
      String registroId, List<ChecklistResultadoInput> resultados);

  Future<Either<Failure, ParoEquipo>> agregarParo(AgregarParoParams params);
  Future<Either<Failure, void>> eliminarParo(String paroId);

  Future<Either<Failure, void>> registrarBin(RegistrarBinParams params);
  Future<Either<Failure, void>> registrarJornada(
      String registroId, String tipo); // 'inicio' | 'fin'
  Future<Either<Failure, void>> guardarSectores(
      String registroId, List<RegistroSectorInput> sectores);

  Future<Either<Failure, int>> getPendientesSincronizacion();
  Stream<int> watchPendientesSincronizacion();

  /// Vuelca un RegistroDiario descargado del SP a las tablas SQLite locales.
  /// Usado en admin mode para que las páginas de edición puedan leer desde SQLite.
  Future<Either<Failure, void>> upsertRegistroFromRemote(RegistroDiario registro);

  /// Construye el payload consolidado desde SQLite y lo sube directamente al servidor
  /// vía SINCRONIZAR_OFFLINE (admin edit re-sync sin outbox).
  /// Retorna el mensaje real del SP en el [Right] para mostrarlo en la UI.
  Future<Either<Failure, String>> resyncAdminEdit(String registroId);

  /// Llama a CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE directamente con el payload dado.
  /// No usa outbox. Retorna el mensaje real del SP en el [Right] para mostrarlo en la UI.
  Future<Either<Failure, String>> actualizarRegistroDirecto(
      Map<String, dynamic> payload);

  /// Construye el payload completo desde SQLite y lo envía directamente al SP.
  /// Equivalente a resyncAdminEdit pero expuesto para que las páginas lo llamen.
  /// Retorna el mensaje real del SP en el [Right] para mostrarlo en la UI.
  Future<Either<Failure, String>> syncRegistroDirecto(String registroId);
}

// ─── Params ───────────────────────────────────────────────────────────────────

class CrearRegistroParams {
  final DateTime fecha;
  final String turno;

  // Proceso (PostgreSQL)
  final int procesoId;
  final String procesoNombre;
  final String procesoCodigo;

  // Subproceso (MMA v3, opcional)
  final int? subprocesoId;
  final String? subprocesoNombre;

  // Cultivo (ERP)
  final int cultivoIdErp;
  final String cultivoNombreEspecie;
  final String cultivoCodigoEspecie;

  // Operador (ERP)
  final int operadorIdErp;
  final String operadorCodigo;
  final String operadorNombre;

  // Supervisor (ERP, opcional)
  final int? supervisorIdErp;
  final String? supervisorCodigo;
  final String? supervisorNombre;

  // Tractor (ERP)
  final int tractorIdErp;
  final String tractorCodigo;
  final String tractorDescripcion;

  // Implemento (ERP, opcional)
  final int? implementoIdErp;
  final String? implementoCodigo;
  final String? implementoDescripcion;

  // Caja de cambios (PostgreSQL, opcional)
  final int? cajaCambiosId;
  final String? cajaCambiosNombre;

  final double? tractorInicio;
  final double? implementoInicio;
  final String? horaSalidaTaller;
  final String? horaLlegadaPunto;
  final String dispositivoId;

  /// ID ERP del usuario que crea el registro (puede ser el supervisor o el propio operador).
  final int createdByErp;

  /// Sub-labores seleccionadas en el formulario (para procesos que requieren sublabores).
  final List<String> sublaboresSeleccionadas;

  const CrearRegistroParams({
    required this.fecha,
    required this.turno,
    required this.procesoId,
    required this.procesoNombre,
    required this.procesoCodigo,
    this.subprocesoId,
    this.subprocesoNombre,
    required this.cultivoIdErp,
    required this.cultivoNombreEspecie,
    required this.cultivoCodigoEspecie,
    required this.operadorIdErp,
    required this.operadorCodigo,
    required this.operadorNombre,
    this.supervisorIdErp,
    this.supervisorCodigo,
    this.supervisorNombre,
    required this.tractorIdErp,
    required this.tractorCodigo,
    required this.tractorDescripcion,
    this.implementoIdErp,
    this.implementoCodigo,
    this.implementoDescripcion,
    this.cajaCambiosId,
    this.cajaCambiosNombre,
    this.tractorInicio,
    this.implementoInicio,
    this.horaSalidaTaller,
    this.horaLlegadaPunto,
    required this.dispositivoId,
    required this.createdByErp,
    this.sublaboresSeleccionadas = const [],
  });
}

class CerrarTurnoParams {
  final String registroId;
  final double? tractorFinal;
  final double? implementoFinal;
  final String? horaSalidaPunto;
  final String? horaLlegadaTaller;
  final String? horaRefrigerio;
  final String? observacionesMaq;
  final String? lotesJson;
  /// JSON array de sublabores: [{"sublabor_nombre":"..."}]
  final String? sublaboresJson;
  /// Firma digital del operador codificada en base64 (PNG).
  final String? firmaOperador;

  const CerrarTurnoParams({
    required this.registroId,
    this.tractorFinal,
    this.implementoFinal,
    this.horaSalidaPunto,
    this.horaLlegadaTaller,
    this.horaRefrigerio,
    this.observacionesMaq,
    this.lotesJson,
    this.sublaboresJson,
    this.firmaOperador,
  });
}

class AprobarRegistroParams {
  final String registroId;
  final int supervisorIdErp;
  final String accion; // 'aprobar' | 'rechazar'
  final String? motivo;

  const AprobarRegistroParams({
    required this.registroId,
    required this.supervisorIdErp,
    required this.accion,
    this.motivo,
  });
}

class AgregarParoParams {
  final String registroId;
  final int tipoParoId;
  final String tipoParoCodigo;
  final String tipoParoNombre;
  final String? motivo;
  final String? equipo;
  final String horaInicio;
  final String? horaFinal;
  final double? galones;
  final int? fallaMecanicaId;
  final String? fallaMecanicaNombre;

  const AgregarParoParams({
    required this.registroId,
    required this.tipoParoId,
    required this.tipoParoCodigo,
    required this.tipoParoNombre,
    this.motivo,
    this.equipo,
    required this.horaInicio,
    this.horaFinal,
    this.galones,
    this.fallaMecanicaId,
    this.fallaMecanicaNombre,
  });
}

class RegistrarBinParams {
  final String registroId;
  final String franjaHoraria;
  final String turno;
  final int cantidad;

  const RegistrarBinParams({
    required this.registroId,
    required this.franjaHoraria,
    required this.turno,
    required this.cantidad,
  });
}

class ChecklistResultadoInput {
  final int itemId;
  final String itemNombre;
  final String categoriaNombre;
  final String resultado;
  final String? observacion;
  final String? fotoUrl;

  const ChecklistResultadoInput({
    required this.itemId,
    required this.itemNombre,
    required this.categoriaNombre,
    required this.resultado,
    this.observacion,
    this.fotoUrl,
  });
}

class RegistroSectorInput {
  final int loteIdErp;
  final String loteCodigo;
  final String loteNombre;
  final String fincaNombre;
  final double? areaTrabajada;
  final String? observacion;

  const RegistroSectorInput({
    required this.loteIdErp,
    required this.loteCodigo,
    required this.loteNombre,
    required this.fincaNombre,
    this.areaTrabajada,
    this.observacion,
  });
}
