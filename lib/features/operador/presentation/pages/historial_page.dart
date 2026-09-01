import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/core/utils/date_utils.dart';
import 'package:agro_aplicaciones/shared/widgets/connectivity_dot.dart';

/// Pantalla de historial de registros diarios
/// Muestra una lista de todos los registros del operador con filtros
/// y navegación a detalles/edición
class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage>
    with SingleTickerProviderStateMixin {
  // Controladores para filtros
  String _filterEstado = 'todos';
  String _searchQuery = '';

  // Controlador de animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final operadorIdErp = authState.usuario.esOperador
              ? authState.usuario.trabajadorIdErp
              : null;
          context.read<RegistroBloc>().add(
                RegistrosWatchRequested(operadorIdErp: operadorIdErp),
              );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Filtra los registros según estado y búsqueda
  List<RegistroDiario> _filtrarRegistros(List<RegistroDiario> registros) {
    return registros.where((r) {
      // Filtro por estado
      if (_filterEstado != 'todos' && r.estado != _filterEstado) {
        return false;
      }
      // Filtro por búsqueda (número de registro, proceso, tractor)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return r.numeroRegistro.toLowerCase().contains(query) ||
            r.procesoNombre.toLowerCase().contains(query) ||
            r.tractorCodigo.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistroBloc, RegistroState>(
      listenWhen: (_, state) => state is RegistroEliminadoExitoso,
      listener: (context, state) {
        if (state is RegistroEliminadoExitoso) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registro eliminado'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ));
          if (context.canPop()) context.pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar expandido con diseño moderno
          _buildSliverAppBar(),

          // Sección de filtros y búsqueda
          _buildFiltersSection(),

          // Lista de registros
          BlocBuilder<RegistroBloc, RegistroState>(
            builder: (context, state) {
              if (state is RegistroLoading) {
                return _buildLoadingState();
              }

              if (state is RegistrosLoaded) {
                final filtrados = _filtrarRegistros(state.registros);

                if (filtrados.isEmpty) {
                  return _buildEmptyState(state.registros.isEmpty);
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        Widget buildItem = _HistorialCardEnterprise(
                          registro: filtrados[index],
                          onTap: () => context
                              .go('/registro/${filtrados[index].id}/editar'),
                        );
                        if (!_animationController.isCompleted) {
                          buildItem = FadeTransition(
                              opacity: _fadeAnimation, child: buildItem);
                        }
                        return buildItem;
                      },
                      childCount: filtrados.length,
                    ),
                  ),
                );
              }

              if (state is RegistroError) {
                return _buildErrorState(state.message);
              }

              return _buildEmptyState(true);
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      ),
    );
  }

  /// AppBar personalizado con gradiente y diseño moderno
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0D241C),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      actions: const [ConnectivityDot()],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: const Text(
          'HISTORIAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D241C), Color(0xFF1B4332)],
            ),
          ),
          child: Stack(
            children: [
              // Patrón decorativo de fondo
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CC53F).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CC53F).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de filtros y búsqueda
  Widget _buildFiltersSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por número, proceso o tractor...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Color(0xFF8CC53F)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Filtros por estado (chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos', Colors.grey),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Borrador', 'borrador', const Color(0xFFEF6C00)),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Completado', 'completado', const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Aprobado', 'aprobado', const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Rechazado', 'rechazado', const Color(0xFFC62828)),
                ],
              ),
            ),
          ),

          // Separador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CC53F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'REGISTROS',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                if (_filterEstado != 'todos' || _searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterEstado = 'todos';
                        _searchQuery = '';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B4332),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('LIMPIAR FILTROS'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip de filtro por estado
  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _filterEstado == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterEstado = value),
      backgroundColor: Colors.white,
      selectedColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF8CC53F),
              ),
            ),
            SizedBox(height: 16),
            Text('Cargando historial...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// Estado vacío (sin registros)
  Widget _buildEmptyState(bool isTotallyEmpty) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTotallyEmpty
                  ? Icons.history_rounded
                  : Icons.filter_alt_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isTotallyEmpty ? 'No hay registros aún' : 'No hay resultados',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTotallyEmpty
                  ? 'Comienza creando un nuevo registro'
                  : 'Prueba con otros filtros',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            if (isTotallyEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/registro/nuevo'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CREAR REGISTRO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Estado de error
  Widget _buildErrorState(String message) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  final operadorIdErp = authState.usuario.esOperador
                      ? authState.usuario.trabajadorIdErp
                      : null;
                  context.read<RegistroBloc>().add(
                        RegistrosWatchRequested(operadorIdErp: operadorIdErp),
                      );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta individual de registro en el historial
class _HistorialCardEnterprise extends StatelessWidget {
  final RegistroDiario registro;
  final VoidCallback onTap;

  const _HistorialCardEnterprise({
    required this.registro,
    required this.onTap,
  });

  Color get _estadoColor {
    switch (registro.estado.toLowerCase()) {
      case 'aprobado':
        return const Color(0xFF2E7D32);
      case 'completado':
        return const Color(0xFF1565C0);
      case 'rechazado':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFEF6C00);
    }
  }

  String get _estadoTexto {
    switch (registro.estado.toLowerCase()) {
      case 'aprobado':
        return 'APROBADO';
      case 'completado':
        return 'COMPLETADO';
      case 'rechazado':
        return 'RECHAZADO';
      default:
        return registro.estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de estado lateral (barra de color)
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _estadoColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Información principal del registro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            registro.numeroRegistro,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF0D241C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!registro.sincronizado)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off_rounded,
                                      size: 10, color: Colors.orange),
                                  SizedBox(width: 2),
                                  Text('OFF',
                                      style: TextStyle(
                                          fontSize: 8, color: Colors.orange)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${registro.procesoNombre} · ${registro.tractorCodigo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.toDisplay(registro.fecha),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_rounded,
                              size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            registro.turno.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge de estado y flecha de navegación
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _estadoTexto,
                        style: TextStyle(
                          color: _estadoColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
