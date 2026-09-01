import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/pages/login_page.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/pages/pin_access_page.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/pages/sync_maestros_page.dart';
import 'package:agro_aplicaciones/shared/profile/presentation/pages/perfil_usuario.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/home_operador_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/crear_registro_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/registro_vehiculo_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/checklist_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/paros_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/cerrar_turno_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/bines_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/bienvenida_turno_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/historial_page.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/editar_registro_vehiculo_page.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/visualizar_registro_page.dart';
import 'package:agro_aplicaciones/features/portero/presentation/pages/home_portero_page.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/pages/home_supervisor_page.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/pages/editor_admin_page.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/pages/mecanico_page.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/injection_container.dart';

// ─── Mapa de acceso por rol ───────────────────────────────────────────────────
//
//  supervisor │
//  gerente    → /supervisor/home  +  /registro/* con ?admin=true o /admin-editar o /ver
//  operador   → /operador/home  +  /bienvenida  +  /historial  +  /registro/* (sin admin)
//  portero    → /portero/home
//  mecanico   → /mecanico/home
//  (todos)    → /perfil  +  /sincronizando
//
// ─────────────────────────────────────────────────────────────────────────────

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/pin',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final path      = state.matchedLocation;
      final isPinPage   = path == '/pin';
      final isLoginPage = path == '/login';

      // ── 1. Cargando / estado inicial → sin redirección ────────────────────
      if (authState is AuthLoading || authState is AuthInitial) return null;

      // ── 2. PIN validado pero aún sin sesión completa → solo /login ────────
      if (authState is AuthPinValidated) {
        return isLoginPage ? null : '/pin';
      }

      // ── 3. No autenticado → siempre a /pin ───────────────────────────────
      if (authState is AuthUnauthenticated || authState is AuthFailureState) {
        return (isPinPage || isLoginPage) ? null : '/pin';
      }

      // ── 4. Autenticado ────────────────────────────────────────────────────
      if (authState is AuthAuthenticated) {
        final rol = authState.usuario.rolNombre;

        // Desde pantallas de auth → redirigir al home del rol
        if (isPinPage || isLoginPage) return _homeForRol(rol);

        // Rutas compartidas: cualquier rol autenticado puede acceder
        if (path == '/sincronizando' || path == '/perfil') return null;

        // ── Guard de rol ──────────────────────────────────────────────────

        // Portero: solo su home
        if (rol == 'portero') {
          return path.startsWith('/portero') ? null : _homeForRol(rol);
        }

        // Mecánico: solo su home
        if (rol == 'mecanico') {
          return path.startsWith('/mecanico') ? null : _homeForRol(rol);
        }

        // Supervisor / Gerente:
        //   - su home
        //   - rutas de /registro/* con ?admin=true (edición de registros de otros)
        //   - /registro/:id/admin-editar (panel de edición por secciones)
        //   - /registro/:id/ver (visualización de cualquier registro)
        if (rol == 'supervisor' || rol == 'gerente') {
          if (path.startsWith('/supervisor')) return null;
          if (path.startsWith('/registro')) {
            final esAdminMode  = state.uri.queryParameters['admin'] == 'true';
            final esAdminPanel = path.contains('/admin-editar');
            final esVer        = path.contains('/ver');
            if (esAdminMode || esAdminPanel || esVer) return null;
          }
          return _homeForRol(rol);
        }

        // Operador:
        //   - su home
        //   - /bienvenida, /historial, ruta legacy /
        //   - /registro/* propios (sin modo admin ni panel de edición admin)
        if (rol == 'operador') {
          if (path.startsWith('/operador')) return null;
          if (path == '/bienvenida' || path == '/historial' || path == '/') {
            return null;
          }
          if (path.startsWith('/registro')) {
            // Bloquear acceso a edición en modo admin (exclusivo supervisor/admin)
            final esAdminMode  = state.uri.queryParameters['admin'] == 'true';
            final esAdminPanel = path.contains('/admin-editar');
            if (esAdminMode || esAdminPanel) return _homeForRol(rol);
            return null; // resto de /registro/* es del operador
          }
          return _homeForRol(rol);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/pin',
        builder: (context, state) => const PinAccessPage(),
      ),
      GoRoute(
        path: '/sincronizando',
        builder: (context, state) => const SyncMaestrosPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) return const PinAccessPage();
          return LoginPage(
            codigo: extra['codigo']?.toString() ?? '',
            pin:    extra['pin']?.toString()    ?? '',
            rol:    extra['rol']?.toString()    ?? 'operador',
          );
        },
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const PerfilUsuarioPage(),
      ),

      // ── Homes por rol ────────────────────────────────────────────────────
      GoRoute(
        path: '/operador/home',
        builder: (context, state) => const HomeOperadorPage(),
      ),
      GoRoute(
        path: '/portero/home',
        builder: (context, state) => const HomePorteroPage(),
      ),
      GoRoute(
        path: '/supervisor/home',
        builder: (context, state) => const HomeSupervisorPage(),
      ),
      GoRoute(
        path: '/mecanico/home',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<MecanicoBloc>(),
          child: const MecanicoPage(),
        ),
      ),

      // Ruta legacy '/' → home de operador
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeOperadorPage(),
      ),

      // ── Flujo de operador ────────────────────────────────────────────────
      GoRoute(
        path: '/bienvenida',
        builder: (context, state) => const BienvenidaTurnoPage(),
      ),
      GoRoute(
        path: '/historial',
        builder: (context, state) => const HistorialPage(),
      ),

      // ── Registros ────────────────────────────────────────────────────────
      GoRoute(
        path: '/registro/nuevo',
        builder: (context, state) => const CrearRegistroPage(),
      ),
      GoRoute(
        path: '/registro/vehiculo/nuevo',
        builder: (context, state) => const RegistroVehiculoPage(),
      ),
      GoRoute(
        path: '/registro/vehiculo/:id/editar',
        builder: (context, state) => EditarRegistroVehiculoPage(
          registroId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/registro/:id/editar',
        builder: (context, state) {
          final extra = state.extra;
          return CrearRegistroPage(
            registroId:      state.pathParameters['id']!,
            registroPrefill: extra is RegistroDiario ? extra : null,
            adminMode:       state.uri.queryParameters['admin'] == 'true',
          );
        },
      ),
      GoRoute(
        path: '/registro/:id/checklist',
        builder: (context, state) => ChecklistPage(
          registroId: state.pathParameters['id']!,
          adminMode:  state.uri.queryParameters['admin'] == 'true',
        ),
      ),
      GoRoute(
        path: '/registro/:id/bines',
        builder: (context, state) => BinesPage(
          registroId: state.pathParameters['id']!,
          turno:      state.uri.queryParameters['turno'] ?? 'dia',
        ),
      ),
      GoRoute(
        path: '/registro/:id/paros',
        builder: (context, state) => ParosPage(
          registroId: state.pathParameters['id']!,
          adminMode:  state.uri.queryParameters['admin'] == 'true',
        ),
      ),
      GoRoute(
        path: '/registro/:id/cerrar',
        builder: (context, state) => CerrarTurnoPage(
          registroId: state.pathParameters['id']!,
          adminMode:  state.uri.queryParameters['admin'] == 'true',
        ),
      ),
      // Panel de edición por secciones (supervisor/admin)
      GoRoute(
        path: '/registro/:id/admin-editar',
        builder: (context, state) {
          final extra = state.extra;
          return EditorAdminPage(
            registroId: state.pathParameters['id']!,
            registro:   extra is RegistroDiario ? extra : null,
          );
        },
      ),
      // Visualización de registro (supervisor/admin)
      GoRoute(
        path: '/registro/:id/ver',
        builder: (context, state) {
          final extra = state.extra;
          return VisualizarRegistroPage(
            registroId: state.pathParameters['id']!,
            registro:   extra is RegistroDiario ? extra : null,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página no encontrada: ${state.error}')),
    ),
  );
}

// ─── Helper: home según rol ───────────────────────────────────────────────────

/// Devuelve la ruta home correspondiente al [rol] del usuario autenticado.
/// Usado por el redirect para llevar a cada usuario a su módulo al iniciar
/// sesión y para bloquear rutas que no le corresponden.
String _homeForRol(String rol) {
  switch (rol) {
    case 'supervisor':
    case 'gerente':
      return '/supervisor/home';
    case 'portero':
      return '/portero/home';
    case 'mecanico':
      return '/mecanico/home';
    default: // 'operador' + cualquier rol no reconocido → operador home
      return '/operador/home';
  }
}

// ─── GoRouterRefreshStream ────────────────────────────────────────────────────

/// Permite que GoRouter reaccione a los cambios de estado del AuthBloc.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
