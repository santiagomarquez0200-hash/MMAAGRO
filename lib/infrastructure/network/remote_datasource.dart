import 'dart:convert';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/exceptions.dart';

import 'erp_api_client.dart';

/// Interfaz para el data source remoto
abstract class RemoteDataSource {
  // Autenticación (valida código de trabajador)
  Future<Map<String, dynamic>> autenticarOperador(String codigoTrabajador);

  // Catálogos
  Future<Map<String, List<Map<String, dynamic>>>> syncAllCatalogos();

  // Operaciones de turno
  Future<Map<String, dynamic>> crearRegistro(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> cerrarTurno(
      String registroId, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> aprobarRegistro(
      String registroId, Map<String, dynamic> payload);
  Future<void> guardarChecklist(
      String registroId, List<Map<String, dynamic>> items);
  Future<void> registrarBin(String registroId, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> agregarParo(
      String registroId, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> sincronizarOffline(Map<String, dynamic> payload);
}

/// Implementación con ErpApiClient
class RemoteDataSourceImpl implements RemoteDataSource {
  final ErpApiClient _erpClient;

  const RemoteDataSourceImpl(this._erpClient);

  @override
  Future<Map<String, dynamic>> autenticarOperador(
      String codigoTrabajador) async {
    // El operador se autentica con PIN local, no contra el ERP.
    // Esta función solo verifica que el código exista en el catálogo sincronizado.
    // Retorna éxito si el código es válido (no vacío).
    if (codigoTrabajador.isEmpty) {
      throw const AuthException(message: 'Código de trabajador inválido');
    }
    return {'success': true, 'codigo': codigoTrabajador};
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> syncAllCatalogos() async {
    return await _erpClient.syncAllCatalogos();
  }

  // crearRegistro() — CÓDIGO LEGADO, no se llama en el flujo actual.
  // La creación de registros va: SQLite → outbox → CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE.
  // El SP CLI547_AGMSP_MMA_CREAR_REGISTRO ya no existe en el servidor.
  @override
  Future<Map<String, dynamic>> crearRegistro(
      Map<String, dynamic> payload) async {
    // Ruta directa eliminada — todo va por el outbox / SINCRONIZAR_OFFLINE.
    throw UnimplementedError(
      'crearRegistro() directo no está disponible. '
      'Usar el outbox offline → CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE.',
    );
  }

  @override
  Future<Map<String, dynamic>> cerrarTurno(
      String registroId, Map<String, dynamic> payload) async {
    final result = await _erpClient.ejecutarSP(
      nombreSP: AppEnvironment.spCerrarTurno,
      parametros: [
        registroId,
        payload['tractor_final'],
        payload['implemento_final'],
        payload['hora_salida_punto'],
        payload['hora_llegada_taller'],
        payload['hora_refrigerio'],
        payload['lotes_json'],
        payload['observaciones_maq'],
      ],
    );

    return {
      'success': result.isNotEmpty ? result[0]['success'] : false,
      'mensaje': result.isNotEmpty ? result[0]['mensaje'] : 'Error',
    };
  }

  @override
  Future<Map<String, dynamic>> aprobarRegistro(
      String registroId, Map<String, dynamic> payload) async {
    final result = await _erpClient.ejecutarSP(
      nombreSP: AppEnvironment.spAprobarRegistro,
      parametros: [
        registroId,
        payload['supervisor_erp_id'],
        payload['accion'],
        payload['motivo'],
      ],
    );

    return {
      'success': result.isNotEmpty ? result[0]['success'] : false,
      'mensaje': result.isNotEmpty ? result[0]['mensaje'] : 'Error',
    };
  }

  @override
  Future<void> guardarChecklist(
      String registroId, List<Map<String, dynamic>> items) async {
    final jsonPayload = jsonEncode(items
        .map((item) => {
              'item_id': item['item_id'],
              'resultado': item['resultado'],
              'observacion': item['observacion'],
              'foto_url': item['foto_url'],
            })
        .toList());

    await _erpClient.ejecutarSP(
      nombreSP: AppEnvironment.spGuardarChecklist,
      parametros: [registroId, jsonPayload],
    );
  }

  @override
  Future<void> registrarBin(
      String registroId, Map<String, dynamic> payload) async {
    await _erpClient.ejecutarSP(
      nombreSP: AppEnvironment.spRegistrarBin,
      parametros: [
        registroId,
        payload['franja_horaria'],
        payload['turno_franja'],
        payload['cantidad'],
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> agregarParo(
      String registroId, Map<String, dynamic> payload) async {
    final result = await _erpClient.ejecutarSP(
      nombreSP: AppEnvironment.spRegistrarParo,
      parametros: [
        registroId,
        payload['tipo_paro_id'],
        payload['motivo'],
        payload['equipo'],
        payload['hora_inicio'],
        payload['hora_final'],
        payload['galones'],
      ],
    );

    return {
      'paro_id': result.isNotEmpty ? result[0]['paro_id'] : null,
      'success': result.isNotEmpty ? result[0]['success'] : false,
      'mensaje': result.isNotEmpty ? result[0]['mensaje'] : 'Error',
    };
  }

  @override
  Future<Map<String, dynamic>> sincronizarOffline(
      Map<String, dynamic> payload) async {
    final jsonPayload = jsonEncode(payload);
    final result = await _erpClient.ejecutarSP(
      nombreSP: AppEnvironment.spSincronizarOffline,
      parametros: [jsonPayload],
    );

    if (result.isEmpty) {
      throw const ServerException(message: 'No response from SP');
    }

    final row = result[0];
    return {
      'success': row['success'] ?? false,
      'mensaje': row['mensaje'] ?? 'Error',
      'registro_id': row['registro_id'],
      'ya_existia': row['ya_existia'] ?? false,
    };
  }
}
