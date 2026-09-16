import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/features/operador/presentation/pages/firma_page.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_event.dart';
import 'package:agro_aplicaciones/shared/widgets/connectivity_dot.dart';
import 'package:agro_aplicaciones/shared/widgets/spinner_time_picker.dart';

/// Clase auxiliar para manejar la selección de lotes con su área trabajada
class LoteSeleccionado {
  final Lote lote;
  final double areaHa;
  final String? observacion;
  LoteSeleccionado({
    required this.lote,
    required this.areaHa,
    this.observacion,
  });
}

class CerrarTurnoPage extends StatefulWidget {
  final String registroId;

  /// Cuando es true el admin puede editar libremente sin bloqueos de hora.
  final bool adminMode;
  const CerrarTurnoPage(
      {super.key, required this.registroId, this.adminMode = false});

  @override
  State<CerrarTurnoPage> createState() => _CerrarTurnoPageState();
}

class _CerrarTurnoPageState extends State<CerrarTurnoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar datos finales del turno
  final _tractorFinalCtrl = TextEditingController();
  final _implementoFinalCtrl = TextEditingController();
  final _horaSalidaPuntoCtrl = TextEditingController();
  final _horaLlegadaTallerCtrl = TextEditingController();
  final _horaRefrigerioInicioCtrl = TextEditingController();
  final _horaRefrigerioFinCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  List<LoteSeleccionado> _lotesSeleccionados = [];
  Uint8List? _firmaBytes;
  String? _firmaBase64;
  bool _loadingData = true;
  Timer? _draftTimer;
  bool _draftReady = false; // evita guardar antes de que carguen los datos
  bool _cerrando = false; // BUG-21: previene doble-tap en Cerrar Turno
  // En adminMode: previene doble-tap en el botón "Guardar cambios" y en el back.
  bool _guardandoAdmin = false;

  // AdminMode: captura del estado inicial para detectar cambios reales.
  final Map<String, String> _initialFieldValues = {};
  List<LoteSeleccionado> _initialLotes = [];
  String? _initialFirmaBase64;
  bool _initialValuesCaptured = false;

  String get _draftKey => 'draft_cerrar_turno_${widget.registroId}';

  @override
  void initState() {
    super.initState();
    _cargarDatosExistentes();
    _guardarUltimoTab();
  }

  Future<void> _guardarUltimoTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_tab_${widget.registroId}', 'cerrar_turno');
  }

  Future<void> _cargarDatosExistentes() async {
    final result =
        await sl<RegistroRepository>().getRegistro(widget.registroId);
    // await aquí asegura que los setState del callback terminen antes de
    // continuar con _cargarBorrador y _captureInitialValues.
    await result.fold<Future<void>>(
      (_) async {},
      (registro) async {
        if (!mounted) return;

        // Pre-llenar lotes previamente guardados, reconstruyendo LoteSeleccionado
        // desde RegistroSector + catálogo local (necesitamos fincaIdErp del catálogo).
        if (registro.sectores.isNotEmpty) {
          final lotesDb = await sl<AppDatabase>().catalogoDao.getLotes();
          final lotesMap = {for (final l in lotesDb) l.idErp: l};
          final preseleccionados = <LoteSeleccionado>[];
          for (final sector in registro.sectores) {
            final loteData = lotesMap[sector.loteIdErp];
            final lote = Lote(
              idErp: sector.loteIdErp,
              loteCodigo: sector.loteCodigo,
              loteNombre: sector.loteNombre,
              fincaIdErp: loteData?.fincaIdErp ?? 0,
              fincaNombre: sector.fincaNombre,
              sublote: loteData?.sublote,
              areaHa: loteData?.areaHa,
              activo: true,
            );
            preseleccionados.add(LoteSeleccionado(
              lote: lote,
              areaHa: sector.areaTrabajada ?? loteData?.areaHa ?? 0.0,
              observacion: sector.observacion,
            ));
          }
          if (mounted) setState(() => _lotesSeleccionados = preseleccionados);
        }

        if (!mounted) return;
        setState(() {
          // Pre-llenar horómetros finales si ya fueron capturados
          if (registro.horometro?.tractorFinal != null) {
            _tractorFinalCtrl.text =
                registro.horometro!.tractorFinal!.toString();
          }
          if (registro.horometro?.implementoFinal != null) {
            _implementoFinalCtrl.text =
                registro.horometro!.implementoFinal!.toString();
          }
          // Pre-llenar tiempos de regreso
          if (registro.tiempoTurno?.horaSalidaPunto != null) {
            _horaSalidaPuntoCtrl.text = registro.tiempoTurno!.horaSalidaPunto!;
          }
          if (registro.tiempoTurno?.horaLlegadaTaller != null) {
            _horaLlegadaTallerCtrl.text =
                registro.tiempoTurno!.horaLlegadaTaller!;
          }
          if (registro.tiempoTurno?.horaRefrigerio != null) {
            final parsed = _parseHoraRefrigerio(
                registro.tiempoTurno!.horaRefrigerio);
            _horaRefrigerioInicioCtrl.text = parsed.inicio ?? '';
            _horaRefrigerioFinCtrl.text = parsed.fin ?? '';
          }
          // Pre-llenar observaciones
          if (registro.observacionesMaq != null) {
            _observacionesCtrl.text = registro.observacionesMaq!;
          }
          // Pre-llenar firma
          if (registro.firmaOperador != null) {
            try {
              _firmaBytes = base64Decode(registro.firmaOperador!);
              _firmaBase64 = registro.firmaOperador;
            } catch (_) {}
          }
        });
      },
    );
    // Overlay con borrador local (el usuario pudo haber llenado más campos
    // antes de salir sin presionar "Cerrar Turno").
    await _cargarBorrador();
    if (mounted) setState(() => _loadingData = false);

    // Capturar estado inicial DESPUÉS de que todos los datos cargaron.
    // Permite detectar si el usuario realmente cambió algo en adminMode.
    if (mounted && widget.adminMode) _captureInitialValues();

    // Iniciar guardado automático del borrador cada 3 segundos.
    _draftReady = true;
    _draftTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_draftReady && mounted) _guardarBorrador();
    });
  }

  /// Guarda una foto del estado actual de los campos para comparar después.
  /// Solo relevante en adminMode. Llamar después de que todos los datos carguen.
  void _captureInitialValues() {
    _initialFieldValues
      ..['tractor_final'] = _tractorFinalCtrl.text
      ..['implemento_final'] = _implementoFinalCtrl.text
      ..['hora_salida_punto'] = _horaSalidaPuntoCtrl.text
      ..['hora_llegada_taller'] = _horaLlegadaTallerCtrl.text
      ..['hora_refrigerio_inicio'] = _horaRefrigerioInicioCtrl.text
      ..['hora_refrigerio_fin'] = _horaRefrigerioFinCtrl.text
      ..['observaciones'] = _observacionesCtrl.text;
    _initialLotes = List.from(_lotesSeleccionados);
    _initialFirmaBase64 = _firmaBase64;
    _initialValuesCaptured = true;
  }

  /// Retorna true sólo si el usuario modificó algún campo respecto al estado
  /// capturado al entrar a la pantalla. Evita falsos positivos de dirty state.
  bool _hasChanges() {
    if (!_initialValuesCaptured) return false;
    if (_tractorFinalCtrl.text != (_initialFieldValues['tractor_final'] ?? '')) return true;
    if (_implementoFinalCtrl.text != (_initialFieldValues['implemento_final'] ?? '')) return true;
    if (_horaSalidaPuntoCtrl.text != (_initialFieldValues['hora_salida_punto'] ?? '')) return true;
    if (_horaLlegadaTallerCtrl.text != (_initialFieldValues['hora_llegada_taller'] ?? '')) return true;
    if (_horaRefrigerioInicioCtrl.text != (_initialFieldValues['hora_refrigerio_inicio'] ?? '')) return true;
    if (_horaRefrigerioFinCtrl.text != (_initialFieldValues['hora_refrigerio_fin'] ?? '')) return true;
    if (_observacionesCtrl.text != (_initialFieldValues['observaciones'] ?? '')) return true;
    if (_firmaBase64 != _initialFirmaBase64) return true;
    if (_lotesSeleccionados.length != _initialLotes.length) return true;
    for (int i = 0; i < _lotesSeleccionados.length; i++) {
      final cur = _lotesSeleccionados[i];
      final ini = _initialLotes[i];
      if (cur.lote.idErp != ini.lote.idErp || cur.areaHa != ini.areaHa) {
        return true;
      }
    }
    return false;
  }

  Future<void> _cargarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || !mounted) return;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        if ((d['tractor_final'] as String?)?.isNotEmpty == true) {
          _tractorFinalCtrl.text = d['tractor_final']!;
        }
        if ((d['implemento_final'] as String?)?.isNotEmpty == true) {
          _implementoFinalCtrl.text = d['implemento_final']!;
        }
        if ((d['hora_salida_punto'] as String?)?.isNotEmpty == true) {
          _horaSalidaPuntoCtrl.text = d['hora_salida_punto']!;
        }
        if ((d['hora_llegada_taller'] as String?)?.isNotEmpty == true) {
          _horaLlegadaTallerCtrl.text = d['hora_llegada_taller']!;
        }
        if ((d['hora_refrigerio_inicio'] as String?)?.isNotEmpty == true) {
          _horaRefrigerioInicioCtrl.text = d['hora_refrigerio_inicio']!;
        }
        if ((d['hora_refrigerio_fin'] as String?)?.isNotEmpty == true) {
          _horaRefrigerioFinCtrl.text = d['hora_refrigerio_fin']!;
        }
        if ((d['observaciones'] as String?)?.isNotEmpty == true) {
          _observacionesCtrl.text = d['observaciones']!;
        }
      });
    } catch (_) {}
  }

  Future<void> _guardarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _draftKey,
        jsonEncode({
          'tractor_final': _tractorFinalCtrl.text,
          'implemento_final': _implementoFinalCtrl.text,
          'hora_salida_punto': _horaSalidaPuntoCtrl.text,
          'hora_llegada_taller': _horaLlegadaTallerCtrl.text,
          'hora_refrigerio_inicio': _horaRefrigerioInicioCtrl.text,
          'hora_refrigerio_fin': _horaRefrigerioFinCtrl.text,
          'observaciones': _observacionesCtrl.text,
        }));
  }

  Future<void> _borrarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> _onPopRequested() async {
    if (widget.adminMode) {
      // Si no hay cambios reales → salir sin marcar la sección como editada.
      if (!_hasChanges()) {
        if (mounted && context.canPop()) context.pop(false);
        return;
      }
      // Hay cambios → guardar y notificar al editor (pop con true).
      await _guardarAdminYSalir();
      return;
    }
    await _guardarBorrador();
    if (mounted) context.pop();
  }

  /// Guarda los datos del cierre de turno directamente en SQLite (sin validación
  /// obligatoria), igual que las demás vistas de edición en adminMode.
  /// Al terminar popa con [true] para notificar a EditorAdminPage que hubo cambios.
  Future<void> _guardarAdminYSalir() async {
    if (_guardandoAdmin) return;
    setState(() => _guardandoAdmin = true);

    // Lotes — pueden estar vacíos; el supervisor completa datos parciales.
    final lotesStr = _lotesSeleccionados.isEmpty
        ? null
        : jsonEncode(_lotesSeleccionados
            .map((l) => {
                  'lote_id_erp': l.lote.idErp,
                  'finca_id_erp': l.lote.fincaIdErp,
                  'lote_codigo_snapshot': l.lote.loteCodigo,
                  'sublote_snapshot': l.lote.sublote ?? '',
                  'area_ha': l.areaHa,
                  'observacion': l.observacion,
                })
            .toList());

    // Refrigerio: ambos presentes o ninguno.
    final refInicio = _horaRefrigerioInicioCtrl.text.trim();
    final refFin = _horaRefrigerioFinCtrl.text.trim();
    final refStr = _buildHoraRefrigerio(refInicio, refFin);

    final result =
        await sl<RegistroRepository>().cerrarTurno(CerrarTurnoParams(
      registroId: widget.registroId,
      tractorFinal: double.tryParse(_tractorFinalCtrl.text.trim()),
      implementoFinal: double.tryParse(_implementoFinalCtrl.text.trim()),
      horaSalidaPunto: _horaSalidaPuntoCtrl.text.isNotEmpty
          ? _horaSalidaPuntoCtrl.text
          : null,
      horaLlegadaTaller: _horaLlegadaTallerCtrl.text.isNotEmpty
          ? _horaLlegadaTallerCtrl.text
          : null,
      horaRefrigerio: refStr,
      observacionesMaq: _observacionesCtrl.text.isNotEmpty
          ? _observacionesCtrl.text
          : null,
      lotesJson: lotesStr,
      firmaOperador: _firmaBase64,
    ));

    if (!mounted) return;
    setState(() => _guardandoAdmin = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar: ${failure.message}'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      )),
      (_) async {
        _draftReady = false;
        await _borrarBorrador();
        if (!mounted) return;
        if (context.canPop()) context.pop(true);
      },
    );
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _tractorFinalCtrl.dispose();
    _implementoFinalCtrl.dispose();
    _horaSalidaPuntoCtrl.dispose();
    _horaLlegadaTallerCtrl.dispose();
    _horaRefrigerioInicioCtrl.dispose();
    _horaRefrigerioFinCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  /// Captura la hora exacta del momento en que el usuario toca el campo.
  /// Si el campo ya tiene valor está bloqueado — solo el ✕ puede limpiarlo.
  /// En adminMode siempre abre el selector de hora libre.
  void _pickTime(TextEditingController ctrl) {
    if (widget.adminMode) {
      _pickTimeLibre(ctrl);
      return;
    }
    if (ctrl.text.isNotEmpty) return;
    final now = TimeOfDay.now();
    setState(() {
      ctrl.text =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
    if (_draftReady) _guardarBorrador();
  }

  /// Muestra el selector de hora estándar (sin bloqueo). Para campos opcionales
  /// como refrigerio donde el usuario elige libremente la hora.
  Future<void> _pickTimeLibre(TextEditingController ctrl) async {
    final partes = ctrl.text.split(':');
    final initial = partes.length == 2
        ? TimeOfDay(
            hour: int.tryParse(partes[0]) ?? TimeOfDay.now().hour,
            minute: int.tryParse(partes[1]) ?? TimeOfDay.now().minute,
          )
        : TimeOfDay.now();
    final picked = await showSpinnerTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        ctrl.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      if (_draftReady) _guardarBorrador();
    }
  }

  /// Navega a la selección de lotes y actualiza el estado local
  Future<void> _seleccionarLotes() async {
    final selected = await Navigator.push<List<LoteSeleccionado>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LotesPickerPage(seleccionadosInicial: _lotesSeleccionados),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _lotesSeleccionados = selected);
    }
  }

  Future<void> _abrirFirma() async {
    final Uint8List? png = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const FirmaPage()),
    );
    if (png != null && mounted) {
      setState(() {
        _firmaBytes = png;
        _firmaBase64 = base64Encode(png);
      });
    }
  }

  static String? _buildHoraRefrigerio(String? inicio, String? fin) {
    final inicioTrim = inicio?.trim() ?? '';
    final finTrim = fin?.trim() ?? '';

    if (inicioTrim.isEmpty && finTrim.isEmpty) return null;
    if (inicioTrim.isEmpty || finTrim.isEmpty) return null;

    return '$inicioTrim - $finTrim';
  }

  static ({String? inicio, String? fin}) _parseHoraRefrigerio(String? raw) {
    if (raw == null) return (inicio: null, fin: null);

    final cleaned = raw.trim();
    if (cleaned.isEmpty || cleaned == '-') {
      return (inicio: null, fin: null);
    }

    final compact = cleaned.replaceAll(RegExp(r'\s+'), '');
    final parts = compact.split('-');
    if (parts.length == 2) {
      final inicio = parts[0].trim();
      final fin = parts[1].trim();
      return (
        inicio: inicio.isEmpty ? null : inicio,
        fin: fin.isEmpty ? null : fin,
      );
    }

    return (inicio: null, fin: null);
  }

  /// Valida y dispara el evento de cierre en el BLoC para persistencia local
  void _cerrarTurno() {
    if (_cerrando) return;
    setState(() => _cerrando = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _cerrando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complete todos los campos requeridos.')));
      return;
    }

    if (_lotesSeleccionados.isEmpty) {
      setState(() => _cerrando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un lote trabajado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación de refrigerio: ambos campos llenos o ambos vacíos
    final refInicio = _horaRefrigerioInicioCtrl.text.trim();
    final refFin = _horaRefrigerioFinCtrl.text.trim();
    if (refInicio.isEmpty != refFin.isEmpty) {
      setState(() => _cerrando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ingrese ambos tiempos de refrigerio o déjelos vacíos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Serialización de lotes — incluye observacion para poblar CLI547_MMA_REGISTROS_LOTES.observacion
    final lotesJson = jsonEncode(_lotesSeleccionados
        .map((l) => {
              'lote_id_erp': l.lote.idErp,
              'finca_id_erp': l.lote.fincaIdErp,
              'lote_codigo_snapshot': l.lote.loteCodigo,
              'sublote_snapshot': l.lote.sublote ?? '',
              'area_ha': l.areaHa,
              'observacion': l.observacion,
            })
        .toList());

    context.read<RegistroBloc>().add(RegistroCerrarTurnoRequested(
          params: CerrarTurnoParams(
            registroId: widget.registroId,
            tractorFinal: double.tryParse(_tractorFinalCtrl.text),
            implementoFinal: double.tryParse(_implementoFinalCtrl.text),
            horaSalidaPunto: _horaSalidaPuntoCtrl.text.isNotEmpty
                ? _horaSalidaPuntoCtrl.text
                : null,
            horaLlegadaTaller: _horaLlegadaTallerCtrl.text.isNotEmpty
                ? _horaLlegadaTallerCtrl.text
                : null,
            horaRefrigerio: _buildHoraRefrigerio(
              _horaRefrigerioInicioCtrl.text,
              _horaRefrigerioFinCtrl.text,
            ),
            observacionesMaq: _observacionesCtrl.text.isNotEmpty
                ? _observacionesCtrl.text
                : null,
            lotesJson: lotesJson,
            firmaOperador: _firmaBase64,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopRequested();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          title: const Text('Cerrar Turno'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _onPopRequested,
          ),
          actions: const [ConnectivityDot()],
        ),
        body: BlocListener<RegistroBloc, RegistroState>(
          listener: (context, state) {
            if (state is RegistroOperacionExitosa) {
              setState(() => _cerrando = false);
              _draftReady = false;
              _borrarBorrador(); // borrador ya no necesario
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Turno cerrado correctamente'),
                  backgroundColor: Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
              if (widget.adminMode) {
                if (context.canPop()) context.pop(true);
              } else {
                // Iniciar sync inmediatamente para que el outbox no espere al siguiente ciclo
                context.read<SyncBloc>().add(const SyncManualRequested());
                context.go('/operador/home');
              }
            } else if (state is RegistroError) {
              setState(() => _cerrando = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          child: _loadingData
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCard('Horómetros Finales', [
                        _buildTextField(_tractorFinalCtrl,
                            'Horómetro tractor final *', Icons.speed,
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Requerido'
                                : null),
                        const SizedBox(height: 12),
                        _buildTextField(_implementoFinalCtrl,
                            'Horómetro implemento final', Icons.speed),
                      ]),
                      const SizedBox(height: 12),
                      _buildCard('Tiempos de Regreso', [
                        _buildTimeField(
                            _horaSalidaPuntoCtrl, 'Hora salida del punto *',
                            showClear: true,
                            freePick: true,
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Requerido' : null),
                        const SizedBox(height: 12),
                        _buildTimeField(
                            _horaLlegadaTallerCtrl, 'Hora llegada al taller *',
                            showClear: true,
                            freePick: widget.adminMode,
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Requerido' : null),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTimeField(
                                    _horaRefrigerioInicioCtrl,
                                    'Refrigerio Inicio',
                                    freePick: true)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildTimeField(
                                    _horaRefrigerioFinCtrl, 'Refrigerio Fin',
                                    freePick: true)),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildCard('Lotes Trabajados', [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Seleccionar lotes',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(_lotesSeleccionados.isEmpty
                              ? 'Ninguno seleccionado'
                              : '${_lotesSeleccionados.length} lote(s) seleccionado(s)'),
                          trailing: const Icon(Icons.chevron_right,
                              color: Color(0xFF1B5E20)),
                          onTap: _seleccionarLotes,
                        ),
                        if (_lotesSeleccionados.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _lotesSeleccionados
                                  .map((l) => Chip(
                                        label: Text(l.lote.loteCodigo),
                                        backgroundColor: Colors.green.shade50,
                                        deleteIcon: const Icon(Icons.close,
                                            size: 16, color: Colors.red),
                                        onDeleted: () => setState(() =>
                                            _lotesSeleccionados.remove(l)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ))
                                  .toList(),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      _buildCard('Observaciones', [
                        Container(
                          decoration: BoxDecoration(
                            color: _kFieldFill,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _kShadow,
                          ),
                          child: TextFormField(
                            controller: _observacionesCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Observaciones de maquinaria o jornada',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.notes_rounded,
                                    color: Color(0xFF1B5E20), size: 20),
                              ),
                              filled: true,
                              fillColor: _kFieldFill,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1B5E20), width: 2),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildFirmaCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
        ),
      ), // Scaffold
    ); // PopScope
  }

  Widget _buildFirmaCard() {
    return _buildCard('Firma del Operador', [
      if (_firmaBytes != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _firmaBytes!,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _abrirFirma,
          icon: Icon(_firmaBytes == null ? Icons.draw : Icons.edit),
          label:
              Text(_firmaBytes == null ? 'Agregar Firma' : 'Modificar Firma'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1B5E20),
            side: const BorderSide(color: Color(0xFF1B5E20)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildActionButtons() {
    if (widget.adminMode) {
      // En adminMode NO hay botón de guardar: el guardado ocurre automáticamente
      // al presionar el botón de retroceso (igual que las demás pestañas del editor).
      // Si el usuario no modificó nada, se retorna false para no marcar dirty state.
      if (_guardandoAdmin) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          ),
        );
      }
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await _guardarBorrador();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Datos guardados como borrador'),
                  backgroundColor: Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ));
                context.go('/operador/home');
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B5E20),
              side: const BorderSide(color: Color(0xFF1B5E20)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<RegistroBloc, RegistroState>(
            builder: (context, state) {
              return ElevatedButton.icon(
                onPressed: (state is RegistroLoading || _cerrando) ? null : _cerrarTurno,
                icon: state is RegistroLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: const Text('Cerrar turno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 18, color: const Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text(title.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 0.5)),
              ],
            ),
            const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 12),
                child: Divider(height: 1)),
            ...children,
          ],
        ),
      ),
    );
  }

  static const _kShadow = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 6, offset: Offset(0, 1)),
  ];
  static const _kFieldFill = Color(0xFFF5F5F5);

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: _kFieldFill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
          filled: true,
          fillColor: _kFieldFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC53030), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC53030), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(TextEditingController ctrl, String label,
      {String? Function(String?)? validator,
      bool showClear = false,
      bool freePick = false}) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, value, __) => Container(
        decoration: BoxDecoration(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _kShadow,
        ),
        child: TextFormField(
          controller: ctrl,
          readOnly: true,
          validator: validator,
          onTap: () => freePick ? _pickTimeLibre(ctrl) : _pickTime(ctrl),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.schedule_rounded,
                color: Color(0xFF1B5E20), size: 20),
            filled: true,
            fillColor: _kFieldFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFC53030), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC53030), width: 2),
            ),
            suffixIcon: value.text.isNotEmpty
                ? ((showClear || freePick)
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
                        onPressed: () {
                          ctrl.clear();
                          if (_draftReady) _guardarBorrador();
                        },
                      )
                    : null)
                : ((showClear || freePick)
                    ? const Icon(Icons.touch_app_outlined,
                        size: 18, color: Color(0xFF1B5E20))
                    : null),
          ),
        ),
      ),
    );
  }
}

// ─── Modelo interno para agrupar lotes por cultivo ───────────────────────────

class _CultivoMeta {
  final String nombre;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _CultivoMeta(this.nombre, this.color, this.bgColor, this.icon);
}

/// Infiere el cultivo a partir del prefijo del código de finca/lote
/// (U- = Uva/Vid, E- = Espárrago, P- = Palta, A- = Arándano).
_CultivoMeta _cultivoMetaDesde(String loteCodigo) {
  final prefix = loteCodigo.split('-').first.toUpperCase();
  switch (prefix) {
    case 'E':
      return const _CultivoMeta(
          'Espárrago', Color(0xFF7B1FA2), Color(0xFFF3E5F5), Icons.grass);
    case 'P':
      return const _CultivoMeta(
          'Palta', Color(0xFF1B5E20), Color(0xFFE8F5E9), Icons.eco);
    case 'A':
      return const _CultivoMeta(
          'Arándano', Color(0xFF283593), Color(0xFFE8EAF6), Icons.water_drop);
    case 'U':
      return const _CultivoMeta(
          'Uva / Vid', Color(0xFF4A148C), Color(0xFFEDE7F6), Icons.wine_bar);
    default:
      return const _CultivoMeta(
          'Otros', Color(0xFF37474F), Color(0xFFECEFF1), Icons.agriculture);
  }
}

// Elemento de la lista aplanada: encabezado de cultivo, sub-encabezado de lote
// o entrada de sublote.
sealed class _ListItem {}

class _CultivoHeader extends _ListItem {
  final _CultivoMeta meta;
  final int count;
  _CultivoHeader(this.meta, this.count);
}

/// Sub-encabezado que agrupa todos los sublotes de un mismo código de lote.
class _LoteSubHeader extends _ListItem {
  final String loteCode;
  final String fincaNombre;
  final int subloteCount;
  _LoteSubHeader(this.loteCode, this.fincaNombre, this.subloteCount);
}

class _LoteEntry extends _ListItem {
  final Lote lote;
  /// true = este ítem va indentado bajo un _LoteSubHeader (tiene sublotes).
  final bool isNested;
  _LoteEntry(this.lote, {this.isNested = false});
}

/// Selector de lotes con búsqueda local y agrupación por cultivo
class LotesPickerPage extends StatefulWidget {
  final List<LoteSeleccionado> seleccionadosInicial;
  const LotesPickerPage({super.key, required this.seleccionadosInicial});

  @override
  State<LotesPickerPage> createState() => _LotesPickerPageState();
}

class _LotesPickerPageState extends State<LotesPickerPage> {
  List<LoteSeleccionado> _seleccionados = [];
  String _searchQuery = '';
  late final Future<List<Lote>> _lotesFuture;

  // Orden de presentación de cultivos
  static const _ordenPrefijos = ['E', 'P', 'A', 'U'];

  @override
  void initState() {
    super.initState();
    _seleccionados = List.from(widget.seleccionadosInicial);
    final db = sl<AppDatabase>();
    _lotesFuture = db.catalogoDao
        .getLotes()
        .then((rows) => rows.map(_loteFromRow).toList());
  }

  /// Construye la lista aplanada agrupada por cultivo y, dentro de cada
  /// cultivo, sub-agrupada por código de lote para mostrar sublotes anidados.
  List<_ListItem> _buildItems(List<Lote> lotes) {
    // Agrupar por prefijo de cultivo (E, P, A, U…)
    final grupos = <String, List<Lote>>{};
    for (final l in lotes) {
      final prefix = l.loteCodigo.split('-').first.toUpperCase();
      grupos.putIfAbsent(prefix, () => []).add(l);
    }
    // Ordenar cada grupo internamente por código
    for (final g in grupos.values) {
      g.sort((a, b) => a.loteCodigo.compareTo(b.loteCodigo));
    }
    // Respetar el orden de cultivos definido, luego prefijos desconocidos
    final prefijosPresentes = [
      ..._ordenPrefijos.where((p) => grupos.containsKey(p)),
      ...grupos.keys.where((p) => !_ordenPrefijos.contains(p)),
    ];

    final items = <_ListItem>[];
    for (final prefix in prefijosPresentes) {
      final grupo = grupos[prefix]!;
      final meta = _cultivoMetaDesde('$prefix-');
      items.add(_CultivoHeader(meta, grupo.length));

      // Sub-agrupar por loteCodigo para mostrar la jerarquía Lote → Sublotes
      final porLote = <String, List<Lote>>{};
      for (final l in grupo) {
        porLote.putIfAbsent(l.loteCodigo, () => []).add(l);
      }
      final loteCodes = porLote.keys.toList()..sort();

      for (final code in loteCodes) {
        final sublotes = porLote[code]!;
        // Si hay más de un registro con ese código, o el campo sublote tiene
        // valor, mostramos sub-encabezado de lote + ítems anidados.
        final tieneSublotes = sublotes.length > 1 ||
            (sublotes.length == 1 &&
                sublotes[0].sublote != null &&
                sublotes[0].sublote!.trim().isNotEmpty);

        if (tieneSublotes) {
          items.add(
            _LoteSubHeader(code, sublotes.first.fincaNombre, sublotes.length),
          );
          for (final l in sublotes) {
            items.add(_LoteEntry(l, isNested: true));
          }
        } else {
          // Lote sin sublotes definidos: se muestra directo (sin anidado)
          items.add(_LoteEntry(sublotes.first));
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final selCount = _seleccionados.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Seleccionar Lotes'),
        actions: [
          if (selCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$selCount sel.',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por código, sublote o finca...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Lote>>(
              future: _lotesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var lotes = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  lotes = lotes
                      .where((l) =>
                          l.loteCodigo.toLowerCase().contains(_searchQuery) ||
                          (l.sublote?.toLowerCase().contains(_searchQuery) ??
                              false) ||
                          l.fincaNombre.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (lotes.isEmpty) {
                  return const Center(
                    child: Text('Sin lotes que coincidan.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final items = _buildItems(lotes);

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    if (item is _CultivoHeader) {
                      return _buildCultivoHeader(item);
                    }
                    if (item is _LoteSubHeader) {
                      return _buildLoteSubHeader(item);
                    }
                    final entry = item as _LoteEntry;
                    return _buildLoteTile(entry.lote, isNested: entry.isNested);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, _seleccionados),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Confirmar ${_seleccionados.length} lote(s)'),
        ),
      ),
    );
  }

  Widget _buildCultivoHeader(_CultivoHeader h) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: h.meta.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: h.meta.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(h.meta.icon, color: h.meta.color, size: 20),
          const SizedBox(width: 10),
          Text(
            h.meta.nombre,
            style: TextStyle(
              color: h.meta.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '${h.count} lote${h.count != 1 ? 's' : ''}',
            style: TextStyle(color: h.meta.color.withValues(alpha: 0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Sub-encabezado de lote: muestra el código de lote como separador visual
  /// dentro del grupo de cultivo, antes de listar sus sublotes anidados.
  Widget _buildLoteSubHeader(_LoteSubHeader h) {
    final meta = _cultivoMetaDesde(h.loteCode);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: meta.color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, size: 16, color: meta.color),
          const SizedBox(width: 8),
          Text(
            'Lote  ${h.loteCode}',
            style: TextStyle(
              color: meta.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            h.fincaNombre,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${h.subloteCount} sublote${h.subloteCount != 1 ? 's' : ''}',
              style: TextStyle(
                  color: meta.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteTile(Lote lote, {bool isNested = false}) {
    final meta = _cultivoMetaDesde(lote.loteCodigo);
    final selectedIndex =
        _seleccionados.indexWhere((s) => s.lote.idErp == lote.idErp);
    final isSelected = selectedIndex >= 0;

    final subloteLabel =
        (lote.sublote?.trim().isNotEmpty == true) ? lote.sublote! : 'Sin sublote';

    return Padding(
      // Sangría extra cuando el ítem está bajo un sub-encabezado de lote
      padding: EdgeInsets.only(left: isNested ? 16.0 : 0.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isSelected
              ? BorderSide(color: meta.color, width: 2)
              : BorderSide(color: meta.color.withValues(alpha: 0.2)),
        ),
        child: CheckboxListTile(
          title: isNested
              // Anidado: muestra prominentemente el sublote (el código de lote
              // ya está en el sub-encabezado superior).
              ? Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 14,
                      color: meta.color.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subloteLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: meta.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              // No anidado: diseño original con punto de color + código
              : Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: meta.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lote.loteCodigo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: meta.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subloteLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: meta.color.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
          subtitle: Text(
            isNested
                // Anidado: solo área (finca ya está en el sub-encabezado)
                ? lote.areaHa != null
                    ? '${lote.areaHa!.toStringAsFixed(2)} ha'
                    : lote.fincaNombre
                // No anidado: finca + área (igual que antes)
                : '${lote.fincaNombre}'
                    '${lote.areaHa != null ? '  ·  ${lote.areaHa!.toStringAsFixed(2)} ha' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          activeColor: meta.color,
          checkColor: Colors.white,
          value: isSelected,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _seleccionados.add(LoteSeleccionado(
                    lote: lote,
                    areaHa: lote.areaHa ?? 0.0,
                    observacion: null));
              } else {
                _seleccionados
                    .removeWhere((s) => s.lote.idErp == lote.idErp);
              }
            });
          },
        ),
      ),
    );
  }

  Lote _loteFromRow(LotesLocalData r) => Lote(
        idErp: r.idErp,
        loteCodigo: r.loteCodigo,
        loteNombre: r.loteNombre,
        fincaIdErp: r.fincaIdErp,
        fincaNombre: r.fincaNombre,
        sublote: r.sublote,
        areaHa: r.areaHa,
        zona: r.zona,
        activo: r.activo,
      );
}
