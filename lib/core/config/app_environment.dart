import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de entornos: ERP SQL Server (via REST proxy Agrokasa).
///
/// Las credenciales se cargan desde el archivo .env (flutter_dotenv).
/// El archivo .env NO debe ser versionado — usa .env.example como plantilla.
///
/// NOTA: Todos los SPs están bajo el esquema dbo con el prefijo CLI547_AGMSP_MMA_.
/// Todas las llamadas van a través del proxy REST → /EjecutarSPERP.
class AppEnvironment {
  // ─── URL override en tiempo de ejecución (SharedPreferences) ─────────────
  static String? _urlOverride;
  static void setUrlOverride(String? url) => _urlOverride = url;

  // ─── ERP SQL Server (proxy REST Agrokasa) ─────────────────────────────────

  static const String urlPruebas =
      'https://agkwebagro.agrokasa.pe/WSRESTMovilidadERPPruebas/api';
  static const String urlProduccion =
      'https://agkwebagro.agrokasa.pe/WSRESTMovilidadERP/api';

  static String get erpBaseUrl =>
      _urlOverride ?? dotenv.get('ERP_BASE_URL', fallback: urlPruebas);

  static String get erpUsername => dotenv.get('ERP_USERNAME', fallback: '');

  static String get erpPassword => dotenv.get('ERP_PASSWORD', fallback: '');

  // ─── Endpoints ERP ────────────────────────────────────────────────────────

  static const String erpAuthEndpoint = '/login/authenticate';
  static const String erpSpEndpoint = '/EjecutarSPERP';

  // ─── SPs activos — catálogos ──────────────────────────────────────────────

  /// Descarga catálogos completos al sincronizar (procesos, cultivos, tractores, etc.)
  static const String spSyncPayloadCompleto =
      'dbo.CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO';

  /// Perfil profesional del usuario autenticado
  static const String spGetPerfilProfesional =
      'dbo.CLI547_AGMSP_MMA_GetPerfilProfesional';

  // ─── SPs activos — operaciones de turno ───────────────────────────────────

  /// SP principal del outbox offline — recibe JSON con tipo de operación.
  /// Maneja: crear_registro, checklist, bins, cerrar_turno (vehículo y tractor).
  static const String spSincronizarOffline =
      'dbo.CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE';

  static const String spRegistrarBin = 'dbo.CLI547_AGMSP_MMA_REGISTRAR_BIN';

  static const String spRegistrarParo = 'dbo.CLI547_AGMSP_MMA_REGISTRAR_PARO';

  static const String spGuardarChecklist =
      'dbo.CLI547_AGMSP_MMA_GUARDAR_CHECKLIST';

  static const String spCerrarTurno = 'dbo.CLI547_AGMSP_MMA_CERRAR_TURNO';

  static const String spAprobarRegistro =
      'dbo.CLI547_AGMSP_MMA_APROBAR_REGISTRO';

  // ─── SPs activos — jornada ───────────────────────────────────────────────

  static const String spActualizarStatusJornada =
      'dbo.CLI547_AGMSP_MMA_ACTUALIZAR_STATUS_JORNADA';

  static const String spRegistrarLecturaPortero =
      'dbo.CLI547_AGMSP_MMA_REGISTRAR_LECTURA_PORTERO';

  /// Programa de entrega del turno: lo que DEBE SALIR por garita.
  /// Es la contraparte de REGISTRAR_LECTURA_PORTERO, que solo escribe.
  static const String spGaritaTurno = 'dbo.CLI547_AGMSP_MMA_GARITA_TURNO';

  /// El dia del tractorista: que maquina, que labor, donde y a que hora.
  static const String spOperadorMiDia =
      'dbo.CLI547_AGMSP_MMA_OPERADOR_MI_DIA';

  // ─── SPs activos — supervisor ────────────────────────────────────────────

  static const String spGetRegistrosSupervisor =
      'dbo.CLI547_AGMSP_MMA_GET_REGISTROS_SUPERVISOR';

  static const String spGetJornadasSupervisor =
      'dbo.CLI547_AGMSP_MMA_GET_JORNADAS_SUPERVISOR';

  // ─── SPs activos — mecánico ──────────────────────────────────────────────

  static const String spGetParosMecanico =
      'dbo.CLI547_AGMSP_MMA_GET_PAROS_MECANICO';

  static const String spCompletarFallaMecanica =
      'dbo.CLI547_AGMSP_MMA_COMPLETAR_FALLA_MECANICA';

  // ─── SPs inactivos / comentados ──────────────────────────────────────────
  // Los siguientes SPs no están en uso actualmente. Se mantienen comentados
  // para referencia histórica. No eliminar sin revisar primero.

  // spCrearRegistro — legado. Fue reemplazado por SINCRONIZAR_OFFLINE.
  // El flujo de creación va: SQLite → outbox → SINCRONIZAR_OFFLINE.
  // static const String spCrearRegistro = 'dbo.SP_MMA_CREAR_REGISTRO';

  // spRegistrarJornada —  no está en la lista de SPs activos del servidor.
  // Verificar si fue eliminado o absorbido por SINCRONIZAR_OFFLINE.
  // Referenciado en sync_manager.dart — revisar antes de eliminar.
  // static const String spRegistrarJornada = 'dbo.SP_MMA_REGISTRAR_JORNADA';

  // spRegistrarFoto — stub. La cámara no está implementada en el APK.
  // static const String spRegistrarFoto = 'dbo.SP_MMA_REGISTRAR_FOTO';

  // spRegistrarAuditLog — declarado pero nunca llamado.
  // static const String spRegistrarAuditLog = 'dbo.SP_MMA_REGISTRAR_AUDIT_LOG';

  // spGetMenusPorRol — declarado pero nunca llamado (menús vienen en sync payload).
  // static const String spGetMenusPorRol = 'dbo.SP_MMA_GET_MENUS_POR_ROL';

  // spGetSubprocesos — declarado pero nunca llamado (subprocesos vienen en sync payload).
  // static const String spGetSubprocesos = 'dbo.SP_MMA_ERP_GET_SUBPROCESOS';

  // spCrearRegistroVehiculo — no está en la lista de SPs activos.
  // El registro de vehículo también va por SINCRONIZAR_OFFLINE con tipo_registro='vehiculo'.
  // static const String spCrearRegistroVehiculo = 'dbo.SP_MMA_CREAR_REGISTRO_VEHICULO';

  // spGetReporteSupervisor — declarado pero nunca llamado.
  // static const String spGetReporteSupervisor = 'dbo.SP_MMA_GET_REPORTE_SUPERVISOR';

  // spEnviarNotificacion — declarado pero nunca llamado.
  // static const String spEnviarNotificacion = 'dbo.SP_MMA_ENVIAR_NOTIFICACION';

  // ─── Secure Storage Keys ──────────────────────────────────────────────────

  static const String erpTokenKey = 'erp_token';
  static const String erpTokenExpiryKey = 'erp_token_expiry';

  // ─── Timeouts ─────────────────────────────────────────────────────────────

  static const Duration erpConnectTimeout = Duration(seconds: 30);
  static const Duration erpReceiveTimeout = Duration(seconds: 120);
  static const Duration erpTokenTtl = Duration(hours: 8);

  // ─── Outbox / Sincronización ──────────────────────────────────────────────

  /// Reintentos del outbox: infinitos (sin límite de conteo).
  /// permanently_failed se usa SOLO para SpValidationException (error de negocio
  /// determinista). En startup, SyncManager resetea permanently_failed → failed.
}
