# MMA APK — Documentación Técnica Completa
## Módulo Maquinaria Agrícola · Agrokasa · v7.1.0

---

## Índice

1. [Visión General del Sistema](#1-visión-general-del-sistema)
2. [Arquitectura — Por qué Clean Architecture + BLoC](#2-arquitectura--por-qué-clean-architecture--bloc)
3. [Estructura de Carpetas](#3-estructura-de-carpetas)
4. [Inyección de Dependencias (GetIt)](#4-inyección-de-dependencias-getit)
5. [Árbol de BLoCs y Estado Global](#5-árbol-de-blocs-y-estado-global)
6. [Cómo llega una llamada al SP: flujo completo de capas](#6-cómo-llega-una-llamada-al-sp-flujo-completo-de-capas)
7. [Módulo: Autenticación](#7-módulo-autenticación)
8. [Módulo: Jornada del Operador](#8-módulo-jornada-del-operador)
9. [Módulo: Registro de Tractor](#9-módulo-registro-de-tractor)
10. [Módulo: Registro de Vehículo](#10-módulo-registro-de-vehículo)
11. [Módulo: Sincronización (Outbox)](#11-módulo-sincronización-outbox)
12. [Módulo: Supervisor](#12-módulo-supervisor)
13. [Módulo: Portero](#13-módulo-portero)
14. [Módulo: Admin](#14-módulo-admin)
15. [Módulo: Catálogos / Maestros](#15-módulo-catálogos--maestros)
16. [ErpApiClient — Cómo se ejecutan los SPs](#16-erpapiclient--cómo-se-ejecutan-los-sps)
17. [Roles del Sistema](#17-roles-del-sistema)
18. [Tablas SQL Server (AGKMMA)](#18-tablas-sql-server-agkmma)
19. [Procedimientos Almacenados — Referencia Completa](#19-procedimientos-almacenados--referencia-completa)
20. [Tablas SQLite Locales (Drift)](#20-tablas-sqlite-locales-drift)
21. [Navegación de Rutas](#21-navegación-de-rutas)
22. [Diagrama de Flujo General](#22-diagrama-de-flujo-general)
23. [Diagrama de Tablas y Relaciones](#23-diagrama-de-tablas-y-relaciones)

---

## 1. Visión General del Sistema

El **MMA APK** es una aplicación móvil Flutter para la gestión de maquinaria agrícola de Agrokasa. Permite registrar, controlar y aprobar la actividad diaria de tractores y vehículos de campo, funcionando **offline-first** con sincronización manual al ERP.

**Stack tecnológico:**
- **Frontend:** Flutter (Dart) · BLoC · GoRouter · GetIt
- **Base de datos local:** SQLite vía Drift (offline-first)
- **Base de datos remota:** SQL Server (esquema `AGKMMA`) vía REST proxy Agrokasa
- **Proxy REST:** `POST /EjecutarSPERP` → ejecuta Stored Procedures
- **Estado en tiempo real:** Cloud Firestore (alertas, incumplimientos)

**Principio offline-first:**
Todos los datos se guardan primero en SQLite local. Cuando el usuario presiona sync, el `SyncManager` procesa la tabla `OutboxEntries` en orden FIFO enviando cada entrada al SP correspondiente. Si no hay red, los datos quedan en cola sin pérdida.

---

## 2. Arquitectura — Por qué Clean Architecture + BLoC

### 2.1 Por qué Clean Architecture

Se adoptó **Clean Architecture** (Robert C. Martin) con tres capas bien separadas:

```
┌────────────────────────────────────────────────────────────┐
│  PRESENTATION (Pages + BLoC + Widgets)                      │
│  Sabe: cómo mostrar datos. No sabe: de dónde vienen.        │
│                    ↕ Events / States                         │
│  DOMAIN (UseCases + Entities + Repository interfaces)        │
│  Sabe: reglas de negocio. No sabe: HTTP ni SQLite.           │
│                    ↕ Repository contracts                    │
│  DATA (RepositoryImpl + DataSources)                         │
│  Sabe: HTTP, SQLite, SecureStorage. Implementa contratos.    │
│                    ↕                         ↕               │
│  SQLite / Drift               ErpApiClient (HTTP REST)       │
│  (offline-first)              → /EjecutarSPERP               │
│                                      ↓                       │
│                            SQL Server AGKMMA                 │
└────────────────────────────────────────────────────────────┘
```

**Razones concretas para este proyecto:**

| Problema del proyecto | Solución que da Clean Architecture |
|----------------------|-----------------------------------|
| La app debe funcionar sin internet | Capa Data tiene dos fuentes (SQLite + API); Domain no lo sabe |
| El ERP cambia sus SPs con frecuencia | Solo `RepositoryImpl` y `ErpApiClient` cambian; Pages y UseCases no se tocan |
| Varios roles con pantallas distintas | Cada feature tiene su propia carpeta con capas independientes |
| Tests sin servidor real | Domain y UseCases se testean con mocks de Repository |
| Múltiples desarrolladores | Contratos claros entre capas evitan pisar el trabajo del otro |

### 2.2 Por qué BLoC (Business Logic Component)

BLoC separa la lógica de la UI usando **Eventos** (inputs) y **Estados** (outputs):

```
UI presiona botón
    → agrega Evento al BLoC
    → BLoC procesa (llama UseCase)
    → BLoC emite nuevo Estado
    → UI reconstruye según Estado
```

**Por qué no setState o Provider:**
- La app tiene flujos complejos (offline/online, reintentos, timers)
- BLoC permite rastrear cada estado en el log (muy útil para debugging)
- Varios widgets que reaccionan al mismo estado (badge sync, progreso jornada, lista de registros)
- El historial de estados facilita reproducir bugs

### 2.3 Por qué GetIt (Service Locator)

Se usa **GetIt** como contenedor de dependencias porque:
- Es más ligero que Riverpod para este caso de uso
- Las dependencias se registran una sola vez en `injection_container.dart`
- Acceso global con `sl<Tipo>()` sin pasar el contexto de Flutter
- Compatible con BLoC sin boilerplate extra

---

## 3. Estructura de Carpetas

```
lib/
├── app.dart                    ← Root widget, MultiBlocProvider con 5 BLoCs globales
├── injection_container.dart    ← Registro de todas las dependencias (GetIt)
├── main.dart                   ← Punto de entrada, carga .env
│
├── core/
│   ├── config/
│   │   └── app_environment.dart   ← URLs, nombres de SPs, claves de storage
│   ├── constants/
│   │   └── app_constants.dart     ← Claves SharedPreferences / SecureStorage
│   ├── errors/
│   │   └── failures.dart          ← AuthFailure, NetworkFailure, ServerFailure, etc.
│   └── network/
│       └── network_info.dart      ← Detecta conectividad
│
├── infrastructure/
│   ├── database/
│   │   ├── app_database.dart      ← Clase Drift (SQLite), une todas las tablas
│   │   ├── app_database.g.dart    ← Código generado por Drift
│   │   ├── tables/                ← Definiciones de tablas Drift
│   │   └── daos/
│   │       ├── catalogo_dao.dart  ← CRUD de catálogos locales
│   │       ├── registro_dao.dart  ← CRUD de registros locales
│   │       └── outbox_dao.dart    ← Cola de sincronización
│   ├── network/
│   │   ├── erp_api_client.dart    ← Cliente HTTP al proxy REST del ERP
│   │   └── sp_contract.dart       ← Contratos de validación de SPs
│   └── services/
│       ├── sync_manager.dart          ← Procesa OutboxEntries → SPs
│       ├── status_sync_manager.dart   ← Jornadas: local SQLite + envío al SP
│       ├── device_service.dart        ← UUID del dispositivo
│       ├── firestore_service.dart     ← Integración Firestore (alertas)
│       └── daily_reset_service.dart   ← Reset a las 04:00 AM
│
├── features/
│   ├── operador/
│   │   ├── domain/
│   │   │   ├── entities/          ← Registro, Horometro, Paro, Bin, etc.
│   │   │   ├── repositories/      ← RegistroRepository (abstracto)
│   │   │   └── usecases/          ← CrearRegistro, CerrarTurno, RegistrarBin, etc.
│   │   ├── data/
│   │   │   └── registro_repository_impl.dart
│   │   └── presentation/
│   │       ├── blocs/             ← RegistroBloc, SyncBloc
│   │       └── pages/             ← 12 páginas del operador
│   ├── supervisor/
│   │   ├── domain/usecases/       ← GetJornadas, GetRegistros, AprobarRegistro
│   │   ├── data/
│   │   └── presentation/
│   │       ├── blocs/             ← SupervisorBloc
│   │       └── pages/             ← HomeSupervisorPage
│   ├── portero/
│   │   └── presentation/pages/    ← HomePorteroPage
│   └── admin/
│       └── presentation/pages/    ← HomeAdminPage
│
├── shared/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/usuario.dart
│   │   │   ├── repositories/auth_repository.dart
│   │   │   └── usecases/login_usecase.dart
│   │   ├── data/
│   │   │   └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── blocs/             ← AuthBloc, AuthEvent, AuthState
│   │       └── pages/             ← PinAccessPage, LoginPage
│   ├── catalogos/
│   │   └── presentation/blocs/    ← CatalogoBloc
│   ├── profile/
│   │   └── presentation/pages/    ← PerfilUsuarioPage
│   └── sync/
│       └── presentation/pages/    ← SyncMaestrosPage
│
└── router/
    └── app_router.dart            ← GoRouter, redirección por AuthState y rol
```

---

## 4. Inyección de Dependencias (GetIt)

Archivo: `lib/injection_container.dart`. Función `initDependencies()` se llama una sola vez en `main.dart`.

```
Orden de registro (las capas bajas primero):
1. Externos:     SharedPreferences, FlutterSecureStorage, Connectivity, DeviceInfo
2. Red:          NetworkInfo, ErpApiClient
3. Base de datos: AppDatabase (Drift/SQLite) + DAOs (CatalogoDao, RegistroDao, OutboxDao)
4. Servicios:    SyncManager, StatusSyncManager, FirestoreService, DeviceService, DailyResetService
5. Repositories: AuthRepositoryImpl, CatalogoRepositoryImpl, RegistroRepositoryImpl, SupervisorRepositoryImpl
6. UseCases:     LoginUseCase, CrearRegistroUseCase, CerrarTurnoUseCase, RegistrarBinUseCase,
                 RegistrarParoUseCase, GuardarChecklistUseCase, SincronizarCatalogosUseCase,
                 GetRegistrosSupervisorUseCase, AprobarRegistroUseCase, ...
7. BLoCs:        AuthBloc, CatalogoBloc, RegistroBloc, SyncBloc, SupervisorBloc
```

Para obtener una instancia en cualquier parte del código:
```dart
final syncManager = sl<SyncManager>();
final erp = sl<ErpApiClient>();
```

---

## 5. Árbol de BLoCs y Estado Global

```dart
// app.dart — MultiBlocProvider envuelve toda la app
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<AuthBloc>()..add(AuthCheckRequested())),
    BlocProvider(create: (_) => sl<CatalogoBloc>()),
    BlocProvider(create: (_) => sl<RegistroBloc>()),
    BlocProvider(create: (_) => sl<SyncBloc>()),
    BlocProvider(create: (_) => sl<SupervisorBloc>()),
  ],
  child: MaterialApp.router(routerConfig: createRouter(authBloc)),
)
```

| BLoC | Eventos | Estados | Páginas que lo consumen |
|------|---------|---------|------------------------|
| `AuthBloc` | CheckRequested, LoginRequested, PinGateRequested, LogoutRequested | Initial, Loading, PinValidated, Authenticated, Unauthenticated, FailureState | PinAccessPage, LoginPage, app_router |
| `CatalogoBloc` | LoadRequested, SyncRequested, SyncMaestrosRequested | Loading, Loaded, Error, SyncEnProgreso, SyncFinalizado | SyncMaestrosPage |
| `RegistroBloc` | RegistrosWatchRequested, RegistroCrearRequested, CerrarTurnoRequested, ... | Loading, Loaded, Creado, Error | HomeOperadorPage, CrearRegistroPage, CerrarTurnoPage |
| `SyncBloc` | ProcessOutboxRequested, WatchRequested | Initial, Syncing, Completed, Error | HomeOperadorPage (badge + dialog) |
| `SupervisorBloc` | GetRegistrosRequested, GetJornadasRequested, AprobarRequested | Loading, Loaded, Error | HomeSupervisorPage |

---

## 6. Cómo llega una llamada al SP: flujo completo de capas

Este es el patrón que siguen **todos** los módulos. Ejemplo: el operador presiona "INICIAR JORNADA".

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. PRESENTATION — BienvenidaTurnoPage                                │
│    _iniciarJornada() {                                               │
│      final usuarioId = authState.usuario.trabajadorIdErp;           │
│      await sl<StatusSyncManager>().guardarYEnviar(                  │
│        usuarioId: usuarioId,                                         │
│        dispositivoId: deviceId,                                      │
│        turno: _turno,                                                │
│        jornadaInicioAt: DateTime.now(),                              │
│      );                                                              │
│    }                                                                 │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ llama servicio directamente (no UseCase)
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. SERVICE — StatusSyncManager.guardarYEnviar()                      │
│    a. INSERT en SQLite: status_jornada_local                         │
│    b. Construye payload JSON:                                        │
│       {"usuario_id": 29273, "dispositivo_id": "...",                │
│        "turno": "noche", "jornada_inicio_at": "2026-06-05T..."}     │
│    c. Si hay red → envía directo al SP                               │
│    d. Si no hay red → INSERT en status_jornada_pendiente            │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. INFRASTRUCTURE — ErpApiClient.ejecutarSP()                        │
│    POST https://.../WSRESTMovilidadERPPruebas/api/EjecutarSPERP     │
│    Body: {                                                           │
│      "NombreSP": "AGKMMA.SP_MMA_ACTUALIZAR_STATUS_JORNADA",         │
│      "TipoRespuesta": 0,                                             │
│      "Parametros": [{"Nombre":"p_payload","Valor":"{...JSON...}"}]  │
│    }                                                                 │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ HTTP 200
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. SQL SERVER — AGKMMA.SP_MMA_ACTUALIZAR_STATUS_JORNADA              │
│    @v_usuario_id = JSON_VALUE(payload, '$.usuario_id')  → 29273     │
│    IF EXISTS (dispositivo+turno+fecha) → UPDATE jornada_fin_at      │
│    ELSE → INSERT INTO CLI547_MMA_STATUS_JORNADA                     │
│    SELECT 1 AS success, 'Status jornada actualizado' AS mensaje     │
└─────────────────────────────────────────────────────────────────────┘
```

**Nota:** Cuando el flujo pasa por BLoC (ej. crear registro), hay una capa adicional:
```
Page → BLoC.add(Evento) → BLoC._handler() → UseCase.call() → Repository.metodo() → ErpApiClient/SQLite
```

---

## 7. Módulo: Autenticación

### 7.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `PinAccessPage` | `shared/auth/presentation/pages/pin_access_page.dart` | UI de login (código + contraseña + rol) |
| `LoginPage` | `shared/auth/presentation/pages/login_page.dart` | Pantalla de carga mientras autentica |
| `AuthBloc` | `shared/auth/presentation/blocs/auth_bloc.dart` | Maneja eventos y estados de auth |
| `AuthEvent` | `shared/auth/presentation/blocs/auth_event.dart` | Eventos: CheckRequested, LoginRequested, PinGateRequested, LogoutRequested |
| `AuthState` | `shared/auth/presentation/blocs/auth_state.dart` | Estados: Initial, Loading, PinValidated, Authenticated, Unauthenticated, FailureState |
| `LoginUseCase` | `shared/auth/domain/usecases/login_usecase.dart` | Regla de negocio: login vía API ERP |
| `AuthRepository` | `shared/auth/domain/repositories/auth_repository.dart` | Contrato abstracto |
| `AuthRepositoryImpl` | `shared/auth/data/auth_repository_impl.dart` | Implementación: SQLite + ErpApiClient |
| `ErpApiClient` | `infrastructure/network/erp_api_client.dart` | HTTP al proxy ERP |
| `AppDatabase` | `infrastructure/database/app_database.dart` | SQLite vía Drift |
| `CatalogoDao` | `infrastructure/database/daos/catalogo_dao.dart` | Busca trabajador por código |

### 7.2 Flujo botón "INGRESAR" en PinAccessPage

```
PinAccessPage._submit()
    │
    │  context.read<AuthBloc>().add(
    │    AuthLoginRequested(
    │      codigo: _codigoCtrl.text,      // ej. "466620"
    │      pin: _passwordCtrl.text,        // contraseña ERP
    │      username: _codigoCtrl.text,
    │      password: _passwordCtrl.text,
    │      rol: _rolSeleccionado,           // 'operador' | 'supervisor' | 'portero'
    │    )
    │  )
    ▼
AuthBloc._onLoginRequested(event)
    │
    │  emit(AuthLoading)   ← UI muestra spinner
    │
    │  result = await _loginUseCase(
    │    LoginParams(username, password, rol)
    │  )
    ▼
LoginUseCase.call(params)
    │
    │  return _authRepository.loginConAPI(username, password, rol)
    ▼
AuthRepositoryImpl.loginConAPI(username, password, rol)
    │
    │  // PASO 1: Autenticar con ERP
    │  await _erp.authenticateWithCredentials(username, password)
    │    → POST /login/authenticate
    │    → guarda token JWT en SecureStorage (clave 'erp_token')
    │
    │  // PASO 2: Obtener perfil desde ERP
    │  perfilResult = await sincronizarPerfilProfesional(username)
    │    → _erp.ejecutarSP("dbo.SP_AGM_GetPerfilProfesional", [username])
    │    → guarda perfil en SQLite (tabla mma_perfil_usuario_local)
    │    → guarda codigo en SecureStorage (clave 'perfil_codigo')
    │
    │  // PASO 3: Resolver t.Id real del trabajador
    │  trabajadorLocal = await _db.catalogoDao.getTrabajadorByCodigo(username)
    │    → SELECT * FROM trabajadores_local WHERE cod_trabajador = '466620'
    │    → retorna idErp = 29273  (t.Id real de la tabla trabajadores del ERP)
    │  trabajadorIdErp = trabajadorLocal?.idErp ?? _parseIdErp(codigoTrabajador)
    │
    │  // PASO 4: Construir entidad Usuario
    │  usuario = Usuario(
    │    id: perfil.codigoUsuario,
    │    codigo: "466620",
    │    nombres: "Santiago",
    │    apellidos: "Marquez",
    │    trabajadorIdErp: 29273,   ← PK real del ERP
    │    rolId: 1,
    │    rolNombre: "operador",
    │    activo: true,
    │  )
    │
    │  // PASO 5: Persistir sesión
    │  await _persistSession(usuario)
    │    → SecureStorage.write(key: 'user', value: jsonEncode(usuario))
    │
    │  // PASO 6: Registrar sesión en ERP (best-effort)
    │  await _registrarSesion(usuario)
    │    → _erp.ejecutarSP("AGKMMA.SP_MMA_CREAR_SESION", [trabajadorIdErp, deviceId, token])
    │
    │  return Right(usuario)
    ▼
AuthBloc recibe Right(usuario)
    │
    │  emit(AuthAuthenticated(usuario: usuario))
    ▼
GoRouter (app_router.dart)
    │
    │  redirect: estado AuthAuthenticated → navega a '/sincronizando'
    ▼
SyncMaestrosPage.initState()
    │
    │  context.read<CatalogoBloc>().add(CatalogoSyncRequested())
    │  → sync de catálogos (trabajadores, tractores, procesos, etc.)
    │  → cuando termina → navega a home según rol:
    │    operador   → /bienvenida
    │    supervisor → /supervisor/home
    │    portero    → /portero/home
    │    admin      → /admin/home
    ▼
```

### 7.3 Restauración de sesión (app restart sin logout)

```
app.dart → AuthBloc..add(AuthCheckRequested())
    ▼
AuthBloc._onCheckRequested()
    │
    │  // Verificar timeout de 24h
    │  lastActivity = await _authRepository.getLastActivity()
    │  if elapsed > 24h → logout() → emit(AuthUnauthenticated)
    │
    │  result = await _authRepository.getUsuarioActual()
    ▼
AuthRepositoryImpl.getUsuarioActual()
    │
    │  userJson = await SecureStorage.read(key: 'user')
    │  usuario = _usuarioFromJson(userJson)
    │
    │  // Auto-corrección del trabajadorIdErp
    │  trabajadorLocal = await _db.catalogoDao.getTrabajadorByCodigo(usuario.codigo)
    │  if (trabajadorLocal.idErp != usuario.trabajadorIdErp)
    │    → reconstruye usuario con idErp correcto
    │    → sobrescribe SecureStorage  ← arregla sesiones viejas con código en lugar de Id
    │
    │  return Right(usuario)
    ▼
AuthBloc → emit(AuthAuthenticated(usuario))
→ GoRouter redirige directo al home del rol (no pasa por sync de catálogos)
```

---

## 8. Módulo: Jornada del Operador

### 8.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `BienvenidaTurnoPage` | `features/operador/presentation/pages/bienvenida_turno_page.dart` | UI de bienvenida e inicio de jornada |
| `StatusSyncManager` | `infrastructure/services/status_sync_manager.dart` | Persiste jornada en SQLite + envía SP |
| `ErpApiClient` | `infrastructure/network/erp_api_client.dart` | Ejecuta el SP en SQL Server |
| `DeviceService` | `infrastructure/services/device_service.dart` | Devuelve el UUID del dispositivo |
| `AuthBloc` | `shared/auth/presentation/blocs/auth_bloc.dart` | Provee `usuario.trabajadorIdErp` |

### 8.2 Flujo botón "INICIAR JORNADA"

```
BienvenidaTurnoPage
    │
    │  initState():
    │    _detectarTurnoYPuntualidad()   → calcula si es turno día (06-14h) o noche (14-22h)
    │    _verificarJornadaActiva()      → revisa si ya hay jornada abierta hoy
    │      → statusMgr.tieneJornadaActiva(deviceId)
    │          SELECT id FROM status_jornada_local
    │          WHERE dispositivo_id=? AND jornada_fin_at IS NULL AND fecha=hoy
    │      → statusMgr.tieneJornadaParaUsuarioYTurno(usuarioId, turno)
    │          Primero: SharedPreferences.getBool("jornada_29273_noche_20260605")
    │          Luego:   SELECT id FROM status_jornada_local WHERE usuario_id=? AND turno=?
    │      Si ya tiene jornada → context.go('/operador/home')  [sin crear nueva]
    │
    │  Usuario presiona "INICIAR JORNADA"
    │    _iniciarJornada()
    │      usuarioId = authState.usuario.trabajadorIdErp   // 29273
    │      deviceId  = await sl<DeviceService>().getDeviceId()
    │
    │      await statusMgr.guardarYEnviar(
    │        usuarioId: 29273,
    │        dispositivoId: "BP2A.250605.031.A3",
    │        turno: "noche",
    │        jornadaInicioAt: DateTime.now(),
    │      )
    ▼
StatusSyncManager.guardarYEnviar()
    │
    │  // 1. Verificar que usuarioId sea válido
    │  if (usuarioId <= 0) throw ArgumentError(...)
    │
    │  // 2. UPSERT en SQLite local
    │  existing = SELECT id FROM status_jornada_local
    │             WHERE dispositivo_id=? AND turno=? AND fecha=hoy
    │  if existing: UPDATE status_jornada_local SET jornada_fin_at=NULL, sincronizado=0
    │  else:        INSERT INTO status_jornada_local
    │               (usuario_id=29273, dispositivo_id, turno, jornada_inicio_at, sincronizado=0)
    │
    │  // 3. Construir payload JSON
    │  payload = {
    │    "usuario_id": 29273,
    │    "dispositivo_id": "BP2A.250605.031.A3",
    │    "turno": "noche",
    │    "jornada_inicio_at": "2026-06-05T17:00:00.000"
    │    // nota: hora local, no UTC, para que el SP compare fechas correctamente
    │  }
    │
    │  // 4. Enviar al ERP (si hay red)
    │  if (await _networkInfo.isConnected)
    │    await _erp.ejecutarSP(
    │      nombreSP: "AGKMMA.SP_MMA_ACTUALIZAR_STATUS_JORNADA",
    │      parametros: [jsonEncode(payload)],
    │    )
    │    → SQL Server hace UPSERT en CLI547_MMA_STATUS_JORNADA
    │    → supervisor ve la jornada activa en tiempo real
    │    → UPDATE status_jornada_local SET sincronizado=1
    │  else:
    │    INSERT INTO status_jornada_pendiente (payload_json, intentos=0)
    │    → StatusSyncManager.processPending() lo enviará cuando haya red
    ▼
BienvenidaTurnoPage (tras guardarYEnviar)
    │
    │  await statusMgr.marcarJornadaIniciada(29273, "noche")
    │    → SharedPreferences.setBool("jornada_29273_noche_20260605", true)
    │    [persiste aunque el usuario haga logout o borre datos locales]
    │
    │  context.go('/operador/home')
```

### 8.3 SP que se ejecuta: `SP_MMA_ACTUALIZAR_STATUS_JORNADA`

```sql
-- Recibe el JSON, deserializa, y hace UPSERT en CLI547_MMA_STATUS_JORNADA
-- Clave única: (dispositivo_id, turno, CAST(jornada_inicio_at AS DATE))
-- Si ya existe la fila: solo actualiza jornada_fin_at y updated_at
-- Si no existe: INSERT con usuario_erp_id = 29273 (t.Id real del trabajador)
-- El supervisor SP luego hace: JOIN trabajadores t ON t.Id = j.usuario_erp_id
-- → necesita el t.Id real, no el código visible "466620"
```

---

## 9. Módulo: Registro de Tractor

### 9.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `HomeOperadorPage` | `features/operador/presentation/pages/home_page.dart` | Dashboard + lista de registros del día |
| `CrearRegistroPage` | `features/operador/presentation/pages/crear_registro_page.dart` | Formulario de nuevo registro tractor |
| `ChecklistPage` | `features/operador/presentation/pages/checklist_page.dart` | Checklist pre-operacional |
| `BinesPage` | `features/operador/presentation/pages/bines_page.dart` | Registro de bins de cosecha |
| `ParosPage` | `features/operador/presentation/pages/paros_page.dart` | Registro de paros de maquinaria |
| `CerrarTurnoPage` | `features/operador/presentation/pages/cerrar_turno_page.dart` | Cierre del turno con datos finales |
| `RegistroBloc` | `features/operador/presentation/blocs/registro_bloc.dart` | Estado de registros |
| `SyncBloc` | `shared/sync/presentation/blocs/sync_bloc.dart` | Estado de sincronización |
| `RegistroRepository` | `features/operador/domain/repositories/registro_repository.dart` | Contrato |
| `RegistroRepositoryImpl` | `features/operador/data/registro_repository_impl.dart` | SQLite + Outbox |
| `RegistroDao` | `infrastructure/database/daos/registro_dao.dart` | CRUD SQLite |
| `OutboxDao` | `infrastructure/database/daos/outbox_dao.dart` | Cola de sync |

### 9.2 Flujo completo: de "+" en home a SP en SQL Server

```
HomeOperadorPage
    │
    │  initState():
    │    context.read<RegistroBloc>().add(RegistrosWatchRequested())
    │    → RegistroBloc llama RegistroRepository.watchRegistros()
    │    → SELECT * FROM registros_diarios_local WHERE fecha=hoy ORDER BY created_at DESC
    │    → Stream que actualiza la UI en tiempo real al cambiar datos locales
    │
    │  Usuario presiona FAB ("+")
    │    → BottomSheet con opciones: "TRACTOR" o "VEHÍCULO"
    │
    │  Usuario elige "TRACTOR"
    │    context.go('/registro/nuevo')
    ▼
CrearRegistroPage
    │
    │  Formulario (todos los campos tienen dropdown de catálogos locales):
    │    - Proceso     → context.read<CatalogoBloc>().state.procesos
    │    - Subproceso  → _erp.ejecutarSP("SP_MMA_ERP_GET_SUBPROCESOS", [procesoId])
    │    - Cultivo     → state.cultivos
    │    - Operador    → state.trabajadores
    │    - Tractor     → state.tractores
    │    - Implemento  → state.implementos
    │    - Supervisor  → state.trabajadores (filtrado por rol)
    │    - Horómetros inicio: campos numéricos
    │    - Horarios:   hora_salida_taller, hora_llegada_punto
    │
    │  Usuario presiona "GUARDAR"
    │    context.read<RegistroBloc>().add(
    │      RegistroCrearRequested(datosRegistro)
    │    )
    ▼
RegistroBloc._onCrear(event)
    │
    │  emit(RegistroLoading)
    │  result = await _crearRegistroUseCase(params)
    ▼
CrearRegistroUseCase.call(params)
    │
    │  return _registroRepository.crearRegistro(params)
    ▼
RegistroRepositoryImpl.crearRegistro(params)
    │
    │  // 1. Generar UUID local
    │  localId = Uuid().v4()   // ej. "a1b2c3d4-..."
    │
    │  // 2. Guardar en SQLite (offline-first)
    │  await _db.registroDao.insertRegistro(
    │    RegistrosDiariosCompanion(
    │      id: Value(localId),
    │      numeroRegistro: Value("RD-20260605-001"),
    │      fecha: Value(hoy),
    │      turno: Value("noche"),
    │      procesoId: Value(procesoId),
    │      operadorIdErp: Value(29273),
    │      nombreOperadorSnapshot: Value("Santiago Marquez"),
    │      tractorIdErp: Value(tractorId),
    │      ... todos los campos
    │      estado: Value("borrador"),
    │      sincronizado: Value(false),
    │    )
    │  )
    │
    │  // 3. Guardar horómetros en SQLite
    │  await _db.registroDao.insertHorometro(...)
    │
    │  // 4. Guardar tiempos de turno en SQLite
    │  await _db.registroDao.insertTiempoTurno(...)
    │
    │  // 5. Agregar a la cola Outbox
    │  await _db.outboxDao.insertEntry(
    │    OutboxEntriesCompanion(
    │      registroLocalId: Value(localId),
    │      endpoint: Value("/registros"),
    │      method: Value("POST"),
    │      payloadJson: Value(jsonEncode({
    │        "id": localId,
    │        "numero_registro": "RD-20260605-001",
    │        "operador_id_erp": 29273,
    │        "tractor_id_erp": tractorId,
    │        ... todos los campos
    │      })),
    │      status: Value("pending"),
    │      retryCount: Value(0),
    │    )
    │  )
    │
    │  return Right(localId)
    ▼
RegistroBloc → emit(RegistroCreado(registroId: localId))
    │
    │  context.go('/registro/$localId/checklist')
    ▼
ChecklistPage
    │
    │  Carga ítems del catálogo local (24 ítems tipo 'tractor')
    │    → context.read<CatalogoBloc>().state.checklistItems
    │      .where((i) => i.tipoRegistro == 'tractor')
    │
    │  Usuario evalúa cada ítem: bien / mal / na
    │
    │  Usuario presiona "GUARDAR CHECKLIST"
    │    → INSERT INTO checklist_resultados_local (registroId, itemId, resultado, observacion)
    │    → INSERT INTO outbox_entries:
    │        endpoint: "/registro/$id/checklist"
    │        method: "POST"
    │        payload: JSON array de resultados
    │    → context.go('/registro/$id/bines') [si proceso.requiere_bines]
    │    → context.go('/registro/$id/paros') [si no requiere bins]
    ▼
BinesPage  [si proceso.requiere_bines = true]
    │
    │  Tabla de franjas horarias (06-08, 08-10, ..., 22-00)
    │  Usuario ingresa cantidad por franja
    │
    │  Guardar:
    │    → UPSERT en cosecha_bines_local por (registroId, franja)
    │    → INSERT INTO outbox_entries:
    │        endpoint: "/registro/$id/bines"
    │        payload: [{franja_horaria, turno_franja, cantidad}]
    │    → context.go('/registro/$id/paros')
    ▼
ParosPage
    │
    │  Lista de paros registrados (de SQLite local)
    │  Botón "+ AGREGAR PARO"
    │    → Dialog con: tipo_paro, motivo, hora_inicio, hora_final, galones, equipo
    │    → INSERT INTO paros_equipos_local
    │    → INSERT INTO outbox_entries:
    │        endpoint: "/registro/$id/paros"
    │        payload: {tipo_paro_id, motivo, hora_inicio, hora_final, galones}
    │
    │  "CONTINUAR" → context.go('/registro/$id/cerrar')
    ▼
CerrarTurnoPage
    │
    │  Campos:
    │    - Horómetro tractor final
    │    - Horómetro implemento final
    │    - Hora salida punto
    │    - Hora llegada taller
    │    - Hora refrigerio
    │    - Lotes trabajados (multi-select)
    │    - Sublabores adicionales
    │    - Marchas usadas + horas
    │    - Observaciones
    │
    │  Usuario presiona "CERRAR TURNO"
    │    → UPDATE registros_diarios_local SET estado='completado'
    │    → INSERT INTO outbox_entries:
    │        endpoint: "/registro/$id/cerrar"
    │        method: "PUT"
    │        payload: {horometro_final, tiempos, lotes, sublabores, marchas, observaciones}
    │    → context.go('/operador/home')
    │
    │  En /operador/home: badge del registro cambia a "Completado / Pendiente sync"
```

### 9.3 SPs ejecutados (vía SyncManager al presionar sync)

```
outbox_entries → SyncManager.processOutbox() → ErpApiClient.ejecutarSP()

Entry 1: POST /registros
    → SP_MMA_SINCRONIZAR_OFFLINE(@p_payload JSON completo)
    → INSERT CLI547_MMA_REGISTROS_DIARIOS
    → UPSERT CLI547_MMA_HOROMETROS
    → UPSERT CLI547_MMA_TIEMPOS_TURNO
    → retorna registro_id (puede ser distinto al UUID local)
    → si GUID cambió: SyncManager actualiza todas las tablas hijas en cascada

Entry 2: POST /registro/:id/checklist
    → SP_MMA_GUARDAR_CHECKLIST(@p_registro_id, @p_numero_registro, @p_resultados JSON)
    → MERGE CLI547_MMA_CHECKLIST_RESULTADOS

Entry 3: POST /registro/:id/bines   [si aplica]
    → SP_MMA_REGISTRAR_BIN(@p_registro_id, @p_franja_horaria, @p_cantidad, ...)
    → UPSERT CLI547_MMA_COSECHA_BINES

Entry 4: POST /registro/:id/paros   [uno por paro]
    → SP_MMA_REGISTRAR_PARO(@p_registro_id, @p_tipo_paro_id, @p_hora_inicio, ...)
    → INSERT CLI547_MMA_PAROS_EQUIPOS

Entry 5: PUT /registro/:id/cerrar
    → SP_MMA_CERRAR_TURNO(@p_registro_id, @p_tractor_final, @p_lotes JSON, ...)
    → UPDATE CLI547_MMA_HOROMETROS (finales)
    → UPDATE CLI547_MMA_TIEMPOS_TURNO (finales)
    → DELETE+INSERT CLI547_MMA_REGISTROS_SUBLABORES
    → DELETE+INSERT CLI547_MMA_REGISTROS_MARCHAS
    → UPDATE CLI547_MMA_REGISTROS_DIARIOS SET estado='completado'
```

---

## 10. Módulo: Registro de Vehículo

### 10.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `RegistroVehiculoPage` | `features/operador/presentation/pages/registro_vehiculo_page.dart` | Formulario completo de vehículo |
| `EditarRegistroVehiculoPage` | `features/operador/presentation/pages/editar_registro_vehiculo_page.dart` | Edición de registro vehículo |

### 10.2 Diferencia clave con Tractor

El registro de vehículo se envía como **un solo payload completo** (tractor usa múltiples outbox entries):

```
RegistroVehiculoPage: usuario completa TODOS los campos (sin flujo multi-paso)
    │
    │  Campos: proceso_vehiculo, operador, vehículo, km_inicio/final,
    │          combustibles (tancadas), paros vehículo, checklist, horarios
    │
    │  Guardar:
    │    → INSERT en registros_vehiculo_local
    │    → INSERT en outbox_entries:
    │        endpoint: "/registros/vehiculo"
    │        payload: JSON con TODO incluido (combustibles + paros + checklist)
    │        [Un solo entry en lugar de 5 como en tractor]
    ▼
SyncManager → SP_MMA_SINCRONIZAR_OFFLINE
    → procesa_vehiculo = true
    → INSERT CLI547_MMA_REGISTROS_DIARIOS (tipo_registro='vehiculo')
    → MERGE CLI547_MMA_COMBUSTIBLE_VEHICULO
    → MERGE CLI547_MMA_PAROS_VEHICULO
    → MERGE CLI547_MMA_CHECKLIST_RESULTADOS
```

---

## 11. Módulo: Sincronización (Outbox)

### 11.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `SyncBloc` | `shared/sync/presentation/blocs/sync_bloc.dart` | Estado de sync en UI |
| `SyncManager` | `infrastructure/services/sync_manager.dart` | Procesa OutboxEntries |
| `OutboxDao` | `infrastructure/database/daos/outbox_dao.dart` | CRUD de la cola |
| `ErpApiClient` | `infrastructure/network/erp_api_client.dart` | Ejecuta SPs |

### 11.2 Flujo botón "sync" (ícono nube en HomeOperadorPage)

```
HomeOperadorPage
    │
    │  Usuario presiona ícono de sync
    │    context.read<SyncBloc>().add(SyncProcessOutboxRequested())
    ▼
SyncBloc._onProcessOutbox()
    │
    │  emit(SyncSyncing)  ← spinner en UI
    │  result = await _syncManager.processOutbox()
    ▼
SyncManager.processOutbox()
    │
    │  // 1. Leer cola FIFO
    │  entries = SELECT * FROM outbox_entries
    │            WHERE status IN ('pending','failed')
    │            ORDER BY timestamp ASC
    │
    │  // 2. Verificar red
    │  if (!await _networkInfo.isConnected) return SyncResult(failed: entries.length)
    │
    │  // 3. Procesar cada entry en orden
    │  for entry in entries:
    │
    │    // 3a. Marcar como 'syncing'
    │    UPDATE outbox_entries SET status='syncing' WHERE id=entry.id
    │
    │    // 3b. Ejecutar el SP correspondiente
    │    response = await _executeRequest(entry.endpoint, entry.method, entry.payload)
    │      ├── POST /registros           → ejecutarSP("SP_MMA_SINCRONIZAR_OFFLINE", ...)
    │      ├── POST /registros/vehiculo  → ejecutarSP("SP_MMA_SINCRONIZAR_OFFLINE", ...)
    │      ├── PUT  /registros/vehiculo  → ejecutarSP("SP_MMA_SINCRONIZAR_OFFLINE", ...)
    │      ├── POST /.../checklist       → ejecutarSP("SP_MMA_GUARDAR_CHECKLIST", ...)
    │      ├── POST /.../bines           → ejecutarSP("SP_MMA_REGISTRAR_BIN", ...)
    │      ├── POST /.../paros           → ejecutarSP("SP_MMA_REGISTRAR_PARO", ...)
    │      ├── PUT  /.../cerrar          → ejecutarSP("SP_MMA_CERRAR_TURNO", ...)
    │      ├── PUT  /.../aprobar         → ejecutarSP("SP_MMA_APROBAR_REGISTRO", ...)
    │      ├── POST /jornada             → ejecutarSP("SP_MMA_REGISTRAR_JORNADA", ...)
    │      └── POST /portero/lecturas    → ejecutarSP("SP_MMA_REGISTRAR_LECTURA_PORTERO", ...)
    │
    │    // 3c. Manejar GUID mismatch (ERP asigna ID diferente al UUID local)
    │    if response.registroId != null && response.registroId != entry.registroLocalId:
    │      → guidMap[localId] = serverId
    │      → UPDATE registros_diarios_local SET id=serverId WHERE id=localId
    │      → UPDATE horometros_local SET registro_id=serverId WHERE registro_id=localId
    │      → UPDATE paros_equipos_local SET registro_id=serverId WHERE registro_id=localId
    │      → UPDATE outbox_entries SET registro_local_id=serverId WHERE registro_local_id=localId
    │      [cascada en transacción SQLite]
    │
    │    // 3d. Marcar como 'done'
    │    UPDATE outbox_entries SET status='done' WHERE id=entry.id
    │    → registroDao.markSincronizado(registroId)
    │      → badge en UI: "Sinc." (verde)
    │
    │    // 3e. Manejo de errores
    │    SpValidationException → UPDATE status='permanently_failed' [bug de contrato]
    │    ConflictException     → UPDATE status='done' [ya existe en servidor, OK]
    │    NetworkException      → UPDATE status='failed', break [reintentará después]
    │    ServerException (retry >= 5) → UPDATE status='permanently_failed'
    │
    │  return SyncResult { succeeded, failed, permanentlyFailed }
    ▼
SyncBloc → emit(SyncCompleted(result))
    │
    │  HomeOperadorPage muestra SyncDetailDialog:
    │    ✓ N registros sincronizados
    │    ✗ M fallaron (con mensaje de error)
    │    ✗✗ P fallaron permanentemente
```

---

## 12. Módulo: Supervisor

### 12.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `HomeSupervisorPage` | `features/supervisor/presentation/pages/home_supervisor_page.dart` | 3 pestañas: Turno, Aprobaciones, Historial |
| `SupervisorBloc` | `features/supervisor/presentation/blocs/supervisor_bloc.dart` | Estado de datos del supervisor |
| `GetJornadasSupervisorUseCase` | `features/supervisor/domain/usecases/` | Consulta jornadas activas |
| `GetRegistrosSupervisorUseCase` | `features/supervisor/domain/usecases/` | Consulta registros a aprobar |
| `AprobarRegistroUseCase` | `features/supervisor/domain/usecases/` | Aprueba o rechaza |
| `SupervisorRepositoryImpl` | `features/supervisor/data/` | Llama ErpApiClient directamente |
| `ErpApiClient` | `infrastructure/network/erp_api_client.dart` | Ejecuta SPs del supervisor |

### 12.2 Pestaña "TURNO" — ver operadores activos

```
HomeSupervisorPage._cargarJornadas()   [timer cada 30 seg]
    │
    │  rows = await _erp.getJornadasSupervisor(fecha: hoy, turno: _turnoFiltro)
    │    → ejecutarSP("AGKMMA.SP_MMA_GET_JORNADAS_SUPERVISOR", [fecha, turno])
    ▼
SP_MMA_GET_JORNADAS_SUPERVISOR
    │
    │  SELECT
    │    j.usuario_erp_id,
    │    CONCAT(s.PrimerApellido,' ',s.SegundoApellido,' ',s.Nombre) AS nombre_usuario,
    │    j.turno, j.jornada_inicio_at, j.jornada_fin_at,
    │    jornada_cerrada, total_registros, registros_sincronizados, registros_completados
    │  FROM CLI547_MMA_STATUS_JORNADA j
    │  LEFT JOIN trabajadores t ON t.Id = j.usuario_erp_id   ← necesita t.Id (29273), no código
    │  LEFT JOIN sujetos s      ON s.Id = t.Id_Sujeto
    │  WHERE CAST(jornada_inicio_at AS DATE) = @p_fecha
    ▼
HomeSupervisorPage: muestra tarjeta por operador con:
    - Nombre del operador (gracias al JOIN correcto)
    - Turno activo/cerrado
    - Conteo de registros
```

### 12.3 Pestaña "APROBACIONES" — aprobar registro

```
HomeSupervisorPage._cargarRegistros()
    │
    │  rows = await _erp.getRegistrosSupervisor(supervisorId, fecha, turno)
    │    → ejecutarSP("AGKMMA.SP_MMA_GET_REGISTROS_SUPERVISOR", [supervisorId, fecha, turno])
    │  Muestra lista de registros con estado 'completado'
    │
    │  Supervisor toca un registro → ve detalles (checklist, bines, paros, horómetros)
    │
    │  Supervisor presiona "APROBAR" o "RECHAZAR"
    │    context.read<SupervisorBloc>().add(
    │      AprobarRegistroRequested(
    │        registroId: id,
    │        accion: "aprobar",   // o "rechazar"
    │        motivo: null,        // requerido si rechaza
    │      )
    │    )
    ▼
SupervisorBloc → AprobarRegistroUseCase → SupervisorRepositoryImpl
    │
    │  // Si hay red: envío directo
    │  await _erp.ejecutarSP(
    │    nombreSP: "AGKMMA.SP_MMA_APROBAR_REGISTRO",
    │    parametros: [registroId, supervisorIdErp, "aprobar", null]
    │  )
    │  // Si no hay red: agrega al Outbox
    │  INSERT INTO outbox_entries endpoint="/registros/$id/aprobar"
    ▼
SP_MMA_APROBAR_REGISTRO
    │
    │  1. Valida que el registro existe y está en estado 'completado'
    │  2. Idempotencia: si ya está 'aprobado', retorna success=1 sin modificar
    │  3. UPDATE CLI547_MMA_REGISTROS_DIARIOS
    │       SET estado='aprobado',
    │           aprobado_por_erp=supervisorIdErp,
    │           aprobado_at=GETUTCDATE()
    │  4. Si accion='rechazar': también guarda motivo_rechazo
    │  5. Llama SP_MMA_ENVIAR_NOTIFICACION para notificar al operador
```

---

## 13. Módulo: Portero

### 13.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `HomePorteroPage` | `features/portero/presentation/pages/home_portero_page.dart` | Escaneo secuencial de QR/códigos |
| `OutboxDao` | `infrastructure/database/daos/outbox_dao.dart` | Cola de sync |

### 13.2 Flujo escaneo QR → SP

```
HomePorteroPage
    │
    │  initState(): carga historial del día desde SQLite (portero_lecturas_local)
    │
    │  Flujo secuencial de escaneo:
    │  1. Escanea TRACTOR   → _tractorLeido  = {id, codigo, timestamp}
    │  2. Escanea IMPLEMENTO → _implementoLeido
    │  3. Escanea OPERADOR  → _trabajadorLeido
    │  4. Selecciona CULTIVO → _cultivoSeleccionado (dropdown catálogo)
    │  5. Escribe COMENTARIO (opcional)
    │
    │  Botón "REGISTRAR LECTURA"
    │    → INSERT INTO portero_lecturas_local (todos los datos)
    │    → INSERT INTO outbox_entries:
    │        endpoint: "/portero/lecturas"
    │        method: "POST"
    │        payload: {
    │          portero_id_erp: 29273,
    │          tractor_id_erp, tractor_codigo, tractor_leido_at,
    │          implemento_id_erp, implemento_codigo, implemento_leido_at,
    │          trabajador_id_erp, trabajador_codigo, operador_leido_at,
    │          cultivo_id_erp, cultivo_nombre,
    │          comentario, dispositivo_id
    │        }
    │    → Muestra en historial del día
    ▼
SyncManager → SP_MMA_REGISTRAR_LECTURA_PORTERO(@p_payload JSON)
    → INSERT INTO CLI547_MMA_PORTERO_LECTURAS
    → visible en dashboard admin
```

---

## 14. Módulo: Admin

### 14.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `HomeAdminPage` | `features/admin/presentation/pages/home_admin_page.dart` | Dashboard KPIs + 3 pestañas |
| `FirestoreService` | `infrastructure/services/firestore_service.dart` | Alertas en tiempo real |
| `ErpApiClient` | `infrastructure/network/erp_api_client.dart` | KPIs desde SP |

### 14.2 Flujo del dashboard

```
HomeAdminPage.initState()
    │
    │  // 1. Clock: actualiza hora cada 30 seg
    │  Timer.periodic(30s, _actualizarReloj)
    │
    │  // 2. Polling ERP: KPIs cada 45 seg
    │  Timer.periodic(45s, _cargarDatos)
    │    → _erp.ejecutarSP("SP_MMA_GET_REPORTE_SUPERVISOR", [fecha, turno])
    │    → _erp.ejecutarSP("SP_MMA_GET_JORNADAS_SUPERVISOR", [fecha, turno])
    │
    │  // 3. Firestore: escucha alertas/incumplimientos en tiempo real
    │  _firestoreService.alertasStream().listen((alertas) {
    │    setState(() => _alertas = alertas)
    │  })
    │
    │  Pestañas:
    │    [TURNO]        → jornadas activas del día
    │    [REGISTROS]    → KPIs: horas, bins, paros, hectáreas
    │    [ALERTAS]      → incumplimientos desde Firestore en tiempo real
    │
    │  Botones:
    │    "EXPORTAR PDF" → PdfService.generarReporte(datos) → Share/Print
    │    "EXPORTAR CSV" → convierte datos a CSV → descarga
```

---

## 15. Módulo: Catálogos / Maestros

### 15.1 Clases involucradas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `SyncMaestrosPage` | `shared/sync/presentation/pages/sync_maestros_page.dart` | UI de carga post-login |
| `CatalogoBloc` | `shared/catalogos/presentation/blocs/catalogo_bloc.dart` | Estado de catálogos |
| `SincronizarCatalogosUseCase` | `shared/catalogos/domain/usecases/` | Descarga todos los maestros |
| `CatalogoRepositoryImpl` | `shared/catalogos/data/` | Llama ERP + guarda en SQLite |
| `CatalogoDao` | `infrastructure/database/daos/catalogo_dao.dart` | CRUD catálogos locales |

### 15.2 Flujo de sincronización de catálogos

```
SyncMaestrosPage.initState()
    │
    │  context.read<CatalogoBloc>().add(CatalogoSyncRequested())
    ▼
CatalogoBloc._onSync()
    │
    │  emit(CatalogoSyncEnProgreso)  ← spinner + "Sincronizando..."
    │  result = await _sincronizarCatalogosUseCase()
    ▼
SincronizarCatalogosUseCase → CatalogoRepositoryImpl.sincronizarTodo()
    │
    │  // Un solo SP descarga todos los maestros
    │  rows = await _erp.ejecutarSP(
    │    "AGKMMA.SP_MMA_ERP_SYNC_PAYLOAD_COMPLETO",
    │    parametros: []
    │  )
    │
    │  // Guarda en SQLite paralelo (Future.wait)
    │  await Future.wait([
    │    _db.catalogoDao.upsertProcesos(rows['procesos']),
    │    _db.catalogoDao.upsertTractores(rows['tractores']),
    │    _db.catalogoDao.upsertImplementos(rows['implementos']),
    │    _db.catalogoDao.upsertTrabajadores(rows['trabajadores']),  // incluye t.Id real
    │    _db.catalogoDao.upsertLotes(rows['lotes']),
    │    _db.catalogoDao.upsertCultivos(rows['cultivos']),
    │    _db.catalogoDao.upsertTiposParo(rows['tipos_paro']),
    │    _db.catalogoDao.upsertChecklistItems(rows['checklist_items']),
    │    _db.catalogoDao.upsertCajasCambios(rows['cajas_cambios']),
    │  ])
    │
    │  // Luego carga desde SQLite para poblar el estado del BLoC
    │  context.read<CatalogoBloc>().add(CatalogoLoadRequested())
    ▼
CatalogoBloc._onLoad()
    │
    │  emit(CatalogoLoading)
    │  [datos] = await Future.wait([
    │    _db.catalogoDao.getProcesos(),
    │    _db.catalogoDao.getTractores(),
    │    _db.catalogoDao.getTrabajadores(),
    │    ... 10 catálogos en paralelo
    │  ])
    │  emit(CatalogoLoaded(procesos, tractores, trabajadores, ...))
    ▼
SyncMaestrosPage (BlocConsumer)
    │
    │  Si CatalogoLoaded:
    │    authState.usuario.rolNombre == 'operador'   → context.go('/bienvenida')
    │    authState.usuario.rolNombre == 'supervisor' → context.go('/supervisor/home')
    │    authState.usuario.rolNombre == 'portero'    → context.go('/portero/home')
    │    authState.usuario.rolNombre == 'admin'      → context.go('/admin/home')
```

---

## 16. ErpApiClient — Cómo se ejecutan los SPs

Archivo: `lib/infrastructure/network/erp_api_client.dart`

### 16.1 Autenticación

```dart
authenticateWithCredentials(username, password)
    │
    │  POST /login/authenticate
    │  Body: {"username": "466620", "password": "****"}
    │  Response: {"token": "eyJ...", "expiry": "2026-06-05T23:00:00"}
    │
    │  → SecureStorage.write("erp_token", token)
    │  → SecureStorage.write("erp_token_expiry", expiry)
```

### 16.2 Ejecución de SP

```dart
ejecutarSP(nombreSP: "AGKMMA.SP_MMA_CERRAR_TURNO", parametros: [payload])
    │
    │  // 1. Obtener token (usa caché, refresca si expiró)
    │  token = await getValidToken()
    │
    │  // 2. Construir body según contrato del SP
    │  body = {
    │    "NombreSP": "AGKMMA.SP_MMA_CERRAR_TURNO",
    │    "TipoRespuesta": 0,
    │    "EntidadMapa": "",
    │    "Parametros": [
    │      {"Nombre": "p_payload", "NombreParametro": "p_payload", "Valor": "{...JSON...}"}
    │    ]
    │  }
    │
    │  // 3. POST al proxy REST
    │  response = await _dio.post(
    │    "https://.../WSRESTMovilidadERPPruebas/api/EjecutarSPERP",
    │    data: body,
    │    options: Options(headers: {"Authorization": "Bearer $token"})
    │  )
    │
    │  // 4. Parsear respuesta (9 formatos posibles del ERP)
    │  //    Puede venir como: Table1.Table1, lista directa, objeto con data, etc.
    │  rows = _parseListResponse(response.data)
    │
    │  // 5. Log de diagnóstico
    │  [ERP/SP] POST https://.../EjecutarSPERP
    │  [ERP/SP] Payload: {"NombreSP":"...","Parametros":[...]}
    │  [ERP/SP] HTTP 200 — tipo: _Map<String, dynamic>
    │  [ERP/PARSE] Table1..Table1 → N filas aplanadas
    │
    │  return rows  // List<Map<String, dynamic>>
```

### 16.3 Interceptor de diagnóstico

`_ErpDiagnosticInterceptor` registra en consola cada llamada:
- URL del endpoint
- Payload completo (SP + parámetros)
- Código HTTP de respuesta
- Tipo del objeto de respuesta
- Número de filas parseadas

---

## 17. Roles del Sistema

| Rol | Home | Función principal |
|-----|------|-------------------|
| `operador` | `/bienvenida` → `/operador/home` | Registros de turno (tractor/vehículo), bins, paros, checklist |
| `supervisor` | `/supervisor/home` | Ver jornadas activas, aprobar/rechazar registros |
| `portero` | `/portero/home` | Escanear QR de activos al ingreso/egreso |
| `admin` | `/admin/home` | Dashboard KPIs, alertas Firestore, exportar PDF/CSV |

**Flujo de autenticación (todos los roles):**
```
/pin → PinAccessPage (código + contraseña + rol)
    ↓ AuthLoginRequested
/login → LoginPage (spinner, autentica con ERP)
    ↓ AuthAuthenticated
/sincronizando → SyncMaestrosPage (descarga catálogos)
    ↓ CatalogoLoaded
/bienvenida | /supervisor/home | /portero/home | /admin/home
```

---

## 18. Tablas SQL Server (AGKMMA)

**Schema:** `AGKMMA` · **Motor:** SQL Server · **Total: 23 tablas**

---

### 18.1 Tablas de Catálogo / Maestros

#### `CLI547_MMA_PROCESOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| codigo | VARCHAR(20) UNIQUE | Código corto |
| nombre | VARCHAR(100) UNIQUE | Nombre del proceso |
| requiere_bines | BIT | Si el proceso genera cosecha de bins |
| requiere_sublabores | BIT | Si requiere sublabores adicionales |
| especie_botanica_erp_id | INT | Especie asociada en el ERP |
| activo | BIT | Estado |

#### `CLI547_MMA_SUBPROCESOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| proceso_id | INT FK→PROCESOS | Proceso padre |
| nombre | NVARCHAR(200) | Nombre |
| codigo | VARCHAR(50) | Código |
| activo | BIT | Estado |

#### `CLI547_MMA_CAJAS_CAMBIOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| nombre | VARCHAR(50) UNIQUE | Código de marcha (T-1..T-4, H-1..H-4, L-1..L-4) |

#### `CLI547_MMA_TIPOS_PARO`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| codigo | VARCHAR(30) UNIQUE | Código del tipo |
| nombre | VARCHAR(100) | Descripción |
| requiere_galones | BIT | Si el paro implica combustible |
| requiere_equipo | BIT | Si debe especificarse equipo externo |
| activo | BIT | Estado |

#### `CLI547_MMA_CHECKLIST_CATEGORIAS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| nombre | VARCHAR(100) UNIQUE | Nombre (Motor, Hidráulico...) |
| orden | SMALLINT | Orden de presentación |

#### `CLI547_MMA_CHECKLIST_ITEMS_CATALOGO`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| categoria_id | INT FK→CATEGORIAS | Categoría |
| nombre | VARCHAR(200) | Descripción del ítem |
| orden | SMALLINT | Orden dentro de la categoría |
| activo | BIT | Estado |
| tipo_registro | VARCHAR(20) | `'tractor'` o `'vehiculo'` |

---

### 18.2 Tablas de Registro Principal

#### `CLI547_MMA_REGISTROS_DIARIOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | UNIQUEIDENTIFIER PK | UUID generado en el APK o por el servidor |
| numero_registro | VARCHAR(30) UNIQUE | `RD-YYYYMMDD-NNN` (tractor) / `RV-...` (vehículo) |
| fecha | DATE | Fecha del turno |
| turno | VARCHAR(10) | `'dia'` o `'noche'` |
| proceso_id | INT FK nullable | Proceso agrícola |
| subproceso_id | INT FK nullable | Subproceso opcional |
| operador_id_erp | INT NOT NULL | t.Id del operador en la tabla `trabajadores` del ERP |
| nombre_operador_snapshot | VARCHAR(300) | Snapshot del nombre |
| supervisor_id_erp | INT | t.Id del supervisor |
| tractor_id_erp | INT NOT NULL | ID del tractor/vehículo |
| implemento_id_erp | INT nullable | ID del implemento |
| caja_cambios_id | INT FK | Marcha de trabajo usada |
| estado | VARCHAR(20) | `borrador` → `completado` → `aprobado`/`rechazado` |
| tipo_registro | VARCHAR(20) | `'tractor'` o `'vehiculo'` |
| sincronizado_erp | BIT | 1 si fue confirmado por el ERP |
| proceso_vehiculo | VARCHAR(50) | Solo vehículos |

#### `CLI547_MMA_HOROMETROS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK UNIQUE | Relación 1:1 |
| tractor_inicio | DECIMAL(10,1) | Lectura al inicio |
| tractor_final | DECIMAL(10,1) | Lectura al cierre |
| horas_tractor | COMPUTED | tractor_final - tractor_inicio |

#### `CLI547_MMA_TIEMPOS_TURNO`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK UNIQUE | Relación 1:1 |
| hora_salida_taller | TIME | Salida del taller |
| hora_llegada_punto | TIME | Llegada al lote |
| hora_salida_punto | TIME | Salida del lote |
| hora_llegada_taller | TIME | Llegada al taller |
| hora_refrigerio | VARCHAR(30) | Rango "HH:mm - HH:mm" |
| minutos_efectivos | COMPUTED | hora_salida - hora_llegada (punto) |

#### `CLI547_MMA_REGISTROS_LOTES`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| lote_id_erp | INT | ID del lote en el ERP |
| lote_codigo_snapshot | VARCHAR(50) | Código del lote |
| area_trabajada_ha | DECIMAL(8,4) | Área en hectáreas |

---

### 18.3 Tablas de Detalle del Turno

#### `CLI547_MMA_COSECHA_BINES`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| franja_horaria | VARCHAR(10) | Ej. "06-08" |
| turno_franja | VARCHAR(5) | `'am'` o `'pm'` |
| cantidad | SMALLINT | Número de bins |

#### `CLI547_MMA_PAROS_EQUIPOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| tipo_paro_id | INT FK→TIPOS_PARO | Tipo de paro |
| motivo | VARCHAR(MAX) | Descripción |
| hora_inicio | TIME NOT NULL | Inicio del paro |
| hora_final | TIME | Fin (NULL = activo) |
| galones | DECIMAL(8,2) | Combustible cargado |
| duracion_min | COMPUTED | Duración en minutos |

#### `CLI547_MMA_CHECKLIST_RESULTADOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| item_id | INT FK→ITEMS_CATALOGO | Ítem evaluado |
| resultado | VARCHAR(4) | `'bien'`, `'mal'`, `'na'` |
| observacion | VARCHAR(MAX) | Observación |

---

### 18.4 Tablas Específicas de Vehículo

#### `CLI547_MMA_COMBUSTIBLE_VEHICULO`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| glns | DECIMAL(10,2) | Galones cargados |
| hora_inicio / hora_final | TIME | Horario de la tanqueada |

#### `CLI547_MMA_PAROS_VEHICULO`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| motivo | NVARCHAR(250) | Descripción |
| hora_inicio / hora_final | TIME | Horario |

#### `CLI547_MMA_REGISTROS_SUBLABORES`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| sublabor_nombre | NVARCHAR(200) | Nombre de la sublabor |

#### `CLI547_MMA_REGISTROS_MARCHAS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| registro_id | UNIQUEIDENTIFIER FK | Registro padre |
| marcha_codigo | VARCHAR(10) | Código (T-1, H-2...) |
| horas_uso | DECIMAL(6,2) | Horas en esa marcha |

---

### 18.5 Tablas de Jornada y Monitoreo

#### `CLI547_MMA_STATUS_JORNADA`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT IDENTITY PK | Identificador |
| usuario_erp_id | INT NOT NULL | t.Id del operador en tabla `trabajadores` del ERP |
| dispositivo_id | VARCHAR(100) | ID del dispositivo |
| turno | VARCHAR(10) | `'dia'` o `'noche'` |
| jornada_inicio_at | DATETIME2 | Inicio de la jornada |
| jornada_fin_at | DATETIME2 nullable | Fin (NULL si activa) |

**Restricción única:** `(dispositivo_id, turno, CAST(jornada_inicio_at AS DATE))`

**IMPORTANTE:** `usuario_erp_id` debe ser el `t.Id` (PK de `trabajadores`), NO el código del empleado. El supervisor SP hace `JOIN trabajadores t ON t.Id = j.usuario_erp_id`.

#### `CLI547_MMA_PORTERO_LECTURAS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| portero_id_erp | INT | t.Id del portero |
| tractor_id_erp | INT | ID del tractor leído |
| tractor_codigo | VARCHAR(50) | Código del tractor |
| tractor_leido_at | DATETIME2 | Timestamp de lectura |
| implemento_id_erp | INT | ID del implemento |
| trabajador_id_erp | INT | t.Id del operador |
| cultivo_id_erp | INT | ID del cultivo |
| comentario | NVARCHAR(500) | Comentario del portero |

---

### 18.6 Tablas de Infraestructura y Auditoría

#### `CLI547_MMA_INCUMPLIMIENTOS`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| usuario_erp_id | INT | ID del usuario |
| fecha_jornada | DATE | Fecha del incumplimiento |
| tipo_incumplimiento | VARCHAR(80) | Tipo (llegada tarde, no registro, etc.) |
| firestore_doc_id | VARCHAR(200) | Referencia al doc en Firestore |

#### `CLI547_MMA_NOTIFICACIONES`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| usuario_erp_id | INT | Destinatario |
| tipo | VARCHAR(50) | Tipo de notificación |
| titulo / cuerpo | NVARCHAR | Contenido |
| leida | BIT | Si fue leída |

#### `CLI547_MMA_SESIONES_DISPOSITIVO`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| usuario_erp_id | INT | Usuario de la sesión |
| dispositivo_id | VARCHAR(150) | ID del dispositivo |
| token | VARCHAR(500) UNIQUE | Token de sesión persistente |
| expira_at | DATETIME2 | Expiración (30 días) |

#### `CLI547_MMA_AUDIT_LOG`
| Columna | Tipo | Descripción |
|---------|------|-------------|
| tabla | VARCHAR(80) | Tabla modificada |
| accion | VARCHAR(10) | `INSERT`, `UPDATE`, `DELETE` |
| datos_old / datos_new | NVARCHAR(MAX) | JSON antes/después |
| usuario_erp_id | INT | Quién hizo el cambio |

---

## 19. Procedimientos Almacenados — Referencia Completa

**Total: 17 SPs** · **Schema:** `AGKMMA`

**Patrón común:** todos reciben parámetros de entrada, ejecutan lógica, y retornan:
```sql
SELECT @p_success AS success, @p_mensaje AS mensaje [, otros campos]
```

---

### 19.1 SPs de Sincronización Principal

#### `SP_MMA_SINCRONIZAR_OFFLINE`
El SP más completo. Sincroniza registro completo (tractor o vehículo) en una sola transacción.

**Llamado desde:** `SyncManager._executeRequest` para endpoints `POST /registros`, `POST /registros/vehiculo`, `PUT /registros/vehiculo`

**Flujo interno:**
1. Extrae ~30 campos del JSON
2. Vehículo: fuerza `proceso_id=NULL` (evita FK inválidas)
3. Busca si existe por `numero_registro` (idempotencia)
4. Si no existe: INSERT en `CLI547_MMA_REGISTROS_DIARIOS`
5. Si existe: UPDATE
6. UPSERT en `CLI547_MMA_HOROMETROS` y `CLI547_MMA_TIEMPOS_TURNO`
7. MERGE de lotes, combustibles, paros, checklist, sublabores, marchas
8. Retorna `registro_id` (puede diferir del UUID local)

#### `SP_MMA_REGISTRAR_BIN`
UPSERT de un bin por franja horaria.
**Parámetros:** `@p_registro_id`, `@p_numero_registro`, `@p_franja_horaria`, `@p_turno`, `@p_cantidad`
**Tabla:** `CLI547_MMA_COSECHA_BINES`

#### `SP_MMA_REGISTRAR_PARO`
INSERT de un paro de maquinaria.
**Parámetros:** `@p_registro_id`, `@p_numero_registro`, `@p_tipo_paro_id`, `@p_motivo`, `@p_equipo`, `@p_hora_inicio`, `@p_hora_final`, `@p_galones`
**Tabla:** `CLI547_MMA_PAROS_EQUIPOS`

#### `SP_MMA_GUARDAR_CHECKLIST`
MERGE de resultados del checklist.
**Parámetros:** `@p_registro_id`, `@p_numero_registro`, `@p_resultados NVARCHAR(MAX)` (JSON array)
**Tabla:** `CLI547_MMA_CHECKLIST_RESULTADOS`

---

### 19.2 SPs de Ciclo de Vida del Turno

#### `SP_MMA_CERRAR_TURNO`
Cierra el turno: horómetros finales, tiempos, lotes, sublabores, marchas. Cambia estado a `completado`.

#### `SP_MMA_APROBAR_REGISTRO`
Aprueba o rechaza un registro completado.
**Parámetros:** `@p_registro_id`, `@p_supervisor_erp_id`, `@p_accion ('aprobar'|'rechazar')`, `@p_motivo`
**Lógica:** Idempotente. Valida que el estado actual sea `completado` o `borrador`.

#### `SP_MMA_REGISTRAR_JORNADA`
Actualiza `jornada_inicio_at` o `jornada_fin_at` en el registro principal.

#### `SP_MMA_ACTUALIZAR_STATUS_JORNADA`
UPSERT del estado de jornada del operador.
**Parámetro:** `@p_payload NVARCHAR(MAX)` con `{usuario_id, dispositivo_id, turno, jornada_inicio_at, jornada_fin_at?}`
**Tabla:** `CLI547_MMA_STATUS_JORNADA`
**Clave única:** `(dispositivo_id, turno, CAST(jornada_inicio_at AS DATE))`
**NOTA:** `usuario_id` debe ser `trabajadores.Id` (PK real), no el código del empleado.

---

### 19.3 SPs de Consulta

#### `SP_MMA_GET_REGISTROS_SUPERVISOR`
**Parámetros:** `@p_supervisor_erp_id INT`, `@p_fecha DATE`, `@p_turno NVARCHAR(10)` nullable
**Retorna:** Registros en estado `completado` asignados al supervisor.

#### `SP_MMA_GET_JORNADAS_SUPERVISOR`
**Parámetros:** `@p_fecha DATE`, `@p_turno NVARCHAR(10)` nullable
**Retorna:** Jornadas activas con nombre del operador (JOIN `trabajadores → sujetos`).
**Nota crítica:** El JOIN es `trabajadores.Id = status_jornada.usuario_erp_id`. Requiere que `usuario_erp_id` sea el `t.Id` real.

#### `SP_MMA_GET_REPORTE_SUPERVISOR`
**Retorna:** KPIs agregados: horas, bins, paros, hectáreas por proceso/operador/fecha.

---

### 19.4 SPs de Catálogos

#### `SP_MMA_ERP_SYNC_PAYLOAD_COMPLETO`
Descarga masiva de catálogos en un solo SP. Retorna: procesos, tractores, implementos, trabajadores (con `t.Id` real), lotes, cultivos, tipos de paro, checklist items, cajas de cambios.

#### `SP_MMA_ERP_GET_SUBPROCESOS`
**Parámetros:** `@p_proceso_id INT`
Cargado bajo demanda al seleccionar un proceso en el formulario.

---

### 19.5 SPs de Portero y Notificaciones

#### `SP_MMA_REGISTRAR_LECTURA_PORTERO`
**Parámetro:** `@p_payload NVARCHAR(MAX)` JSON completo de la lectura.
**Tabla:** `CLI547_MMA_PORTERO_LECTURAS`

#### `SP_MMA_ENVIAR_NOTIFICACION`
**Parámetros:** `@p_usuario_erp_id`, `@p_tipo`, `@p_titulo`, `@p_cuerpo`
Registra en `CLI547_MMA_NOTIFICACIONES` y dispara push via Firebase.

#### `SP_MMA_CREAR_SESION`
**Parámetros:** `@p_trabajador_id_erp`, `@p_dispositivo_id`, `@p_token`
Registra sesión en `CLI547_MMA_SESIONES_DISPOSITIVO`.

---

### 19.6 Funciones SQL

#### `SP_MMA_FN_GENERAR_NUMERO_REGISTRO` (FUNCTION, no SP)
**Parámetros:** `@p_fecha DATE`, `@p_tipo VARCHAR(20)` (`'tractor'` | `'vehiculo'`)
**Retorna:** `RD-YYYYMMDD-NNN` o `RV-YYYYMMDD-NNN`

---

### 19.7 SP Externo del ERP

#### `dbo.SP_AGM_GetPerfilProfesional` (ERP, schema `dbo`)
**Parámetro:** `@UsuarioCodigo NVARCHAR` — el código de login del usuario
**Retorna:** `CodigoUsuario`, `NombreCompleto`, `CodigoTrabajador` (código visible, ej. "466620"), `DNI`, `PuestoTrabajo`, `EstadoUsuario`, etc.
**Nota:** Retorna el código del empleado en `CodigoTrabajador`, NO el `t.Id` de la tabla `trabajadores`. El APK resuelve el `t.Id` real buscando en el catálogo local por `cod_trabajador`.

---

## 20. Tablas SQLite Locales (Drift)

Drift es un ORM type-safe para SQLite en Flutter. Las tablas locales son el espejo offline de SQL Server.

| Tabla Drift | Tabla SQL Server | SP de sync |
|-------------|-----------------|------------|
| `registros_diarios_local` | `CLI547_MMA_REGISTROS_DIARIOS` | `SP_MMA_SINCRONIZAR_OFFLINE` |
| `horometros_local` | `CLI547_MMA_HOROMETROS` | (incluido en registro) |
| `tiempos_turno_local` | `CLI547_MMA_TIEMPOS_TURNO` | (incluido en registro) |
| `registros_sectores_local` | `CLI547_MMA_REGISTROS_LOTES` | (incluido en cierre) |
| `cosecha_bines_local` | `CLI547_MMA_COSECHA_BINES` | `SP_MMA_REGISTRAR_BIN` |
| `paros_equipos_local` | `CLI547_MMA_PAROS_EQUIPOS` | `SP_MMA_REGISTRAR_PARO` |
| `checklist_resultados_local` | `CLI547_MMA_CHECKLIST_RESULTADOS` | `SP_MMA_GUARDAR_CHECKLIST` |
| `portero_lecturas_local` | `CLI547_MMA_PORTERO_LECTURAS` | `SP_MMA_REGISTRAR_LECTURA_PORTERO` |
| `status_jornada_local` | `CLI547_MMA_STATUS_JORNADA` | `SP_MMA_ACTUALIZAR_STATUS_JORNADA` |
| `status_jornada_pendiente` | — | Cola para envío diferido de jornadas |
| `trabajadores_local` | `trabajadores` (ERP) | Sync vía `SP_MMA_ERP_SYNC_PAYLOAD_COMPLETO` |
| `tractores_local` | `maquinaria` (ERP) | Sync vía payload completo |
| `implementos_local` | `maquinaria` (ERP) | Sync vía payload completo |
| `procesos_local` | `CLI547_MMA_PROCESOS` | Sync vía payload completo |
| `outbox_entries` | — | Cola de sincronización FIFO |

**Tabla OutboxEntries:**
```
id                INTEGER PK AUTOINCREMENT
registro_local_id TEXT          ← UUID local del registro padre
endpoint          TEXT          ← '/registros', '/bines', '/paros', etc.
method            TEXT          ← 'POST' | 'PUT'
payload_json      TEXT          ← JSON del dato a enviar
timestamp         DATETIME      ← para orden FIFO
status            TEXT          ← 'pending' | 'syncing' | 'done' | 'failed' | 'permanently_failed'
retry_count       INTEGER
error_message     TEXT
```

---

## 21. Navegación de Rutas

Archivo: `lib/router/app_router.dart` — usa **GoRouter** con redirección reactiva por `AuthState`.

```dart
redirect: (context, state) {
  if (authState is AuthLoading)         → '/splash'
  if (authState is AuthUnauthenticated) → '/pin'
  if (authState is AuthPinValidated)    → '/login'
  if (authState is AuthAuthenticated)   → según rol y ruta actual
}
```

| Ruta | Página | Rol | Descripción |
|------|--------|-----|-------------|
| `/pin` | `PinAccessPage` | todos | Login: código + contraseña + rol |
| `/login` | `LoginPage` | todos | Spinner de autenticación ERP |
| `/sincronizando` | `SyncMaestrosPage` | todos | Descarga catálogos post-login |
| `/bienvenida` | `BienvenidaTurnoPage` | operador | Control de inicio de jornada |
| `/operador/home` | `HomeOperadorPage` | operador | Dashboard diario + registros |
| `/registro/nuevo` | `CrearRegistroPage` | operador | Nuevo registro de tractor |
| `/registro/vehiculo/nuevo` | `RegistroVehiculoPage` | operador | Nuevo registro de vehículo |
| `/registro/vehiculo/:id/editar` | `EditarRegistroVehiculoPage` | operador | Editar registro vehículo |
| `/registro/:id/checklist` | `ChecklistPage` | operador | Checklist pre-operacional |
| `/registro/:id/bines` | `BinesPage` | operador | Registro de bins |
| `/registro/:id/paros` | `ParosPage` | operador | Registro de paros |
| `/registro/:id/cerrar` | `CerrarTurnoPage` | operador | Cierre del turno |
| `/registro/:id/ver` | `VisualizarRegistroPage` | operador | Vista solo lectura |
| `/historial` | `HistorialPage` | operador | Historial completo |
| `/supervisor/home` | `HomeSupervisorPage` | supervisor | Jornadas + aprobaciones + historial |
| `/portero/home` | `HomePorteroPage` | portero | Escaneo de QR |
| `/admin/home` | `HomeAdminPage` | admin | Dashboard KPIs + alertas |
| `/perfil` | `PerfilUsuarioPage` | todos | Perfil + sincronizar maestros |

---

## 22. Diagrama de Flujo General

```
[INICIO]
   │
   ▼
PinAccessPage (/pin)
   • código empleado + contraseña + rol
   • AuthBloc.add(AuthLoginRequested)
   ▼
LoginPage (/login)
   • AuthRepositoryImpl.loginConAPI()
     1. POST /login/authenticate → token JWT
     2. SP_AGM_GetPerfilProfesional → perfil
     3. getTrabajadorByCodigo(codigo) → t.Id real (29273)
     4. _persistSession(usuario) → SecureStorage
     5. SP_MMA_CREAR_SESION → registro en BD
   • GoRouter detecta AuthAuthenticated
   ▼
SyncMaestrosPage (/sincronizando)
   • CatalogoBloc.add(CatalogoSyncRequested)
   • SP_MMA_ERP_SYNC_PAYLOAD_COMPLETO → 9 catálogos → SQLite
   ▼
   ├── rol='operador' ────────────────────────────────────────────────────
   │
   │  BienvenidaTurnoPage (/bienvenida)
   │    • Detecta turno actual (día 06-14h / noche 14-22h)
   │    • Verifica jornada activa (SQLite + SharedPrefs)
   │    • Si activa → /operador/home  [sin crear nueva]
   │    • Si no → botón "INICIAR JORNADA"
   │        → StatusSyncManager.guardarYEnviar(usuarioId=29273,...)
   │        → SP_MMA_ACTUALIZAR_STATUS_JORNADA (usuario_id=29273)
   │        → SharedPreferences.set("jornada_29273_noche_20260605", true)
   │
   │  HomeOperadorPage (/operador/home)
   │    • RegistroBloc: lista registros del día (SQLite stream)
   │    • Botón sync ícono → SyncBloc → SyncManager.processOutbox()
   │    • FAB "+" → BottomSheet → TRACTOR o VEHÍCULO
   │
   │    [TRACTOR]
   │    CrearRegistroPage → SQLite + Outbox(POST /registros)
   │    ChecklistPage     → SQLite + Outbox(POST /checklist)
   │    BinesPage         → SQLite + Outbox(POST /bines)        [si aplica]
   │    ParosPage         → SQLite + Outbox(POST /paros)
   │    CerrarTurnoPage   → SQLite + Outbox(PUT /cerrar)
   │
   │    [VEHÍCULO]
   │    RegistroVehiculoPage → SQLite + Outbox(POST /registros/vehiculo)
   │
   │    [SYNC]
   │    SyncManager procesa Outbox FIFO:
   │      SP_MMA_SINCRONIZAR_OFFLINE
   │      SP_MMA_GUARDAR_CHECKLIST
   │      SP_MMA_REGISTRAR_BIN
   │      SP_MMA_REGISTRAR_PARO
   │      SP_MMA_CERRAR_TURNO
   │
   ├── rol='supervisor' ───────────────────────────────────────────────────
   │
   │  HomeSupervisorPage (/supervisor/home)
   │    Tab TURNO:       SP_MMA_GET_JORNADAS_SUPERVISOR   [cada 30s]
   │    Tab APROBACIONES: SP_MMA_GET_REGISTROS_SUPERVISOR  [cada 30s]
   │    Aprobar/Rechazar: SP_MMA_APROBAR_REGISTRO
   │
   ├── rol='portero' ──────────────────────────────────────────────────────
   │
   │  HomePorteroPage (/portero/home)
   │    Escaneo QR: tractor → implemento → operador → cultivo
   │    SQLite + Outbox → SP_MMA_REGISTRAR_LECTURA_PORTERO
   │
   └── rol='admin' ────────────────────────────────────────────────────────

      HomeAdminPage (/admin/home)
        SP_MMA_GET_REPORTE_SUPERVISOR  [cada 45s]
        SP_MMA_GET_JORNADAS_SUPERVISOR [cada 45s]
        Firestore alertas en tiempo real
        Exportar PDF / CSV
```

---

## 23. Diagrama de Tablas y Relaciones

```
CATÁLOGOS (maestros ERP)
  CLI547_MMA_PROCESOS ──────────────────────────────────────────────────────┐
    └── CLI547_MMA_SUBPROCESOS                                               │
  CLI547_MMA_TIPOS_PARO                                                      │
  CLI547_MMA_CAJAS_CAMBIOS                                                   │
  CLI547_MMA_CHECKLIST_CATEGORIAS                                            │
    └── CLI547_MMA_CHECKLIST_ITEMS_CATALOGO                                  │

REGISTRO PRINCIPAL                                                           │
  CLI547_MMA_REGISTROS_DIARIOS ◄───────────────────────────────────────────-┘
    │  (PK: UNIQUEIDENTIFIER)
    │  operador_id_erp → trabajadores.Id (ERP externo)
    │  supervisor_id_erp → trabajadores.Id (ERP externo)
    │  proceso_id → CLI547_MMA_PROCESOS.id
    │
    ├── CLI547_MMA_HOROMETROS (1:1)
    ├── CLI547_MMA_TIEMPOS_TURNO (1:1)
    ├── CLI547_MMA_REGISTROS_LOTES (1:N)
    ├── CLI547_MMA_COSECHA_BINES (1:N)
    ├── CLI547_MMA_PAROS_EQUIPOS (1:N) → CLI547_MMA_TIPOS_PARO
    ├── CLI547_MMA_CHECKLIST_RESULTADOS (1:N) → ITEMS_CATALOGO
    ├── CLI547_MMA_COMBUSTIBLE_VEHICULO (1:N)  [solo vehículo]
    ├── CLI547_MMA_PAROS_VEHICULO (1:N)         [solo vehículo]
    ├── CLI547_MMA_REGISTROS_SUBLABORES (1:N)   [solo tractor]
    └── CLI547_MMA_REGISTROS_MARCHAS (1:N)      [solo tractor]

JORNADA Y MONITOREO
  CLI547_MMA_STATUS_JORNADA
    └── usuario_erp_id → trabajadores.Id (ERP)  ← JOIN en SP_GET_JORNADAS_SUPERVISOR

PORTERO
  CLI547_MMA_PORTERO_LECTURAS
    └── portero_id_erp → trabajadores.Id (ERP)

INFRAESTRUCTURA
  CLI547_MMA_SESIONES_DISPOSITIVO
  CLI547_MMA_NOTIFICACIONES
  CLI547_MMA_INCUMPLIMIENTOS
  CLI547_MMA_AUDIT_LOG (trigger en tablas críticas)

TABLAS ERP EXTERNAS (solo JOIN, no AGKMMA)
  trabajadores  (t.Id, t.Codigo como "465P0466620", t.Id_Sujeto)
  sujetos       (Id, PrimerApellido, SegundoApellido, Nombre)
  maquinaria    (Id, Codigo como código de tractor/implemento)
  EspeciesBotanicas (Id, NombreComun como cultivo)
  fincas / lotes    (para sectores trabajados)
```
