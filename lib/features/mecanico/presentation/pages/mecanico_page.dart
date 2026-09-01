import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_bloc.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_event.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_state.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/pages/completar_falla_page.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';

// ─── Paleta (igual que supervisor/operador) ───────────────────────────────────
const _kBg          = Color(0xFFF5F8F5);
const _kCardBg      = Color(0xFFFFFFFF);
const _kPrimary     = Color(0xFF1B4332);
const _kPrimaryMid  = Color(0xFF2E7D32);
const _kLime        = Color(0xFF8CC53F);
const _kBorder      = Color(0xFFE2E8F0);
const _kTextPrimary = Color(0xFF1A202C);
const _kTextSec     = Color(0xFF64748B);
const _kTextMuted   = Color(0xFFADB5BD);
const _kRed         = Color(0xFFDC2626);

class MecanicoPage extends StatefulWidget {
  const MecanicoPage({super.key});

  @override
  State<MecanicoPage> createState() => _MecanicoPageState();
}

class _MecanicoPageState extends State<MecanicoPage>
    with SingleTickerProviderStateMixin {
  DateTime _fecha        = DateTime.now();
  // null = todos (vista inicial sin filtro → muestra pendientes primero)
  // 'pendiente' = solo pendientes
  // 'resuelto'  = solo completados
  String? _filtroEstado;
  Timer? _autoRefresh;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _cargar();
    _autoRefresh = Timer.periodic(const Duration(minutes: 3), (_) {
      if (mounted) _cargar();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _cargar() {
    context
        .read<MecanicoBloc>()
        .add(MecanicoParosRequested(fecha: _fecha, estado: _filtroEstado));
  }

  Future<void> _seleccionarFecha() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _fecha) {
      setState(() => _fecha = picked);
      _cargar();
    }
  }

  Future<void> _abrirFalla(ParoMecanico paro) async {
    HapticFeedback.mediumImpact();
    final authState = context.read<AuthBloc>().state;
    final mecanicoNombre = authState is AuthAuthenticated
        ? authState.usuario.nombreCompleto
        : '';
    final mecanicoId = authState is AuthAuthenticated
        ? (authState.usuario.trabajadorIdErp ?? 0)
        : 0;

    if (mecanicoId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Tu perfil no tiene ID ERP. Sincroniza los catálogos primero.')),
          ]),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => BlocProvider.value(
          value: context.read<MecanicoBloc>(),
          child: CompletarFallaPage(
            paro: paro,
            mecanicoId: mecanicoId,
            mecanicoNombre: mecanicoNombre,
          ),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final nombre = authState is AuthAuthenticated
        ? authState.usuario.nombreCompleto
        : 'Mecánico';

    return Scaffold(
      backgroundColor: _kBg,
      body: BlocConsumer<MecanicoBloc, MecanicoState>(
        listener: (ctx, state) {
          if (state is MecanicoFallaCompletada) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: const Row(children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Registro guardado correctamente'),
                ]),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
            _cargar();
          }
          if (state is MecanicoError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ]),
                backgroundColor: _kRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (ctx, state) {
          final todosParos = _parosFromState(state);
          final cargando   = state is MecanicoLoading;

          // Aplicar filtro local
          final paros = _filtroEstado == null
              ? todosParos
              : todosParos
                  .where((p) => p.estadoFalla == _filtroEstado)
                  .toList();

          final pendientes  = todosParos.where((p) => p.esPendiente).length;
          final completados = todosParos.where((p) => p.esCompletado).length;

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildSliverAppBar(nombre, pendientes, completados),
            ],
            body: RefreshIndicator(
              color: _kPrimary,
              onRefresh: () async => _cargar(),
              child: Column(
                children: [
                  // Filtros: solo 2 botones
                  _FiltroBar(
                    filtroActual: _filtroEstado,
                    countPendientes: pendientes,
                    countCompletados: completados,
                    onChanged: (v) {
                      setState(() => _filtroEstado = v);
                    },
                  ),
                  // Lista
                  Expanded(
                    child: cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: _kLime))
                        : paros.isEmpty
                            ? _EmptyState(filtro: _filtroEstado)
                            : FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _animCtrl,
                                  curve: Curves.easeOut,
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 100),
                                  itemCount: paros.length,
                                  itemBuilder: (_, i) => _ParoCard(
                                    paro: paros[i],
                                    onAtender: () => _abrirFalla(paros[i]),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
      String nombre, int pendientes, int completados) {
    final esHoy = DateUtils.isSameDay(_fecha, DateTime.now());
    final fechaLabel = esHoy
        ? 'Hoy — ${DateFormat('dd MMM yyyy', 'es').format(_fecha)}'
        : DateFormat('EEEE dd MMM yyyy', 'es').format(_fecha);

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.person_outline_rounded),
        tooltip: 'Perfil',
        onPressed: () => context.push('/perfil'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded),
          tooltip: 'Cambiar fecha',
          onPressed: _seleccionarFecha,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar',
          onPressed: _cargar,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4332), Color(0xFF2E7D32)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.build_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MÓDULO MECÁNICO',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fecha + KPIs inline
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _seleccionarFecha,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_rounded,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                fechaLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      _KpiChip(
                          label: '$pendientes pendiente${pendientes != 1 ? 's' : ''}',
                          color: pendientes > 0
                              ? const Color(0xFFFCA5A5)
                              : Colors.white60),
                      const SizedBox(width: 8),
                      _KpiChip(
                          label: '$completados completado${completados != 1 ? 's' : ''}',
                          color: const Color(0xFF86EFAC)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ParoMecanico> _parosFromState(MecanicoState state) => switch (state) {
        MecanicoLoaded(paros: final p)           => p,
        MecanicoFallaCompletada(paros: final p)  => p,
        MecanicoCompletandoFalla(paros: final p) => p,
        _                                        => [],
      };
}

// ─── KPI chip en header ───────────────────────────────────────────────────────

class _KpiChip extends StatelessWidget {
  final String label;
  final Color color;
  const _KpiChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Filtro bar: solo 2 botones ───────────────────────────────────────────────

class _FiltroBar extends StatelessWidget {
  final String? filtroActual;
  final int countPendientes;
  final int countCompletados;
  final ValueChanged<String?> onChanged;

  const _FiltroBar({
    required this.filtroActual,
    required this.countPendientes,
    required this.countCompletados,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _FiltroBtn(
            label: 'Pendientes',
            count: countPendientes,
            selected: filtroActual == 'pendiente',
            selectedColor: _kRed,
            icon: Icons.pending_actions_rounded,
            onTap: () => onChanged(
                filtroActual == 'pendiente' ? null : 'pendiente'),
          ),
          const SizedBox(width: 10),
          _FiltroBtn(
            label: 'Completados',
            count: countCompletados,
            selected: filtroActual == 'resuelto',
            selectedColor: _kPrimary,
            icon: Icons.check_circle_rounded,
            onTap: () => onChanged(
                filtroActual == 'resuelto' ? null : 'resuelto'),
          ),
        ],
      ),
    );
  }
}

class _FiltroBtn extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color selectedColor;
  final IconData icon;
  final VoidCallback onTap;

  const _FiltroBtn({
    required this.label,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.08)
                : _kBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? selectedColor : _kBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? selectedColor : _kTextSec),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : _kTextSec,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? selectedColor : _kTextMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card de paro ─────────────────────────────────────────────────────────────

class _ParoCard extends StatelessWidget {
  final ParoMecanico paro;
  final VoidCallback onAtender;

  const _ParoCard({required this.paro, required this.onAtender});

  Color get _statusColor => paro.esPendiente ? _kRed : _kPrimary;
  String get _statusLabel =>
      paro.esPendiente ? 'PENDIENTE' : 'COMPLETADO';
  IconData get _statusIcon => paro.esPendiente
      ? Icons.pending_actions_rounded
      : Icons.check_circle_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header coloreado
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.06),
              border: Border(
                  bottom: BorderSide(color: _kBorder),
                  left: BorderSide(color: _statusColor, width: 3)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 14, color: _statusColor),
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                // Tipo de falla chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_circle_rounded,
                          size: 11, color: _kPrimary),
                      const SizedBox(width: 4),
                      Text(
                        paro.fallaMecanicaNombre,
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cuerpo
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Operador
                Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        size: 15, color: _kTextSec),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        paro.operadorNombre,
                        style: const TextStyle(
                          color: _kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tractor
                _InfoRow(
                  icon: Icons.agriculture_rounded,
                  text: paro.tractorCodigo,
                ),

                // Motivo
                if (paro.motivo != null && paro.motivo!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.description_rounded,
                    text: paro.motivo!,
                  ),

                // Horas operador
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text:
                      'Reportado: ${paro.horaInicio}${paro.horaFinal != null ? '  →  ${paro.horaFinal}' : ''}',
                ),

                // Si completado: mostrar datos del mecánico
                if (paro.esCompletado) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.engineering_rounded,
                                size: 13, color: _kPrimaryMid),
                            SizedBox(width: 5),
                            Text(
                              'TRABAJO REALIZADO',
                              style: TextStyle(
                                color: _kPrimaryMid,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (paro.horaInicioReal != null ||
                            paro.horaFinReal != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_rounded,
                                    size: 12,
                                    color: _kPrimaryMid),
                                const SizedBox(width: 5),
                                Text(
                                  'Horas reales: ${paro.horaInicioReal ?? '--'}  →  ${paro.horaFinReal ?? '--'}',
                                  style: const TextStyle(
                                    color: _kPrimaryMid,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (paro.trabajoRealizado != null)
                          Text(
                            paro.trabajoRealizado!,
                            style: const TextStyle(
                              color: _kTextSec,
                              fontSize: 12,
                            ),
                          ),
                        if (paro.mecanicoNombre != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.badge_rounded,
                                  size: 11, color: _kTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                paro.mecanicoNombre!,
                                style: const TextStyle(
                                  color: _kTextMuted,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Botón: "Atender" para pendientes, "Editar" para completados
                SizedBox(
                  width: double.infinity,
                  child: paro.esPendiente
                      ? ElevatedButton.icon(
                          onPressed: onAtender,
                          icon: const Icon(Icons.engineering_rounded,
                              size: 16),
                          label: const Text('Atender falla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onAtender,
                          icon: const Icon(Icons.edit_rounded, size: 15),
                          label: const Text('Editar registro'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimaryMid,
                            side: const BorderSide(
                                color: _kPrimaryMid, width: 1.5),
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? filtro;
  const _EmptyState({this.filtro});

  @override
  Widget build(BuildContext context) {
    final esPendiente  = filtro == 'pendiente';
    final esCompletado = filtro == 'resuelto';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  esPendiente
                      ? Icons.check_circle_outline_rounded
                      : esCompletado
                          ? Icons.history_rounded
                          : Icons.build_circle_outlined,
                  size: 38,
                  color: _kPrimary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                esPendiente
                    ? '¡Sin fallas pendientes!'
                    : esCompletado
                        ? 'Sin completados en esta fecha'
                        : 'Sin fallas mecánicas',
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                esPendiente
                    ? 'No hay fallas por atender.\nBuen trabajo.'
                    : 'No hay registros para mostrar.',
                style: const TextStyle(
                    color: _kTextSec, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Fila de info ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 13, color: _kTextMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: _kTextSec, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
