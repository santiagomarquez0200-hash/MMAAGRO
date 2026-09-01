import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/shared/profile/domain/entities/perfil_usuario.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sincronizar_maestros_page.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({super.key});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  late Future<PerfilUsuario?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPerfil();
  }

  Future<PerfilUsuario?> _loadPerfil() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      debugPrint('perfil: no hay usuario autenticado');
      return null;
    }

    debugPrint('perfil: usuario autenticado ${authState.usuario.codigo}');

    final repo = sl<AuthRepository>();
    final storage = sl<FlutterSecureStorage>();

    final loginUsuario = await storage.read(key: AppConstants.loginUsuarioKey);
    debugPrint('perfil: loginUsuario en storage = "$loginUsuario"');

    String? codigoParaSync;

    if (loginUsuario != null && loginUsuario.trim().isNotEmpty) {
      codigoParaSync = loginUsuario.trim();
      debugPrint('perfil: sincronizando con loginUsuario "$codigoParaSync"');
      final syncResult =
          await repo.sincronizarPerfilProfesional(codigoParaSync);
      syncResult.fold(
        (failure) => debugPrint('perfil: error en sync - ${failure.message}'),
        (perfil) => debugPrint('perfil: sincronizado ${perfil.codigoUsuario}'),
      );
    } else {
      codigoParaSync = authState.usuario.codigo;
      debugPrint('perfil: loginUsuario vacio, usando codigo de trabajador "$codigoParaSync"');
      final syncResult =
          await repo.sincronizarPerfilProfesional(codigoParaSync);
      syncResult.fold(
        (failure) =>
            debugPrint('perfil: error en sync (fallback) - ${failure.message}'),
        (perfil) => debugPrint('perfil: sincronizado por fallback ${perfil.codigoUsuario}'),
      );
    }

    final local = await repo.getPerfilProfesionalLocal(null);
    debugPrint('perfil local disponible: ${local.isRight()}');

    return local.fold((_) => null, (p) => p);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadPerfil());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D241C),
        elevation: 0,
        automaticallyImplyLeading: false, // Sin hamburguesa
        title: Row(
          children: [
            const Icon(Icons.eco, color: Color(0xFF8CC53F), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Perfil',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {}, // Funcionalidad futura de ajustes
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF8CC53F),
          child: FutureBuilder<PerfilUsuario?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8CC53F)));
              }

              final authState = context.read<AuthBloc>().state;
              final defaultNombre = authState is AuthAuthenticated
                  ? '${authState.usuario.nombres} ${authState.usuario.apellidos}'.trim()
                  : 'Usuario';
              final defaultCodigo = authState is AuthAuthenticated
                  ? authState.usuario.codigo
                  : '';

              final perfil = snapshot.data ??
                  PerfilUsuario(
                    codigoUsuario: defaultCodigo,
                    nombreCompleto: defaultNombre.isEmpty ? 'Usuario sin nombre' : defaultNombre,
                    areaProviene: '-',
                    fundo: '-',
                    sede: '-',
                    estadoUsuario: '-',
                    sincronizadoAt: DateTime.now(),
                  );

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _headerEnterprise(perfil),
                  const SizedBox(height: 20),
                  _infoSectionEnterprise(perfil),
                  const SizedBox(height: 30),

                  // BOTÓN PANEL PRINCIPAL
                  _actionButton(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        final rol = authState.usuario.rolNombre;
                        if (rol == 'portero') {
                          context.go('/portero/home');
                        } else if (rol == 'supervisor') {
                          context.go('/supervisor/home');
                        } else if (rol == 'mecanico') {
                          context.go('/mecanico/home');
                        } else {
                          context.go('/operador/home');
                        }
                      } else {
                        context.go('/pin');
                      }
                    },
                    icon: Icons.dashboard_outlined,
                    label: 'PANEL PRINCIPAL',
                    color: const Color(0xFF0D241C),
                    textColor: Colors.white,
                  ),

                  const SizedBox(height: 12),

                  // BOTÓN SINCRONIZAR MAESTROS
                  _actionButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SincronizarMaestrosPage(),
                      ),
                    ),
                    icon: Icons.cloud_sync_outlined,
                    label: 'SINCRONIZAR MAESTROS',
                    color: const Color(0xFF1B4332),
                    textColor: const Color(0xFF8CC53F),
                  ),

                  const SizedBox(height: 12),

                  // BOTÓN CERRAR SESIÓN
                  _actionButton(
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested()),
                    icon: Icons.logout_rounded,
                    label: 'CERRAR SESIÓN',
                    color: Colors.white,
                    textColor: Colors.red.shade700,
                    isOutlined: true,
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _headerEnterprise(PerfilUsuario p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8CC53F), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(
                p.nombreCompleto.isNotEmpty
                    ? p.nombreCompleto.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                    color: Color(0xFF1B4332),
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombreCompleto,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D241C)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC5E1A5)),
                  ),
                  child: Text(
                    p.puestoTrabajo ?? 'Usuario',
                    style: const TextStyle(
                        color: Color(0xFF33691E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSectionEnterprise(PerfilUsuario p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _infoTile(Icons.person_outline, 'Nombre completo', p.nombreCompleto),
          _divider(),
          _infoTile(
              Icons.badge_outlined, 'Rol / Puesto', p.puestoTrabajo ?? '-'),
          _divider(),
          _infoTile(Icons.alternate_email, 'Usuario', p.codigoUsuario),
          _divider(),
          _infoTile(
              Icons.qr_code_2_rounded, 'Código', p.codigoTrabajador ?? '-'),
          _divider(),
          _infoTile(Icons.location_on_outlined, 'Sede', p.sede),
          _divider(),
          _infoTile(Icons.eco_outlined, 'Área', p.areaProviene),
          _divider(),
          _infoTile(Icons.apartment_outlined, 'Fundo', p.fundo, isLast: true),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4A6759), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      color: Color(0xFF0D241C),
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1, indent: 70, endIndent: 16, color: Colors.grey.shade100);

  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    bool isOutlined = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor, size: 20),
        label: Text(
          label,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined
                ? BorderSide(color: Colors.red.shade100, width: 1.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
