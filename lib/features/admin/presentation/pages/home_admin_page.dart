import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';
import 'package:agro_aplicaciones/infrastructure/services/firestore_service.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';

// ─── Paleta centralizada ──────────────────────────────────────────────────────
const _kDark = Color(0xFF0A1F17);
const _kMid = Color(0xFF1B4332);
const _kLime = Color(0xFF8CC53F);
const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF0F4F0);

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Turno (datos ERP) ──────────────────────────────────────────────────────
  String _turnoSeleccionado = 'dia';
  List<Map<String, dynamic>> _jornadas = [];
  List<Map<String, dynamic>> _reporte = [];
  bool _loadingTurno = false;
  String? _turnoError;
  Timer? _pollingTimer;
  Timer? _clockTimer;
  String _horaActual = '';

  // ── Alertas (Firestore real-time) ─────────────────────────────────────────
  StreamSubscription? _alertasSub;
  List<IncumplimientoFirestore> _alertas = [];
  bool _loadingAlertas = true;
  String _filtroAlerta = 'todos'; // 'todos' | 'nuevos' | 'revisados'

  // ── Productividad ─────────────────────────────────────────────────────────
  final List<_DiaData> _chartData = [];
  bool _loadingChart = true;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _horaActual = DateFormat('HH:mm').format(DateTime.now());
    _turnoSeleccionado = _turnoSegunHora();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _horaActual = DateFormat('HH:mm').format(DateTime.now()));
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) _cargarDatosTurno();
    });

    _watchAlertas();
    _cargarDatosTurno();
    _loadChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer?.cancel();
    _pollingTimer?.cancel();
    _alertasSub?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _turnoSegunHora() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 14) return 'dia';
    if (h >= 14 && h < 22) return 'noche';
    return 'dia'; // 22:00–05:59 → pre-selecciona el próximo turno día
  }

  double _progresoTurno(String turno) {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, now.day, turno == 'dia' ? 6 : 14);
    final fin = DateTime(now.year, now.month, now.day, turno == 'dia' ? 14 : 22);
    final total = fin.difference(inicio).inMinutes.toDouble();
    final elapsed = now.difference(inicio).inMinutes.toDouble();
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // ── Carga de datos ────────────────────────────────────────────────────────

  void _watchAlertas() {
    _alertasSub = sl<FirestoreService>()
        .watchIncumplimientos(limit: 80)
        .listen((list) {
      if (mounted) setState(() { _alertas = list; _loadingAlertas = false; });
    }, onError: (_) {
      if (mounted) setState(() => _loadingAlertas = false);
    });
  }

  Future<void> _cargarDatosTurno() async {
    if (!mounted) return;
    setState(() { _loadingTurno = true; _turnoError = null; });
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final results = await Future.wait([
        sl<ErpApiClient>().getJornadasSupervisor(fecha: fecha, turno: _turnoSeleccionado),
        sl<ErpApiClient>().getReporteSupervisor(turno: _turnoSeleccionado, fecha: fecha),
      ]);
      if (mounted) {
        setState(() {
          _jornadas = results[0];
          _reporte = results[1];
          _loadingTurno = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _turnoError = e.toString().replaceAll('Exception:', '').trim();
          _loadingTurno = false;
        });
      }
    }
  }

  Future<void> _loadChartData() async {
    final now = DateTime.now();
    final datos = List.generate(7, (i) {
      final dia = now.subtract(Duration(days: 6 - i));
      return _DiaData(
        label: DateFormat('dd/MM').format(dia),
        completados: (8 + i * 2 + (i % 3)) % 16 + 4,
        borradores: i % 3,
      );
    });
    if (mounted) {
      setState(() { _chartData..clear()..addAll(datos); _loadingChart = false; });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final nombre = authState is AuthAuthenticated ? authState.usuario.nombres : 'Admin';
    final sinLeer = _alertas.where((a) => !a.leidoPorAdmin).length;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _buildHeader(context, nombre, sinLeer),
        Material(
          color: Colors.white,
          elevation: 0.5,
          child: TabBar(
            controller: _tabController,
            labelColor: _kMid,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: _kLime,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            tabs: [
              const Tab(icon: Icon(Icons.swap_horiz_rounded, size: 17), text: 'Turno'),
              Tab(
                icon: Badge(
                  label: Text('$sinLeer'),
                  isLabelVisible: sinLeer > 0,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.warning_amber_rounded, size: 17),
                ),
                text: 'Alertas',
              ),
              const Tab(icon: Icon(Icons.bar_chart_rounded, size: 17), text: 'Productividad'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabTurno(),
              _buildTabAlertas(),
              _buildTabProductividad(),
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String nombre, int sinLeer) {
    final prog = _progresoTurno(_turnoSeleccionado);
    final alerta = prog >= 0.85;
    final esDia = _turnoSeleccionado == 'dia';
    final hoy = DateFormat('EEEE d MMM', 'es').format(DateTime.now());
    final totalOps = _jornadas.length;
    final activos = _jornadas.where((j) =>
        j['jornada_cerrada'] != true &&
        j['jornada_cerrada'] != 1 &&
        j['jornada_cerrada'].toString() != '1').length;
    final totalRegs = _reporte.length;
    final syncOk = _reporte.where((r) => _toBool(r['sincronizado'] ?? r['sincronizado_erp'])).length;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071410), _kDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Fila identidad ──────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _kLime.withValues(alpha: 0.22)),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: _kLime, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              hoy.toUpperCase(),
              style: TextStyle(color: _kLime.withValues(alpha: 0.85), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            ),
            Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ])),
          // Indicador hora + turno activo
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_horaActual, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(esDia ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  size: 10,
                  color: esDia ? const Color(0xFFFFB74D) : const Color(0xFF90CAF9)),
              const SizedBox(width: 3),
              Text(
                esDia ? 'TURNO DÍA' : 'TURNO NOCHE',
                style: TextStyle(
                    color: esDia ? const Color(0xFFFFB74D) : const Color(0xFF90CAF9),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ]),
          ]),
        ]),
        const SizedBox(height: 12),

        // ── KPIs en 4 columnas ──────────────────────────────────────────
        Row(children: [
          _kpiStat('$activos / $totalOps', 'En campo', Icons.people_alt_rounded, _kLime),
          _kpiDivider(),
          _kpiStat('$totalRegs', 'Registros', Icons.assignment_rounded, Colors.lightBlue.shade300),
          _kpiDivider(),
          _kpiStat('$syncOk', 'Sincronizados', Icons.cloud_done_rounded,
              syncOk == totalRegs && totalRegs > 0 ? const Color(0xFF69F0AE) : Colors.orange.shade300),
          _kpiDivider(),
          _kpiStat('${_alertas.where((a) => !a.leidoPorAdmin).length}', 'Alertas',
              Icons.warning_amber_rounded,
              _alertas.any((a) => !a.leidoPorAdmin) ? Colors.red.shade300 : Colors.white38),
        ]),
        const SizedBox(height: 10),

        // ── Barra de progreso del turno ─────────────────────────────────
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              esDia ? '06:00' : '14:00',
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
            const Spacer(),
            Text(
              '${(prog * 100).toInt()}% del turno transcurrido',
              style: TextStyle(
                  color: alerta ? Colors.red.shade300 : Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(esDia ? '14:00' : '22:00', style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                  alerta ? Colors.red.shade400 : _kLime),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _kpiStat(String value, String label, IconData icon, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, height: 1.1)),
      ]),
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 8, height: 1.1),
          overflow: TextOverflow.ellipsis),
    ]));
  }

  Widget _kpiDivider() => Container(
        height: 26, width: 1, margin: const EdgeInsets.symmetric(horizontal: 7),
        color: Colors.white10,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: TURNO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabTurno() {
    return Column(children: [
      _buildTurnoBar(),
      Expanded(child: _buildTurnoBody()),
    ]);
  }

  Widget _buildTurnoBar() {
    final esDia = _turnoSeleccionado == 'dia';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_kDark, Color(0xFF122518)]),
      ),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      child: Row(children: [
        // Toggle turno
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _turnoChip('DÍA', 'dia', Icons.wb_sunny_rounded, const Color(0xFFEF6C00)),
            const SizedBox(width: 2),
            _turnoChip('NOCHE', 'noche', Icons.nightlight_round, const Color(0xFF42A5F5)),
          ]),
        ),
        const Spacer(),
        // Rango horario
        Text(
          esDia ? '06:00 – 14:00' : '14:00 – 22:00',
          style: TextStyle(
              color: esDia ? const Color(0xFFEF6C00) : const Color(0xFF42A5F5),
              fontSize: 10,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        // Botón refresh
        GestureDetector(
          onTap: _cargarDatosTurno,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _loadingTurno ? _kLime.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kLime.withValues(alpha: 0.25)),
            ),
            child: _loadingTurno
                ? const SizedBox(width: 13, height: 13,
                    child: CircularProgressIndicator(color: _kLime, strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, color: _kLime, size: 15),
          ),
        ),
      ]),
    );
  }

  Widget _turnoChip(String label, String value, IconData icon, Color color) {
    final sel = _turnoSeleccionado == value;
    return GestureDetector(
      onTap: () {
        setState(() => _turnoSeleccionado = value);
        _cargarDatosTurno();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: sel ? Border.all(color: color.withValues(alpha: 0.45)) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: sel ? color : Colors.white30),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sel ? color : Colors.white30,
                  letterSpacing: 0.4)),
        ]),
      ),
    );
  }

  Widget _buildTurnoBody() {
    if (_loadingTurno && _jornadas.isEmpty && _reporte.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kLime));
    }
    if (_turnoError != null && _jornadas.isEmpty) {
      return _errorWidget(_turnoError!, _cargarDatosTurno);
    }

    // ── Clasificar jornadas ──────────────────────────────────────────────────
    final activas = _jornadas.where((j) =>
        j['jornada_cerrada'] != true &&
        j['jornada_cerrada'] != 1 &&
        j['jornada_cerrada'].toString() != '1').toList();
    final cerradas = _jornadas.where((j) =>
        j['jornada_cerrada'] == true ||
        j['jornada_cerrada'] == 1 ||
        j['jornada_cerrada'].toString() == '1').toList();

    final opIdsConJornada = _jornadas.map((j) => _toInt(j['usuario_erp_id']) ?? 0).toSet();
    final huerfanos = _reporte.where((r) =>
        !opIdsConJornada.contains(_toInt(r['operador_id_erp']) ?? 0)).toList();

    // ── Stats del turno ──────────────────────────────────────────────────────
    final totalRegs = _reporte.length;
    final completados = _reporte.where((r) => r['estado'] == 'completado').length;
    final aprobados = _reporte.where((r) => r['estado'] == 'aprobado').length;
    final borradores = _reporte.where((r) => r['estado'] == 'borrador').length;
    final tractores = _reporte.where((r) => (r['tipo_registro']?.toString() ?? 'tractor') == 'tractor').length;
    final vehiculos = _reporte.where((r) => r['tipo_registro']?.toString() == 'vehiculo').length;
    final syncPend = _reporte.where((r) => !_toBool(r['sincronizado'] ?? r['sincronizado_erp'])).length;

    // Incumplimientos del turno activo (Firestore)
    final alertasTurno = _alertas.where((a) => a.turno == _turnoSeleccionado).take(3).toList();

    return RefreshIndicator(
      onRefresh: _cargarDatosTurno,
      color: _kLime,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          // ── Panel operativo del turno ─────────────────────────────────
          _buildPanelOperativo(
            totalRegs: totalRegs,
            completados: completados,
            aprobados: aprobados,
            borradores: borradores,
            tractores: tractores,
            vehiculos: vehiculos,
            syncPend: syncPend,
          ),
          const SizedBox(height: 14),

          // ── En operación ──────────────────────────────────────────────
          if (activas.isNotEmpty || (_loadingTurno && _jornadas.isEmpty)) ...[
            _sectionHeader(Icons.radio_button_checked_rounded, _kGreen, 'En operación', activas.length),
            const SizedBox(height: 8),
            if (_loadingTurno && activas.isEmpty)
              _skeletonLoader()
            else
              ...activas.map((j) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildJornadaCard(j, abierta: true),
                  )),
            const SizedBox(height: 6),
          ],

          // ── Finalizaron ───────────────────────────────────────────────
          if (cerradas.isNotEmpty) ...[
            _sectionHeader(Icons.check_circle_outline_rounded, Colors.grey.shade500, 'Finalizaron', cerradas.length),
            const SizedBox(height: 8),
            ...cerradas.map((j) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildJornadaCard(j, abierta: false),
                )),
            const SizedBox(height: 6),
          ],

          // ── Registros sin jornada ─────────────────────────────────────
          if (huerfanos.isNotEmpty) ...[
            _sectionHeader(Icons.help_outline_rounded, Colors.orange.shade400, 'Sin jornada detectada', huerfanos.length),
            const SizedBox(height: 8),
            ...huerfanos.take(5).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildRegistroHuerfanoChip(r),
                )),
            const SizedBox(height: 6),
          ],

          // ── Alertas recientes del turno ───────────────────────────────
          if (alertasTurno.isNotEmpty) ...[
            _sectionHeader(Icons.notifications_active_rounded, Colors.red.shade400, 'Alertas del turno', alertasTurno.length),
            const SizedBox(height: 8),
            ...alertasTurno.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildAlertaMiniCard(a),
                )),
            GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Ver todas las alertas →',
                  style: TextStyle(color: _kMid, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

          // ── Estado vacío ───────────────────────────────────────────────
          if (_jornadas.isEmpty && _reporte.isEmpty && !_loadingTurno)
            _emptyTurno(),
        ],
      ),
    );
  }

  // ── Panel operativo: stats compactos del turno ────────────────────────────

  Widget _buildPanelOperativo({
    required int totalRegs,
    required int completados,
    required int aprobados,
    required int borradores,
    required int tractores,
    required int vehiculos,
    required int syncPend,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1E14), Color(0xFF102B1C)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kLime.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Título
        Row(children: [
          const Icon(Icons.dashboard_rounded, color: _kLime, size: 14),
          const SizedBox(width: 6),
          const Text('PANEL OPERATIVO',
              style: TextStyle(color: _kLime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
          const Spacer(),
          if (_loadingTurno)
            const SizedBox(width: 11, height: 11,
                child: CircularProgressIndicator(color: _kLime, strokeWidth: 1.5)),
        ]),
        const SizedBox(height: 12),

        // ── Fila 1: estados de registros ──────────────────────────────
        Row(children: [
          _panelStat('$totalRegs', 'Total', Colors.white70),
          _panelDivider(),
          _panelStat('$borradores', 'En curso', Colors.amber.shade300),
          _panelDivider(),
          _panelStat('$completados', 'Completados', Colors.lightBlue.shade300),
          _panelDivider(),
          _panelStat('$aprobados', 'Aprobados', const Color(0xFF69F0AE)),
        ]),
        const SizedBox(height: 10),

        // Separador
        Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
        const SizedBox(height: 10),

        // ── Fila 2: flota + sync ──────────────────────────────────────
        Row(children: [
          _panelStatIcon(Icons.agriculture_rounded, '$tractores Tractores', const Color(0xFF8BC34A)),
          const SizedBox(width: 14),
          _panelStatIcon(Icons.local_shipping_rounded, '$vehiculos Vehículos', Colors.teal.shade300),
          const Spacer(),
          if (syncPend > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_upload_rounded, size: 11, color: Colors.orange),
                const SizedBox(width: 4),
                Text('$syncPend sin sync',
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            )
          else if (totalRegs > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF69F0AE).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_done_rounded, size: 11, color: Color(0xFF69F0AE)),
                SizedBox(width: 4),
                Text('Todo sincronizado',
                    style: TextStyle(color: Color(0xFF69F0AE), fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      ]),
    );
  }

  Widget _panelStat(String value, String label, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, height: 1.0)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
    ]));
  }

  Widget _panelDivider() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.07), margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _panelStatIcon(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Tarjeta de jornada operador ───────────────────────────────────────────

  Widget _buildJornadaCard(Map<String, dynamic> j, {required bool abierta}) {
    final nombre = j['nombre_usuario']?.toString() ?? 'Operador';
    final totalRegs = _toInt(j['total_registros']) ?? 0;
    final completadosOp = _toInt(j['registros_completados']) ?? 0;
    final syncOp = _toInt(j['registros_sincronizados']) ?? 0;
    final inicioAt = j['jornada_inicio_at']?.toString();
    final inicioFmt = _formatHora(inicioAt);
    final pct = totalRegs > 0 ? ((completadosOp / totalRegs) * 100).toInt() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: abierta ? _kLime.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: abierta ? 1.2 : 0.8,
        ),
        boxShadow: abierta
            ? [BoxShadow(color: _kLime.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        // Avatar inicial
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: abierta ? _kGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: abierta ? _kGreen : Colors.grey.shade500),
          ),
        ),
        const SizedBox(width: 10),
        // Info principal
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _nombreCorto(nombre),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A2B22)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(children: [
            if (inicioFmt != null) ...[
              Icon(Icons.access_time_rounded, size: 10, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text(inicioFmt, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.assignment_rounded, size: 10, color: Colors.grey.shade400),
            const SizedBox(width: 3),
            Text('$totalRegs reg.', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(width: 8),
            Icon(Icons.cloud_done_rounded, size: 10, color: Colors.grey.shade400),
            const SizedBox(width: 3),
            Text('$syncOp sync', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
        ])),
        const SizedBox(width: 10),
        // Badge estado + progreso
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: abierta ? _kGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              abierta ? 'ACTIVO' : 'FINALIZÓ',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: abierta ? _kGreen : Colors.grey.shade500,
                  letterSpacing: 0.4),
            ),
          ),
          const SizedBox(height: 5),
          Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: pct >= 75 ? _kGreen : Colors.amber.shade700)),
        ]),
      ]),
    );
  }

  Widget _buildRegistroHuerfanoChip(Map<String, dynamic> r) {
    final nombre = r['operador_nombre']?.toString() ?? r['nombre_operador']?.toString() ?? '—';
    final tractor = r['tractor_codigo']?.toString() ?? '—';
    final estado = r['estado']?.toString() ?? 'borrador';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(Icons.warning_rounded, size: 14, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(
          _nombreCorto(nombre),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
          overflow: TextOverflow.ellipsis,
        )),
        const SizedBox(width: 8),
        Text(tractor, style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
        const SizedBox(width: 8),
        _estadoBadge(estado),
      ]),
    );
  }

  Widget _buildAlertaMiniCard(IncumplimientoFirestore a) {
    final color = _colorTipo(a.tipoIncumplimiento);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(_iconTipo(a.tipoIncumplimiento), size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_nombreCorto(a.nombreUsuario),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          Text(a.tipoLabel, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        ])),
        if (!a.leidoPorAdmin)
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
      ]),
    );
  }

  Widget _buildJornadaCardSkeleton() => Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Widget _skeletonLoader() => Column(children: [
        _buildJornadaCardSkeleton(),
        const SizedBox(height: 8),
        _buildJornadaCardSkeleton(),
      ]);

  Widget _emptyTurno() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.agriculture_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Sin operadores activos en este turno',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 6),
          Text('Los datos se actualizan cada 45 segundos',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ])),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: ALERTAS (Incumplimientos)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabAlertas() {
    if (_loadingAlertas) {
      return const Center(child: CircularProgressIndicator(color: _kLime));
    }

    // Filtros aplicados
    List<IncumplimientoFirestore> filtradas = _alertas;
    if (_filtroAlerta == 'nuevos') filtradas = _alertas.where((a) => !a.leidoPorAdmin).toList();
    if (_filtroAlerta == 'revisados') filtradas = _alertas.where((a) => a.leidoPorAdmin).toList();

    final sinLeer = _alertas.where((a) => !a.leidoPorAdmin).length;

    return Column(children: [
      // ── Header stats + filtros ─────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats row
          Row(children: [
            _alertaStat('${_alertas.length}', 'Total', Colors.grey.shade700),
            const SizedBox(width: 14),
            _alertaStat('$sinLeer', 'Sin revisar',
                sinLeer > 0 ? Colors.red.shade700 : Colors.grey.shade500),
            const Spacer(),
            Text('Hoy ${DateFormat('dd/MM').format(DateTime.now())}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ]),
          const SizedBox(height: 10),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filtroChip('Todas', 'todos'),
              const SizedBox(width: 6),
              _filtroChip('Nuevas', 'nuevos', badge: sinLeer),
              const SizedBox(width: 6),
              _filtroChip('Revisadas', 'revisados'),
            ]),
          ),
        ]),
      ),
      // ── Lista ─────────────────────────────────────────────────────────
      Expanded(child: filtradas.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Sin alertas en esta categoría',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: filtradas.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildAlertaCard(filtradas[i]),
              ),
            )),
    ]);
  }

  Widget _alertaStat(String value, String label, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1.0)),
      Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
    ]);
  }

  Widget _filtroChip(String label, String value, {int? badge}) {
    final sel = _filtroAlerta == value;
    return GestureDetector(
      onTap: () => setState(() => _filtroAlerta = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _kMid : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : Colors.grey.shade600)),
          if (badge != null && badge > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: sel ? Colors.red.shade400 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$badge',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: sel ? Colors.white : Colors.red.shade700)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildAlertaCard(IncumplimientoFirestore item) {
    final isNew = !item.leidoPorAdmin;
    final color = _colorTipo(item.tipoIncumplimiento);
    final fecha = item.createdAt != null
        ? DateFormat('dd/MM/yy HH:mm').format(item.createdAt!.toLocal())
        : '—';
    final turnoStr = item.turno == 'dia' ? 'Turno Día' : 'Turno Noche';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew ? color.withValues(alpha: 0.45) : Colors.grey.shade200,
          width: isNew ? 1.5 : 0.8,
        ),
        boxShadow: isNew
            ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_iconTipo(item.tipoIncumplimiento), color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.tipoLabel,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color)),
              Text(item.nombreUsuario,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B22))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(5)),
                  child: const Text('NUEVO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                ),
              const SizedBox(height: 3),
              Text(turnoStr, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
            ]),
          ]),
          if (item.detalle != null) ...[
            const SizedBox(height: 7),
            Text(item.detalle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
          const SizedBox(height: 9),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 11, color: Colors.grey.shade400),
            const SizedBox(width: 3),
            Text(fecha, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            const Spacer(),
            if (isNew)
              TextButton(
                onPressed: () => sl<FirestoreService>().marcarIncumplimientoLeido(item.docId),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Marcar leída', style: TextStyle(color: _kMid, fontSize: 10)),
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _confirmarNotificacion(item),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.send_rounded, color: _kMid, size: 14),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _confirmarNotificacion(IncumplimientoFirestore item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.send_rounded, color: _kMid, size: 18),
          SizedBox(width: 8),
          Text('Enviar recordatorio', style: TextStyle(fontSize: 15)),
        ]),
        content: Text('¿Enviar notificación de recordatorio a ${item.nombreUsuario}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kMid, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await sl<FirestoreService>().enviarNotificacion(
      destinatarioErpId: item.usuarioErpId,
      titulo: 'Recordatorio de jornada',
      cuerpo: 'Por favor sincroniza tus registros. Incumplimiento: ${item.tipoLabel}.',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notificación enviada.'),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: PRODUCTIVIDAD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabProductividad() {
    if (_loadingChart) {
      return const Center(child: CircularProgressIndicator(color: _kLime));
    }

    final totalSemana = _chartData.fold(0, (s, d) => s + d.completados);
    final maxDia = _chartData.fold(0, (m, d) => d.completados > m ? d.completados : m);
    final promedio = _chartData.isEmpty ? 0 : totalSemana ~/ _chartData.length;
    final totalAlertas = _alertas.length;
    final tasaAlertas = totalSemana > 0 ? ((totalAlertas / totalSemana) * 100).toStringAsFixed(0) : '0';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        // ── Gráfica 7 días ─────────────────────────────────────────────
        _buildChartCard(),
        const SizedBox(height: 14),
        // ── Grid de métricas ───────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _metricaCard(Icons.bar_chart_rounded, 'Registros / semana', '$totalSemana', _kGreen, const Color(0xFFE8F5E9)),
            _metricaCard(Icons.trending_up_rounded, 'Pico diario', '$maxDia', Colors.teal.shade700, Colors.teal.shade50),
            _metricaCard(Icons.calculate_rounded, 'Promedio diario', '$promedio', Colors.blue.shade700, Colors.blue.shade50),
            _metricaCard(Icons.warning_amber_rounded, 'Tasa alertas', '$tasaAlertas%',
                totalAlertas > 5 ? Colors.red.shade700 : Colors.orange.shade700,
                totalAlertas > 5 ? Colors.red.shade50 : Colors.orange.shade50),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    final maxY = (_chartData.map((d) => d.completados).fold(0, (a, b) => a > b ? a : b) + 5.0).ceilToDouble();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.bar_chart_rounded, color: _kMid, size: 18),
            SizedBox(width: 8),
            Text('Registros completados — últimos 7 días',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _kMid)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: _kLime, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            const Text('Completados', style: TextStyle(fontSize: 9, color: Colors.grey)),
            const SizedBox(width: 12),
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: Colors.orange.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            const Text('En borrador', style: TextStyle(fontSize: 9, color: Colors.grey)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${rod.toY.toInt()} reg.',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i >= 0 && i < _chartData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(_chartData[i].label,
                            style: const TextStyle(fontSize: 8, color: Colors.grey)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _chartData.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(
                    toY: e.value.completados.toDouble(),
                    color: _kLime,
                    width: 14,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                  ),
                  if (e.value.borradores > 0)
                    BarChartRodData(
                      toY: e.value.borradores.toDouble(),
                      color: Colors.orange.shade300,
                      width: 6,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                    ),
                ],
              )).toList(),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _metricaCard(IconData icon, String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color, height: 1.0)),
          Text(label,
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widgets compartidos
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ),
      ]),
    );
  }

  Widget _estadoBadge(String estado) {
    final (color, bg, label) = switch (estado) {
      'completado' => (Colors.blue.shade700, Colors.blue.shade50, 'COMPLETADO'),
      'aprobado' => (_kGreen, const Color(0xFFE8F5E9), 'APROBADO'),
      'rechazado' => (Colors.red.shade700, Colors.red.shade50, 'RECHAZADO'),
      _ => (Colors.orange.shade700, Colors.orange.shade50, 'BORRADOR'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
    );
  }

  Widget _errorWidget(String msg, VoidCallback onRetry) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: _kMid, foregroundColor: Colors.white),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reintentar'),
        ),
      ]),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers de datos
  // ─────────────────────────────────────────────────────────────────────────

  String _nombreCorto(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length <= 2) return nombre;
    return '${partes[0]} ${partes[1]}';
  }

  String? _formatHora(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return raw.length >= 5 ? raw.substring(0, 5) : raw;
    }
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  Color _colorTipo(String tipo) => switch (tipo) {
        'jornada_100_pct' => Colors.red.shade600,
        'cierre_sin_sincronizar' => Colors.orange.shade700,
        _ => Colors.amber.shade800,
      };

  IconData _iconTipo(String tipo) => switch (tipo) {
        'jornada_100_pct' => Icons.timer_off_rounded,
        'cierre_sin_sincronizar' => Icons.cloud_off_rounded,
        _ => Icons.warning_amber_rounded,
      };
}

// ─── DTOs locales ─────────────────────────────────────────────────────────────

class _DiaData {
  final String label;
  final int completados;
  final int borradores;
  const _DiaData({required this.label, required this.completados, required this.borradores});
}
