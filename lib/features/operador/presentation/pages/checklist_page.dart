import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/shared/widgets/connectivity_dot.dart';

class ChecklistPage extends StatefulWidget {
  final String registroId;
  final bool adminMode;
  const ChecklistPage({super.key, required this.registroId, this.adminMode = false});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage>
    with TickerProviderStateMixin {
  final Map<int, String> _resultados = {};
  final Map<int, String> _observaciones = {};
  final Map<int, String> _fotoUrls = {};
  Map<int, String> _initialResultados = {};
  Map<int, String> _initialObservaciones = {};
  String? _categoriaSeleccionada;
  late ScrollController _scrollController;
  Timer? _obsDebounce;

  /// Tipo del registro ('tractor' o 'vehiculo'). Se carga desde SQLite al init.
  /// Determina qué ítems del catálogo se muestran en el checklist.
  String _tipoRegistro = 'tractor';
  String? _implementoCodigo;

  static const _categoriaImplementoPorPrefijo = <String, String>{
    'AZU': 'Inspeccionar azufradora',
    'ELE': 'Inspeccionar electroestática agrícola',
    'TRI': 'Inspeccionar picadora agrícola',
    'CVI': 'Inspeccionar carreta viñatera',
    'CHI': 'Inspeccionar carreta hidráulica',
    'ROT': 'Inspeccionar rotocultor',
  };

  String get _categoriaImplemento {
    final codigo = _normalizarCodigo(_implementoCodigo);
    for (final entry in _categoriaImplementoPorPrefijo.entries) {
      if (codigo.startsWith(entry.key)) return entry.value;
    }
    return 'Inspeccionar Implemento';
  }

  String _normalizarCodigo(String? value) =>
      (value ?? '').trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();

  String _tipoRegistroNormalizado(String value) =>
      value.trim().toLowerCase();

    String _normalizarCategoria(String value) => value
      .replaceAll(RegExp('[áÁ]'), 'a')
      .replaceAll(RegExp('[éÉ]'), 'e')
      .replaceAll(RegExp('[íÍ]'), 'i')
      .replaceAll(RegExp('[óÓ]'), 'o')
      .replaceAll(RegExp('[úÚ]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('Ñ', 'N')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();

  String _categoriaCanonica(String value) {
    final normalized = _normalizarCategoria(value);
    for (final categoria in [
      'Inspeccionar Tractor',
      'Inspeccionar Implemento',
      ..._categoriaImplementoPorPrefijo.values,
    ]) {
      if (_normalizarCategoria(categoria) == normalized) return categoria;
    }
    return value.trim();
  }

  List<ChecklistItem> _itemsVisibles(List<ChecklistItem> items) {
    final tipoRegistro = _tipoRegistroNormalizado(_tipoRegistro);
    final activos = items
      .where((i) =>
        i.activo && _tipoRegistroNormalizado(i.tipoRegistro) == tipoRegistro)
        .toList();
    if (tipoRegistro != 'tractor') return activos;

    final categoriasPermitidas = {
      _normalizarCategoria('Inspeccionar Tractor'),
      _normalizarCategoria(_categoriaImplemento),
    };
    return activos
        .where((i) => categoriasPermitidas.contains(
            _normalizarCategoria(i.categoriaNombre)))
        .toList();
  }

  // BUG-08: stored before dispatching so the BlocListener can navigate correctly.
  bool? _pendingRequiereBines;
  String? _pendingTurno;

  bool get _hayCambios =>
      !_mapEquals(_resultados, _initialResultados) ||
      !_mapEquals(_observaciones, _initialObservaciones);

  bool _mapEquals(Map<int, String> a, Map<int, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _restaurarEstadoPrevio();
    _guardarUltimoTab();
  }

  Future<void> _guardarUltimoTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_tab_${widget.registroId}', 'checklist');
  }

  @override
  void dispose() {
    _obsDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restaurarEstadoPrevio() async {
    // Leer el tipo de registro real para filtrar el checklist correctamente.
    // Un 'vehiculo' tiene ítems propios distintos a los de 'tractor'.
    final regResult =
        await sl<RegistroRepository>().getRegistro(widget.registroId);
    regResult.fold(
      (_) => null,
      (r) {
        if (mounted) {
          setState(() {
            _tipoRegistro = r.tipoRegistro;
            _implementoCodigo = r.implementoCodigo;
            _categoriaSeleccionada = null;
          });
        }
      },
    );

    final result =
        await sl<RegistroRepository>().getChecklist(widget.registroId);
    result.fold(
      (_) => null,
      (savedItems) {
        if (!mounted || savedItems.isEmpty) return;
        setState(() {
          for (final item in savedItems) {
            _resultados[item.itemId] = item.resultado;
            if (item.observacion != null && item.observacion!.isNotEmpty) {
              _observaciones[item.itemId] = item.observacion!;
            }
          }
          // Snapshot inicial para detectar cambios en admin mode
          _initialResultados = Map.from(_resultados);
          _initialObservaciones = Map.from(_observaciones);
        });
      },
    );
  }

  void _setResultado(int itemId, String resultado) {
    setState(() {
      _resultados[itemId] = resultado;
      if (resultado != 'mal') _observaciones.remove(itemId);
    });
    _autoSave();
  }

  // Guarda el estado actual (parcial) sin validar completitud.
  // Permite que _restaurarEstadoPrevio recupere el progreso si el usuario sale.
  void _autoSave() {
    final catState = context.read<CatalogoBloc>().state;
    if (catState is! CatalogoLoaded || _resultados.isEmpty) return;
    final activos = _itemsVisibles(catState.checklistItems);
    final itemsMap = {for (final i in activos) i.id: i};
    final resultados = _resultados.entries
        .map((e) => ChecklistResultadoInput(
              itemId: e.key,
              itemNombre: itemsMap[e.key]?.nombre ?? '',
              categoriaNombre: itemsMap[e.key]?.categoriaNombre ?? '',
              resultado: e.value,
              observacion: _observaciones[e.key],
            ))
        .toList();
    // isAutoSave: true → el BLoC guarda silenciosamente sin emitir
    // RegistroChecklistGuardadoExitoso, evitando que el BlocListener
    // de navegación dispare en cada item marcado.
    context.read<RegistroBloc>().add(
          RegistroChecklistGuardarRequested(
            registroId: widget.registroId,
            resultados: resultados,
            isAutoSave: true,
          ),
        );
  }

  // Guarda el progreso actual como borrador (sin validar completitud).
  void _guardarBorrador() {
    _autoSave();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Checklist guardado como borrador'),
      backgroundColor: Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _guardar() async {
    final catState = context.read<CatalogoBloc>().state;
    if (catState is! CatalogoLoaded) return;

    final activos = _itemsVisibles(catState.checklistItems);

    if (widget.adminMode) return; // En admin mode no hay botón de guardar; los cambios se sincronizan desde EditorAdminPage.

    // Validación de completitud (solo modo operador)
    if (_resultados.length < activos.length) {
      final faltantes =
          activos.where((i) => !_resultados.containsKey(i.id)).toList();
      _mostrarAlerta(
          'Checklist Incompleto',
          'Faltan ${faltantes.length} de ${activos.length} ítems. El primer ítem pendiente es: ${faltantes.first.nombre}',
          Colors.orange.shade800);
      return;
    }

    // Validación de observaciones para 'MAL'
    final malSinObservacion = _resultados.entries.any((e) {
      if (e.value != 'mal') return false;
      final obs = _observaciones[e.key];
      return obs == null || obs.trim().isEmpty;
    });

    if (malSinObservacion) {
      _mostrarAlerta(
          'Observación Requerida',
          'Todos los ítems marcados como MAL deben tener una descripción del problema.',
          Colors.redAccent);
      return;
    }

    final itemsMap = {for (final i in activos) i.id: i};
    final resultados = _resultados.entries
        .map((e) => ChecklistResultadoInput(
              itemId: e.key,
              itemNombre: itemsMap[e.key]?.nombre ?? '',
              categoriaNombre: itemsMap[e.key]?.categoriaNombre ?? '',
              resultado: e.value,
              observacion: _observaciones[e.key],
              fotoUrl: _fotoUrls[e.key],
            ))
        .toList();

    // BUG-08: resolve navigation destination BEFORE dispatching so the
    // BlocListener has the values ready when the success state arrives.
    final registroResult =
        await sl<RegistroRepository>().getRegistro(widget.registroId);
    if (!mounted) return;

    _pendingRequiereBines = registroResult.fold(
      (_) => false,
      (r) => r.procesoCodigo.toUpperCase() == 'COSEC',
    );
    _pendingTurno = registroResult.fold((_) => 'dia', (r) => r.turno);

    // Dispatch the save event — navigation happens in the BlocListener below.
    context.read<RegistroBloc>().add(
          RegistroChecklistGuardarRequested(
            registroId: widget.registroId,
            resultados: resultados,
          ),
        );
  }

  void _mostrarAlerta(String titulo, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(msg),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BUG-08: listener drives navigation only after the BLoC confirms success.
    Widget wrapWithListener(Widget child) {
      return BlocListener<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroChecklistGuardadoExitoso) {
            if (!mounted) return;
            if (_pendingRequiereBines == true) {
              context.go(
                '/registro/${widget.registroId}/bines?turno=${_pendingTurno ?? 'dia'}',
              );
            } else {
              context.go('/registro/${widget.registroId}/paros');
            }
          }
        },
        child: child,
      );
    }

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text('Inspección Técnica',
                style: TextStyle(fontSize: 18, color: Colors.white)),
            Text('CHECKLIST OPERATIVO',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: const [ConnectivityDot()],
      ),
      body: BlocBuilder<CatalogoBloc, CatalogoState>(
        builder: (context, state) {
          if (state is! CatalogoLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final activos = _itemsVisibles(state.checklistItems);
          final grouped = _groupByCategoria(
            activos,
            categoriasVacias: _tipoRegistroNormalizado(_tipoRegistro) == 'tractor'
                ? ['Inspeccionar Tractor', _categoriaImplemento]
                : const [],
          );
          if (grouped.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando ítems del checklist...'),
                ],
              ),
            );
          }
          if (_categoriaSeleccionada == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _categoriaSeleccionada ??= grouped.keys.first);
              }
            });
          }
          final currentCategoria = _categoriaSeleccionada ?? grouped.keys.first;

          return Column(
            children: [
              _buildProgressHeader(activos.length, _resultados.length),
              _buildCategorySelector(grouped.keys.toList()),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView(
                    key: ValueKey(currentCategoria),
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (grouped[currentCategoria]!.isEmpty)
                        _buildEmptyCategory(currentCategoria)
                      else
                        ...grouped[currentCategoria]!
                            .map((item) => _ChecklistItemCard(
                                  item: item,
                                  resultado: _resultados[item.id],
                                  observacion: _observaciones[item.id],
                                  onResultado: (r) => _setResultado(item.id, r),
                                  onObservacion: (o) {
                                    _observaciones[item.id] = o;
                                    _obsDebounce?.cancel();
                                    _obsDebounce = Timer(
                                      const Duration(milliseconds: 600),
                                      _autoSave,
                                    );
                                  },
                                )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.adminMode
          ? null // Sin botón: cambios se sincronizan desde EditorAdminPage
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: 'checklist_guardar',
                      onPressed: _guardarBorrador,
                      backgroundColor: const Color(0xFF388E3C),
                      label: const Text('GUARDAR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: 'checklist_siguiente',
                      onPressed: _guardar,
                      backgroundColor: const Color(0xFF1B5E20),
                      label: const Text('SIGUIENTE',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );

    if (!widget.adminMode) return wrapWithListener(scaffold);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_hayCambios);
      },
      child: wrapWithListener(scaffold),
    );
  }

  Widget _buildCategorySelector(List<String> categorias) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final cat = categorias[index];
          final isSelected = _categoriaSeleccionada == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(cat, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (val) => setState(() => _categoriaSeleccionada = cat),
              selectedColor: const Color(0xFF1B5E20),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade300)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(int total, int completados) {
    final porcentaje = total > 0 ? completados / total : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Avance Total',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(porcentaje * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: porcentaje,
              backgroundColor: Colors.white24,
              color: Colors.greenAccent,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<ChecklistItem>> _groupByCategoria(
      List<ChecklistItem> items, {List<String> categoriasVacias = const []}) {
    final grouped = <String, List<ChecklistItem>>{};
    for (final categoria in categoriasVacias) {
      grouped[_categoriaCanonica(categoria)] = [];
    }
    for (final item in items) {
      grouped.putIfAbsent(_categoriaCanonica(item.categoriaNombre), () => [])
          .add(item);
    }
    return grouped;
  }

  Widget _buildEmptyCategory(String categoria) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.fact_check_outlined,
              size: 42, color: Colors.orange.shade700),
          const SizedBox(height: 12),
          Text(
            categoria,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay ítems configurados para esta inspección.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemCard extends StatefulWidget {
  final ChecklistItem item;
  final String? resultado;
  final String? observacion;
  final Function(String) onResultado;
  final Function(String) onObservacion;

  const _ChecklistItemCard({
    required this.item,
    required this.resultado,
    required this.observacion,
    required this.onResultado,
    required this.onObservacion,
  });

  @override
  State<_ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends State<_ChecklistItemCard> {
  late TextEditingController _obsCtrl;

  @override
  void initState() {
    super.initState();
    _obsCtrl = TextEditingController(text: widget.observacion ?? '');
  }

  @override
  void didUpdateWidget(_ChecklistItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the controller if the parent restored a saved observacion
    // and the controller doesn't already have that value.
    if (widget.observacion != null &&
        widget.observacion!.isNotEmpty &&
        _obsCtrl.text != widget.observacion) {
      _obsCtrl.text = widget.observacion!;
      _obsCtrl.selection =
          TextSelection.collapsed(offset: _obsCtrl.text.length);
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMal = widget.resultado == 'mal';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.resultado != null
                ? _getColor(widget.resultado!).withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: _getColor(widget.resultado).withValues(alpha: 0.1),
              child: Text('${widget.item.orden}',
                  style: TextStyle(
                      color: _getColor(widget.resultado),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            title: Text(widget.item.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: widget.resultado == null
                ? const Text('Pendiente',
                    style: TextStyle(fontSize: 11, color: Colors.orange))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _OptionBtn(
                    label: 'BIEN',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    isSelected: widget.resultado == 'bien',
                    onTap: () => widget.onResultado('bien')),
                const SizedBox(width: 8),
                _OptionBtn(
                    label: 'MAL',
                    icon: Icons.error_outline,
                    color: Colors.red,
                    isSelected: widget.resultado == 'mal',
                    onTap: () => widget.onResultado('mal')),
              ],
            ),
          ),
          if (isMal)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _obsCtrl,
                onChanged: (o) {
                  widget.onObservacion(o);
                },
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Describa el fallo detectado...',
                  prefixIcon: const Icon(Icons.edit_note, color: Colors.red),
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getColor(String? res) {
    switch (res) {
      case 'bien':
        return Colors.green;
      case 'mal':
        return Colors.red;
      case 'na':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}

class _OptionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isSelected,
      required this.onTap});

  static const _filledIcons = {
    'BIEN': Icons.check_circle_rounded,
    'MAL': Icons.cancel_rounded,
    'N/A': Icons.do_not_disturb_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final filledIcon = _filledIcons[label] ?? icon;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 0 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : icon,
                color: isSelected ? Colors.white : color,
                size: 18,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
