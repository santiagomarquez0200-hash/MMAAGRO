import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/shared/auth/domain/entities/usuario.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/pdf_service.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/blocs/supervisor_bloc.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/blocs/supervisor_event.dart';
import 'package:agro_aplicaciones/features/supervisor/presentation/blocs/supervisor_state.dart';

// ─── Paleta centralizada ──────────────────────────────────────────────────────
const _kDark = Color(0xFF0D241C);
const _kMid = Color(0xFF1B4332);
const _kLime = Color(0xFF8CC53F);
const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF5F8F5);

// Paleta semántica de estados
const _kStatusActive = Color(0xFF16A34A);
const _kStatusClosed = Color(0xFF64748B);
const _kStatusAlert = Color(0xFFDC2626);
const _kStatusPending = Color(0xFFD97706);
const _kBorder = Color(0xFFE2E8F0);
const _kCardBg = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF1A202C);
const _kTextSecondary = Color(0xFF64748B);
const _kTextMuted = Color(0xFFADB5BD);

class HomeSupervisorPage extends StatefulWidget {
  const HomeSupervisorPage({super.key});
  @override
  State<HomeSupervisorPage> createState() => _HomeSupervisorPageState();
}

class _HomeSupervisorPageState extends State<HomeSupervisorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Turno (ERP live) ──────────────────────────────────────────────────────
  String _turnoSeleccionado = 'dia';
  List<Map<String, dynamic>> _reporte = [];
  bool _loadingReporte = false;
  String? _reporteError;
  bool _datosReporteCargados = false; // true tras la primera carga exitosa
  DateTime? _ultimaActualizacion; // hora de la última carga exitosa
  Timer? _pollingTimer;

  // ── Jornadas activas ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _jornadas = [];
  bool _loadingJornadas = false;
  String? _jornadasError;

  // ── Filtros (aprobaciones / historial) ───────────────────────────────────
  DateTime _fechaFiltro = DateTime.now();
  String? _turnoFiltro; // null = todos
  String _estadoFiltro = 'completado'; // 'completado' | 'todos'
  String _tipoFiltro = 'todos'; // 'tractor' | 'vehiculo' | 'todos'

  // ── Paginación del historial ──────────────────────────────────────────────
  static const int _kPageSize = 20;
  int _historialPagina = 1;
  bool _exportandoCsv = false;

  // IDs de registros con una acción de aprobación/rechazo en curso.
  // Evita doble-submit si el usuario toca el botón dos veces antes de que
  // el BLoC actualice el estado.
  final Set<String> _accionesEnProceso = {};

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarReporte();
    _cargarRegistros();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted || _loadingReporte) return;
      _cargarReporte();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ── Carga ─────────────────────────────────────────────────────────────────

  Future<void> _cargarJornadas() async {
    if (!mounted) return;
    setState(() {
      _loadingJornadas = true;
      _jornadasError = null;
    });
    try {
      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final rows =
          await _withRetry(() => sl<ErpApiClient>().getJornadasSupervisor(
                fecha: fecha,
                turno: _turnoSeleccionado,
              ));
      if (mounted) setState(() => _jornadas = rows);
    } catch (e) {
      if (mounted) setState(() => _jornadasError = _mensajeError(e));
    } finally {
      if (mounted) setState(() => _loadingJornadas = false);
    }
  }

  Future<void> _cargarReporte() async {
    if (!mounted) return;
    setState(() {
      _loadingReporte = true;
      _reporteError = null;
      // NO se borra _reporte aquí: los datos cacheados permanecen visibles
      // mientras se recarga, evitando el parpadeo con pantalla vacía.
    });
    await _cargarJornadas();
    try {
      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final rows =
          await _withRetry(() => sl<ErpApiClient>().getReporteSupervisor(
                turno: _turnoSeleccionado,
                fecha: fecha,
              ));
      if (mounted) {
        setState(() {
          _reporte = rows;
          _loadingReporte = false;
          _datosReporteCargados = true;
          _ultimaActualizacion = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reporteError = _mensajeError(e);
          _loadingReporte = false;
          // _reporte conserva los datos anteriores para no mostrar vacío
        });
      }
    }
  }

  // Reintenta una vez tras 2 s si el primer intento falla por red/timeout.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    try {
      return await fn().timeout(const Duration(seconds: 20));
    } on SocketException {
      await Future.delayed(const Duration(seconds: 2));
      return fn().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      await Future.delayed(const Duration(seconds: 2));
      return fn().timeout(const Duration(seconds: 20));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final esRed = e is SocketException ||
          e is TimeoutException ||
          msg.contains('network') ||
          msg.contains('timeout') ||
          msg.contains('connection');
      if (!esRed) rethrow;
      await Future.delayed(const Duration(seconds: 2));
      return fn().timeout(const Duration(seconds: 20));
    }
  }

  String _mensajeError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('network') ||
        s.contains('connection')) {
      return 'Sin conexión con el servidor. Verifica la red y reintenta.';
    }
    if (s.contains('timeout')) {
      return 'El servidor tardó demasiado en responder. Reintenta en un momento.';
    }
    if (s.contains('401') || s.contains('auth')) {
      return 'Sesión expirada. Vuelve al inicio de sesión.';
    }
    return e.toString().replaceAll('Exception:', '').trim();
  }

  void _cargarRegistros() {
    setState(() => _historialPagina = 1);
    context.read<SupervisorBloc>().add(SupervisorLoadRegistros(
          fecha: _fechaFiltro,
          turno: _turnoFiltro,
        ));
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _aprobarRegistro(RegistroDiario r, int supervisorIdErp) async {
    // Guard doble-submit: ignorar si ya hay una acción en curso para este registro.
    if (_accionesEnProceso.contains(r.id)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        titulo: 'Aprobar Registro',
        icon: Icons.check_circle_rounded,
        iconColor: _kGreen,
        mensaje: '¿Confirma la aprobación de ${r.numeroRegistro}?',
        labelOk: 'Aprobar',
        colorOk: _kGreen,
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _accionesEnProceso.add(r.id));
    context.read<SupervisorBloc>().add(SupervisorAprobarRegistro(
          params: AprobarRegistroParams(
            registroId: r.id,
            supervisorIdErp: supervisorIdErp,
            accion: 'aprobar',
          ),
        ));
    // El Set se limpia cuando el BLoC emite el resultado (ver BlocListener en build).
  }

  Future<void> _rechazarRegistro(RegistroDiario r, int supervisorIdErp) async {
    if (_accionesEnProceso.contains(r.id)) return;

    // Paso 1: diálogo de elección — rechazar o editar contenido
    final accion = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.report_problem_outlined,
                color: Colors.red.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('¿Qué desea hacer?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registro ${r.numeroRegistro}',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            // Opción 1 — Rechazar
            _OpcionAccionTile(
              icono: Icons.cancel_outlined,
              color: Colors.red.shade700,
              titulo: 'Rechazar este informe',
              descripcion: 'El registro quedará marcado como rechazado.',
              onTap: () => Navigator.pop(_, 'rechazar'),
            ),
            const SizedBox(height: 10),
            // Opción 2 — Editar
            _OpcionAccionTile(
              icono: Icons.edit_outlined,
              color: _kMid,
              titulo: 'Editar su contenido',
              descripcion: 'Modifica el registro antes de tomar una decisión.',
              onTap: () => Navigator.pop(_, 'editar'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, null),
            child:
                Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );

    if (accion == null || !mounted) return;

    // Paso 2a: navegar a la pantalla de edición
    if (accion == 'editar') {
      await context.push('/registro/${r.id}/admin-editar', extra: r);
      if (mounted) _cargarRegistros();
      return;
    }

    // Paso 2b: flujo de rechazo con motivo
    final motivoCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: _dialogTitle(
              Icons.cancel_rounded, Colors.red.shade700, 'Rechazar Registro'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registro: ${r.numeroRegistro}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Motivo:',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                TextField(
                  controller: motivoCtrl,
                  decoration: InputDecoration(
                    hintText: 'Describe el motivo...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Rechazar'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      setState(() => _accionesEnProceso.add(r.id));
      context.read<SupervisorBloc>().add(SupervisorAprobarRegistro(
            params: AprobarRegistroParams(
              registroId: r.id,
              supervisorIdErp: supervisorIdErp,
              accion: 'rechazar',
              motivo: motivoCtrl.text.trim().isEmpty
                  ? null
                  : motivoCtrl.text.trim(),
            ),
          ));
    } finally {
      motivoCtrl.dispose();
    }
  }

  Future<void> _mostrarPdfPreview(RegistroDiario r) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PdfPreviewSheet(registro: r, onShare: _compartirPdf),
    );
  }

  Future<void> _compartirPdf(RegistroDiario r) async {
    try {
      await PdfService.generarYCompartir(r);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PDF generado correctamente'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Error PDF: ${msg.length > 100 ? msg.substring(0, 100) : msg}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null && mounted) {
      setState(() => _fechaFiltro = picked);
      _cargarRegistros();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final usuario = authState is AuthAuthenticated ? authState.usuario : null;

    return BlocListener<SupervisorBloc, SupervisorState>(
      listener: (ctx, state) {
        if (state is SupervisorOperacionExitosa) {
          // Liberar solo el registro que completó la operación, no todos.
          setState(() {
            if (state.registroId != null) {
              _accionesEnProceso.remove(state.registroId);
            } else {
              _accionesEnProceso.clear();
            }
          });
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.mensaje),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ));
          _cargarRegistros();
          // Refrescar también el tab Turno para que refleje el nuevo estado
          // sin esperar al próximo ciclo del pollingTimer (30 s).
          _cargarReporte();
        }
        if (state is SupervisorError) {
          // Error — no limpiar todas las acciones; dejar que cada registro
          // espere o reintente individualmente (no sabemos cuál falló aquí).
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.mensaje),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(usuario),
        drawer: _buildDrawer(usuario),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabTurno(),
            _buildTabAprobaciones(usuario),
            _buildTabHistorial(usuario),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Usuario? usuario) {
    final iniciales = (usuario?.nombreCompleto.isNotEmpty == true)
        ? usuario!.nombreCompleto
            .split(' ')
            .take(2)
            .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
            .join()
        : 'S';

    return AppBar(
      backgroundColor: _kDark,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel Supervisor',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
          if (usuario != null)
            Text(
              usuario.nombreCompleto.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kLime,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () {
            _cargarReporte();
            _cargarRegistros();
          },
          tooltip: 'Actualizar datos',
          style: IconButton.styleFrom(foregroundColor: Colors.white70),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _kLime,
              child: Text(
                iniciales,
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: _kLime,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.timer_outlined, size: 17),
                text: 'Turno',
                height: 46,
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline_rounded, size: 17),
                text: 'Aprobaciones',
                height: 46,
              ),
              Tab(
                icon: Icon(Icons.history_rounded, size: 17),
                text: 'Historial',
                height: 46,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────

  Widget _buildDrawer(Usuario? usuario) {
    final nombre = usuario?.nombreCompleto ?? 'Supervisor';
    final rol = usuario?.rolNombre.toUpperCase() ?? 'SUPERVISOR';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'S';

    return Drawer(
      backgroundColor: _kCardBg,
      child: Column(children: [
        // ── Header del perfil ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          decoration: const BoxDecoration(color: _kDark),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _kLime,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              rol,
              style: const TextStyle(
                color: _kLime,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ]),
        ),

        // ── Navegación ────────────────────────────────────────────────
        const SizedBox(height: 8),
        _drawerTile(Icons.timer_outlined, 'Control de turno',
            'Avance y alertas en tiempo real', () {
          Navigator.pop(context);
          _tabController.animateTo(0);
        }),
        _drawerTile(Icons.check_circle_outline_rounded, 'Aprobaciones',
            'Aprobar o rechazar registros', () {
          Navigator.pop(context);
          _tabController.animateTo(1);
        }),
        _drawerTile(
            Icons.history_rounded, 'Historial', 'Consulta e exportación', () {
          Navigator.pop(context);
          _tabController.animateTo(2);
        }),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(color: _kBorder),
        ),

        // ── Sync status ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _drawerSyncCard(),
        ),
        const SizedBox(height: 8),

        _drawerTile(Icons.person_outline_rounded, 'Mi Perfil', null, () {
          Navigator.pop(context);
          context.push('/perfil');
        }),

        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(color: _kBorder),
        ),
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kStatusAlert.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.logout_rounded,
                color: _kStatusAlert, size: 18),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: _kStatusAlert,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  ListTile _drawerTile(
      IconData icon, String title, String? sub, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _kMid, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: _kTextPrimary,
        ),
      ),
      subtitle: sub != null
          ? Text(
              sub,
              style: const TextStyle(fontSize: 11, color: _kTextMuted),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _drawerSyncCard() {
    final total = _reporte.length;
    final syncOk = _reporte
        .where((r) => _toBool(r['sincronizado_erp'] ?? r['sincronizado']))
        .length;
    final pend = total - syncOk;
    final color = total == 0
        ? _kStatusPending
        : pend > 0
            ? _kStatusAlert
            : _kStatusActive;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(
          pend > 0 ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Sincronización ERP',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              total == 0
                  ? 'Sin registros aún'
                  : pend > 0
                      ? '$syncOk/$total confirmados · $pend pendientes'
                      : 'Todos confirmados ($syncOk)',
              style: const TextStyle(color: _kTextSecondary, fontSize: 11),
            ),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB TURNO — Vista unificada Enterprise
  // Arquitectura: cada operador es UNA tarjeta que integra su jornada
  // (de SP_MMA_GET_JORNADAS_SUPERVISOR) y sus registros individuales
  // (de SP_MMA_GET_REGISTROS_SUPERVISOR), eliminando la fragmentación visual.
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabTurno() {
    return Column(children: [
      _buildTurnoBar(),
      Expanded(
        child: (_loadingReporte &&
                _reporte.isEmpty &&
                _jornadas.isEmpty &&
                !_loadingJornadas)
            ? const Center(child: CircularProgressIndicator(color: _kLime))
            : _reporteError != null && _reporte.isEmpty
                ? _errorState(_reporteError!, _cargarReporte)
                : _buildTurnoContent(),
      ),
    ]);
  }

  // ── Barra superior: selector compacto + fecha/hora + botón refresco ───────

  Widget _buildTurnoBar() {
    final esDia = _turnoSeleccionado == 'dia';
    final horaActual = DateFormat('HH:mm').format(DateTime.now());

    final ultimaStr = _ultimaActualizacion != null
        ? 'Update ${DateFormat('HH:mm').format(_ultimaActualizacion!)}'
        : _loadingReporte
            ? 'Actualizando...'
            : 'Sin datos aún';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Selector de turno: segmented control
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _buildTurnoTab(
                'Día', 'dia', Icons.wb_sunny_rounded, const Color(0xFFB45309)),
            const SizedBox(width: 2),
            _buildTurnoTab('Noche', 'noche', Icons.nightlight_round,
                const Color(0xFF1D4ED8)),
          ]),
        ),
        const SizedBox(width: 6),
        // Rango horario
        Text(
          esDia ? '06:00 – 14:00' : '14:00 – 22:00',
          style: TextStyle(
            color: esDia ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Última actualización
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            horaActual,
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (_loadingReporte)
              const SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _kTextMuted)),
            if (_loadingReporte) const SizedBox(width: 4),
            Text(
              ultimaStr,
              style: const TextStyle(color: _kTextMuted, fontSize: 10),
            ),
          ]),
        ]),
        const SizedBox(width: 4),
        // Botón refresco
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            onPressed: _loadingReporte
                ? null
                : () {
                    _cargarReporte();
                    _cargarRegistros();
                  },
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: _loadingReporte
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: _kMid,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: _kMid, size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _buildTurnoTab(
      String label, String value, IconData icon, Color color) {
    final sel = _turnoSeleccionado == value;
    return GestureDetector(
      onTap: () {
        setState(() => _turnoSeleccionado = value);
        _cargarReporte();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? _kCardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: sel ? color : _kTextMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  color: sel ? color : _kTextMuted,
                ),
              ),
            ]),
      ),
    );
  }

  // ── Contenido principal del turno ─────────────────────────────────────────

  Widget _buildTurnoContent() {
    final prog = _turnoProgress(_turnoSeleccionado);
    final shiftPct = (prog * 100).clamp(0, 100).toInt();
    final alerta = prog >= 0.85;

    // ── Merge: jornadas ↔ registros ──────────────────────────────────────────
    // GET_JORNADAS_SUPERVISOR devuelve usuario_erp_id (ID de login).
    // GET_REGISTROS_SUPERVISOR devuelve operador_id_erp (ID de trabajador).
    // Son tablas distintas — el SP de registros debe incluir usuario_erp_id
    // (campo añadido vía JOIN en el servidor). Mientras el SP lo tenga,
    // el merge por ID funciona; si no, cae al fallback por nombre normalizado.

    String normNombre(String? s) =>
        (s ?? '').trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

    // Índice por usuario_erp_id (cuando el SP ya lo devuelve)
    final Map<int, List<Map<String, dynamic>>> reportePorId = {};
    // Índice por nombre normalizado (fallback)
    final Map<String, List<Map<String, dynamic>>> reportePorNombre = {};

    for (final r in _reporte) {
      // Campo que el SP de registros devuelve para cruzar con jornadas
      final uid = _toInt(r['operador_usuario_erp_id']) ??
          _toInt(r['usuario_erp_id']);
      if (uid != null && uid > 0) {
        reportePorId.putIfAbsent(uid, () => []).add(r);
      }
      // Fallback por nombre
      final nombre = normNombre(
        r['operador_nombre']?.toString() ??
            r['nombre_operador']?.toString() ??
            r['nombre_usuario']?.toString(),
      );
      if (nombre.isNotEmpty) {
        reportePorNombre.putIfAbsent(nombre, () => []).add(r);
      }
    }

    List<Map<String, dynamic>> registrosDe(Map<String, dynamic> j) {
      final uid = _toInt(j['usuario_erp_id']) ?? 0;
      // 1º intento: por usuario_erp_id (requiere SP actualizado)
      final porId = uid > 0 ? reportePorId[uid] : null;
      if (porId != null && porId.isNotEmpty) return porId;
      // 2º intento: por nombre normalizado (fallback mientras el SP no se actualiza)
      final nombre = normNombre(j['nombre_usuario']?.toString());
      return reportePorNombre[nombre] ?? [];
    }

    // Jornadas activas y cerradas
    bool esCerrada(Map<String, dynamic> j) {
      final c = j['jornada_cerrada'];
      return c == true || c == 1 || c?.toString() == '1';
    }

    final activas = _jornadas.where((j) => !esCerrada(j)).toList();
    final cerradas = _jornadas.where((j) => esCerrada(j)).toList();

    final hayDatos = _jornadas.isNotEmpty || _reporte.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _cargarReporte,
      color: _kLime,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          // ── Panel de comando — solo cuando hay datos reales ─────────
          if (hayDatos || _loadingReporte) ...[
            _buildCommandCenter(shiftPct, alerta, prog),
            const SizedBox(height: 16),
          ],

          // ── Sección: En campo ───────────────────────────────────────
          if (activas.isNotEmpty || _loadingJornadas) ...[
            _buildSectionHeader(
              icon: Icons.radio_button_checked_rounded,
              iconColor: _kGreen,
              label: 'En campo',
              count: activas.length,
              badge:
                  activas.isEmpty && _loadingJornadas ? null : activas.length,
            ),
            const SizedBox(height: 8),
            if (_loadingJornadas && activas.isEmpty)
              _buildSkeletonLoader()
            else
              ...activas.map((j) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildOperadorCard(
                      j,
                      registrosDe(j),
                      abierta: true,
                    ),
                  )),
            const SizedBox(height: 8),
          ],

          // ── Sección: Finalizaron ─────────────────────────────────────
          if (cerradas.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.check_circle_outline_rounded,
              iconColor: Colors.grey.shade500,
              label: 'Finalizaron',
              count: cerradas.length,
              badge: cerradas.length,
            ),
            const SizedBox(height: 8),
            ...cerradas.map((j) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildOperadorCard(
                    j,
                    registrosDe(j),
                    abierta: false,
                  ),
                )),
            const SizedBox(height: 8),
          ],

          // ── Error de jornadas ──────────────────────────────────────────
          if (_jornadasError != null && !_loadingJornadas && _jornadas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.wifi_off_rounded,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_jornadasError!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800))),
                ]),
              ),
            ),

          // ── Estado vacío: solo cuando sabemos con certeza que no hay datos ──
          if (_datosReporteCargados &&
              _jornadas.isEmpty &&
              _reporte.isEmpty &&
              !_loadingJornadas &&
              !_loadingReporte)
            _buildTurnoVacio(),
        ],
      ),
    );
  }

  // ── Panel de comando: resumen visual del turno ────────────────────────────

  Widget _buildCommandCenter(int shiftPct, bool alerta, double prog) {
    final total = _reporte.length;
    final aprobados = _reporte.where((r) => r['estado'] == 'aprobado').length;
    final completados =
        _reporte.where((r) => r['estado'] == 'completado').length;
    final enCurso = _reporte.where((r) => r['estado'] == 'borrador').length;
    final syncOk = _reporte
        .where((r) => _toBool(r['sincronizado_erp'] ?? r['sincronizado']))
        .length;
    final syncPend = total - syncOk;
    final tractores = _reporte
        .where(
            (r) => (r['tipo_registro']?.toString() ?? 'tractor') == 'tractor')
        .length;
    final vehiculos = _reporte
        .where((r) => r['tipo_registro']?.toString() == 'vehiculo')
        .length;

    final rangoInicio = _turnoSeleccionado == 'dia' ? '06:00' : '14:00';
    final rangoFin = _turnoSeleccionado == 'dia' ? '14:00' : '22:00';
    final turnoColor = alerta ? _kStatusAlert : _kLime;
    final turnoIcono = _turnoSeleccionado == 'dia'
        ? Icons.wb_sunny_rounded
        : Icons.nightlight_round;
    final turnoIconColor = _turnoSeleccionado == 'dia'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF60A5FA);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alerta
              ? _kStatusAlert.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        // ── Header: turno + alerta ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(turnoIcono, color: turnoIconColor, size: 14),
            const SizedBox(width: 7),
            Text(
              'TURNO ${_turnoSeleccionado == 'dia' ? 'DÍA' : 'NOCHE'}  ·  $rangoInicio – $rangoFin',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (alerta)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kStatusAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _kStatusAlert.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 11, color: Colors.red.shade300),
                  const SizedBox(width: 4),
                  Text(
                    'CIERRE PRÓXIMO',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Barra de progreso del turno ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Stack(children: [
              // Track
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: prog.clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: alerta
                          ? [Colors.red.shade700, Colors.red.shade400]
                          : [const Color(0xFF4ADE80), _kLime],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Dot indicator
              Positioned(
                left: (prog.clamp(0.0, 0.97)) *
                    (MediaQuery.sizeOf(context).width - 64),
                top: -4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: turnoColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF0D1F16), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: turnoColor.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text(
                rangoInicio,
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
              const Spacer(),
              Text(
                '$shiftPct% del turno',
                style: TextStyle(
                  color: turnoColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                rangoFin,
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 4),

        // ── Divisor ─────────────────────────────────────────────────────
        Divider(
          height: 1,
          color: Colors.white.withValues(alpha: 0.06),
        ),

        // ── Grid de 4 métricas ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(children: [
            _metricBox(
              '$total',
              'TOTAL',
              Colors.white,
              Icons.assignment_outlined,
            ),
            _metricDivider(),
            _metricBox(
              '$enCurso',
              'EN CURSO',
              enCurso > 0 ? const Color(0xFFFCD34D) : Colors.white38,
              Icons.pending_actions_rounded,
            ),
            _metricDivider(),
            _metricBox(
              '$completados',
              'COMPLETOS',
              _kLime,
              Icons.task_alt_rounded,
            ),
            _metricDivider(),
            _metricBox(
              '$aprobados',
              'APROBADOS',
              aprobados > 0 ? const Color(0xFF34D399) : Colors.white38,
              Icons.verified_rounded,
            ),
          ]),
        ),

        // ── Divisor ─────────────────────────────────────────────────────
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

        // ── Franja inferior: tipos + sync ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(children: [
            _equipoBadge(
                Icons.agriculture_rounded, tractores, _kLime, 'Tractores'),
            const SizedBox(width: 8),
            _equipoBadge(Icons.directions_car_rounded, vehiculos,
                const Color(0xFF60A5FA), 'Camiones'),
            const Spacer(),
            // Sync badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: syncPend > 0
                    ? _kStatusAlert.withValues(alpha: 0.12)
                    : _kStatusActive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: syncPend > 0
                      ? _kStatusAlert.withValues(alpha: 0.35)
                      : _kStatusActive.withValues(alpha: 0.35),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  syncPend > 0
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_done_rounded,
                  size: 13,
                  color: syncPend > 0
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF6EE7B7),
                ),
                const SizedBox(width: 5),
                Text(
                  syncPend > 0
                      ? '$syncPend pendiente${syncPend > 1 ? 's' : ''}'
                      : total == 0
                          ? 'Sin registros'
                          : '$syncOk/$total sync',
                  style: TextStyle(
                    color: syncPend > 0
                        ? const Color(0xFFFCA5A5)
                        : total == 0
                            ? Colors.white38
                            : const Color(0xFF6EE7B7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _metricBox(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _metricDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.07),
        margin: const EdgeInsets.symmetric(horizontal: 2),
      );

  Widget _equipoBadge(IconData icon, int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$count $label',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  // ── Cabecera de sección ───────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int count,
    int? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary.withValues(alpha: 0.7),
            letterSpacing: 0.8,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badge',
              style: TextStyle(
                fontSize: 10,
                color: iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            thickness: 1,
            color: _kBorder,
          ),
        ),
      ]),
    );
  }

  // ── Tarjeta de operador: jornada + registros unificados ───────────────────

  /// Detecta si la jornada está activa pasada la hora normal de cierre del turno.
  /// Turno día termina a las 14:00; turno noche a las 22:00.
  bool _enHorasExtras(bool abierta) {
    if (!abierta) return false;
    final h = DateTime.now().hour;
    if (_turnoSeleccionado == 'dia') return h >= 14;
    if (_turnoSeleccionado == 'noche') return h >= 22 || h < 4;
    return false;
  }

  Widget _buildOperadorCard(
    Map<String, dynamic> jornada,
    List<Map<String, dynamic>> registros, {
    required bool abierta,
  }) {
    final nombre = jornada['nombre_usuario']?.toString() ?? 'Operador';
    final totalReg = _toInt(jornada['total_registros']) ?? registros.length;
    final syncCount = _toInt(jornada['registros_sincronizados']) ??
        registros
            .where((r) => _toBool(r['sincronizado_erp'] ?? r['sincronizado']))
            .length;
    final inicioStr = jornada['jornada_inicio_at'] != null
        ? _formatHora(jornada['jornada_inicio_at'].toString())
        : '--:--';
    final finStr = jornada['jornada_fin_at'] != null
        ? _formatHora(jornada['jornada_fin_at'].toString())
        : null;
    final shiftPct = _turnoProgress(_turnoSeleccionado);
    final syncRatio = totalReg > 0 ? syncCount / totalReg : 1.0;
    final alertaSync = abierta && shiftPct >= 0.8 && syncCount < totalReg;
    final enHorasExtras = _enHorasExtras(abierta);

    final statusColor = alertaSync
        ? _kStatusAlert
        : abierta
            ? _kStatusActive
            : _kStatusClosed;
    final statusLabel = alertaSync
        ? 'ALERTA'
        : abierta
            ? 'ACTIVO'
            : 'CERRADO';

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Franja de color superior (indicador de estado) ────────────
        Container(height: 3, color: statusColor),

        // ── Header del operador ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'O',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nombre + horario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 11, color: _kTextMuted),
                    const SizedBox(width: 4),
                    Text(
                      finStr != null
                          ? '$inicioStr – $finStr'
                          : 'Inicio $inicioStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextSecondary,
                      ),
                    ),
                    if (totalReg > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _kTextMuted)),
                      const SizedBox(width: 6),
                      Text(
                        '$totalReg reg.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            // Badges de estado + horas extras
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ]),
                ),
                if (enHorasExtras) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.more_time_rounded,
                          size: 10, color: Colors.orange.shade700),
                      const SizedBox(width: 3),
                      Text(
                        'HRS EXTRAS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ]),
        ),

        // ── Barra de progreso sync ──────────────────────────────────────
        if (totalReg > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: syncRatio,
                    minHeight: 3,
                    backgroundColor: _kBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      syncRatio >= 1.0
                          ? _kStatusActive
                          : alertaSync
                              ? _kStatusAlert
                              : _kStatusPending,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$syncCount/$totalReg sync',
                style: const TextStyle(
                  fontSize: 10,
                  color: _kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ],

        // ── Banner horas extras ─────────────────────────────────────────
        if (enHorasExtras) ...[
          Divider(height: 1, color: Colors.orange.shade100),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.orange.shade50,
            child: Row(children: [
              Icon(Icons.more_time_rounded,
                  size: 15, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jornada extendida por horas extras — '
                  'el turno ${_turnoSeleccionado == 'dia' ? 'día' : 'noche'} '
                  'debió cerrar a las '
                  '${_turnoSeleccionado == 'dia' ? '14:00' : '22:00'}.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ]),
          ),
        ],

        // ── Lista de registros ──────────────────────────────────────────
        if (registros.isNotEmpty) ...[
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Text(
              'REGISTROS  (${registros.length})',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kTextMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...registros.asMap().entries.map(
                (e) => _buildRegistroMiniRow(e.value, index: e.key + 1),
              ),
          const SizedBox(height: 4),
        ] else if (abierta) ...[
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _kStatusPending.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _kStatusPending.withValues(alpha: 0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.sync_rounded, size: 14, color: _kStatusPending),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A la espera de sincronización',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kStatusPending,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'El operador tiene jornada activa. Los registros aparecerán aquí cuando el dispositivo sincronice.',
                        style: TextStyle(
                          fontSize: 10,
                          color: _kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
        ],
      ]),
    );
  }

  // ── Fila de registro dentro de la tarjeta del operador ────────────────────

  Widget _buildRegistroMiniRow(Map<String, dynamic> item, {int index = 0}) {
    final numero = item['numero_registro']?.toString() ?? '';
    final proceso = item['proceso_nombre']?.toString() ?? '';
    final estado = item['estado']?.toString() ?? 'borrador';
    final tipo = item['tipo_registro']?.toString() ?? 'tractor';
    final sync = _toBool(item['sincronizado_erp'] ?? item['sincronizado']);
    final esVeh = tipo == 'vehiculo';

    // Contar paros del registro para el badge de fallas
    final parosRaw = item['paros_json'];
    final parosList = parosRaw != null ? _parseList(parosRaw) : <Map<String, dynamic>>[];
    final totalParos = parosList.length;

    Color estadoColor;
    String estadoLabel;
    switch (estado) {
      case 'aprobado':
        estadoColor = _kStatusActive;
        estadoLabel = 'Aprobado';
        break;
      case 'completado':
        estadoColor = const Color(0xFF2563EB);
        estadoLabel = 'Completo';
        break;
      case 'rechazado':
        estadoColor = _kStatusAlert;
        estadoLabel = 'Rechazado';
        break;
      default:
        estadoColor = _kStatusPending;
        estadoLabel = 'En curso';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.8)),
      ),
      child: Row(children: [
        // Ícono de tipo
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: esVeh ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              esVeh ? Icons.directions_car_rounded : Icons.agriculture_rounded,
              size: 14,
              color: esVeh ? const Color(0xFF2563EB) : _kStatusActive,
            ),
          ),
        ),
        const SizedBox(width: 9),
        // Número + proceso
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                numero,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              if (proceso.isNotEmpty)
                Text(
                  proceso,
                  style: const TextStyle(fontSize: 10, color: _kTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Estado badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            estadoLabel,
            style: TextStyle(
              fontSize: 9,
              color: estadoColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Badge de paros (fallas / interrupciones)
        if (totalParos > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warning_amber_rounded,
                  size: 9, color: Colors.red.shade600),
              const SizedBox(width: 3),
              Text(
                '$totalParos',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(width: 6),
        // Sync dot
        Icon(
          sync ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
          size: 13,
          color: sync ? _kStatusActive : _kTextMuted,
        ),
        const SizedBox(width: 4),
        // PDF button
        GestureDetector(
          onTap: () => _mostrarPdfPreview(_registroFromReporteRow(item)),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _kMid.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                size: 14, color: _kMid),
          ),
        ),
      ]),
    );
  }

  // ── Esqueleto de carga ────────────────────────────────────────────────────

  Widget _buildSkeletonLoader() {
    return Column(
      children: List.generate(
          2,
          (_) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(children: [
                  Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      color: _kBorder,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: _kBorder,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 12,
                                width: 140,
                                decoration: BoxDecoration(
                                    color: _kBorder,
                                    borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 6),
                            Container(
                                height: 10,
                                width: 100,
                                decoration: BoxDecoration(
                                    color: _kBorder,
                                    borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ]),
              )),
    );
  }

  // ── Estado vacío del turno ────────────────────────────────────────────────

  Widget _buildTurnoVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: _kBorder,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 30,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin actividad en este turno',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Los operadores aparecerán aquí\ncuando inicien su jornada y sincronicen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _kTextMuted),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB APROBACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabAprobaciones(Usuario? usuario) {
    final supervisorIdNullable = usuario?.trabajadorIdErp;
    if (supervisorIdNullable == null) {
      return const Center(
        child: Text('ID de supervisor no disponible. Sincroniza los catálogos.',
            style: TextStyle(color: Colors.red)),
      );
    }
    final int supervisorId = supervisorIdNullable;
    return Column(children: [
      _filtrosHeader(mostrarEstado: true),
      Expanded(child: BlocBuilder<SupervisorBloc, SupervisorState>(
        builder: (ctx, state) {
          if (state is SupervisorLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kLime));
          }
          if (state is SupervisorError) {
            return _errorState(state.mensaje, _cargarRegistros);
          }

          final all = _extractRegistros(state);
          final filtered = all.where((r) {
            if (r.estado == 'borrador') return false;
            if (_estadoFiltro == 'completado' && r.estado != 'completado') {
              return false;
            }
            if (_tipoFiltro != 'todos' && r.tipoRegistro != _tipoFiltro) {
              return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return _emptyRegistros('Sin registros pendientes de aprobación');
          }

          return RefreshIndicator(
            onRefresh: () async => _cargarRegistros(),
            color: _kLime,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _buildRegistroCard(filtered[i], supervisorId),
            ),
          );
        },
      )),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB HISTORIAL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabHistorial(Usuario? usuario) {
    final supervisorId = usuario?.trabajadorIdErp ?? 0;
    return Column(children: [
      _filtrosHeader(mostrarEstado: false),
      Expanded(child: BlocBuilder<SupervisorBloc, SupervisorState>(
        builder: (ctx, state) {
          if (state is SupervisorLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kLime));
          }

          final all = _extractRegistros(state);
          final filtered = all.where((r) {
            if (r.estado == 'borrador') return false;
            return _tipoFiltro == 'todos' || r.tipoRegistro == _tipoFiltro;
          }).toList();

          if (filtered.isEmpty) {
            return _emptyRegistros('Sin registros para esta fecha');
          }

          final visible = filtered.take(_historialPagina * _kPageSize).toList();
          final hayMas = visible.length < filtered.length;

          return Column(
            children: [
              // Barra de herramientas: total + CSV
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} registro(s)',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Spacer(),
                    _exportandoCsv
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kMid))
                        : IconButton(
                            tooltip: 'Exportar CSV',
                            icon: const Icon(Icons.download_rounded,
                                color: _kMid, size: 22),
                            onPressed: () => _exportarCsv(filtered),
                          ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _historialPagina = 1);
                    _cargarRegistros();
                  },
                  color: _kLime,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length + (hayMas ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == visible.length) {
                        // Botón "Cargar más"
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _historialPagina++),
                              icon: const Icon(Icons.expand_more_rounded,
                                  size: 18),
                              label: Text(
                                'Cargar más (${filtered.length - visible.length} restantes)',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kMid,
                                side: const BorderSide(color: _kMid),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildRegistroCard(visible[i], supervisorId, historial: true);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      )),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPORTAR EXCEL — Historial completo con dos hojas y colores por grupo
  // ══════════════════════════════════════════════════════════════════════════

  // ── Helpers internos ─────────────────────────────────────────────────────

  /// Devuelve el n-ésimo paro de la lista (o null).
  static ParoEquipo? _xParo(List<ParoEquipo> list, int i) =>
      i < list.length ? list[i] : null;

  /// Devuelve el n-ésimo combustible vehículo (o null).
  static CombustibleVehiculoDetalle? _xComb(
          List<CombustibleVehiculoDetalle> list, int i) =>
      i < list.length ? list[i] : null;

  /// Devuelve el n-ésimo paro vehículo (o null).
  static ParoVehiculoDetalle? _xParoVeh(
          List<ParoVehiculoDetalle> list, int i) =>
      i < list.length ? list[i] : null;

  /// Devuelve el n-ésimo bin (o null).
  static CosechaBin? _xBin(List<CosechaBin> list, int i) =>
      i < list.length ? list[i] : null;

  // ── Constantes de colores (formato ARGB sin #) ───────────────────────────

  // Banners (fondo oscuro del encabezado de grupo)
  static const _bId    = 'FFA5D6A7';
  static const _bProc  = 'FF90CAF9';
  static const _bPers  = 'FFF48FB1';
  static const _bEquip = 'FFFFE082';
  static const _bHora  = 'FFFFAB91';
  static const _bTurno = 'FFCE93D8';
  static const _bLotes = 'FFBA68C8';
  static const _bBines = 'FF80DEEA';
  static const _bParos = 'FFEF9A9A';
  static const _bVeh   = 'FF9FA8DA';
  static const _bObs   = 'FFBDBDBD';

  // Tints (fondo claro de datos)
  static const _tId    = 'FFE8F5E9';
  static const _tProc  = 'FFE3F2FD';
  static const _tPers  = 'FFFCE4EC';
  static const _tEquip = 'FFFFF8E1';
  static const _tHora  = 'FFFBE9E7';
  static const _tTurno = 'FFEDE7F6';
  static const _tLotes = 'FFF3E5F5';
  static const _tBines = 'FFE0F7FA';
  static const _tParos = 'FFFFEBEE';
  static const _tVeh   = 'FFE8EAF6';
  static const _tObs   = 'FFF5F5F5';

  static const _cBlack  = 'FF1A1A2E';
  static const _cWhite  = 'FFFFFFFF';
  static const _cAlt    = 'FFF9FAFB'; // fila alternada

  // ── Helpers de escritura ─────────────────────────────────────────────────

  /// Escribe texto en celda con estilo.
  static void _xCell(
    Sheet sheet,
    int row,
    int col,
    String text, {
    String bg = _cWhite,
    String fg = _cBlack,
    bool bold = false,
    HorizontalAlign align = HorizontalAlign.Left,
    bool wrap = false,
  }) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      TextCellValue(text),
      cellStyle: CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
        fontColorHex: ExcelColor.fromHexString(fg),
        bold: bold,
        horizontalAlign: align,
        textWrapping: wrap ? TextWrapping.WrapText : null,
      ),
    );
  }

  /// Escribe double en celda (se muestra como número en Excel).
  static void _xCellD(
    Sheet sheet,
    int row,
    int col,
    double? value, {
    String bg = _cWhite,
  }) {
    if (value == null) {
      _xCell(sheet, row, col, '', bg: bg);
      return;
    }
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      DoubleCellValue(value),
      cellStyle: CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
        horizontalAlign: HorizontalAlign.Right,
      ),
    );
  }

  /// Escribe int en celda.
  static void _xCellI(Sheet sheet, int row, int col, int? value,
      {String bg = _cWhite}) {
    if (value == null) {
      _xCell(sheet, row, col, '', bg: bg);
      return;
    }
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      IntCellValue(value),
      cellStyle: CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
        horizontalAlign: HorizontalAlign.Right,
      ),
    );
  }

  /// Banner de grupo (fila 0): merge + fondo + texto centrado negrita.
  static void _xBanner(Sheet sheet, int col, int span, String label,
      String bannerColor) {
    final start = CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0);
    final end = CellIndex.indexByColumnRow(
        columnIndex: col + span - 1, rowIndex: 0);
    if (span > 1) sheet.merge(start, end);
    _xCell(sheet, 0, col, label,
        bg: bannerColor, bold: true, align: HorizontalAlign.Center);
  }

  /// Encabezado de columna (fila 1): fondo tint + negrita centrado.
  static void _xHeader(
      Sheet sheet, int col, String label, String tintColor) {
    _xCell(sheet, 1, col, label,
        bg: tintColor, bold: true, align: HorizontalAlign.Center);
  }

  // ── Método principal ──────────────────────────────────────────────────────

  Future<void> _exportarCsv(List<RegistroDiario> registros) async {
    setState(() => _exportandoCsv = true);
    try {
      final excel = Excel.createExcel();

      // Excel crea 'Sheet1' por defecto; la renombramos a nuestra primera hoja
      excel.rename('Sheet1', 'Datos Generales');
      excel.setDefaultSheet('Datos Generales');
      final sh1 = excel['Datos Generales'];
      final sh2 = excel['Checklist'];

      // ════════════════════════════════════════════════════════════════════
      // HOJA 1 — Datos Generales
      // Grupos y columnas:
      //  0-4   IDENTIFICACIÓN   (5): Nro, Fecha, Turno, Tipo, Estado
      //  5-7   PROCESO          (3): Proceso, Código, Cultivo
      //  8-9   PERSONAL         (2): Operador, Supervisor
      // 10-12  EQUIPO           (3): Tractor/Camión, Implemento, Caja
      // 13-18  HORÓMETROS       (6): TrIni,TrFin,HrsTr, ImpIni,ImpFin,HrsImp
      // 19-23  TIEMPOS TURNO    (5): SalTall,LlegPto,SalPto,LlegTall,Refrig
      // 24-25  LOTES            (2): Códigos, Nombres
      // 26-32  BINES (COSECHA)  (7): Total, B1H,B1C, B2H,B2C, B3H,B3C
      // 33-45  PAROS TRACTOR   (13): P1Tipo,P1Mot,P1Ini,P1Fin × 3 + TotalMin
      // 46-60  VEHÍCULO        (15): KM ini/fin, HorImpl, 5 horarios, Tanc,
      //                              Comb1 ×3, Comb2 ×3
      // 61-66  PAROS VEHÍCULO   (6): PV1 Mot/Ini/Fin, PV2 Mot/Ini/Fin
      // 67     OBSERVACIONES    (1)
      // ════════════════════════════════════════════════════════════════════

      // ── Banners (fila 0) ─────────────────────────────────────────────────
      _xBanner(sh1, 0,  5, '🔢 IDENTIFICACIÓN',     _bId);
      _xBanner(sh1, 5,  3, '📋 PROCESO',             _bProc);
      _xBanner(sh1, 8,  2, '👤 PERSONAL',             _bPers);
      _xBanner(sh1, 10, 3, '🚜 EQUIPO',              _bEquip);
      _xBanner(sh1, 13, 6, '⏱ HORÓMETROS (Tractor)', _bHora);
      _xBanner(sh1, 19, 5, '🕐 TIEMPOS DE TURNO',   _bTurno);
      _xBanner(sh1, 24, 2, '🗺 LOTES',               _bLotes);
      _xBanner(sh1, 26, 7, '📦 BINES (solo Cosecha)',_bBines);
      _xBanner(sh1, 33,13, '⛔ PAROS DE EQUIPOS',   _bParos);
      _xBanner(sh1, 46,15, '🚛 VEHÍCULO',            _bVeh);
      _xBanner(sh1, 61, 6, '⛔ PAROS VEHÍCULO',      _bParos);
      _xBanner(sh1, 67, 1, '💬 OBS.',                _bObs);

      // ── Encabezados de columna (fila 1) ──────────────────────────────────
      // Identificación
      _xHeader(sh1,  0, 'Nro Registro',    _tId);
      _xHeader(sh1,  1, 'Fecha',           _tId);
      _xHeader(sh1,  2, 'Turno',           _tId);
      _xHeader(sh1,  3, 'Tipo',            _tId);
      _xHeader(sh1,  4, 'Estado',          _tId);
      // Proceso
      _xHeader(sh1,  5, 'Proceso',         _tProc);
      _xHeader(sh1,  6, 'Código',          _tProc);
      _xHeader(sh1,  7, 'Cultivo',         _tProc);
      // Personal
      _xHeader(sh1,  8, 'Operador',        _tPers);
      _xHeader(sh1,  9, 'Supervisor',      _tPers);
      // Equipo
      _xHeader(sh1, 10, 'Tractor/Camión',  _tEquip);
      _xHeader(sh1, 11, 'Implemento',      _tEquip);
      _xHeader(sh1, 12, 'Caja Cambios',    _tEquip);
      // Horómetros
      _xHeader(sh1, 13, 'Tract. Inicio',   _tHora);
      _xHeader(sh1, 14, 'Tract. Final',    _tHora);
      _xHeader(sh1, 15, 'Horas Tractor',   _tHora);
      _xHeader(sh1, 16, 'Impl. Inicio',    _tHora);
      _xHeader(sh1, 17, 'Impl. Final',     _tHora);
      _xHeader(sh1, 18, 'Horas Impl.',     _tHora);
      // Tiempos turno
      _xHeader(sh1, 19, 'Sal. Taller',     _tTurno);
      _xHeader(sh1, 20, 'Lleg. Punto',     _tTurno);
      _xHeader(sh1, 21, 'Sal. Punto',      _tTurno);
      _xHeader(sh1, 22, 'Lleg. Taller',    _tTurno);
      _xHeader(sh1, 23, 'Refrigerio',      _tTurno);
      // Lotes
      _xHeader(sh1, 24, 'Lotes (códigos)', _tLotes);
      _xHeader(sh1, 25, 'Sectores (nombres)', _tLotes);
      // Bines
      _xHeader(sh1, 26, 'Total Bines',     _tBines);
      _xHeader(sh1, 27, 'Bin 1 Horario',   _tBines);
      _xHeader(sh1, 28, 'Bin 1 Cant.',     _tBines);
      _xHeader(sh1, 29, 'Bin 2 Horario',   _tBines);
      _xHeader(sh1, 30, 'Bin 2 Cant.',     _tBines);
      _xHeader(sh1, 31, 'Bin 3 Horario',   _tBines);
      _xHeader(sh1, 32, 'Bin 3 Cant.',     _tBines);
      // Paros tractor
      _xHeader(sh1, 33, 'Paro 1 Tipo',     _tParos);
      _xHeader(sh1, 34, 'Paro 1 Motivo',   _tParos);
      _xHeader(sh1, 35, 'Paro 1 Inicio',   _tParos);
      _xHeader(sh1, 36, 'Paro 1 Fin',      _tParos);
      _xHeader(sh1, 37, 'Paro 2 Tipo',     _tParos);
      _xHeader(sh1, 38, 'Paro 2 Motivo',   _tParos);
      _xHeader(sh1, 39, 'Paro 2 Inicio',   _tParos);
      _xHeader(sh1, 40, 'Paro 2 Fin',      _tParos);
      _xHeader(sh1, 41, 'Paro 3 Tipo',     _tParos);
      _xHeader(sh1, 42, 'Paro 3 Motivo',   _tParos);
      _xHeader(sh1, 43, 'Paro 3 Inicio',   _tParos);
      _xHeader(sh1, 44, 'Paro 3 Fin',      _tParos);
      _xHeader(sh1, 45, 'Total Min Paro',  _tParos);
      // Vehículo
      _xHeader(sh1, 46, 'KM Camión Ini.',   _tVeh);
      _xHeader(sh1, 47, 'KM Camión Fin.',   _tVeh);
      _xHeader(sh1, 48, 'Horóm. Impl. Veh.',_tVeh);
      _xHeader(sh1, 49, 'Sal. Base',        _tVeh);
      _xHeader(sh1, 50, 'Lleg. Zona',       _tVeh);
      _xHeader(sh1, 51, 'Ret. Base',        _tVeh);
      _xHeader(sh1, 52, 'Lleg. Taller Veh.',_tVeh);
      _xHeader(sh1, 53, 'Refrig. Veh.',     _tVeh);
      _xHeader(sh1, 54, 'Tancadas',         _tVeh);
      _xHeader(sh1, 55, 'Comb1 Glns',       _tVeh);
      _xHeader(sh1, 56, 'Comb1 Inicio',     _tVeh);
      _xHeader(sh1, 57, 'Comb1 Fin',        _tVeh);
      _xHeader(sh1, 58, 'Comb2 Glns',       _tVeh);
      _xHeader(sh1, 59, 'Comb2 Inicio',     _tVeh);
      _xHeader(sh1, 60, 'Comb2 Fin',        _tVeh);
      // Paros vehículo
      _xHeader(sh1, 61, 'ParoVeh1 Motivo',  _tParos);
      _xHeader(sh1, 62, 'ParoVeh1 Inicio',  _tParos);
      _xHeader(sh1, 63, 'ParoVeh1 Fin',     _tParos);
      _xHeader(sh1, 64, 'ParoVeh2 Motivo',  _tParos);
      _xHeader(sh1, 65, 'ParoVeh2 Inicio',  _tParos);
      _xHeader(sh1, 66, 'ParoVeh2 Fin',     _tParos);
      // Observaciones
      _xHeader(sh1, 67, 'Observaciones',    _tObs);

      // ── Ancho de columnas ─────────────────────────────────────────────────
      sh1.setColumnWidth(0, 20);   // Nro Registro
      sh1.setColumnWidth(1, 12);   // Fecha
      sh1.setColumnWidth(2, 9);    // Turno
      sh1.setColumnWidth(3, 10);   // Tipo
      sh1.setColumnWidth(4, 13);   // Estado
      sh1.setColumnWidth(5, 20);   // Proceso
      sh1.setColumnWidth(6, 14);   // Código
      sh1.setColumnWidth(7, 16);   // Cultivo
      sh1.setColumnWidth(8, 22);   // Operador
      sh1.setColumnWidth(9, 22);   // Supervisor
      sh1.setColumnWidth(10, 13);  // Tractor
      sh1.setColumnWidth(11, 18);  // Implemento
      sh1.setColumnWidth(12, 16);  // Caja Cambios
      for (int c = 13; c <= 18; c++) {
        sh1.setColumnWidth(c, 11); // Horóm.
      }
      for (int c = 19; c <= 23; c++) {
        sh1.setColumnWidth(c, 11); // Tiempos
      }
      sh1.setColumnWidth(24, 18);  // Lotes códigos
      sh1.setColumnWidth(25, 30);  // Sectores nombres
      sh1.setColumnWidth(26, 10);  // Total Bines
      for (int c = 27; c <= 32; c++) {
        sh1.setColumnWidth(c, 14); // Bines
      }
      for (int c = 33; c <= 44; c++) {
        sh1.setColumnWidth(c, 18); // Paros
      }
      sh1.setColumnWidth(45, 13);  // Total Min
      for (int c = 46; c <= 60; c++) {
        sh1.setColumnWidth(c, 14); // Veh.
      }
      for (int c = 61; c <= 66; c++) {
        sh1.setColumnWidth(c, 18); // PVeh
      }
      sh1.setColumnWidth(67, 30);  // Observaciones

      // Altura de filas de encabezado
      sh1.setRowHeight(0, 22);
      sh1.setRowHeight(1, 20);

      // ── Hoja 2 — encabezados ─────────────────────────────────────────────
      _xBanner(sh2, 0, 4, '🔢 REFERENCIA REGISTRO', _bId);
      _xBanner(sh2, 4, 4, '✅ CHECKLIST DETALLE',    _bObs);
      _xHeader(sh2, 0, 'Nro Registro',  _tId);
      _xHeader(sh2, 1, 'Fecha',         _tId);
      _xHeader(sh2, 2, 'Turno',         _tId);
      _xHeader(sh2, 3, 'Operador',      _tId);
      _xHeader(sh2, 4, 'Categoría',     _tObs);
      _xHeader(sh2, 5, 'Ítem',          _tObs);
      _xHeader(sh2, 6, 'Resultado',     _tObs);
      _xHeader(sh2, 7, 'Observación',   _tObs);
      sh2.setColumnWidth(0, 20);
      sh2.setColumnWidth(1, 12);
      sh2.setColumnWidth(2, 9);
      sh2.setColumnWidth(3, 22);
      sh2.setColumnWidth(4, 22);
      sh2.setColumnWidth(5, 36);
      sh2.setColumnWidth(6, 12);
      sh2.setColumnWidth(7, 30);
      sh2.setRowHeight(0, 22);
      sh2.setRowHeight(1, 20);

      // ── Datos ─────────────────────────────────────────────────────────────
      final fmt = DateFormat('dd/MM/yyyy');
      int rowData = 2;   // fila de datos en hoja1 (0=banner, 1=headers)
      int rowCl   = 2;   // fila de datos en hoja2

      for (final r in registros) {
        final bg = (rowData % 2 == 0) ? _cWhite : _cAlt;

        // ── IDENTIFICACIÓN ──────────────────────────────────────────────
        _xCell(sh1, rowData, 0, r.numeroRegistro,         bg: bg, bold: true);
        _xCell(sh1, rowData, 1, fmt.format(r.fecha),      bg: bg);
        _xCell(sh1, rowData, 2, r.turno,                  bg: bg);
        _xCell(sh1, rowData, 3,
            r.tipoRegistro == 'vehiculo' ? 'Vehículo' : 'Tractor', bg: bg);
        _xCell(sh1, rowData, 4, r.estado,                 bg: bg);

        // ── PROCESO ─────────────────────────────────────────────────────
        _xCell(sh1, rowData, 5, r.procesoNombre,          bg: bg);
        _xCell(sh1, rowData, 6, r.procesoCodigo,          bg: bg);
        _xCell(sh1, rowData, 7, r.cultivoNombreEspecie,   bg: bg);

        // ── PERSONAL ────────────────────────────────────────────────────
        _xCell(sh1, rowData, 8, r.operadorNombre,         bg: bg);
        _xCell(sh1, rowData, 9, r.supervisorNombre ?? '', bg: bg);

        // ── EQUIPO ──────────────────────────────────────────────────────
        _xCell(sh1, rowData, 10, r.tractorCodigo,         bg: bg);
        _xCell(sh1, rowData, 11, r.implementoCodigo ?? '', bg: bg);
        _xCell(sh1, rowData, 12, r.cajaCambiosNombre ?? '', bg: bg);

        // ── HORÓMETROS ──────────────────────────────────────────────────
        _xCellD(sh1, rowData, 13, r.horometro?.tractorInicio,    bg: bg);
        _xCellD(sh1, rowData, 14, r.horometro?.tractorFinal,     bg: bg);
        _xCellD(sh1, rowData, 15, r.horometro?.horasTractor,     bg: bg);
        _xCellD(sh1, rowData, 16, r.horometro?.implementoInicio, bg: bg);
        _xCellD(sh1, rowData, 17, r.horometro?.implementoFinal,  bg: bg);
        _xCellD(sh1, rowData, 18, r.horometro?.horasImplemento,  bg: bg);

        // ── TIEMPOS TURNO ────────────────────────────────────────────────
        final tt = r.tiempoTurno;
        _xCell(sh1, rowData, 19, tt?.horaSalidaTaller  ?? '', bg: bg);
        _xCell(sh1, rowData, 20, tt?.horaLlegadaPunto  ?? '', bg: bg);
        _xCell(sh1, rowData, 21, tt?.horaSalidaPunto   ?? '', bg: bg);
        _xCell(sh1, rowData, 22, tt?.horaLlegadaTaller ?? '', bg: bg);
        _xCell(sh1, rowData, 23, tt?.horaRefrigerio    ?? '', bg: bg);

        // ── LOTES ────────────────────────────────────────────────────────
        _xCell(sh1, rowData, 24,
            r.sectores.map((s) => s.loteCodigo)
                .where((l) => l.isNotEmpty).toSet().join(', '),
            bg: bg);
        _xCell(sh1, rowData, 25,
            r.sectores.map((s) => s.loteNombre)
                .where((n) => n.isNotEmpty).toSet().join(', '),
            bg: bg);

        // ── BINES ────────────────────────────────────────────────────────
        final binesSorted = [...r.bines]
          ..sort((a, b) => a.franjaHoraria.compareTo(b.franjaHoraria));
        _xCellI(sh1, rowData, 26, r.bines.isEmpty ? null : r.totalBines, bg: bg);
        for (int bi = 0; bi < 3; bi++) {
          final bin = _xBin(binesSorted, bi);
          _xCell(sh1, rowData, 27 + bi * 2,     bin?.franjaHoraria ?? '', bg: bg);
          _xCellI(sh1, rowData, 27 + bi * 2 + 1, bin?.cantidad, bg: bg);
        }

        // ── PAROS TRACTOR ────────────────────────────────────────────────
        for (int pi = 0; pi < 3; pi++) {
          final p = _xParo(r.paros, pi);
          _xCell(sh1, rowData, 33 + pi * 4,     p?.tipoParoNombre ?? '', bg: bg);
          _xCell(sh1, rowData, 33 + pi * 4 + 1, p?.motivo         ?? '', bg: bg);
          _xCell(sh1, rowData, 33 + pi * 4 + 2, p?.horaInicio     ?? '', bg: bg);
          _xCell(sh1, rowData, 33 + pi * 4 + 3, p?.horaFinal      ?? '', bg: bg);
        }
        _xCellI(sh1, rowData, 45,
            r.totalMinParos > 0 ? r.totalMinParos : null, bg: bg);

        // ── VEHÍCULO ─────────────────────────────────────────────────────
        final vd = r.vehiculoDetalle;
        _xCellD(sh1, rowData, 46, vd?.kmCamionInicio,    bg: bg);
        _xCellD(sh1, rowData, 47, vd?.kmCamionFinal,     bg: bg);
        _xCellD(sh1, rowData, 48, vd?.kmImplementoInicio,bg: bg);
        _xCell(sh1, rowData, 49, vd?.horaSalidaBase    ?? '', bg: bg);
        _xCell(sh1, rowData, 50, vd?.horaLlegadaZona   ?? '', bg: bg);
        _xCell(sh1, rowData, 51, vd?.horaRetornoBase   ?? '', bg: bg);
        _xCell(sh1, rowData, 52, vd?.horaLlegadaTaller ?? '', bg: bg);
        _xCell(sh1, rowData, 53, vd?.horaRefrigerio    ?? '', bg: bg);
        _xCellI(sh1, rowData, 54, vd?.cantidadTancadas,  bg: bg);
        for (int ci = 0; ci < 2; ci++) {
          final c = _xComb(r.combustiblesVehiculo, ci);
          _xCellD(sh1, rowData, 55 + ci * 3,     c?.glns,        bg: bg);
          _xCell(sh1, rowData, 55 + ci * 3 + 1,  c?.horaInicio ?? '', bg: bg);
          _xCell(sh1, rowData, 55 + ci * 3 + 2,  c?.horaFinal  ?? '', bg: bg);
        }

        // ── PAROS VEHÍCULO ───────────────────────────────────────────────
        for (int pi = 0; pi < 2; pi++) {
          final pv = _xParoVeh(r.parosVehiculo, pi);
          _xCell(sh1, rowData, 61 + pi * 3,     pv?.motivo    ?? '', bg: bg);
          _xCell(sh1, rowData, 61 + pi * 3 + 1, pv?.horaInicio ?? '', bg: bg);
          _xCell(sh1, rowData, 61 + pi * 3 + 2, pv?.horaFinal  ?? '', bg: bg);
        }

        // ── OBSERVACIONES ────────────────────────────────────────────────
        _xCell(sh1, rowData, 67, r.observacionesMaq ?? '', bg: bg, wrap: true);

        rowData++;

        // ── HOJA 2 — Checklist (una fila por ítem) ───────────────────────
        for (final item in r.checklist) {
          final bgCl = (rowCl % 2 == 0) ? _cWhite : _cAlt;
          _xCell(sh2, rowCl, 0, r.numeroRegistro,   bg: bgCl, bold: true);
          _xCell(sh2, rowCl, 1, fmt.format(r.fecha), bg: bgCl);
          _xCell(sh2, rowCl, 2, r.turno,             bg: bgCl);
          _xCell(sh2, rowCl, 3, r.operadorNombre,    bg: bgCl);
          _xCell(sh2, rowCl, 4, item.categoriaNombre, bg: bgCl);
          _xCell(sh2, rowCl, 5, item.itemNombre,     bg: bgCl);
          // Resultado con color
          final res = item.resultado.toLowerCase();
          final resBg = res == 'bien'
              ? 'FFD1FADF'
              : res == 'mal'
                  ? 'FFFEE2E2'
                  : 'FFF3F4F6';
          final resFg = res == 'bien'
              ? 'FF065F46'
              : res == 'mal'
                  ? 'FF991B1B'
                  : 'FF374151';
          _xCell(sh2, rowCl, 6, item.resultado.toUpperCase(),
              bg: resBg, fg: resFg, bold: true,
              align: HorizontalAlign.Center);
          _xCell(sh2, rowCl, 7, item.observacion ?? '', bg: bgCl);
          rowCl++;
        }
      }

      // ── Guardar y compartir ───────────────────────────────────────────────
      final bytes = excel.save();
      if (bytes == null) throw Exception('No se pudo generar el archivo Excel');

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/historial_$timestamp.xlsx');
      await file.writeAsBytes(bytes);

      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [share_plus.XFile(file.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject:
              'Historial de registros — ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportandoCsv = false);
    }
  }

  // ── Filtros header ────────────────────────────────────────────────────────

  Widget _filtrosHeader({required bool mostrarEstado}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: fecha + filtros de turno
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Selector de fecha
                GestureDetector(
                  onTap: _seleccionarFecha,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 7),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_fechaFiltro),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.expand_more_rounded,
                              size: 14, color: Colors.white54),
                        ]),
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 22, color: _kBorder),
                const SizedBox(width: 10),
                _turnoFiltroChip('Todos', null, Icons.view_list_rounded),
                const SizedBox(width: 6),
                _turnoFiltroChip('Día', 'dia', Icons.wb_sunny_rounded),
                const SizedBox(width: 6),
                _turnoFiltroChip('Noche', 'noche', Icons.nightlight_round),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: tipo + estado
          SizedBox(
            height: 34,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text(
                  'Tipo:',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                _tipoChip('Todos', 'todos', Icons.grid_view_rounded),
                const SizedBox(width: 6),
                _tipoChip('Tractor', 'tractor', Icons.agriculture_rounded),
                const SizedBox(width: 6),
                _tipoChip('Camión', 'vehiculo', Icons.directions_car_rounded),
                if (mostrarEstado) ...[
                  const SizedBox(width: 12),
                  Container(width: 1, height: 20, color: _kBorder),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _estadoFiltro =
                        _estadoFiltro == 'completado' ? 'todos' : 'completado'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _estadoFiltro == 'completado'
                            ? _kStatusPending.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _estadoFiltro == 'completado'
                              ? _kStatusPending.withValues(alpha: 0.4)
                              : _kBorder,
                        ),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_alt_rounded,
                              size: 13,
                              color: _estadoFiltro == 'completado'
                                  ? _kStatusPending
                                  : _kTextSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _estadoFiltro == 'completado'
                                  ? 'Pendientes'
                                  : 'Todos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _estadoFiltro == 'completado'
                                    ? _kStatusPending
                                    : _kTextSecondary,
                              ),
                            ),
                          ]),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnoFiltroChip(String label, String? value, IconData icon) {
    final sel = _turnoFiltro == value;
    return GestureDetector(
      onTap: () {
        setState(() => _turnoFiltro = value);
        _cargarRegistros();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: sel ? _kDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? _kDark : _kBorder),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: sel ? Colors.white : _kTextSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : _kTextSecondary,
                ),
              ),
            ]),
      ),
    );
  }

  Widget _tipoChip(String label, String value, IconData icon) {
    final sel = _tipoFiltro == value;
    final color = value == 'vehiculo'
        ? const Color(0xFF2563EB)
        : value == 'tractor'
            ? _kStatusActive
            : _kTextSecondary;
    return GestureDetector(
      onTap: () => setState(() {
        _tipoFiltro = value;
        _historialPagina = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? color.withValues(alpha: 0.35) : _kBorder,
          ),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: sel ? color : _kTextSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? color : _kTextSecondary,
                ),
              ),
            ]),
      ),
    );
  }

  // ── Registro Card (Aprobaciones + Historial) ──────────────────────────────

  Widget _buildRegistroCard(RegistroDiario r, int supervisorId,
      {bool historial = false}) {
    final esVeh = r.tipoRegistro == 'vehiculo';
    final esPend = r.estado == 'completado';
    final esAprov = r.estado == 'aprobado';
    final esRech = r.estado == 'rechazado';

    final statusColor = esPend
        ? _kStatusPending
        : esAprov
            ? _kStatusActive
            : esRech
                ? _kStatusAlert
                : _kStatusClosed;

    final statusLabel = esPend
        ? 'PENDIENTE'
        : esAprov
            ? 'APROBADO'
            : esRech
                ? 'RECHAZADO'
                : 'BORRADOR';

    return _borderedCard(
      borderColor: statusColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ícono de tipo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    esVeh ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                esVeh
                    ? Icons.directions_car_rounded
                    : Icons.agriculture_rounded,
                size: 20,
                color: esVeh ? const Color(0xFF2563EB) : _kStatusActive,
              ),
            ),
            const SizedBox(width: 12),
            // Número + operador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.numeroRegistro,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.operadorNombre,
                    style:
                        const TextStyle(fontSize: 12, color: _kTextSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ]),
        ),

        // ── Metadata: fecha + equipo ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                Icons.calendar_today_outlined,
                '${DateFormat('dd MMM yyyy', 'es').format(r.fecha)}  ·  Turno ${r.turno.toUpperCase()}',
              ),
              const SizedBox(height: 4),
              _infoRow(
                esVeh
                    ? Icons.directions_car_outlined
                    : Icons.precision_manufacturing_outlined,
                '${r.tractorCodigo}  ·  ${r.procesoNombre}',
              ),
              const SizedBox(height: 10),
              // Datos según tipo
              if (esVeh) _vehiculoInfoSection(r) else _tractorInfoSection(r),
              // Motivo rechazo
              if (esRech && r.motivoRechazo != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kStatusAlert.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: _kStatusAlert.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 13, color: _kStatusAlert),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Motivo: ${r.motivoRechazo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kStatusAlert,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Action bar ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: _kBg,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          child: Row(children: [
            _actionBtn(Icons.visibility_outlined, 'Ver', _kMid,
                () => context.push('/registro/${r.id}/ver', extra: r),
                outlined: true),
            const SizedBox(width: 4),
            _actionBtn(Icons.picture_as_pdf_outlined, 'PDF',
                const Color(0xFF4F46E5), () => _mostrarPdfPreview(r),
                outlined: true),
            const Spacer(),
            if (historial) ...[
              _actionBtn(Icons.edit_outlined, 'Editar', _kMid, () async {
                await context.push('/registro/${r.id}/admin-editar', extra: r);
                if (mounted) _cargarRegistros();
              }),
            ] else if (esPend) ...[
              _actionBtn(Icons.close_rounded, 'Rechazar', _kStatusAlert,
                  () => _rechazarRegistro(r, supervisorId),
                  outlined: true),
              const SizedBox(width: 3),
              _actionBtn(Icons.check_rounded, 'Aprobar', _kStatusActive,
                  () => _aprobarRegistro(r, supervisorId)),
            ],
          ]),
        ),
      ]),
    );
  }

  // ── Sección de datos TRACTOR ──────────────────────────────────────────────

  Widget _tractorInfoSection(RegistroDiario r) {
    final hor = r.horometro;
    final tt = r.tiempoTurno;
    final horasTractor = hor?.horasTractor;
    final checklistMal = r.checklist.where((c) => c.esMal).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hor != null || tt != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kStatusActive.withValues(alpha: 0.15)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.agriculture_rounded, size: 13, color: _kStatusActive),
              SizedBox(width: 6),
              Text(
                'Datos del tractor',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kStatusActive,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            if (hor != null)
              Row(children: [
                _hmCell(
                    'H. Inicio', hor.tractorInicio?.toStringAsFixed(1) ?? '-'),
                _hmCell(
                    'H. Final', hor.tractorFinal?.toStringAsFixed(1) ?? '-'),
                if (horasTractor != null)
                  _hmCell('Horas trabajadas',
                      '${horasTractor.toStringAsFixed(1)} h',
                      highlight: true),
              ]),
            if (tt != null) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 5, children: [
                if (tt.horaSalidaTaller != null)
                  _horaChipGreen('Salida taller', tt.horaSalidaTaller!),
                if (tt.horaLlegadaPunto != null)
                  _horaChipGreen('Llegada punto', tt.horaLlegadaPunto!),
                if (tt.horaSalidaPunto != null)
                  _horaChipGreen('Salida punto', tt.horaSalidaPunto!),
                if (tt.horaLlegadaTaller != null)
                  _horaChipGreen('Llegada taller', tt.horaLlegadaTaller!),
                if (tt.horaRefrigerio != null)
                  _horaChipGreen('Refrigerio', tt.horaRefrigerio!),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 8),
      ],
      Wrap(spacing: 6, runSpacing: 6, children: [
        if (r.bines.isNotEmpty)
          _pill(Icons.inventory_2_rounded, '${r.totalBines} bines'),
        if (r.paros.isNotEmpty)
          _pill(Icons.pause_circle_rounded, '${r.paros.length} paros'),
        if (r.sectores.isNotEmpty)
          _pill(Icons.map_rounded, '${r.sectores.length} sectores'),
        if (r.checklist.isNotEmpty && checklistMal > 0)
          _pill(Icons.report_problem_rounded, '$checklistMal obs.',
              isAlert: true),
        if (r.checklist.isNotEmpty && checklistMal == 0)
          _pill(Icons.fact_check_rounded, 'Checklist ok'),
      ]),
    ]);
  }

  Widget _hmCell(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: _kTextMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? _kStatusActive : _kTextPrimary,
          ),
        ),
      ]),
    );
  }

  Widget _horaChipGreen(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kStatusActive.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: _kTextMuted)),
        Text(value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kStatusActive,
            )),
      ]),
    );
  }

  // ── Sección de datos VEHÍCULO ─────────────────────────────────────────────

  Widget _vehiculoInfoSection(RegistroDiario r) {
    final vd = r.vehiculoDetalle;
    final kmTotal = (vd?.kmCamionFinal != null && vd?.kmCamionInicio != null)
        ? (vd!.kmCamionFinal! - vd.kmCamionInicio!).abs()
        : null;
    final totalGlns =
        r.combustiblesVehiculo.fold<double>(0, (s, c) => s + (c.glns ?? 0));
    const kBlue = Color(0xFF2563EB);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (vd != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBlue.withValues(alpha: 0.15)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.directions_car_rounded, size: 13, color: kBlue),
              SizedBox(width: 6),
              Text(
                'Datos del camión',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kBlue,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              if (vd.kmCamionInicio != null)
                _kmCell('KM Inicio', vd.kmCamionInicio!.toStringAsFixed(0)),
              if (vd.kmCamionFinal != null)
                _kmCell('KM Final', vd.kmCamionFinal!.toStringAsFixed(0)),
              if (kmTotal != null)
                _kmCell('KM Recorridos', kmTotal.toStringAsFixed(0),
                    highlight: true),
              if (vd.cantidadTancadas != null)
                _kmCell('Tancadas', vd.cantidadTancadas!.toString()),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 5, children: [
              if (vd.horaSalidaBase != null)
                _horaChip('Salida base', vd.horaSalidaBase!),
              if (vd.horaLlegadaZona != null)
                _horaChip('Llegada zona', vd.horaLlegadaZona!),
              if (vd.horaRetornoBase != null)
                _horaChip('Retorno', vd.horaRetornoBase!),
              if (vd.horaRefrigerio != null)
                _horaChip('Refrigerio', vd.horaRefrigerio!),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
      ],
      Wrap(spacing: 6, runSpacing: 6, children: [
        if (totalGlns > 0)
          _pill(Icons.local_gas_station_rounded,
              '${totalGlns.toStringAsFixed(1)} gln'),
        if (r.parosVehiculo.isNotEmpty)
          _pill(Icons.pause_circle_rounded, '${r.parosVehiculo.length} paros',
              isAlert: r.parosVehiculo.isNotEmpty),
        if (r.combustiblesVehiculo.length > 1)
          _pill(
              Icons.repeat_rounded, '${r.combustiblesVehiculo.length} cargas'),
      ]),
    ]);
  }

  Widget _kmCell(String label, String value, {bool highlight = false}) {
    const kBlue = Color(0xFF2563EB);
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: _kTextMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? kBlue : _kTextPrimary,
          ),
        ),
      ]),
    );
  }

  Widget _horaChip(String label, String value) {
    const kBlue = Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBlue.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: _kTextMuted)),
        Text(value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kBlue,
            )),
      ]),
    );
  }

  // ── Shared widget helpers ─────────────────────────────────────────────────

  Widget _borderedCard({required Color borderColor, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _pill(IconData icon, String text, {bool isAlert = false}) {
    final color = isAlert ? _kStatusAlert : _kTextSecondary;
    final bg = isAlert
        ? _kStatusAlert.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: isAlert
            ? Border.all(color: _kStatusAlert.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: isAlert ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 13, color: _kTextMuted),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: _kTextSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap,
      {bool outlined = false}) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    const ts = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.45)),
          shape: shape,
          padding: pad,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: ts,
          minimumSize: Size.zero,
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: shape,
        padding: pad,
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: ts,
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _errorState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _kStatusAlert.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 28, color: _kStatusAlert),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin conexión con el servidor',
            style: TextStyle(
              color: _kTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg,
            style: const TextStyle(color: _kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyRegistros(String msg) {
    return RefreshIndicator(
      onRefresh: () async => _cargarRegistros(),
      color: _kLime,
      child: ListView(children: [
        SizedBox(
          height: 350,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _kStatusActive.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      size: 30, color: _kStatusActive),
                ),
                const SizedBox(height: 16),
                Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd \'de\' MMMM yyyy', 'es').format(_fechaFiltro),
                  style: const TextStyle(fontSize: 12, color: _kTextMuted),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dialogTitle(IconData icon, Color color, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
        ),
      ),
    ]);
  }

  // ── Logic helpers ─────────────────────────────────────────────────────────

  List<RegistroDiario> _extractRegistros(SupervisorState state) {
    if (state is SupervisorRegistrosLoaded) return state.registros;
    if (state is SupervisorOperacionExitosa) return state.registros;
    return [];
  }

  double _turnoProgress(String turno) {
    final now = DateTime.now();
    final s = turno == 'dia' ? 6 : 14;
    final e = turno == 'dia' ? 14 : 22;
    final start = DateTime(now.year, now.month, now.day, s);
    final end = DateTime(now.year, now.month, now.day, e);
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    return now.difference(start).inMinutes / end.difference(start).inMinutes;
  }

  RegistroDiario _registroFromReporteRow(Map<String, dynamic> row) {
    final id = row['registro_id']?.toString() ?? '';
    final horData = _parseObject(row['horometro_json']);
    final tiemData = _parseObject(row['tiempos_turno_json']);
    final vehData = _parseObject(row['vehiculo_json']);

    return RegistroDiario(
      id: id,
      numeroRegistro: row['numero_registro']?.toString() ?? '',
      fecha: _parseDate(row['fecha']?.toString()),
      turno: row['turno']?.toString() ?? _turnoSeleccionado,
      procesoId: _toInt(row['proceso_id']) ?? 0,
      procesoNombre: row['proceso_nombre']?.toString() ?? '',
      procesoCodigo: row['proceso_codigo']?.toString() ?? '',
      cultivoIdErp: _toInt(row['cultivo_id_erp']) ?? 0,
      cultivoNombreEspecie: row['nombre_cultivo']?.toString() ?? '',
      cultivoCodigoEspecie: '',
      operadorIdErp: _toInt(row['operador_id_erp']) ?? 0,
      operadorCodigo: '',
      operadorNombre: row['operador_nombre']?.toString() ??
          row['nombre_operador']?.toString() ??
          '',
      supervisorIdErp: _toInt(row['supervisor_id_erp']),
      supervisorCodigo: null,
      supervisorNombre: row['nombre_supervisor']?.toString(),
      tractorIdErp: _toInt(row['tractor_id_erp']) ?? 0,
      tractorCodigo: row['tractor_codigo']?.toString() ??
          row['codigo_tractor']?.toString() ??
          '',
      tractorDescripcion: '',
      implementoIdErp: _toInt(row['implemento_id_erp']),
      implementoCodigo: row['implemento_codigo']?.toString() ??
          row['codigo_implemento']?.toString(),
      implementoDescripcion: row['implemento_codigo']?.toString() ??
          row['codigo_implemento']?.toString(),
      cajaCambiosNombre: row['caja_cambios_nombre']?.toString(),
      estado: row['estado']?.toString() ?? 'borrador',
      tipoRegistro: row['tipo_registro']?.toString() ?? 'tractor',
      observacionesMaq: row['observaciones_maq']?.toString(),
      motivoRechazo: row['motivo_rechazo']?.toString(),
      dispositivoId: row['dispositivo_id']?.toString(),
      sincronizado: _toBool(row['sincronizado_erp'] ?? row['sincronizado']),
      sincronizadoAt: _parseDateTime(row['sincronizado_at']?.toString()),
      createdAt:
          _parseDateTime(row['created_at']?.toString()) ?? DateTime.now(),
      horometro: horData == null
          ? null
          : Horometro(
              id: id,
              registroId: id,
              tractorInicio: _toDouble(horData['tractor_inicio']),
              tractorFinal: _toDouble(horData['tractor_final']),
              implementoInicio: _toDouble(horData['implemento_inicio']),
              implementoFinal: _toDouble(horData['implemento_final']),
            ),
      tiempoTurno: tiemData == null
          ? null
          : TiempoTurno(
              id: id,
              registroId: id,
              horaSalidaTaller: tiemData['hora_salida_taller']?.toString(),
              horaLlegadaPunto: tiemData['hora_llegada_punto']?.toString(),
              horaSalidaPunto: tiemData['hora_salida_punto']?.toString(),
              horaLlegadaTaller: tiemData['hora_llegada_taller']?.toString(),
              horaRefrigerio: tiemData['hora_refrigerio']?.toString(),
            ),
      bines: _parseList(row['bines_json'])
          .map((b) => CosechaBin(
                id: '${id}_${b['franja_horaria']}',
                registroId: id,
                franjaHoraria: b['franja_horaria']?.toString() ?? '',
                turno: b['turno_franja']?.toString() ?? '',
                cantidad: _toInt(b['cantidad']) ?? 0,
              ))
          .toList(),
      paros: _parseList(row['paros_json'])
          .map((p) => ParoEquipo(
                id: p['paro_id']?.toString() ?? '',
                registroId: id,
                tipoParoId: _toInt(p['tipo_paro_id']) ?? 0,
                tipoParoCodigo: p['tipo_paro_codigo']?.toString() ?? '',
                tipoParoNombre: p['tipo_paro_nombre']?.toString() ?? '',
                motivo: p['motivo']?.toString(),
                equipo: p['equipo']?.toString(),
                horaInicio: p['hora_inicio']?.toString() ?? '00:00',
                horaFinal: p['hora_final']?.toString(),
                galones: _toDouble(p['galones']),
                duracionMin: _toInt(p['duracion_min']),
              ))
          .toList(),
      checklist: () {
        final result = <ChecklistResultado>[];
        for (final c in _parseList(row['checklist_json'])) {
          final itemId = c['item_id'];
          if (itemId == null) continue;
          result.add(ChecklistResultado(
            id: '${id}_$itemId',
            registroId: id,
            itemId: _toInt(itemId) ?? 0,
            itemNombre: c['item_nombre']?.toString() ?? '',
            categoriaNombre: c['categoria_nombre']?.toString() ?? '',
            resultado: c['resultado']?.toString() ?? 'na',
            observacion: c['observacion']?.toString(),
          ));
        }
        return result;
      }(),
      sectores: () {
        final result = <RegistroSector>[];
        for (final s in _parseList(row['sectores_json'])) {
          final loteId = s['lote_id_erp'];
          if (loteId == null) continue;
          result.add(RegistroSector(
            id: '${id}_$loteId',
            registroId: id,
            loteIdErp: _toInt(loteId) ?? 0,
            loteCodigo: s['lote_codigo']?.toString() ?? '',
            loteNombre: s['lote_nombre']?.toString() ?? '',
            fincaNombre: s['finca_id']?.toString() ?? '',
            areaTrabajada: _toDouble(s['area_trabajada_ha']),
          ));
        }
        return result;
      }(),
      vehiculoDetalle: vehData == null
          ? null
          : VehiculoDetalle(
              kmCamionInicio: _toDouble(vehData['km_camion_inicio']),
              kmCamionFinal: _toDouble(vehData['km_camion_final']),
              kmImplementoInicio: _toDouble(vehData['km_implemento_inicio']),
              kmImplementoFinal: _toDouble(vehData['km_implemento_final']),
              horaSalidaBase: vehData['hora_salida_base_td']?.toString(),
              horaLlegadaZona: vehData['hora_llegada_zona']?.toString(),
              horaRetornoBase: vehData['hora_retorno_base']?.toString(),
              horaLlegadaTaller: vehData['hora_llegada_taller']?.toString(),
              horaRefrigerio: vehData['hora_refrigerio']?.toString(),
              cantidadTancadas: _toInt(vehData['cantidad_tancadas']),
            ),
      combustiblesVehiculo: _parseList(row['combustible_vehiculo_json'])
          .map(
            (c) => CombustibleVehiculoDetalle(
              glns: _toDouble(c['glns']),
              horaInicio: c['hora_inicio']?.toString(),
              horaFinal: c['hora_final']?.toString(),
            ),
          )
          .toList(),
      parosVehiculo: _parseList(row['paros_vehiculo_json'])
          .map(
            (p) => ParoVehiculoDetalle(
              motivo: p['motivo']?.toString(),
              horaInicio: p['hora_inicio']?.toString(),
              horaFinal: p['hora_final']?.toString(),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic>? _parseObject(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        return d is Map<String, dynamic> ? d : null;
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _parseList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is List) {
          return d
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  DateTime _parseDate(String? s) {
    if (s == null || s.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(s);
    if (parsed == null) {
      developer.log(
        '_parseDate: no se pudo parsear la fecha "$s", usando DateTime.now()',
        name: 'HomeSupervisorPage',
      );
    }
    return parsed ?? DateTime.now();
  }
  DateTime? _parseDateTime(String? s) =>
      s == null || s.isEmpty ? null : DateTime.tryParse(s);

  String _formatHora(String? iso) {
    if (iso == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso.length >= 5 ? iso.substring(0, 5) : iso;
    }
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Color iconColor;
  final String mensaje;
  final String labelOk;
  final Color colorOk;

  const _ConfirmDialog({
    required this.titulo,
    required this.icon,
    required this.iconColor,
    required this.mensaje,
    required this.labelOk,
    required this.colorOk,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono + título
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Mensaje
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 14,
                color: _kTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Botones
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kTextSecondary,
                    side: const BorderSide(color: _kBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorOk,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    labelOk,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── PDF Preview Bottom Sheet ─────────────────────────────────────────────────

class _PdfPreviewSheet extends StatelessWidget {
  final RegistroDiario registro;
  final Future<void> Function(RegistroDiario) onShare;

  const _PdfPreviewSheet({required this.registro, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final esVeh = r.tipoRegistro == 'vehiculo';
    final vd = r.vehiculoDetalle;

    final kmTotal = (vd?.kmCamionFinal != null && vd?.kmCamionInicio != null)
        ? (vd!.kmCamionFinal! - vd.kmCamionInicio!).abs()
        : null;
    final totalGlns =
        r.combustiblesVehiculo.fold<double>(0, (s, c) => s + (c.glns ?? 0));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Vista previa de PDF',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(r.numeroRegistro,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ])),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              ),
            ]),
          ),
          const Divider(height: 20),
          // Content — Expanded requiere parent con altura acotada (ConstrainedBox lo provee)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            esVeh ? Colors.blue.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: esVeh
                                ? Colors.blue.shade200
                                : Colors.green.shade200),
                      ),
                      child: Row(children: [
                        Icon(
                            esVeh
                                ? Icons.directions_car_rounded
                                : Icons.agriculture_rounded,
                            size: 14,
                            color: esVeh ? Colors.blue.shade700 : _kGreen),
                        const SizedBox(width: 6),
                        Text(
                            esVeh
                                ? 'Registro de Camión'
                                : 'Registro de Tractor',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: esVeh ? Colors.blue.shade800 : _kGreen)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Datos comunes
                    _row('Operador', r.operadorNombre),
                    _row(esVeh ? 'Camión' : 'Tractor', r.tractorCodigo),
                    _row('Proceso', r.procesoNombre),
                    _row('Fecha', DateFormat('dd/MM/yyyy').format(r.fecha)),
                    _row('Turno', r.turno.toUpperCase()),
                    _row('Estado', r.estado.toUpperCase()),
                    if (r.supervisorNombre?.isNotEmpty == true)
                      _row('Supervisor', r.supervisorNombre!),
                    const SizedBox(height: 8),
                    // Datos específicos por tipo
                    if (esVeh) ...[
                      if (vd != null) ...[
                        if (vd.kmCamionInicio != null)
                          _row('KM Inicio',
                              '${vd.kmCamionInicio!.toStringAsFixed(0)} km'),
                        if (vd.kmCamionFinal != null)
                          _row('KM Final',
                              '${vd.kmCamionFinal!.toStringAsFixed(0)} km'),
                        if (kmTotal != null)
                          _row('KM Recorridos',
                              '${kmTotal.toStringAsFixed(0)} km'),
                        if (vd.cantidadTancadas != null)
                          _row('Tancadas', '${vd.cantidadTancadas}'),
                        if (vd.horaSalidaBase != null)
                          _row('Salida base', vd.horaSalidaBase!),
                        if (vd.horaLlegadaZona != null)
                          _row('Llegada zona', vd.horaLlegadaZona!),
                        if (vd.horaRetornoBase != null)
                          _row('Retorno base', vd.horaRetornoBase!),
                      ],
                      if (totalGlns > 0)
                        _row('Combustible',
                            '${totalGlns.toStringAsFixed(1)} gln'),
                      if (r.parosVehiculo.isNotEmpty)
                        _row('Paros camión', '${r.parosVehiculo.length}'),
                    ] else ...[
                      if (r.bines.isNotEmpty)
                        _row('Total bines', '${r.totalBines}'),
                      if (r.paros.isNotEmpty)
                        _row('Paros equipo', '${r.paros.length}'),
                      if (r.horometro?.horasTractor != null)
                        _row('Horas tractor',
                            '${r.horometro!.horasTractor!.toStringAsFixed(1)} h'),
                      if (r.sectores.isNotEmpty)
                        _row('Sectores', '${r.sectores.length}'),
                      if (r.checklist.isNotEmpty)
                        _row('Checklist obs.',
                            '${r.checklist.where((c) => c.esMal).length} mal de ${r.checklist.length}'),
                    ],
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await onShare(r);
                  },
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Compartir / Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ─── Tile de opción en el diálogo Rechazar/Editar ────────────────────────────

class _OpcionAccionTile extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _OpcionAccionTile({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 2),
                Text(descripcion,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5), size: 20),
        ]),
      ),
    );
  }
}
