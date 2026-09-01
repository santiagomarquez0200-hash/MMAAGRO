class AppConstants {
  AppConstants._();

  static const String appName = 'AgriControl';
  static const String dbName = 'agricontrol.db';
  static const int dbVersion = 1;

  // API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.agricontrol.com/v1',
  );
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;

  // Auth
  static const String tokenKey = 'auth_token';
  static const String deviceIdKey = 'device_id';
  static const String userKey = 'current_user';
  static const String perfilCodigoKey = 'perfil_codigo_usuario';
  static const String loginUsuarioKey = 'login_usuario';
  static const String sessionTokenKey = 'session_token';
  static const String lastActivityKey = 'last_activity_at';

  // Outbox
  static const int maxRetries = 3;
  static const int syncIntervalSeconds = 30;

  // Roles
  static const String rolOperador = 'operador';
  static const String rolSupervisor = 'supervisor';
  static const String rolGerente = 'gerente';

  // Estados registro
  static const String estadoBorrador = 'borrador';
  static const String estadoCompletado = 'completado';
  static const String estadoAprobado = 'aprobado';
  static const String estadoRechazado = 'rechazado';

  // Turnos
  static const String turnoDia = 'dia';
  static const String turnoNoche = 'noche';

  // Checklist
  static const String checkBien = 'bien';
  static const String checkMal = 'mal';
  static const String checkNa = 'na';

  // Outbox status
  static const String outboxPending = 'pending';
  static const String outboxSyncing = 'syncing';
  static const String outboxDone = 'done';
  static const String outboxFailed = 'failed';
}
