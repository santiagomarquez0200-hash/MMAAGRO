import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_event.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/blocs/supervisor_bloc.dart';
import 'package:agro_aplicaciones/router/app_router.dart';
import 'package:agro_aplicaciones/infrastructure/services/sync_manager.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';

class AgriControlApp extends StatefulWidget {
  const AgriControlApp({super.key});

  @override
  State<AgriControlApp> createState() => _AgriControlAppState();
}

class _AgriControlAppState extends State<AgriControlApp> {
  late final AuthBloc _authBloc;
  late final CatalogoBloc _cataloBloc;
  late final RegistroBloc _registroBloc;
  late final SyncBloc _syncBloc;
  late final SupervisorBloc _supervisorBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    _cataloBloc = sl<CatalogoBloc>()..add(const CatalogoLoadRequested());
    _registroBloc = sl<RegistroBloc>();
    _syncBloc = sl<SyncBloc>();
    _supervisorBloc = sl<SupervisorBloc>();

    sl<SyncManager>().start();
    sl<StatusSyncManager>().startListening();
  }

  @override
  void dispose() {
    _authBloc.close();
    _cataloBloc.close();
    _registroBloc.close();
    _syncBloc.close();
    _supervisorBloc.close();
    sl<SyncManager>().stop();
    sl<StatusSyncManager>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _cataloBloc),
        BlocProvider.value(value: _registroBloc),
        BlocProvider.value(value: _syncBloc),
        BlocProvider.value(value: _supervisorBloc),
      ],
      child: Builder(
        builder: (context) {
          final router = createRouter(_authBloc);
          return MaterialApp.router(
            title: 'AgriControl',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            locale: const Locale('es'),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1B4332),
                primary: const Color(0xFF1B4332),
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
