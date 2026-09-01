import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/core/network/network_info.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/firestore_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/sync_manager.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';
import 'package:agro_aplicaciones/infrastructure/services/backup_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/daily_reset_service.dart';
import 'package:agro_aplicaciones/shared/auth/data/auth_repository_impl.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';
import 'package:agro_aplicaciones/shared/auth/domain/usecases/login_usecase.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/data/catalogo_repository_impl.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/repositories/catalogo_repository.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/usecases/obtener_catalogos_usecase.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/features/operador/data/registro_repository_impl.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/agregar_paro_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/cerrar_turno_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/crear_registro_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/guardar_checklist_usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/usecases/registrar_bin_usecase.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/usecases/aprobar_registro_usecase.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/repositories/supervisor_repository.dart';
import 'package:agro_aplicaciones/features/supervisor/domain/usecases/get_registros_supervisor_usecase.dart';
import 'package:agro_aplicaciones/features/supervisor/data/supervisor_repository_impl.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/blocs/supervisor_bloc.dart';
import 'package:agro_aplicaciones/features/mecanico/data/mecanico_repository_impl.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/repositories/mecanico_repository.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/usecases/get_paros_mecanico_usecase.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/usecases/completar_falla_usecase.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_bloc.dart';
import 'package:agro_aplicaciones/infrastructure/services/connectivity_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/gps_tracking_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── Connectivity ─────────────────────────────────────────────────────────
  final connectivityService = ConnectivityService()..init();
  sl.registerSingleton<ConnectivityService>(connectivityService);

  // ─── Externos ─────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerSingleton<Connectivity>(Connectivity());
  sl.registerSingleton<DeviceInfoPlugin>(DeviceInfoPlugin());

  // ─── Network ──────────────────────────────────────────────────────────────
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));

  // ─── Base de datos (Drift / SQLite) ───────────────────────────────────────
  final database = AppDatabase();
  sl.registerSingleton<AppDatabase>(database);

  // ─── Cliente HTTP único: ERP SQL Server via proxy REST ────────────────────
  final erpClient = ErpApiClient(secureStorage: sl());
  sl.registerSingleton<ErpApiClient>(erpClient);

  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      db: sl(),
      secureStorage: sl(),
      erp: sl(),
    ),
  );

  sl.registerSingleton<CatalogoRepository>(
    CatalogoRepositoryImpl(
      erp: sl(),
      db: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerSingleton<RegistroRepository>(
    RegistroRepositoryImpl(
      db: sl(),
      erp: sl(),
    ),
  );

  sl.registerSingleton<SupervisorRepository>(
    SupervisorRepositoryImpl(erp: sl()),
  );

  sl.registerSingleton<MecanicoRepository>(
    MecanicoRepositoryImpl(erp: sl(), db: sl()),
  );

  // ─── Use Cases ────────────────────────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => ObtenerProcesosUseCase(sl()));
  sl.registerFactory(() => ObtenerCultivosUseCase(sl()));
  sl.registerFactory(() => ObtenerTractoresUseCase(sl()));
  sl.registerFactory(() => ObtenerImplementosUseCase(sl()));
  sl.registerFactory(() => ObtenerTrabajadoresUseCase(sl()));
  sl.registerFactory(() => ObtenerSectoresUseCase(sl()));
  sl.registerFactory(() => ObtenerCajasCambiosUseCase(sl()));
  sl.registerFactory(() => ObtenerTiposParoUseCase(sl()));
  sl.registerFactory(() => ObtenerChecklistItemsUseCase(sl()));
  sl.registerFactory(() => SincronizarCatalogosUseCase(sl()));
  sl.registerFactory(() => ObtenerSubprocesosUseCase(sl()));
  sl.registerFactory(() => ObtenerVehiculosUseCase(sl()));
  sl.registerFactory(() => ContarHorometroTractoresUseCase(sl()));
  sl.registerFactory(() => ObtenerFallasMecanicasUseCase(sl()));
  sl.registerFactory(() => ContarFallasMecanicasUseCase(sl()));
  sl.registerFactory(() => CrearRegistroUseCase(sl()));
  sl.registerFactory(() => CerrarTurnoUseCase(sl()));
  sl.registerFactory(() => AprobarRegistroUseCase(sl()));
  sl.registerFactory(() => AgregarParoUseCase(sl()));
  sl.registerFactory(() => RegistrarBinUseCase(sl()));
  sl.registerFactory(() => GuardarChecklistUseCase(sl()));
  sl.registerFactory(() => GetRegistrosSupervisorUseCase(sl()));
  sl.registerFactory(() => GetParosMecanicoUseCase(sl()));
  sl.registerFactory(() => CompletarFallaUseCase(sl()));

  // ─── Services ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
  sl.registerSingleton<DeviceService>(DeviceService(sl(), sl()));
  sl.registerSingleton<SyncManager>(
    SyncManager(
      db: sl(),
      erp: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerSingleton<StatusSyncManager>(
    StatusSyncManager(
      networkInfo: sl(),
      erp: sl(),
      db: sl(),
    ),
  );
  sl.registerLazySingleton<DailyResetService>(
    () => DailyResetService(db: sl()),
  );
  sl.registerLazySingleton<BackupService>(
    () => BackupService(db: sl()),
  );
  sl.registerSingleton<GpsTrackingService>(
    GpsTrackingService(db: sl()),
  );
  // GpsSyncService eliminado en v3: la ruta GPS ya no se envía como puntos
  // individuales al servidor. Al cerrar jornada, _buildFullPayloadFromSQLite
  // convierte los puntos a WKT LineString y los incluye en el payload principal.

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc(loginUseCase: sl(), authRepository: sl()),
  );
  sl.registerFactory(
    () => CatalogoBloc(
      getProcesos: sl(),
      getCultivos: sl(),
      getTractores: sl(),
      getImplementos: sl(),
      getVehiculos: sl(),
      getTrabajadores: sl(),
      getSectores: sl(),
      getCajasCambios: sl(),
      getTiposParo: sl(),
      getChecklistItems: sl(),
      syncCatalogos: sl(),
      getSubprocesos: sl(),
      contarHorometros: sl(),
      getFallasMecanicas: sl(),
      contarFallasMecanicas: sl(),
    ),
  );
  sl.registerFactory(
    () => RegistroBloc(
      crearRegistro: sl(),
      cerrarTurno: sl(),
      aprobarRegistro: sl(),
      agregarParo: sl(),
      registrarBin: sl(),
      guardarChecklist: sl(),
      registroRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => SyncBloc(
      registroRepository: sl(),
      syncManager: sl(),
    ),
  );
  sl.registerFactory(
    () => SupervisorBloc(
      getRegistros: sl(),
      supervisorRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => MecanicoBloc(
      getParos: sl(),
      completarFalla: sl(),
    ),
  );
}
