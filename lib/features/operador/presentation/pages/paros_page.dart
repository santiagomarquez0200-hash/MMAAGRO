import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/shared/widgets/connectivity_dot.dart';

class ParosPage extends StatefulWidget {
  final String registroId;
  final bool adminMode;

  const ParosPage({super.key, required this.registroId, this.adminMode = false});

  @override
  State<ParosPage> createState() => _ParosPageState();
}

class _ParosPageState extends State<ParosPage> {
  final List<_ParoData> _paros = [];
  bool _loadingParos = true;
  bool _huboCambios = false;

  @override
  void initState() {
    super.initState();
    _cargarParosExistentes();
    _guardarUltimoTab();
  }

  Future<void> _guardarUltimoTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_tab_${widget.registroId}', 'paros');
  }

  /// Carga los paros previamente registrados desde la base de datos local
  Future<void> _cargarParosExistentes() async {
    final result =
        await sl<RegistroRepository>().getRegistro(widget.registroId);
    result.fold(
      (_) => null,
      (registro) {
        if (!mounted) return;
        setState(() {
          for (final p in registro.paros) {
            _paros.add(_ParoData(
              tipoParoId: p.tipoParoId,
              tipoParoCodigo: p.tipoParoCodigo,
              tipoParoNombre: p.tipoParoNombre,
              motivo: p.motivo,
              equipo: p.equipo,
              horaInicio: p.horaInicio,
              horaFinal: p.horaFinal,
              galones: p.galones,
            ));
          }
        });
      },
    );
    if (mounted) setState(() => _loadingParos = false);
  }

  /// Muestra el modal para agregar un nuevo paro
  Future<void> _agregarParo() async {
    final catState = context.read<CatalogoBloc>().state;
    if (catState is! CatalogoLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cargando catálogos, por favor espere...')),
      );
      return;
    }

    final result = await showModalBottomSheet<_ParoData>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AgregarParoSheet(
            tiposParo: catState.tiposParo,
            fallasMecanicas: catState.fallasMecanicas,
          ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _paros.add(result);
        _huboCambios = true;
      });

      // Disparar evento BLoC para guardar en BD local y sincronizar
      context.read<RegistroBloc>().add(RegistroParoAgregarRequested(
            params: AgregarParoParams(
              registroId: widget.registroId,
              tipoParoId: result.tipoParoId,
              tipoParoCodigo: result.tipoParoCodigo,
              tipoParoNombre: result.tipoParoNombre,
              motivo: result.motivo,
              equipo: result.equipo,
              horaInicio: result.horaInicio,
              horaFinal: result.horaFinal,
              galones: result.galones,
              fallaMecanicaId: result.fallaMecanicaId,
              fallaMecanicaNombre: result.fallaMecanicaNombre,
            ),
          ));
    }
  }

  /// Navega al home (o vuelve atrás en admin mode) — los paros ya fueron guardados al confirmar cada uno.
  void _guardarYSalir() {
    if (_paros.isNotEmpty && !widget.adminMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${_paros.length} paro(s) registrado(s) correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (widget.adminMode) {
      context.pop(_huboCambios);
    } else {
      context.go('/operador/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B5E20);

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Paros de Equipo'),
        centerTitle: true,
        actions: widget.adminMode
            ? const [ConnectivityDot()]
            : [
                const ConnectivityDot(),
                IconButton(
                  onPressed: () => context.go('/operador/home'),
                  icon: const Icon(Icons.home),
                  tooltip: 'Ir al inicio',
                ),
              ],
      ),
      // Cuerpo principal: muestra lista de paros o estado vacío
      body: _loadingParos
          ? const Center(child: CircularProgressIndicator())
          : _paros.isEmpty
              ? _buildEmptyState()
              : _buildParosList(),
      // Botón flotante para agregar paros
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarParo,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Agregar Paro', style: TextStyle(color: Colors.white)),
      ),
      // Barra inferior con acciones
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );

    if (!widget.adminMode) return scaffold;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_huboCambios);
      },
      child: scaffold,
    );
  }

  /// Estado vacío cuando no hay paros registrados
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_outline,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No hay paros registrados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca el botón + para agregar un nuevo paro',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Lista de paros registrados
  Widget _buildParosList() {
    const primaryColor = Color(0xFF1B5E20);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paros.length,
      itemBuilder: (context, index) {
        final paro = _paros[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.pause_circle, color: primaryColor),
            ),
            title: Text(
              paro.tipoParoNombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Horario: ${paro.horaInicio} - ${paro.horaFinal ?? 'En curso'}'),
                if (paro.fallaMecanicaNombre != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      Icon(Icons.build_circle_outlined,
                          size: 13, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          paro.fallaMecanicaNombre!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
                if (paro.motivo != null)
                  Text(
                    'Motivo: ${paro.motivo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: paro.galones != null
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '${paro.galones} gal',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }

  /// Barra inferior con botones de acción
  Widget _buildBottomBar(Color primaryColor) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: widget.adminMode
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardarYSalir,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<RegistroBloc, RegistroState>(
                        builder: (context, state) {
                          final isSyncing = state is RegistroLoading;
                          return OutlinedButton.icon(
                            onPressed: isSyncing ? null : _guardarYSalir,
                            icon: isSyncing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label:
                                Text(isSyncing ? 'Guardando...' : 'Guardar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // BUG-13: disable Cerrar Turno while a paro save is in progress.
                    Expanded(
                      child: BlocBuilder<RegistroBloc, RegistroState>(
                        builder: (context, state) {
                          final isSyncing = state is RegistroLoading;
                          return ElevatedButton.icon(
                            onPressed: isSyncing
                                ? null
                                : () => context.go(
                                    '/registro/${widget.registroId}/cerrar'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Cerrar Turno'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Estilo neutro por categoría de falla ────────────────────────────────────

({Color color, Color bg, IconData icon}) _categoriaStyle(String cat) {
  switch (cat.toUpperCase()) {
    case 'ELECTRICO':
      return (
        color: const Color(0xFF424242),
        bg: const Color(0xFFF5F5F5),
        icon: Icons.electric_bolt
      );
    case 'HIDRAULICO':
      return (
        color: const Color(0xFF424242),
        bg: const Color(0xFFF5F5F5),
        icon: Icons.water
      );
    case 'LUBRICACION':
      return (
        color: const Color(0xFF424242),
        bg: const Color(0xFFF5F5F5),
        icon: Icons.opacity
      );
    case 'FISICOQUIMICO':
      return (
        color: const Color(0xFF424242),
        bg: const Color(0xFFF5F5F5),
        icon: Icons.science
      );
    default: // MECANICO
      return (
        color: const Color(0xFF424242),
        bg: const Color(0xFFF5F5F5),
        icon: Icons.build
      );
  }
}

/// Campo de selección de falla mecánica agrupado por categoría.
/// Muestra el valor actual como un campo outlined y abre un bottom-sheet
/// con secciones por categoría (MECANICO, ELECTRICO, HIDRAULICO, …).
class _FallaMecanicaPicker extends StatelessWidget {
  final List<FallaMecanica> fallasMecanicas;
  final FallaMecanica? seleccionada;
  final ValueChanged<FallaMecanica?> onChanged;

  const _FallaMecanicaPicker({
    required this.fallasMecanicas,
    required this.seleccionada,
    required this.onChanged,
  });

  // Orden fijo de presentación de categorías
  static const _ordenCategorias = [
    'MECANICO',
    'ELECTRICO',
    'HIDRAULICO',
    'LUBRICACION',
    'FISICOQUIMICO',
  ];

  Map<String, List<FallaMecanica>> get _grupos {
    final map = <String, List<FallaMecanica>>{};
    for (final f in fallasMecanicas) {
      map.putIfAbsent(f.categoria.toUpperCase(), () => []).add(f);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final style = seleccionada != null
        ? _categoriaStyle(seleccionada!.categoria)
        : null;

    return FormField<FallaMecanica>(
      initialValue: seleccionada,
      validator: (_) =>
          seleccionada == null ? 'Seleccione el tipo de falla' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _abrirPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tipo de falla mecánica *',
                  prefixIcon: Icon(
                    style?.icon ?? Icons.build_circle,
                    color: style?.color ?? Colors.grey,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  errorText: field.errorText,
                  filled: seleccionada != null,
                  fillColor: const Color(0xFFF5F5F5),
                ),
                child: seleccionada == null
                    ? const Text('Seleccionar…',
                        style: TextStyle(color: Colors.grey))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            seleccionada!.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121)),
                          ),
                          if (seleccionada!.componentesAfectados != null)
                            Text(
                              seleccionada!.componentesAfectados!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF757575)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirPicker(BuildContext context) async {
    final grupos = _grupos;
    final result = await showModalBottomSheet<FallaMecanica>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Icon(Icons.build_circle, color: Color(0xFFBF360C)),
                  SizedBox(width: 10),
                  Text('Tipo de falla mecánica',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final cat in _ordenCategorias)
                      if (grupos.containsKey(cat)) ...[
                        _buildCatHeader(cat, grupos[cat]!.length),
                        for (final falla in grupos[cat]!)
                          _buildFallaItem(context, falla),
                      ],
                    // Categorías no previstas
                    for (final cat in grupos.keys
                        .where((c) => !_ordenCategorias.contains(c))) ...[
                      _buildCatHeader(cat, grupos[cat]!.length),
                      for (final falla in grupos[cat]!)
                        _buildFallaItem(context, falla),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  Widget _buildCatHeader(String categoria, int count) {
    final s = _categoriaStyle(categoria);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: s.color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(s.icon, color: s.color, size: 18),
        const SizedBox(width: 8),
        Text(categoria,
            style: TextStyle(
                color: s.color,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const Spacer(),
        Text('$count falla${count != 1 ? 's' : ''}',
            style:
                TextStyle(color: s.color.withValues(alpha: 0.8), fontSize: 12)),
      ]),
    );
  }

  Widget _buildFallaItem(BuildContext context, FallaMecanica falla) {
    final isSelected = seleccionada?.id == falla.id;
    return ListTile(
      onTap: () => Navigator.of(context).pop(falla),
      selected: isSelected,
      selectedTileColor: const Color(0xFFF0F0F0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF212121) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBDBDBD)),
        ),
        child: Center(
          child: Text(
            falla.codigo.length > 4
                ? falla.codigo.substring(0, 4)
                : falla.codigo,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF424242),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      title: Text(falla.nombre,
          style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF212121))),
      subtitle: falla.componentesAfectados != null
          ? Text(falla.componentesAfectados!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis)
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF212121))
          : null,
    );
  }
}

/// Modelo de datos para un paro (almacenado en memoria)
class _ParoData {
  final int tipoParoId;
  final String tipoParoCodigo;
  final String tipoParoNombre;
  final String? motivo;
  final String? equipo;
  final String horaInicio;
  final String? horaFinal;
  final double? galones;
  final int? fallaMecanicaId;
  final String? fallaMecanicaNombre;

  const _ParoData({
    required this.tipoParoId,
    required this.tipoParoCodigo,
    required this.tipoParoNombre,
    this.motivo,
    this.equipo,
    required this.horaInicio,
    this.horaFinal,
    this.galones,
    this.fallaMecanicaId,
    this.fallaMecanicaNombre,
  });
}

/// Hoja modal para agregar un nuevo paro
/// Muestra campos dinámicos según el tipo de paro seleccionado:
/// - COMBUSTIBLE: requiere galones
/// - MECANICO: requiere equipo afectado
class _AgregarParoSheet extends StatefulWidget {
  final List<TipoParo> tiposParo;
  final List<FallaMecanica> fallasMecanicas;

  const _AgregarParoSheet({
    required this.tiposParo,
    required this.fallasMecanicas,
  });

  @override
  State<_AgregarParoSheet> createState() => _AgregarParoSheetState();
}

class _AgregarParoSheetState extends State<_AgregarParoSheet> {
  final _formKey = GlobalKey<FormState>();
  TipoParo? _tipoParo;
  FallaMecanica? _fallaMecanica;
  final _motivoCtrl = TextEditingController();
  final _equipoCtrl = TextEditingController();
  final _horaInicioCtrl = TextEditingController();
  final _horaFinalCtrl = TextEditingController();
  final _galonesCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _equipoCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFinalCtrl.dispose();
    _galonesCtrl.dispose();
    super.dispose();
  }

  /// Muestra el selector de hora
  Future<void> _pickTime(TextEditingController ctrl) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
          ),
          child: child!,
        );
      },
    );
    if (t != null) {
      setState(() {
        ctrl.text =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  /// Valida y envía el formulario
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_tipoParo == null) return;

      final isMecanicoSubmit = _tipoParo!.codigo == 'MECANICO';
      Navigator.pop(
        context,
        _ParoData(
          tipoParoId: _tipoParo!.id,
          tipoParoCodigo: _tipoParo!.codigo,
          tipoParoNombre: _tipoParo!.nombre,
          motivo: _motivoCtrl.text.trim().isNotEmpty
              ? _motivoCtrl.text.trim()
              : null,
          equipo: _equipoCtrl.text.trim().isNotEmpty
              ? _equipoCtrl.text.trim()
              : null,
          horaInicio: _horaInicioCtrl.text,
          horaFinal: isMecanicoSubmit
              ? null
              : (_horaFinalCtrl.text.isNotEmpty ? _horaFinalCtrl.text : null),
          galones: double.tryParse(_galonesCtrl.text),
          fallaMecanicaId: _fallaMecanica?.id,
          fallaMecanicaNombre: _fallaMecanica?.nombre,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCombustible = _tipoParo?.codigo == 'COMBUSTIBLE';
    final isMecanico = _tipoParo?.codigo == 'MECANICO';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador visual de la hoja modal
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Título
              const Text(
                'Registrar Paro de Equipo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Campo: Tipo de paro (dropdown)
              DropdownButtonFormField<TipoParo>(
                initialValue: _tipoParo,
                validator: (value) => value == null ? 'Campo requerido' : null,
                decoration: InputDecoration(
                  labelText: 'Tipo de paro *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.tiposParo
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.nombre)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoParo = v),
              ),
              const SizedBox(height: 16),

              // Campos de hora (inicio y final)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _horaInicioCtrl,
                      readOnly: true,
                      validator: (value) => (value?.isEmpty ?? true) ? 'Requerido' : null,
                      onTap: () => _pickTime(_horaInicioCtrl),
                      decoration: InputDecoration(
                        labelText: 'Hora inicio *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _horaFinalCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(_horaFinalCtrl),
                      decoration: InputDecoration(
                        labelText: 'Hora final',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.access_time_filled),
                      ),
                    ),
                  ),
                ],
              ),

              // Campo adicional para paros de tipo COMBUSTIBLE (galones)
              if (isCombustible) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _galonesCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Galones suministrados',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.local_gas_station),
                  ),
                ),
              ],

              // Campos adicionales para paros de tipo MECANICO
              if (isMecanico) const SizedBox(height: 16),
              Visibility(
                visible: isMecanico,
                child: _FallaMecanicaPicker(
                  fallasMecanicas: widget.fallasMecanicas,
                  seleccionada: _fallaMecanica,
                  onChanged: (f) => setState(() => _fallaMecanica = f),
                ),
              ),
              if (isMecanico) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _equipoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Equipo/Componente afectado',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.build),
                  ),
                ),
              ],

              // Campo de observaciones/motivo
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observaciones / Motivo',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),

              // Botón de confirmación
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Confirmar Registro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
