import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/constants/app_constants.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/shared/profile/domain/entities/perfil_usuario.dart';
import 'package:agro_aplicaciones/shared/auth/domain/entities/usuario.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/infrastructure/network/sp_contract.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;
  final FlutterSecureStorage _secureStorage;
  final ErpApiClient _erp;

  const AuthRepositoryImpl({
    required AppDatabase db,
    required FlutterSecureStorage secureStorage,
    required ErpApiClient erp,
  })  : _db = db,
        _secureStorage = secureStorage,
        _erp = erp;

  @override
  Future<Either<Failure, void>> validarAccesoPin(
      String codigo, String pin) async {
    try {
      final pinHash = _hashPin(pin);
      final trabajador = await _db.catalogoDao.getTrabajadorByCodigo(codigo);
      if (trabajador == null) {
        return const Left(AuthFailure(
            message:
                'Trabajador no encontrado. Sincronice los catalogos primero.'));
      }

      if (trabajador.pinHash == null) {
        await _db.catalogoDao.savePinHash(trabajador.idErp, pinHash);
        return const Right(null);
      }

      if (trabajador.pinHash != pinHash) {
        return const Left(AuthFailure(message: 'PIN incorrecto'));
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Usuario>> loginConPin(
      String codigo, String pin, String rol) async {
    try {
      final pinHash = _hashPin(pin);

      // 1. Buscar trabajador en BD local
      final trabajadorLocal =
          await _db.catalogoDao.getTrabajadorByCodigo(codigo);

      developer.log(
        '[AUTH/PIN] lookup codigo="$codigo" → '
        'encontrado=${trabajadorLocal != null} '
        'idErp=${trabajadorLocal?.idErp} '
        'usuarioErpId=${trabajadorLocal?.usuarioErpId} '
        'codTrabajador="${trabajadorLocal?.codTrabajador}"',
        name: 'Auth',
      );

      if (trabajadorLocal == null) {
        return const Left(AuthFailure(
            message:
                'Trabajador no encontrado. Sincronice los catálogos primero.'));
      }

      // 2. Si aún no tiene PIN guardado, registrarlo
      if (trabajadorLocal.pinHash == null) {
        await _db.catalogoDao.savePinHash(trabajadorLocal.idErp, pinHash);
      } else if (trabajadorLocal.pinHash != pinHash) {
        // 3. Verificar PIN
        return const Left(AuthFailure(message: 'PIN incorrecto'));
      }

      // 4. Validar acceso al módulo seleccionado consultando la BD (igual que loginConAPI)
      final rolReal = await _resolverRolDesdeNavegacion(
        usuarioErpId: trabajadorLocal.usuarioErpId,
        rolSeleccionado: rol,
        rolLocal: trabajadorLocal.rolApk,
      );
      if (rolReal == null) {
        return Left(AuthFailure(
          message: 'No tiene permiso para acceder al módulo "$rol". '
              'Contacte al administrador del sistema.',
        ));
      }

      // 5. Construir usuario con el rol validado
      final pinHashFinal = trabajadorLocal.pinHash ?? pinHash;
      final usuario = _mapTrabajadorToUsuario(
        trabajadorLocal.copyWith(pinHash: Value(pinHashFinal)),
        rolOverride: rolReal,
      );
      await _persistSession(usuario);
      return Right(usuario);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Usuario>> loginConAPI(
      String username, String password, String rol) async {
    try {
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return const Left(
            AuthFailure(message: 'Ingrese usuario y contraseña para continuar'));
      }

      // 1. Autenticar con la API ERP usando las credenciales del trabajador
      await _erp.authenticateWithCredentials(username.trim(), password);

      // 2. Obtener perfil profesional del trabajador desde el ERP
      final perfilResult =
          await sincronizarPerfilProfesional(username.trim());
      if (perfilResult.isLeft()) {
        return Left(perfilResult.fold(
            (l) => AuthFailure(message: 'Perfil no encontrado: ${l.message}'),
            (_) => const AuthFailure(message: 'Error al obtener perfil')));
      }
      final perfil = perfilResult.fold((_) => null, (p) => p)!;

      // 3. Construir objeto Usuario desde el perfil

      // Resolver el t.Id real (PK de trabajadores) desde el catálogo local.
      // Se usa `username` (el código que el usuario escribió en la pantalla PIN)
      // porque ya fue validado contra el catálogo local en validarAccesoPin,
      // garantizando que getTrabajadorByCodigo lo encuentre siempre.
      // perfil.codigoTrabajador NO se usa aquí porque puede venir con formato
      // distinto del ERP y no coincidir con lo almacenado localmente.
      final codigoTrabajador = perfil.codigoTrabajador;
      final trabajadorLocal =
          await _db.catalogoDao.getTrabajadorByCodigo(username.trim());
      final trabajadorIdErp =
          trabajadorLocal?.idErp ?? _parseIdErp(codigoTrabajador);

      // usuarioErpId: prioridad al catálogo local (más confiable);
      // si el catálogo está vacío (fresh install / datos borrados) se usa
      // el idUsuario que devuelve el SP de perfil.
      // Si el SP de perfil no devuelve IdUsuario, queda null y el fallback
      // del resolver lanzará error en vez de asumir 'operador'.
      final usuarioErpId =
          trabajadorLocal?.usuarioErpId ?? perfil.idUsuario;

      // Validar acceso al módulo seleccionado consultando la BD (no local).
      // Se llama a CLI547_AGMSP_Obtener_Navegacion que devuelve solo las rutas
      // que el usuario tiene permiso de ver según CLI547_AGM_PermisosNavegacion.
      // Si la ruta home del rol seleccionado no está en la lista → acceso denegado.
      // Fallback a rolApk local si no hay usuarioErpId o el SP no responde.
      final rolReal = await _resolverRolDesdeNavegacion(
        usuarioErpId: usuarioErpId,
        rolSeleccionado: rol,
        rolLocal: trabajadorLocal?.rolApk,
      );
      if (rolReal == null) {
        return Left(AuthFailure(
          message: 'No tiene permiso para acceder al módulo "$rol". '
              'Contacte al administrador del sistema.',
        ));
      }

      final rolId = rolReal == 'supervisor'
          ? 2
          : rolReal == 'portero'
              ? 3
              : rolReal == 'mecanico'
                  ? 4
                  : rolReal == 'gerente'
                      ? 5
                      : 1;

      developer.log(
        '[AUTH/API] username="$username" perfil.codigoTrabajador="$codigoTrabajador" → '
        'encontrado=${trabajadorLocal != null} '
        'rolSeleccionado=$rol rolReal=$rolReal '
        'idErp=$trabajadorIdErp '
        'usuarioErpId=$usuarioErpId '
        'codTrabajador="${trabajadorLocal?.codTrabajador}"',
        name: 'Auth',
      );

      final usuario = Usuario(
        id: perfil.codigoUsuario,
        // CodigoUsuario es el código de login del ERP (ej. "PCORZO").
        // codigoTrabajador es el código físico/barcode ("468834") — no sirve para
        // buscar en el catálogo local que ahora indexa por CodigoUsuario.
        codigo: perfil.codigoUsuario.isNotEmpty ? perfil.codigoUsuario : username.trim(),
        nombres: _extractNombres(perfil.nombreCompleto),
        apellidos: _extractApellidos(perfil.nombreCompleto),
        dni: perfil.dni,
        usuarioErpId: usuarioErpId,
        trabajadorIdErp: trabajadorIdErp,
        rolId: rolId,
        rolNombre: rolReal,
        activo: perfil.estadoUsuario.toLowerCase() == 'activo' ||
            perfil.estadoUsuario.toLowerCase() == 'a',
      );

      // 4. Persistir sesión
      await _persistSession(usuario);

      // 4b. Guardar sesión offline: incluye hash de password para validación
      //     sin red en arranques posteriores.
      await _persistOfflineSession(usuario, username.trim(), password);

      return Right(usuario);
    } catch (e) {
      if (_isNetworkError(e)) {
        return const Left(NetworkFailure());
      }
      return Left(AuthFailure(message: e.toString()));
    }
  }


  @override
  Future<Either<Failure, PerfilUsuario>> sincronizarPerfilProfesional(
      String usuarioLogin) async {
    try {
      final usuarioParam = usuarioLogin.trim();
      if (usuarioParam.isEmpty) {
        return const Left(
            AuthFailure(message: 'Usuario de login vacio para perfil'));
      }
      final rows = await _erp.ejecutarSP(
        nombreSP: AppEnvironment.spGetPerfilProfesional,
        parametros: [usuarioParam],
      );
      if (rows.isEmpty) {
        return const Left(
            ServerFailure(message: 'No se encontro perfil profesional'));
      }
      final row = rows.first;
      final perfil = _mapPerfil(row);
      await _ensurePerfilTable();
      await _db.customStatement(
        '''
        INSERT OR REPLACE INTO mma_perfil_usuario_local (
          codigo_usuario, nombre_completo, area_proviene, fundo, sede, dni,
          puesto_trabajo, codigo_trabajador, fecha_creacion_usuario,
          estado_usuario, sincronizado_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          perfil.codigoUsuario,
          perfil.nombreCompleto,
          perfil.areaProviene,
          perfil.fundo,
          perfil.sede,
          perfil.dni,
          perfil.puestoTrabajo,
          perfil.codigoTrabajador,
          perfil.fechaCreacionUsuario?.toIso8601String(),
          perfil.estadoUsuario,
          perfil.sincronizadoAt.toIso8601String(),
        ],
      );
      await _secureStorage.write(
        key: AppConstants.perfilCodigoKey,
        value: perfil.codigoUsuario,
      );
      await _secureStorage.write(
        key: AppConstants.loginUsuarioKey,
        value: usuarioParam,
      );
      return Right(perfil);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PerfilUsuario?>> getPerfilProfesionalLocal(
      String? codigoUsuario) async {
    try {
      await _ensurePerfilTable();
      final codigo = (codigoUsuario?.trim().isNotEmpty ?? false)
          ? codigoUsuario!.trim()
          : await _secureStorage.read(key: AppConstants.perfilCodigoKey);
      if (codigo == null || codigo.isEmpty) return const Right(null);
      final result = await _db.customSelect(
        '''
        SELECT * FROM mma_perfil_usuario_local
        WHERE codigo_usuario = ?
        LIMIT 1
        ''',
        variables: [Variable.withString(codigo)],
      ).getSingleOrNull();
      if (result == null) return const Right(null);
      final row = result.data;
      return Right(PerfilUsuario(
        codigoUsuario: row['codigo_usuario'] as String,
        nombreCompleto: row['nombre_completo'] as String? ?? '',
        areaProviene: row['area_proviene'] as String? ?? '',
        fundo: row['fundo'] as String? ?? '',
        sede: row['sede'] as String? ?? '',
        dni: row['dni'] as String?,
        puestoTrabajo: row['puesto_trabajo'] as String?,
        codigoTrabajador: row['codigo_trabajador'] as String?,
        fechaCreacionUsuario:
            DateTime.tryParse((row['fecha_creacion_usuario'] ?? '').toString()),
        estadoUsuario: row['estado_usuario'] as String? ?? '',
        sincronizadoAt:
            DateTime.tryParse((row['sincronizado_at'] ?? '').toString()) ??
                DateTime.now(),
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: AppConstants.tokenKey),
        _secureStorage.delete(key: AppConstants.userKey),
        _secureStorage.delete(key: AppConstants.perfilCodigoKey),
        _secureStorage.delete(key: AppConstants.loginUsuarioKey),
        // Invalidar token ERP para que el dispositivo no pueda usarlo
        // tras cerrar sesión (aunque su TTL de 8 h no haya expirado).
        _secureStorage.delete(key: AppEnvironment.erpTokenKey),
        _secureStorage.delete(key: AppEnvironment.erpTokenExpiryKey),
        // Limpiar credenciales guardadas para que el siguiente usuario
        // no vea pre-llenados los campos del usuario anterior.
        _secureStorage.delete(key: 'saved_usuario'),
        _secureStorage.delete(key: 'saved_password'),
        _secureStorage.delete(key: 'saved_rol'),
        // Eliminar sesión offline para que el siguiente logout impida re-entrada
        // sin red.
        _secureStorage.delete(key: 'session_usuario_json'),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Usuario?>> getUsuarioActual() async {
    try {
      final userJson = await _secureStorage.read(key: AppConstants.userKey);
      if (userJson == null) return const Right(null);
      var usuario = _usuarioFromJson(jsonDecode(userJson) as Map<String, dynamic>);

      // Auto-corrección: si trabajadorIdErp en caché es el código visible
      // (ej. 466620) en lugar del t.Id real del ERP, lo corrige desde el
      // catálogo local y actualiza la sesión persistida.
      if (usuario.codigo.isNotEmpty) {
        final trabajadorLocal =
            await _db.catalogoDao.getTrabajadorByCodigo(usuario.codigo);
        if (trabajadorLocal != null &&
            (trabajadorLocal.idErp != usuario.trabajadorIdErp ||
             trabajadorLocal.usuarioErpId != usuario.usuarioErpId)) {
          usuario = Usuario(
            id: usuario.id,
            codigo: usuario.codigo,
            nombres: usuario.nombres,
            apellidos: usuario.apellidos,
            dni: usuario.dni,
            telefono: usuario.telefono,
            email: usuario.email,
            pinHash: usuario.pinHash,
            usuarioErpId: trabajadorLocal.usuarioErpId,
            trabajadorIdErp: trabajadorLocal.idErp,
            rolId: usuario.rolId,
            rolNombre: usuario.rolNombre,
            fotoUrl: usuario.fotoUrl,
            activo: usuario.activo,
          );
          await _persistSession(usuario);
        }
      }

      return Right(usuario);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validarPin(String pin) async {
    try {
      final userJson = await _secureStorage.read(key: AppConstants.userKey);
      if (userJson == null) return const Right(false);
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      final codigo = data['codigo'] as String;
      final trabajador = await _db.catalogoDao.getTrabajadorByCodigo(codigo);
      if (trabajador == null) return const Right(false);
      return Right(trabajador.pinHash == _hashPin(pin));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveLastActivity() async {
    try {
      await _secureStorage.write(
        key: AppConstants.lastActivityKey,
        value: DateTime.now().toUtc().toIso8601String(),
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastActivity() async {
    try {
      final value =
          await _secureStorage.read(key: AppConstants.lastActivityKey);
      if (value == null || value.isEmpty) return const Right(null);
      return Right(DateTime.tryParse(value));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Sesión offline ───────────────────────────────────────────────────────

  /// Serializa [usuario] + [loginUsuario] + hash de [password] a SecureStorage
  /// bajo la clave `session_usuario_json`.
  Future<void> _persistOfflineSession(
      Usuario usuario, String loginUsuario, String password) async {
    final map = _usuarioToJson(usuario);
    map['login_usuario'] = loginUsuario;
    map['password_hash'] = _hashPin(password);
    await _secureStorage.write(
      key: 'session_usuario_json',
      value: jsonEncode(map),
    );
  }

  @override
  Future<Either<Failure, Usuario>> tryRestoreOfflineSession(
      String usuario, String password) async {
    try {
      final raw = await _secureStorage.read(key: 'session_usuario_json');
      if (raw == null || raw.isEmpty) {
        return const Left(AuthFailure(message: 'Sin sesión guardada'));
      }

      final data = jsonDecode(raw) as Map<String, dynamic>;

      // 1. Verificar que el nombre de usuario coincide
      final storedLogin = (data['login_usuario'] as String? ?? '').trim();
      if (storedLogin.toLowerCase() != usuario.trim().toLowerCase()) {
        return const Left(AuthFailure(
            message: 'Credenciales incorrectas: usuario diferente al guardado'));
      }

      // 2. Verificar hash de password
      final storedHash = data['password_hash'] as String? ?? '';
      if (_hashPin(password) != storedHash) {
        return const Left(
            AuthFailure(message: 'Credenciales incorrectas'));
      }

      // 3. Reconstruir objeto Usuario (sin `login_usuario` ni `password_hash`)
      final usuarioRestaurado = _usuarioFromJson(data);
      return Right(usuarioRestaurado);
    } catch (e) {
      return Left(CacheFailure(message: 'Error al leer sesión offline: $e'));
    }
  }

  /// Devuelve `true` si la excepción corresponde a un error de red/conectividad.
  bool _isNetworkError(Object e) {
    if (e is SocketException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection timed out') ||
        msg.contains('handshakeexception') ||
        msg.contains('timeoutexception') ||
        msg.contains('no route to host') ||
        msg.contains('os error');
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> _persistSession(Usuario u) => _secureStorage.write(
        key: AppConstants.userKey,
        value: jsonEncode(_usuarioToJson(u)),
      );

  Usuario _mapTrabajadorToUsuario(TrabajadoresLocalData t,
          {String? rolOverride}) =>
      Usuario(
        id: t.idErp.toString(),
        codigo: t.codTrabajador,
        nombres: t.nombres,
        apellidos: t.apellidos,
        dni: t.dni,
        usuarioErpId: t.usuarioErpId,
        trabajadorIdErp: t.idErp,
        rolId: (rolOverride ?? t.rolApk) == 'supervisor' ? 2 : 1,
        rolNombre: rolOverride ?? t.rolApk,
        activo: t.activo,
      );

  Usuario _usuarioFromJson(Map<String, dynamic> d) => Usuario(
        id: d['id'] as String,
        codigo: d['codigo'] as String,
        nombres: d['nombres'] as String,
        apellidos: d['apellidos'] as String,
        dni: d['dni'] as String?,
        telefono: d['telefono'] as String?,
        email: d['email'] as String?,
        usuarioErpId: d['usuario_erp_id'] as int?,
        trabajadorIdErp: d['trabajador_id_erp'] as int?,
        rolId: d['rol_id'] as int,
        rolNombre: d['rol_nombre'] as String? ?? 'operador',
        fotoUrl: d['foto_url'] as String?,
        activo: d['activo'] as bool? ?? true,
      );

  Map<String, dynamic> _usuarioToJson(Usuario u) => {
        'id': u.id,
        'codigo': u.codigo,
        'nombres': u.nombres,
        'apellidos': u.apellidos,
        'dni': u.dni,
        'telefono': u.telefono,
        'email': u.email,
        'usuario_erp_id': u.usuarioErpId,
        'trabajador_id_erp': u.trabajadorIdErp,
        'rol_id': u.rolId,
        'rol_nombre': u.rolNombre,
        'foto_url': u.fotoUrl,
        'activo': u.activo,
      };

  PerfilUsuario _mapPerfil(Map<String, dynamic> row) {
    // Intentar extraer IdUsuario entero del SP de perfil.
    // El campo puede llamarse 'IdUsuario', 'Id_Usuario', 'id_usuario', etc.
    // Si el SP no lo devuelve, queda null → se usará el catálogo local.
    final idUsuarioRaw = row['IdUsuario'] ??
        row['Id_Usuario'] ??
        row['id_usuario'] ??
        row['idUsuario'];
    final idUsuario = idUsuarioRaw != null
        ? int.tryParse(idUsuarioRaw.toString())
        : null;

    return PerfilUsuario(
      codigoUsuario:
          (row['CodigoUsuario'] ?? row['codigo_usuario'] ?? '').toString(),
      nombreCompleto:
          (row['NombreCompleto'] ?? row['nombre_completo'] ?? '').toString(),
      areaProviene:
          (row['AreaProviene'] ?? row['area_proviene'] ?? '').toString(),
      fundo: (row['Fundo'] ?? row['fundo'] ?? '').toString(),
      sede: (row['Sede'] ?? row['sede'] ?? '').toString(),
      dni: (row['DNI'] ?? row['dni'])?.toString(),
      puestoTrabajo:
          (row['PuestoTrabajo'] ?? row['puesto_trabajo'])?.toString(),
      codigoTrabajador:
          (row['CodigoTrabajador'] ?? row['codigo_trabajador'])?.toString(),
      fechaCreacionUsuario: DateTime.tryParse(
          (row['FechaCreacionUsuario'] ?? row['fecha_creacion_usuario'] ?? '')
              .toString()),
      estadoUsuario:
          (row['EstadoUsuario'] ?? row['estado_usuario'] ?? '').toString(),
      sincronizadoAt: DateTime.now(),
      idUsuario: idUsuario,
    );
  }

  Future<void> _ensurePerfilTable() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS mma_perfil_usuario_local (
        codigo_usuario TEXT PRIMARY KEY,
        nombre_completo TEXT,
        area_proviene TEXT,
        fundo TEXT,
        sede TEXT,
        dni TEXT,
        puesto_trabajo TEXT,
        codigo_trabajador TEXT,
        fecha_creacion_usuario TEXT,
        estado_usuario TEXT,
        sincronizado_at TEXT
      )
    ''');
  }

  String _extractNombres(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return '';
    final partes = nombreCompleto.split(',');
    if (partes.length > 1) {
      return partes[1].trim(); // Apellidos, Nombres -> Nombres
    }
    final espacio = nombreCompleto.lastIndexOf(' ');
    if (espacio != -1) {
      return nombreCompleto.substring(0, espacio).trim();
    }
    return nombreCompleto;
  }

  String _extractApellidos(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return '';
    final partes = nombreCompleto.split(',');
    if (partes.length > 1) {
      return partes[0].trim(); // Apellidos, Nombres -> Apellidos
    }
    final espacio = nombreCompleto.lastIndexOf(' ');
    if (espacio != -1) {
      return nombreCompleto.substring(espacio + 1).trim();
    }
    return '';
  }

  int? _parseIdErp(String? codigoTrabajador) {
    if (codigoTrabajador == null) return null;
    final digits = codigoTrabajador.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits);
  }

  // ─── Navegación dinámica desde BD ─────────────────────────────────────────

  /// Valida si el usuario tiene acceso al módulo seleccionado consultando el
  /// SP `CLI547_AGMSP_Obtener_Navegacion` (BD → no local).
  ///
  /// Retorna el [rolSeleccionado] si el SP confirma acceso a su ruta home.
  /// Retorna `null` si el SP indica que NO tiene permiso.
  ///
  /// Fallback: si [usuarioErpId] es null o el SP lanza excepción (red, timeout),
  /// se valida contra el [rolLocal] del catálogo local para no bloquear el acceso
  /// cuando la infraestructura falla momentáneamente.
  Future<String?> _resolverRolDesdeNavegacion({
    required int?   usuarioErpId,
    required String rolSeleccionado,
    required String? rolLocal,
  }) async {
    final rutaRequerida = _homeRouteForRol(rolSeleccionado);

    if (usuarioErpId != null) {
      try {
        final rows = await _erp.ejecutarSP(
          nombreSP: SpRegistry.spObtenerNavegacion,
          parametros: [usuarioErpId, 'AGROMOV'],
        );

        final rutasPermitidas = rows
            .map((r) => r['Ruta']?.toString() ?? '')
            .where((r) => r.isNotEmpty)
            .toSet();

        developer.log(
          '[AUTH/NAV] IdUsuario=$usuarioErpId rutasPermitidas=$rutasPermitidas '
          'rutaRequerida=$rutaRequerida',
          name: 'Auth',
        );

        // El SP devuelve solo las rutas que el usuario puede ver.
        // Si la ruta del módulo seleccionado no está → no tiene acceso.
        if (rutasPermitidas.contains(rutaRequerida)) {
          return rolSeleccionado; // acceso confirmado por BD
        }

        developer.log(
          '[AUTH/NAV] Acceso denegado: "$rutaRequerida" no está en las rutas '
          'permitidas para IdUsuario=$usuarioErpId',
          name: 'Auth',
        );
        return null; // denegado por BD
      } catch (e) {
        // El SP falló (red, SP no publicado, timeout).
        // Degradamos a la validación local para no bloquear el login.
        developer.log(
          '[AUTH/NAV] SP de navegación no disponible → fallback a rolLocal. '
          'Error: $e',
          name: 'Auth',
        );
      }
    }

    // Fallback: catálogo local (rolApk).
    // Solo si el catálogo tiene datos (rolLocal != null).
    // Si rolLocal también es null → catálogo vacío + SP no disponible
    // → no hay forma de validar → denegar (más seguro que asumir acceso).
    if (rolLocal == null) {
      developer.log(
        '[AUTH/NAV] Sin usuarioErpId ni catálogo local → sin datos para validar → denegado',
        name: 'Auth',
      );
      return null;
    }

    if (rolLocal == rolSeleccionado) return rolSeleccionado;

    developer.log(
      '[AUTH/NAV] Fallback local: rolLocal="$rolLocal" ≠ rolSeleccionado="$rolSeleccionado" → denegado',
      name: 'Auth',
    );
    return null;
  }

  /// Ruta home Flutter correspondiente a cada rol.
  /// Debe coincidir exactamente con las rutas cargadas en CLI547_AGM_Navegacion.
  static String _homeRouteForRol(String rol) {
    switch (rol) {
      case 'supervisor':
      case 'gerente':
        return '/supervisor/home';
      case 'portero':
        return '/portero/home';
      case 'mecanico':
        return '/mecanico/home';
      default: // 'operador' + cualquier rol no reconocido
        return '/operador/home';
    }
  }
}
