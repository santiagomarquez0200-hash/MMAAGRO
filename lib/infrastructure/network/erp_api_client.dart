import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sp_contract.dart';

const _tag = 'ERP';

class ErpApiClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  // Completer reutilizado para serializar llamadas concurrentes a getValidToken.
  // Evita que dos llamadas simultáneas lancen dos authenticate() en paralelo.
  Completer<String>? _pendingAuth;

  ErpApiClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage,
        _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppEnvironment.erpBaseUrl,
      connectTimeout: AppEnvironment.erpConnectTimeout,
      receiveTimeout: AppEnvironment.erpReceiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    ));
    dio.interceptors.add(_ErpDiagnosticInterceptor());
    return dio;
  }

  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  Future<String> authenticate() async {
    return authenticateWithCredentials(
        AppEnvironment.erpUsername, AppEnvironment.erpPassword);
  }

  Future<String> authenticateWithCredentials(
      String username, String password) async {
    debugPrint(
        '[$_tag/AUTH] Autenticando → ${AppEnvironment.erpBaseUrl}${AppEnvironment.erpAuthEndpoint}');
    debugPrint('[$_tag/AUTH] Usuario: $username');
    try {
      final response = await _dio.post(
        AppEnvironment.erpAuthEndpoint,
        options: Options(headers: {
          'username': username,
          'password': password,
        }),
      );
      final token = _extractToken(response.data);
      await _saveToken(token);
      debugPrint(
          '[$_tag/AUTH] token obtenido, expira en ${AppEnvironment.erpTokenTtl.inHours}h');
      return token;
    } on DioException catch (e) {
      debugPrint(
          '[$_tag/AUTH] error de autenticacion: ${e.response?.statusCode} ${e.response?.data}');
      throw _mapDioException(e);
    }
  }

  Future<String> getValidToken() async {
    final stored = await _secureStorage.read(key: AppEnvironment.erpTokenKey);
    final expiryStr =
        await _secureStorage.read(key: AppEnvironment.erpTokenExpiryKey);
    if (stored != null && expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isBefore(expiry)) {
        developer.log('Token en cache válido hasta $expiryStr',
            name: '$_tag/AUTH');
        return stored;
      }
      developer.log('Token expirado ($expiryStr). Renovando...',
          name: '$_tag/AUTH');
    } else {
      developer.log('Sin token en cache. Autenticando...', name: '$_tag/AUTH');
    }
    // Si ya hay una autenticación en curso, esperar su resultado en lugar de
    // lanzar una segunda llamada concurrente.
    if (_pendingAuth != null) return _pendingAuth!.future;
    _pendingAuth = Completer<String>();
    try {
      final token = await authenticate();
      _pendingAuth!.complete(token);
      return token;
    } catch (e) {
      _pendingAuth!.completeError(e);
      rethrow;
    } finally {
      _pendingAuth = null;
    }
  }

  Future<List<Map<String, dynamic>>> ejecutarSP({
    required String nombreSP,
    required List<dynamic> parametros,
  }) async {
    // 1. Validación y coerción (solo de los parámetros de entrada)
    final List<dynamic> parametrosValidados;
    try {
      parametrosValidados = SpRegistry.validateAndCoerce(nombreSP, parametros);
    } on SpValidationException catch (e) {
      developer.log('validacion fallida para "$nombreSP": ${e.message}',
          name: '$_tag/SP', error: e);
      rethrow;
    }

    developer.log(
        '$nombreSP con ${parametrosValidados.length} parametro(s) de entrada',
        name: '$_tag/SP');
    _logParams(nombreSP, parametrosValidados);

    final token = await getValidToken();
    final contract = SpRegistry.getContract(nombreSP);

    if (contract == null) {
      throw SpValidationException(
          'No se encontró contrato para el SP "$nombreSP"');
    }

    // Si la cantidad de params que armamos no coincide con el contrato, algo puede
    // haber cambiado en el SP del servidor. Vale la pena saberlo en logs.
    if (parametrosValidados.length != contract.inputCount) {
      developer.log(
        'aviso: ${parametrosValidados.length} params recibidos, contrato espera'
        ' ${contract.inputCount} para $nombreSP',
        name: '$_tag/SP',
      );
    }

    // Armamos la lista completa que el proxy necesita: primero inputs, luego outputs.
    final List<Map<String, dynamic>> parametrosCompletos = [];

    // Si vinieron menos params de los esperados, los restantes se envian null.
    final inputLimit = parametrosValidados.length < contract.inputCount
        ? parametrosValidados.length
        : contract.inputCount;

    for (int i = 0; i < inputLimit; i++) {
      final value = parametrosValidados[i];
      final paramDef = contract.inputParams[i];
      final paramName = paramDef.cleanName;
      final valorStr = value == null ? null : value.toString();

      parametrosCompletos.add({
        'Nombre': paramName,
        'NombreParametro': paramName,
        'Valor': valorStr,
        'ValorParametro': valorStr,
      });
    }

    if (parametrosValidados.length < contract.inputCount) {
      developer.log(
          'faltan ${contract.inputCount - parametrosValidados.length} params INPUT, se completan con null',
          name: '$_tag/SP');
      for (int i = parametrosValidados.length; i < contract.inputCount; i++) {
        final paramDef = contract.inputParams[i];
        final paramName = paramDef.cleanName;
        parametrosCompletos.add({
          'Nombre': paramName,
          'NombreParametro': paramName,
          'Valor': null,
          'ValorParametro': null,
        });
      }
    }

    // Los parámetros OUTPUT hay que declararlos igual aunque vayan vacíos,
    // porque el proxy los necesita en el payload para mapearlos en la respuesta.
    for (int i = 0; i < contract.outputParams.length; i++) {
      final paramDef = contract.outputParams[i];
      final paramName = paramDef.cleanName;
      parametrosCompletos.add({
        'Nombre': paramName,
        'NombreParametro': paramName,
        'Valor': null,
        'ValorParametro': null,
      });
    }

    final payload = {
      'NombreSP': nombreSP,
      'TipoRespuesta': 0,
      'EntidadMapa': '',
      'Parametros': parametrosCompletos,
    };

    debugPrint(
        '[$_tag/SP] POST ${AppEnvironment.erpBaseUrl}${AppEnvironment.erpSpEndpoint}');
    debugPrint('[$_tag/SP] Payload: ${jsonEncode(payload)}');

    try {
      final response = await _dio.post(
        AppEnvironment.erpSpEndpoint,
        data: payload,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'X-Requested-With': 'XMLHttpRequest',
        }),
      );

      debugPrint(
          '[$_tag/SP] HTTP ${response.statusCode} — tipo: ${response.data.runtimeType}');
      final result = _parseListResponse(response.data, nombreSP);
      _logResult(nombreSP, result);
      return result;
    } on DioException catch (e) {
      debugPrint(
          '[$_tag/SP] error HTTP ${e.response?.statusCode}: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        developer.log('respuesta 401, renovando token antes de reintentar',
            name: '$_tag/SP');
        final freshToken = await authenticate();
        try {
          final retry = await _dio.post(
            AppEnvironment.erpSpEndpoint,
            data: payload,
            options: Options(headers: {
              'Authorization': 'Bearer $freshToken',
              'X-Requested-With': 'XMLHttpRequest',
            }),
          );
          final result = _parseListResponse(retry.data, nombreSP);
          _logResult(nombreSP, result);
          return result;
        } on DioException catch (e2) {
          throw _mapDioException(e2);
        }
      }
      throw _mapDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getReporteSupervisor({
    required String turno,
    required String fecha,
  }) async {
    final rows = await ejecutarSP(
      nombreSP: AppEnvironment.spGetRegistrosSupervisor,
      parametros: [fecha, turno],
    );

    return rows.map((row) {
      final estado = row['estado']?.toString() ?? 'borrador';
      final progreso = switch (estado) {
        'aprobado' => 100,
        'completado' => 75,
        'rechazado' => 100,
        'borrador' => 25,
        _ => 50,
      };

      return {
        ...row,
        'operador_nombre':
            row['operador_nombre'] ?? row['nombre_operador'] ?? 'Operador',
        'tractor_codigo': row['tractor_codigo'] ?? row['codigo_tractor'] ?? '-',
        'implemento_codigo':
            row['implemento_codigo'] ?? row['codigo_implemento'],
        'sincronizado': row['sincronizado'] ?? row['sincronizado_erp'] ?? false,
        'progreso_pct': row['progreso_pct'] ?? progreso,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getRegistrosSupervisor({
    required String fecha,
    String? turno,
  }) async {
    return ejecutarSP(
      nombreSP: AppEnvironment.spGetRegistrosSupervisor,
      parametros: [fecha, turno],
    );
  }

  Future<List<Map<String, dynamic>>> getJornadasSupervisor({
    required String fecha,
    String? turno,
  }) async {
    return ejecutarSP(
      nombreSP: AppEnvironment.spGetJornadasSupervisor,
      parametros: [fecha, turno],
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> syncAllCatalogos() async {
    debugPrint('[$_tag/SYNC] iniciando sync de catalogos...');
    developer.log('sync de catalogos iniciado', name: '$_tag/SYNC');

    final rows = await ejecutarSP(
      nombreSP: AppEnvironment.spSyncPayloadCompleto,
      parametros: [],
    );

    debugPrint('[$_tag/SYNC] filas recibidas del proxy: ${rows.length}');
    if (rows.isNotEmpty) {
      debugPrint('[$_tag/SYNC] claves de la primera fila: ${rows[0].keys.toList()}');
      debugPrint('[$_tag/SYNC] primera fila raw: ${rows[0]}');
    }
    developer.log('filas del proxy: ${rows.length}', name: '$_tag/SYNC');
    final result = <String, List<Map<String, dynamic>>>{};

    for (final row in rows) {
      final catalogo = row['catalogo']?.toString();
      final datosRaw = row['datos'];

      if (catalogo == null || datosRaw == null) {
        developer.log('fila ignorada, catalogo o datos nulos: catalogo=$catalogo',
            name: '$_tag/SYNC');
        continue;
      }

      List<Map<String, dynamic>> items;
      if (datosRaw is List) {
        items = datosRaw.whereType<Map<String, dynamic>>().toList();
        developer.log(
            '"$catalogo" lista directa: ${items.length} registros'
            '${items.isNotEmpty ? ' | cols: ${items[0].keys.toList()}' : ''}',
            name: '$_tag/SYNC');
      } else if (datosRaw is String && datosRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(datosRaw);
          if (decoded is List) {
            items = decoded.whereType<Map<String, dynamic>>().toList();
            developer.log(
                '"$catalogo" JSON decodificado: ${items.length} registros'
                '${items.isNotEmpty ? ' | cols: ${items[0].keys.toList()}' : ''}',
                name: '$_tag/SYNC');
          } else {
            developer.log(
                '"$catalogo" JSON vino como ${decoded.runtimeType}, se omite',
                name: '$_tag/SYNC');
            items = [];
          }
        } catch (e) {
          developer.log(
              '"$catalogo" error al parsear JSON: $e | preview: ${datosRaw.substring(0, datosRaw.length.clamp(0, 200))}',
              name: '$_tag/SYNC',
              error: e);
          items = [];
        }
      } else {
        developer.log(
            '"$catalogo" tipo de datos no esperado: ${datosRaw.runtimeType}',
            name: '$_tag/SYNC');
        items = [];
      }
      result[catalogo] = items;
    }

    final resumen =
        result.entries.map((e) => '${e.key}(${e.value.length})').join(', ');
    debugPrint('[$_tag/SYNC] sync completado: $resumen');
    developer.log('catalogos listos: $resumen', name: '$_tag/SYNC');
    return result;
  }

  String _extractToken(dynamic data) {
    developer.log('Extrayendo token. Tipo: ${data.runtimeType}',
        name: '$_tag/AUTH');
    if (data is String && data.isNotEmpty) {
      developer.log('Token como String puro.', name: '$_tag/AUTH');
      return data.trim();
    }
    if (data is Map) {
      developer.log('Token como Map. Keys: ${data.keys.toList()}',
          name: '$_tag/AUTH');
      final v = data['token'] ?? data['Token'] ?? data['access_token'];
      if (v != null) return v.toString().trim();
    }
    throw const ServerException(
        message: 'Formato de token ERP inesperado', statusCode: 200);
  }

  // Intenta extraer una lista de mapas de lo que devuelva el proxy,
  // que puede venir en distintos formatos según el SP y la versión del servidor.
  List<Map<String, dynamic>> _parseListResponse(dynamic data, String spName) {
    developer.log('$spName tipo de respuesta: ${data.runtimeType}',
        name: '$_tag/PARSE');

    if (data is List) {
      final result = data.whereType<Map<String, dynamic>>().toList();
      developer.log('lista directa con ${result.length} elemento(s)',
          name: '$_tag/PARSE');
      return result;
    }

    if (data is Map) {
      developer.log('respuesta es un mapa con keys: ${data.keys.toList()}',
          name: '$_tag/PARSE');

      // El proxy a veces devuelve resultsets múltiples como Table0, Table1, etc.
      // Se aplanan en una sola lista para simplificar el consumo.
      final tableKeys = data.keys
          .where((k) => RegExp(r'^Table\d+$').hasMatch(k.toString()))
          .toList()
        ..sort((a, b) {
          final na = int.tryParse(a.toString().replaceFirst('Table', '')) ?? 0;
          final nb = int.tryParse(b.toString().replaceFirst('Table', '')) ?? 0;
          return na.compareTo(nb);
        });

      if (tableKeys.isNotEmpty) {
        final allRows = <Map<String, dynamic>>[];
        for (final key in tableKeys) {
          final tableData = data[key];
          if (tableData is List) {
            allRows.addAll(tableData.whereType<Map<String, dynamic>>());
          }
        }
        if (allRows.isNotEmpty) {
          debugPrint(
              '[$_tag/PARSE] Table1..Table${tableKeys.length} → ${allRows.length} filas aplanadas');
          return allRows;
        }
      }

      // Algunas versiones del proxy devolvian los datos bajo claves distintas.
      final inner = data['data'] ??
          data['resultado'] ??
          data['Resultado'] ??
          data['Table'];
      if (inner is List) {
        final result = inner.whereType<Map<String, dynamic>>().toList();
        developer.log(
            'Lista anidada (clave legacy): ${result.length} elemento(s)',
            name: '$_tag/PARSE');
        return result;
      }

      // El proxy envuelve los parámetros OUTPUT bajo la clave 'Output'.
      if (data.containsKey('Output')) {
        final output = data['Output'];
        if (output is Map) {
          developer.log(
              'OUTPUT parameters encontrados: ${output.keys.toList()}',
              name: '$_tag/PARSE');
          return [output.cast<String, dynamic>()];
        }
        if (output is List && output.isNotEmpty && output.first is Map) {
          developer.log('OUTPUT como lista con ${output.length} elemento(s)',
              name: '$_tag/PARSE');
          return output.whereType<Map<String, dynamic>>().toList();
        }
      }

      // Otros SPs, sobre todo los de escritura/cierre, usan 'ReturnValue'.
      if (data.containsKey('ReturnValue') || data.containsKey('Result')) {
        final returnVal = data['ReturnValue'] ?? data['Result'];
        if (returnVal is Map) {
          developer.log('ReturnValue encontrado: ${returnVal.keys.toList()}',
              name: '$_tag/PARSE');
          return [returnVal.cast<String, dynamic>()];
        }
      }

      // Busca cualquier valor que sea lista de mapas — ej. "Usuarios", "registros".
      for (final key in data.keys) {
        final value = data[key];
        if (value is List && value.isNotEmpty && value.first is Map) {
          final result = value.cast<Map<String, dynamic>>();
          developer.log(
              'lista extraida de clave "$key": ${result.length} elemento(s)',
              name: '$_tag/PARSE');
          return result;
        }
      }

      // Si el mapa tiene claves como 'success' o 'registro_id', es la respuesta
      // directa de un SP de escritura — lo tratamos como una sola fila.
      final expectedKeys = [
        'registro_id',
        'numero_registro',
        'success',
        'mensaje',
        'paro_id',
        'total'
      ];
      final hasExpectedKey = expectedKeys.any((k) => data.containsKey(k));
      if (hasExpectedKey) {
        developer.log(
            'respuesta es un mapa con claves conocidas: ${data.keys.toList()}',
            name: '$_tag/PARSE');
        return [data.cast<String, dynamic>()];
      }

      // No encontramos nada mejor, tratamos el mapa completo como una sola fila.
      developer.log('sin lista anidada, se interpreta el mapa como fila unica',
          name: '$_tag/PARSE');
      return [data.cast<String, dynamic>()];
    }

    developer.log('tipo de respuesta no manejado, devolviendo lista vacia', name: '$_tag/PARSE');
    return [];
  }

  void _logParams(String spName, List<dynamic> params) {
    if (params.isEmpty) {
      developer.log('  (sin parámetros)', name: '$_tag/SP');
      return;
    }
    final contract = SpRegistry.getContract(spName);
    final buf = StringBuffer('Parámetros enviados:\n');
    for (var i = 0; i < params.length; i++) {
      final hint = (contract != null && i < contract.inputParams.length)
          ? contract.inputParams[i].hint
          : 'param${i + 1}';
      final val = params[i];
      final preview = val == null
          ? 'NULL'
          : (val is String && val.length > 80
              ? '"${val.substring(0, 80)}..."'
              : '$val');
      buf.writeln('  [$i] $hint = $preview');
    }
    developer.log(buf.toString().trimRight(), name: '$_tag/SP');
  }

  void _logResult(String spName, List<Map<String, dynamic>> result) {
    if (result.isEmpty) {
      developer.log('"$spName" volvio vacio', name: '$_tag/SP');
    } else {
      developer.log(
          '"$spName" devolvio ${result.length} fila(s) | cols: ${result[0].keys.toList()}',
          name: '$_tag/SP');
    }
  }

  Future<void> _saveToken(String token) async {
    final expiry =
        DateTime.now().add(AppEnvironment.erpTokenTtl).toIso8601String();
    await _secureStorage.write(key: AppEnvironment.erpTokenKey, value: token);
    await _secureStorage.write(
        key: AppEnvironment.erpTokenExpiryKey, value: expiry);
  }

  Exception _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ErpTimeoutException();
    }
    final code = e.response?.statusCode ?? 0;
    final msg = e.response?.data?.toString() ?? e.message ?? 'Error ERP';
    if (code == 401) {
      return const AuthException(message: 'Credenciales ERP inválidas');
    }
    return ServerException(message: msg, statusCode: code);
  }
}

class _ErpDiagnosticInterceptor extends Interceptor {
  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final ts = DateTime.now().toIso8601String();
    final buf = StringBuffer();
    buf.writeln('REQUEST [$ts]');
    buf.writeln('${options.method} ${options.baseUrl}${options.path}');
    buf.writeln('Headers:');
    options.headers.forEach((k, v) {
      if (k.toLowerCase() == 'authorization') {
        final s = v.toString();
        buf.writeln(
            '  $k: ${s.substring(0, s.length.clamp(0, 20))}...[hidden]');
      } else if (k.toLowerCase() != 'username' &&
          k.toLowerCase() != 'password') {
        buf.writeln('  $k: $v');
      } else {
        buf.writeln('  $k: [credential-hidden]');
      }
    });
    if (options.data != null) {
      buf.writeln('Body (exacto enviado al proxy):');
      try {
        final obj =
            options.data is String ? jsonDecode(options.data) : options.data;
        for (final line in _encoder.convert(obj).split('\n')) {
          buf.writeln('  $line');
        }
      } catch (_) {
        buf.writeln('  ${options.data}');
      }
    }
    developer.log(buf.toString().trimRight(), name: 'ERP/HTTP');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buf = StringBuffer();
    buf.writeln('RESPONSE ${response.statusCode} ${response.statusMessage}');
    buf.writeln('Tipo: ${response.data.runtimeType}');
    final rawStr = _safeEncode(response.data);
    if (rawStr.length <= 2000) {
      buf.writeln('Body:');
      for (final line in rawStr.split('\n')) {
        buf.writeln('  $line');
      }
    } else {
      buf.writeln(
          'Body (primeros 2000 chars):\n  ${rawStr.substring(0, 2000)}...[truncado total:${rawStr.length}]');
    }
    developer.log(buf.toString().trimRight(), name: 'ERP/HTTP');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buf = StringBuffer();
    buf.writeln('ERROR HTTP');
    buf.writeln('Tipo   : ${err.type}');
    buf.writeln('Status : ${err.response?.statusCode}');
    buf.writeln('Mensaje: ${err.message}');
    if (err.response?.data != null) {
      buf.writeln('Server response (causa del error):');
      buf.writeln('  ${_safeEncode(err.response!.data)}');
    }
    buf.writeln('Request enviado:');
    final reqData = err.requestOptions.data;
    if (reqData != null) {
      try {
        final obj = reqData is String ? jsonDecode(reqData) : reqData;
        for (final line in _encoder.convert(obj).split('\n')) {
          buf.writeln('  $line');
        }
      } catch (_) {
        buf.writeln('  $reqData');
      }
    }
    developer.log(buf.toString().trimRight(), name: 'ERP/HTTP', error: err);
    handler.next(err);
  }

  String _safeEncode(dynamic data) {
    if (data is String) return data;
    try {
      return _encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
