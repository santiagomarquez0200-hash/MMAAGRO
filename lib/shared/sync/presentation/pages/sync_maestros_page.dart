import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_event.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';

class SyncMaestrosPage extends StatefulWidget {
  const SyncMaestrosPage({super.key});

  @override
  State<SyncMaestrosPage> createState() => _SyncMaestrosPageState();
}

class _SyncMaestrosPageState extends State<SyncMaestrosPage> {
  // true = cargando desde SQLite local, false = sincronizando desde ERP
  bool _cargandoLocal = true;
  // true = sync ERP falló y SQLite sigue vacío (primer arranque sin red)
  bool _errorSinDatos = false;
  bool _navigating = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    // Siempre relanzar CatalogoLoadRequested al montar, aunque app.dart ya lo
    // haya disparado. Si el estado actual ya es CatalogoLoaded(vacío), el bloc
    // emitirá Loading→Loaded(vacío) nuevamente y el listener detectará la
    // necesidad de sync ERP.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CatalogoBloc>().add(const CatalogoLoadRequested());
      }
    });
  }

  void _reintentarSync() {
    if (!mounted) return;
    setState(() {
      _errorSinDatos = false;
      _errorMsg = '';
      _cargandoLocal = false;
    });
    context.read<CatalogoBloc>().add(const CatalogoSyncRequested());
  }

  Future<void> _navigateToHome() async {
    if (_navigating) return;
    _navigating = true;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) context.go('/pin');
      return;
    }

    // Corregir y guardar la sesión en SecureStorage con los datos reales de SQLite
    final authRepository = sl<AuthRepository>();
    final result = await authRepository.getUsuarioActual();
    final updatedUsuario = result.fold((_) => null, (u) => u);

    dev.log(
      '[SYNC→HOME] getUsuarioActual: usuarioErpId=${updatedUsuario?.usuarioErpId} '
      'codigo="${updatedUsuario?.codigo}" '
      'resultado=${result.isRight() ? "Right" : "Left"}',
      name: 'Sync',
    );

    // Actualizar el estado del BLoC en memoria con los IDs corregidos.
    // El Future.delayed(zero) cede al event loop para que el BLoC procese
    // AuthUserUpdated ANTES de navegar — sin esto, el estado podría llegar
    // null a bienvenida_turno_page en el primer arranque.
    if (updatedUsuario != null && mounted) {
      final authBloc = context.read<AuthBloc>();
      authBloc.add(AuthUserUpdated(updatedUsuario));
      await Future.delayed(Duration.zero);
      final st = authBloc.state;
      dev.log(
        '[SYNC→HOME] AuthUserUpdated procesado — bloc.usuarioErpId='
        '${st is AuthAuthenticated ? st.usuario.usuarioErpId : "no-auth"}',
        name: 'Sync',
      );
    }

    final updatedState = context.read<AuthBloc>().state;
    final rol = updatedState is AuthAuthenticated
        ? updatedState.usuario.rolNombre
        : authState.usuario.rolNombre; // fallback to original
    if (rol == 'portero') {
      if (mounted) context.go('/portero/home');
    } else if (rol == 'supervisor') {
      if (mounted) context.go('/supervisor/home');
    } else if (rol == 'mecanico') {
      if (mounted) context.go('/mecanico/home');
    } else {
      // Operador: siempre va al home. Si tiene jornada activa, marcarla para
      // que home_page muestre la notificación de restauración. Si no tiene,
      // el home muestra el card "Sin jornada activa → Toca para iniciar".
      try {
        final deviceId = await sl<DeviceService>().getDeviceId();
        final db = sl<AppDatabase>();
        final trabajadorLocal = await db.catalogoDao.getTrabajadorByCodigo(authState.usuario.codigo);
        final usuarioId = trabajadorLocal?.usuarioErpId;
        final tieneActiva = await sl<StatusSyncManager>().tieneJornadaActiva(
          deviceId,
          usuarioId: usuarioId,
        );
        if (!mounted) return;
        if (tieneActiva) {
          // Marcar para que home_page muestre notificación de restauración
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('jornada_restaurada_notif', true);
        }
      } catch (_) {}
      if (mounted) context.go('/operador/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: BlocConsumer<CatalogoBloc, CatalogoState>(
        listener: (context, state) {
          if (state is CatalogoLoaded) {
            final tieneDataLocal = state.tractores.isNotEmpty ||
                state.trabajadores.isNotEmpty;
            if (tieneDataLocal) {
              // Catálogos listos → navegar al home correspondiente.
              _navigateToHome();
            } else {
              // SQLite vacío (primer arranque) → forzar sync desde ERP.
              setState(() { _cargandoLocal = false; _errorSinDatos = false; });
              context.read<CatalogoBloc>().add(const CatalogoSyncRequested());
            }
          } else if (state is CatalogoSyncFinalizado && state.hasErrors) {
            // Sync detallado con errores parciales pero con algún dato → navegar.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Algunos catálogos no pudieron sincronizarse. Usando datos locales.'),
              backgroundColor: Colors.orange,
            ));
            Future.delayed(const Duration(seconds: 2), _navigateToHome);
          } else if (state is CatalogoSyncFinalizado && !state.hasErrors) {
            _navigateToHome();
          } else if (state is CatalogoError) {
            if (_cargandoLocal) {
              // Error leyendo SQLite → intentar sync ERP de todas formas.
              setState(() { _cargandoLocal = false; _errorSinDatos = false; });
              context.read<CatalogoBloc>().add(const CatalogoSyncRequested());
            } else {
              // Sync ERP falló. Si no hay datos locales (primer arranque),
              // NO navegar — el operador no puede trabajar con SQLite vacío.
              // Mostrar pantalla de error con opción de reintentar.
              setState(() {
                _errorSinDatos = true;
                _errorMsg = state.message;
              });
            }
          }
        },
        builder: (context, state) {
          // ── Error sin datos locales (primer arranque sin red) ───────────────
          if (_errorSinDatos) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          color: Colors.white54, size: 64),
                      const SizedBox(height: 24),
                      const Text(
                        'Sin conexión al servidor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Es la primera vez que usas la app y los catálogos '
                        'aún no están descargados. Necesitas conexión a internet '
                        'para continuar.',
                        style:
                            TextStyle(color: Color(0xFF95D5B2), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMsg,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _reintentarSync,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar conexión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF95D5B2),
                          foregroundColor: const Color(0xFF1B4332),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ── Carga / sync normal ─────────────────────────────────────────────
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/ic_launcher2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    color: Color(0xFF95D5B2),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _cargandoLocal
                        ? 'Cargando datos...'
                        : 'Sincronizando Maestros...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cargandoLocal
                        ? 'Leyendo catálogos locales'
                        : (state is CatalogoSyncEnProgreso &&
                                state.items.isNotEmpty
                            ? state.items
                                .where((i) => i.count == null)
                                .map((i) => i.label)
                                .join(', ')
                            : 'Descargando catálogos del ERP'),
                    style: const TextStyle(
                      color: Color(0xFF95D5B2),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
