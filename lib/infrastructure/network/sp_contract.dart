import 'dart:convert';
import 'dart:developer' as developer;

/// Tipos de parámetros soportados por los Stored Procedures
enum SpParamType {
  uuid, // UNIQUEIDENTIFIER
  string, // VARCHAR / NVARCHAR
  integer, // INT / SMALLINT
  decimal, // DECIMAL / FLOAT
  bit, // BIT (booleano)
  dateString, // DATE (yyyy-MM-dd)
  timeString, // TIME (HH:mm)
  jsonString, // NVARCHAR(MAX) con JSON
}

/// Definición de un parámetro individual del SP
class SpParamDef {
  final String hint; // Nombre del parámetro (incluye @)
  final SpParamType type;
  final bool nullable;

  const SpParamDef(
    this.hint,
    this.type, {
    this.nullable = false,
  });

  /// Nombre del parámetro sin el símbolo '@'
  String get cleanName => hint.startsWith('@') ? hint.substring(1) : hint;

  @override
  String toString() => '$hint(${type.name}, nullable:$nullable)';
}

/// Contrato completo de un Stored Procedure
/// Define los parámetros de entrada, salida y el formato de GUID específico
class SpContract {
  final String spName;
  final List<SpParamDef> inputParams;
  final List<SpParamDef> outputParams;

  /// Formato GUID específico para este SP
  /// Opciones:
  ///   - 'no_braces_with_hyphens': 8526F050-4F84-48ED-9A69-15D21539D690 (DEFAULT)
  ///   - 'with_braces_and_hyphens': {8526F050-4F84-48ED-9A69-15D21539D690}
  ///   - 'with_braces_no_hyphens': {8526F0504F8448ED9A6915D21539D690}
  ///   - 'no_braces_no_hyphens': 8526F0504F8448ED9A6915D21539D690
  final String? guidFormat;

  const SpContract({
    required this.spName,
    this.inputParams = const [],
    this.outputParams = const [],
    this.guidFormat,
  });

  List<SpParamDef> get allParams => [...inputParams, ...outputParams];
  int get inputCount => inputParams.length;
  int get outputCount => outputParams.length;
}

/// Excepción lanzada cuando falla la validación de un SP
class SpValidationException implements Exception {
  final String message;

  const SpValidationException(this.message);

  @override
  String toString() => '[SpValidation] $message';
}

/// Registro central de todos los SPs con sus contratos
class SpRegistry {
  SpRegistry._();

  // ─── Nombres de SPs activos ───────────────────────────────────────────────
  static const _syncPayload             = 'dbo.CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO';
  static const _getPerfilProfesional    = 'dbo.CLI547_AGMSP_MMA_GetPerfilProfesional';
  static const _sincronizarOffline      = 'dbo.CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE';
  static const _registrarBin            = 'dbo.CLI547_AGMSP_MMA_REGISTRAR_BIN';
  static const _registrarParo           = 'dbo.CLI547_AGMSP_MMA_REGISTRAR_PARO';
  static const _guardarChecklist        = 'dbo.CLI547_AGMSP_MMA_GUARDAR_CHECKLIST';
  static const _cerrarTurno             = 'dbo.CLI547_AGMSP_MMA_CERRAR_TURNO';
  static const _aprobarRegistro         = 'dbo.CLI547_AGMSP_MMA_APROBAR_REGISTRO';
  static const _actualizarStatusJornada = 'dbo.CLI547_AGMSP_MMA_ACTUALIZAR_STATUS_JORNADA';
  static const _registrarLecturaPortero = 'dbo.CLI547_AGMSP_MMA_REGISTRAR_LECTURA_PORTERO';
  static const _getRegistrosSupervisor  = 'dbo.CLI547_AGMSP_MMA_GET_REGISTROS_SUPERVISOR';
  static const _getJornadasSupervisor   = 'dbo.CLI547_AGMSP_MMA_GET_JORNADAS_SUPERVISOR';
  static const _getParosMecanico        = 'dbo.CLI547_AGMSP_MMA_GET_PAROS_MECANICO';
  static const _completarFallaMecanica  = 'dbo.CLI547_AGMSP_MMA_COMPLETAR_FALLA_MECANICA';
  static const _registrarPuntosGps      = 'dbo.CLI547_AGMSP_MMA_REGISTRAR_PUNTOS_GPS';
  static const _obtenerNavegacion       = 'dbo.CLI547_AGMSP_Obtener_Navegacion';

  /// Expone el nombre del SP de navegación para uso externo (auth repository).
  static String get spObtenerNavegacion => _obtenerNavegacion;

  // ─── SPs inactivos (no están en la lista de SPs del servidor) ─────────────
  // static const _crearRegistro        = 'dbo.SP_MMA_CREAR_REGISTRO';         // legado — reemplazado por SINCRONIZAR_OFFLINE
  // static const _registrarJornada     = 'dbo.SP_MMA_REGISTRAR_JORNADA';      // ⚠️ no está en lista activa — verificar
  // static const _crearRegistroVehiculo= 'dbo.SP_MMA_CREAR_REGISTRO_VEHICULO'; // no en lista activa
  // static const _getReporteSupervisor = 'dbo.SP_MMA_GET_REPORTE_SUPERVISOR';  // nunca llamado
  // static const _enviarNotificacion   = 'dbo.SP_MMA_ENVIAR_NOTIFICACION';     // nunca llamado
  // static const _getSubprocesos       = 'dbo.SP_MMA_ERP_GET_SUBPROCESOS';     // nunca llamado

  // Registro de contratos — solo SPs activos
  static const Map<String, SpContract> _registry = {
    _syncPayload: SpContract(
      spName: _syncPayload,
    ),
    _getPerfilProfesional: SpContract(
      spName: _getPerfilProfesional,
      inputParams: [
        SpParamDef('@UsuarioCodigo', SpParamType.string),
      ],
    ),
    _sincronizarOffline: SpContract(
      spName: _sincronizarOffline,
      inputParams: [
        SpParamDef('@p_payload', SpParamType.jsonString),
      ],
      outputParams: [
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
        SpParamDef('@p_registro_id', SpParamType.uuid),
        SpParamDef('@p_ya_existia', SpParamType.bit),
      ],
    ),
    // _crearRegistro — comentado: legado, reemplazado por SINCRONIZAR_OFFLINE
    _registrarBin: SpContract(
      spName: _registrarBin,
      guidFormat: 'no_braces_with_hyphens',
      inputParams: [
        SpParamDef('@p_registro_id', SpParamType.uuid, nullable: true),
        SpParamDef('@p_numero_registro', SpParamType.string, nullable: true), // NUEVO
        SpParamDef('@p_franja_horaria', SpParamType.string),
        SpParamDef('@p_turno_franja', SpParamType.string),
        SpParamDef('@p_cantidad', SpParamType.integer),
      ],
      outputParams: [
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
      ],
    ),
    _registrarParo: SpContract(
      spName: _registrarParo,
      guidFormat: 'no_braces_with_hyphens',
      inputParams: [
        SpParamDef('@p_registro_id', SpParamType.uuid, nullable: true),
        SpParamDef('@p_numero_registro', SpParamType.string, nullable: true), // NUEVO
        SpParamDef('@p_tipo_paro_id', SpParamType.integer),
        SpParamDef('@p_motivo', SpParamType.string, nullable: true),
        SpParamDef('@p_equipo', SpParamType.string, nullable: true),
        SpParamDef('@p_hora_inicio', SpParamType.timeString),
        SpParamDef('@p_hora_final', SpParamType.timeString, nullable: true),
        SpParamDef('@p_galones', SpParamType.decimal, nullable: true),
      ],
      outputParams: [
        SpParamDef('@p_paro_id', SpParamType.uuid),
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
      ],
    ),
    _guardarChecklist: SpContract(
      spName: _guardarChecklist,
      guidFormat: 'no_braces_with_hyphens',
      inputParams: [
        SpParamDef('@p_registro_id', SpParamType.uuid, nullable: true),
        SpParamDef('@p_numero_registro', SpParamType.string, nullable: true), // NUEVO
        SpParamDef('@p_resultados', SpParamType.jsonString),
      ],
      outputParams: [
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
        SpParamDef('@p_total', SpParamType.integer),
      ],
    ),
    _cerrarTurno: SpContract(
      spName: _cerrarTurno,
      guidFormat: 'no_braces_with_hyphens',
      inputParams: [
        SpParamDef('@p_registro_id', SpParamType.uuid, nullable: true),
        SpParamDef('@p_numero_registro', SpParamType.string, nullable: true), // NUEVO
        SpParamDef('@p_tractor_final', SpParamType.decimal, nullable: true),
        SpParamDef('@p_implemento_final', SpParamType.decimal, nullable: true),
        SpParamDef('@p_hora_salida_punto', SpParamType.timeString,
            nullable: true),
        SpParamDef('@p_hora_llegada_taller', SpParamType.timeString,
            nullable: true),
        SpParamDef('@p_hora_refrigerio', SpParamType.timeString,
            nullable: true),
        SpParamDef('@p_lotes', SpParamType.jsonString, nullable: true),
        SpParamDef('@p_sublabores', SpParamType.jsonString, nullable: true),
        SpParamDef('@p_marchas', SpParamType.jsonString, nullable: true),
        SpParamDef('@p_observaciones_maq', SpParamType.string, nullable: true),
      ],
      outputParams: [
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
      ],
    ),
    _aprobarRegistro: SpContract(
      spName: _aprobarRegistro,
      guidFormat: 'no_braces_with_hyphens',
      inputParams: [
        SpParamDef('@p_registro_id', SpParamType.uuid),
        SpParamDef('@p_supervisor_erp_id', SpParamType.integer),
        SpParamDef('@p_accion', SpParamType.string),
        SpParamDef('@p_motivo', SpParamType.string, nullable: true),
      ],
      outputParams: [
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
      ],
    ),
    // _registrarJornada — ⚠️ no está en la lista de SPs activos del servidor.
    // Verificar si fue eliminado o absorbido por SINCRONIZAR_OFFLINE.
    // Referenciado en sync_manager.dart — revisar antes de eliminar.
    _registrarLecturaPortero: SpContract(
      spName: _registrarLecturaPortero,
      inputParams: [
        SpParamDef('@p_payload', SpParamType.jsonString),
      ],
    ),
    // _crearRegistroVehiculo — no está en lista activa.
    // El vehículo va por SINCRONIZAR_OFFLINE con tipo_registro='vehiculo'.
    _getRegistrosSupervisor: SpContract(
      spName: _getRegistrosSupervisor,
      inputParams: [
        SpParamDef('@p_fecha', SpParamType.dateString),
        SpParamDef('@p_turno', SpParamType.string, nullable: true),
      ],
    ),
    _getJornadasSupervisor: SpContract(
      spName: _getJornadasSupervisor,
      inputParams: [
        SpParamDef('@p_fecha', SpParamType.dateString),
        SpParamDef('@p_turno', SpParamType.string, nullable: true),
      ],
    ),
    _actualizarStatusJornada: SpContract(
      spName: _actualizarStatusJornada,
      inputParams: [
        SpParamDef('@p_payload', SpParamType.jsonString),
      ],
    ),
    _getParosMecanico: SpContract(
      spName: _getParosMecanico,
      inputParams: [
        SpParamDef('@p_fecha', SpParamType.dateString),
        SpParamDef('@p_estado', SpParamType.string, nullable: true),
      ],
    ),
    _completarFallaMecanica: SpContract(
      spName: _completarFallaMecanica,
      inputParams: [
        SpParamDef('@p_paro_id', SpParamType.string),
        SpParamDef('@p_hora_inicio_real', SpParamType.timeString),
        SpParamDef('@p_hora_fin_real', SpParamType.timeString),
        SpParamDef('@p_mecanico_id_erp', SpParamType.integer),
        SpParamDef('@p_trabajo_realizado', SpParamType.string, nullable: true),
        SpParamDef('@p_estado_falla', SpParamType.string, nullable: true),
        SpParamDef('@p_mecanico_nombre', SpParamType.string, nullable: true),
      ],
      outputParams: [
        SpParamDef('@p_success', SpParamType.bit),
        SpParamDef('@p_mensaje', SpParamType.string),
      ],
    ),

    // ─── GPS trazabilidad de maquinaria ──────────────────────────────────────
    // SP de escritura: recibe un JSON array de puntos GPS desde el APK y los
    // persiste mediante MERGE (idempotente). Se llama en segundo plano al
    // restaurar cobertura, sin depender del flujo de SINCRONIZAR_OFFLINE.
    _registrarPuntosGps: SpContract(
      spName: _registrarPuntosGps,
      guidFormat: 'no_braces_with_hyphens',
      inputParams: [
        SpParamDef('@p_registro_id',  SpParamType.uuid,       nullable: false),
        SpParamDef('@p_puntos_json',  SpParamType.jsonString,  nullable: false),
      ],
      outputParams: [
        SpParamDef('@p_success',          SpParamType.bit),
        SpParamDef('@p_mensaje',          SpParamType.string),
        SpParamDef('@p_total_insertados', SpParamType.integer),
      ],
    ),

    // ─── Navegación dinámica AGROMOV ─────────────────────────────────────────
    // Devuelve los nodos de menú que el usuario tiene permiso de ver en el
    // sistema AGROMOV. Se llama después del login para validar acceso al módulo.
    _obtenerNavegacion: SpContract(
      spName: _obtenerNavegacion,
      inputParams: [
        SpParamDef('@IdUsuario', SpParamType.integer),
        SpParamDef('@Sistema',   SpParamType.string),
      ],
    ),
  };

  /// Obtiene el contrato de un SP registrado
  static SpContract? getContract(String spName) => _registry[spName];

  /// Valida y coerce los parámetros de entrada según el contrato
  static List<dynamic> validateAndCoerce(
    String spName,
    List<dynamic> parametros,
  ) {
    final contract = _registry[spName];

    if (contract == null) {
      developer.log('⚠️ SP no registrado: $spName');
      return parametros;
    }

    if (parametros.length != contract.inputCount) {
      throw SpValidationException(
        'SP "$spName" requiere ${contract.inputCount} parámetros, '
        'pero llegaron ${parametros.length}.',
      );
    }

    final salida = <dynamic>[];

    for (int i = 0; i < parametros.length; i++) {
      final def = contract.inputParams[i];
      final raw = parametros[i];

      if (raw == null && !def.nullable) {
        throw SpValidationException(
          'Parámetro ${def.hint} no acepta null.',
        );
      }

      salida.add(
        raw == null
            ? null
            : _coerce(
                spName,
                i + 1,
                def,
                raw,
                contract.guidFormat,
              ),
      );
    }

    return salida;
  }

  /// Formatea un string GUID según el formato especificado
  ///
  /// Formatos soportados:
  /// - 'no_braces_with_hyphens': 8526F050-4F84-48ED-9A69-15D21539D690
  /// - 'with_braces_and_hyphens': {8526F050-4F84-48ED-9A69-15D21539D690}
  /// - 'with_braces_no_hyphens': {8526F0504F8448ED9A6915D21539D690}
  /// - 'no_braces_no_hyphens': 8526F0504F8448ED9A6915D21539D690
  static String _formatGuid(
    String uuidStr, {
    String? format,
  }) {
    String clean = uuidStr.trim();

    // Eliminar llaves, espacios y guiones (normalización)
    clean = clean.replaceAll(RegExp(r'[\{\}\s-]'), '');

    // Validar longitud (debe ser 32 caracteres hex)
    if (clean.length != 32) {
      throw SpValidationException(
          'GUID inválido: $uuidStr (longitud: ${clean.length})');
    }

    // Validar que solo contenga caracteres hexadecimales
    if (!RegExp(r'^[0-9A-Fa-f]{32}$').hasMatch(clean)) {
      throw const SpValidationException(
          'GUID inválido: contiene caracteres no hexadecimales');
    }

    // Normalizar a MAYÚSCULAS (formato estándar SQL Server)
    clean = clean.toUpperCase();

    // Reconstruir con guiones (formato estándar)
    final withHyphens = '${clean.substring(0, 8)}-'
        '${clean.substring(8, 12)}-'
        '${clean.substring(12, 16)}-'
        '${clean.substring(16, 20)}-'
        '${clean.substring(20, 32)}';

    switch (format) {
      case 'with_braces_and_hyphens':
        return '{$withHyphens}';
      case 'with_braces_no_hyphens':
        return '{$clean}';
      case 'no_braces_no_hyphens':
        return clean;
      case 'no_braces_with_hyphens':
      default:
        return withHyphens;
    }
  }

  /// Convierte un valor al tipo de dato esperado por el SP
  static dynamic _coerce(
    String spName,
    int pos,
    SpParamDef def,
    dynamic value,
    String? guidFormat,
  ) {
    if (value == null) return null;

    switch (def.type) {
      case SpParamType.uuid:
        if (value is! String) {
          throw SpValidationException(
            'Se esperaba String para ${def.hint}',
          );
        }

        final guid = _formatGuid(
          value,
          format: guidFormat,
        );

        developer.log(
          '📦 GUID formateado: $value -> $guid',
          name: 'SpRegistry',
        );

        return guid;

      case SpParamType.string:
      case SpParamType.dateString:
      case SpParamType.timeString:
        if (value is! String) {
          throw SpValidationException(
            'Se esperaba String para ${def.hint}',
          );
        }
        return value;

      case SpParamType.integer:
        if (value is int) return value;
        if (value is double) return value.toInt();

        final entero = int.tryParse(value.toString());

        if (entero == null) {
          throw SpValidationException(
            'No se pudo convertir ${def.hint} a int: $value',
          );
        }

        return entero;

      case SpParamType.decimal:
        if (value is double) return value;
        if (value is int) return value.toDouble();

        final decimal = double.tryParse(value.toString());

        if (decimal == null) {
          throw SpValidationException(
            'No se pudo convertir ${def.hint} a decimal: $value',
          );
        }

        return decimal;

      case SpParamType.bit:
        if (value is bool) return value ? 1 : 0;
        if (value is int) return value == 0 ? 0 : 1;

        throw SpValidationException(
          'BIT espera bool o int, recibió ${value.runtimeType}',
        );

      case SpParamType.jsonString:
        if (value is Map || value is List) {
          throw SpValidationException(
            'Use jsonEncode() antes de enviar JSON. Recibió ${value.runtimeType}',
          );
        }

        if (value is! String) {
          throw SpValidationException(
            'Se esperaba String JSON, recibió ${value.runtimeType}',
          );
        }

        try {
          jsonDecode(value);
        } catch (e) {
          throw SpValidationException(
            'JSON inválido: ${value.length > 100 ? '${value.substring(0, 100)}...' : value}',
          );
        }

        return value;
    }
  }
}
