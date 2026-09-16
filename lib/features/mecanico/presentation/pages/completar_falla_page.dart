import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/entities/paro_mecanico.dart';
import 'package:agro_aplicaciones/features/mecanico/domain/repositories/mecanico_repository.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_bloc.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_event.dart';
import 'package:agro_aplicaciones/features/mecanico/presentation/blocs/mecanico_state.dart';

// ─── Paleta (igual que módulo operador/supervisor) ────────────────────────────
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
const _kOrange      = Color(0xFFD97706);

class CompletarFallaPage extends StatefulWidget {
  final ParoMecanico paro;
  final int mecanicoId;
  final String mecanicoNombre;

  const CompletarFallaPage({
    super.key,
    required this.paro,
    required this.mecanicoId,
    required this.mecanicoNombre,
  });

  @override
  State<CompletarFallaPage> createState() => _CompletarFallaPageState();
}

class _CompletarFallaPageState extends State<CompletarFallaPage>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _horaInicioCtrl = TextEditingController();
  final _horaFinCtrl    = TextEditingController();
  final _trabajoCtrl    = TextEditingController();
  String _estadoFalla   = 'resuelto';
  bool _enviando        = false;

  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  bool get _esEdicion => widget.paro.esCompletado;

  @override
  void initState() {
    super.initState();
    _horaInicioCtrl.text =
        widget.paro.horaInicioReal ?? widget.paro.horaInicio;
    _horaFinCtrl.text = widget.paro.horaFinReal ?? '';
    _trabajoCtrl.text = widget.paro.trabajoRealizado ?? '';
    if (widget.paro.esEnProceso) _estadoFalla = 'en_proceso';

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _horaInicioCtrl.dispose();
    _horaFinCtrl.dispose();
    _trabajoCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
      TextEditingController ctrl, String label, IconData icon) async {
    HapticFeedback.selectionClick();
    final initial = _parseTime(ctrl.text) ?? TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: label.toUpperCase(),
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
    if (t != null) {
      setState(() {
        ctrl.text =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _submit() async {
    if (_enviando) return;
    setState(() => _enviando = true);

    if (_horaFinCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Ingresa la hora fin antes de guardar.')),
          ]),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() => _enviando = false);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.heavyImpact();
      setState(() => _enviando = false);
      return;
    }
    HapticFeedback.mediumImpact();

    context.read<MecanicoBloc>().add(
          MecanicoFallaCompletarRequested(
            params: CompletarFallaParams(
              paroId: widget.paro.paroId,
              horaInicioReal: _horaInicioCtrl.text,
              horaFinReal: _horaFinCtrl.text,
              mecanicoIdErp: widget.mecanicoId,
              trabajoRealizado: _trabajoCtrl.text.trim(),
              estadoFalla: _estadoFalla,
              mecanicoNombre: widget.mecanicoNombre.isNotEmpty
                  ? widget.mecanicoNombre
                  : null,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: BlocListener<MecanicoBloc, MecanicoState>(
          listener: (ctx, state) {
            if (state is MecanicoFallaCompletada) {
              setState(() => _enviando = false);
              Navigator.pop(ctx);
            }
            if (state is MecanicoError) {
              setState(() => _enviando = false);
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ParoResumen(
                        paro: widget.paro,
                        mecanicoNombre: widget.mecanicoNombre,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel(
                              icon: Icons.build_rounded,
                              label: _esEdicion
                                  ? 'Actualizar trabajo'
                                  : 'Datos del trabajo',
                            ),
                            const SizedBox(height: 16),
                            _HorasRow(
                              horaInicioCtrl: _horaInicioCtrl,
                              horaFinCtrl: _horaFinCtrl,
                              onPickInicio: () => _pickTime(
                                  _horaInicioCtrl,
                                  'Hora inicio real',
                                  Icons.play_circle_rounded),
                              onPickFin: () => _pickTime(_horaFinCtrl,
                                  'Hora fin real', Icons.stop_circle_rounded),
                            ),
                            const SizedBox(height: 14),
                            _LightField(
                              controller: _trabajoCtrl,
                              label: 'Descripción del trabajo realizado',
                              hint:
                                  'Diagnóstico, repuestos utilizados, acciones tomadas...',
                              maxLines: 5,
                              icon: Icons.description_rounded,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Campo obligatorio'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            const _SectionLabel(
                              icon: Icons.flag_rounded,
                              label: 'Estado final',
                            ),
                            const SizedBox(height: 12),
                            _EstadoSelector(
                              value: _estadoFalla,
                              onChanged: (v) =>
                                  setState(() => _estadoFalla = v),
                            ),
                            const SizedBox(height: 28),
                            BlocBuilder<MecanicoBloc, MecanicoState>(
                              builder: (ctx, state) {
                                final cargando =
                                    state is MecanicoCompletandoFalla;
                                return _SubmitButton(
                                  cargando: cargando,
                                  esEdicion: _esEdicion,
                                  onTap: _submit,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: _kPrimary,
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _esEdicion ? 'Editar reparación' : 'Atender falla',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.paro.fallaMecanicaNombre,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1, color: Colors.white.withValues(alpha: 0.15)),
      ),
    );
  }
}

// ─── Resumen del paro ─────────────────────────────────────────────────────────

class _ParoResumen extends StatelessWidget {
  final ParoMecanico paro;
  final String mecanicoNombre;

  const _ParoResumen({required this.paro, required this.mecanicoNombre});

  @override
  Widget build(BuildContext context) {
    final colorEstado = paro.esPendiente
        ? _kRed
        : paro.esEnProceso
            ? _kOrange
            : _kPrimary;

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorEstado.withValues(alpha: 0.06),
              border: Border(
                bottom: const BorderSide(color: _kBorder),
                left: BorderSide(color: colorEstado, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.report_problem_rounded,
                    color: colorEstado, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'FALLA REPORTADA POR OPERADOR',
                  style: TextStyle(
                    color: _kTextSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paro.esPendiente
                        ? 'PENDIENTE'
                        : paro.esEnProceso
                            ? 'EN PROCESO'
                            : 'COMPLETADO',
                    style: TextStyle(
                      color: colorEstado,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mecánico que atiende
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.engineering_rounded,
                          size: 14, color: _kPrimary),
                      const SizedBox(width: 6),
                      Text(
                        mecanicoNombre.isNotEmpty
                            ? mecanicoNombre
                            : 'Mecánico',
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  paro.operadorNombre,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _ResumenRow(
                  icon: Icons.agriculture_rounded,
                  label: 'Tractor',
                  value: paro.tractorCodigo,
                ),
                _ResumenRow(
                  icon: Icons.build_circle_rounded,
                  label: 'Tipo de falla',
                  value: paro.fallaMecanicaNombre,
                  valueColor: _kPrimaryMid,
                ),
                if (paro.equipo != null && paro.equipo!.isNotEmpty)
                  _ResumenRow(
                    icon: Icons.settings_rounded,
                    label: 'Componente',
                    value: paro.equipo!,
                  ),
                if (paro.motivo != null && paro.motivo!.isNotEmpty)
                  _ResumenRow(
                    icon: Icons.description_rounded,
                    label: 'Motivo',
                    value: paro.motivo!,
                  ),
                _ResumenRow(
                  icon: Icons.access_time_rounded,
                  label: 'Hora paro',
                  value:
                      '${paro.horaInicio}${paro.horaFinal != null ? '  →  ${paro.horaFinal}' : ' (sin fin)'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ResumenRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: _kTextMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  const TextStyle(color: _kTextSec, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? _kTextPrimary,
                fontSize: 13,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kPrimary),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: _kBorder, thickness: 1)),
      ],
    );
  }
}

// ─── Fila de horas ────────────────────────────────────────────────────────────

class _HorasRow extends StatelessWidget {
  final TextEditingController horaInicioCtrl;
  final TextEditingController horaFinCtrl;
  final VoidCallback onPickInicio;
  final VoidCallback onPickFin;

  const _HorasRow({
    required this.horaInicioCtrl,
    required this.horaFinCtrl,
    required this.onPickInicio,
    required this.onPickFin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            controller: horaInicioCtrl,
            label: 'Inicio real',
            icon: Icons.play_circle_rounded,
            iconColor: _kPrimary,
            onTap: onPickInicio,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Icon(Icons.arrow_forward_rounded,
                  color: _kTextMuted, size: 18),
              SizedBox(height: 4),
              Text('a',
                  style: TextStyle(
                      color: _kTextMuted,
                      fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          child: _TimeField(
            controller: horaFinCtrl,
            label: 'Fin real',
            icon: Icons.stop_circle_rounded,
            iconColor: _kRed,
            onTap: onPickFin,
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _TimeField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                      color: _kTextSec,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, __) => Text(
                val.text.isEmpty ? '--:--' : val.text,
                style: TextStyle(
                  color: val.text.isEmpty ? _kTextMuted : _kTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campo claro ──────────────────────────────────────────────────────────────

class _LightField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final IconData icon;
  final String? Function(String?)? validator;

  const _LightField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      cursorColor: _kPrimary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: _kTextSec, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding:
              const EdgeInsets.only(left: 14, right: 10, bottom: 60),
          child: Icon(icon, color: _kTextSec, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: _kCardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _kRed, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Selector de estado ───────────────────────────────────────────────────────

class _EstadoSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _EstadoSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EstadoOption(
          label: 'Completado',
          sublabel: 'Falla resuelta',
          icon: Icons.check_circle_rounded,
          color: _kPrimary,
          selected: value == 'resuelto',
          onTap: () => onChanged('resuelto'),
        ),
        const SizedBox(width: 10),
        _EstadoOption(
          label: 'En proceso',
          sublabel: 'Requiere seguimiento',
          icon: Icons.pending_actions_rounded,
          color: _kOrange,
          selected: value == 'en_proceso',
          onTap: () => onChanged('en_proceso'),
        ),
      ],
    );
  }
}

class _EstadoOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _EstadoOption({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.06) : _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : _kBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 26, color: selected ? color : _kTextMuted),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : _kTextSec,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  color: selected
                      ? color.withValues(alpha: 0.7)
                      : _kTextMuted,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón guardar ────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool cargando;
  final bool esEdicion;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.cargando,
    required this.esEdicion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: cargando ? 0.7 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: cargando ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kPrimary.withValues(alpha: 0.6),
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    esEdicion
                        ? Icons.save_rounded
                        : Icons.check_circle_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(esEdicion
                      ? 'Actualizar registro'
                      : 'Guardar trabajo realizado'),
                ],
              ),
      ),
    );
  }
}
