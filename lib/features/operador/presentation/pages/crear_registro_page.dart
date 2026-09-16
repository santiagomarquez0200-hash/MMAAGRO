import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/shared/widgets/offline_banner.dart';
import 'package:agro_aplicaciones/shared/widgets/scanner_dialog.dart';
import 'package:agro_aplicaciones/shared/widgets/connectivity_dot.dart';
import 'package:agro_aplicaciones/shared/widgets/spinner_time_picker.dart';

class CrearRegistroPage extends StatefulWidget {
  final String? registroId;
  final RegistroDiario? registroPrefill;
  final bool adminMode;
  const CrearRegistroPage({super.key, this.registroId, this.registroPrefill, this.adminMode = false});

  @override
  State<CrearRegistroPage> createState() => _CrearRegistroPageState();
}

class _CrearRegistroPageState extends State<CrearRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  bool _huboCambios = false; // solo relevante en adminMode+isEdit

  // Estado del formulario
  DateTime _fecha = DateTime.now();
  String _turno = 'dia';

  Proceso? _proceso;
  Subproceso? _subproceso;
  Cultivo? _cultivo;
  Tractor? _tractor;
  Implemento? _implemento;
  CajaCambios? _cajaCambios;

  // Controladores
  final _tractorInicioCtrl = TextEditingController();
  final _implementoInicioCtrl = TextEditingController();
  final _horaSalidaBaseCtrl = TextEditingController();
  final _horaLlegadaZonaCtrl = TextEditingController();
  final _supervisorNombreCtrl = TextEditingController();

  // Operador seleccionado (solo en adminMode — permite editar quién es el operador)
  Trabajador? _operadorSeleccionado;

  // Sub-labores (condicional por proceso)
  String? _sublaborSeleccionada;

  static const _kSublaboresOpciones = [
    'Aplicación de cianamida',
    'Aplicación de chanchito',
    'Aplicación Sanitaria',
  ];

  // ── Mínimo horómetro del tractor/implemento seleccionado ─────────────────
  double? _minHorometroTractor;
  double? _minImplementoTractor;
  // ID del implemento que generó _minImplementoTractor (del turno anterior).
  int?    _storedImplementoIdErp;
  // Código base del implemento almacenado (fallback cuando el ID aún no está).
  String? _storedImplementoCodigo;

  // true solo cuando el implemento seleccionado coincide con el almacenado.
  // Primero compara por ID entero (exacto); si el ID no está aún disponible,
  // usa el código base como fallback para no romper instalaciones antiguas.
  bool get _aplicarMinImplemento {
    if (_minImplementoTractor == null || _implemento == null) return false;
    if (_storedImplementoIdErp != null) {
      return _implemento!.idErp == _storedImplementoIdErp;
    }
    if (_storedImplementoCodigo != null) {
      return _implemento!.codigoImplemento.trim().toUpperCase() ==
          _storedImplementoCodigo!.trim().toUpperCase();
    }
    return false;
  }

  bool _loadingEditData = false;
  bool _turnoLocked = false;
  bool get _isEdit => widget.registroId != null;

  // Draft pendiente de aplicar a los dropdowns (cuando el catálogo cargue)
  Map<String, dynamic>? _pendingDraft;
  bool _draftRestaurado = false;

  // Registro pendiente de aplicar a los dropdowns en modo edición
  // (cuando el catálogo aún no ha cargado al momento de llamar _applyRegistroToForm)
  RegistroDiario? _pendingRegistroEdit;
  bool _registroEditAplicado = false;

  // Auto-guardado por campo
  Timer? _debounceTimer;

  // ─── Completitud para el botón ────────────────────────────────────────────

  /// true cuando hay suficiente información para crear el registro localmente.
  /// La hora de llegada a zona de mezcla es opcional — se puede agregar después.
  bool get _completoParaGuardar =>
      _proceso != null &&
      _tractor != null &&
      _cultivo != null &&
      _horaSalidaBaseCtrl.text.isNotEmpty;

  bool get _hayContenido =>
      _proceso != null ||
      _tractor != null ||
      _cultivo != null ||
      _tractorInicioCtrl.text.isNotEmpty ||
      _horaSalidaBaseCtrl.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _autoSeleccionarTurno();
    if (_isEdit) {
      _cargarTurnoJornada();
      _loadForEdit();
    } else {
      // hora llegada zona queda vacía — el usuario la registra al llegar
      // BUG-04: _cargarBorrador depende de _turno (vía _draftKey); ejecutar
      // después de que _cargarTurnoJornada resuelva el turno de jornada.
      _cargarTurnoJornada().then((_) => _cargarBorrador());
    }
  }

  // ─── Auto-guardado por campo ──────────────────────────────────────────────

  /// Guarda el borrador inmediatamente (dropdowns, campos de hora, escaneo).
  /// Con debounce=true espera 800 ms (campos de texto mientras se escribe).
  void _autoGuardar({bool debounce = false}) {
    if (_isEdit) {
      if (widget.adminMode && !_huboCambios) {
        setState(() => _huboCambios = true);
      }
      return;
    }
    if (debounce) {
      _debounceTimer?.cancel();
      _debounceTimer =
          Timer(const Duration(milliseconds: 800), _guardarBorrador);
    } else {
      _guardarBorrador();
    }
  }

  // ─── Borrador ─────────────────────────────────────────────────────────────

  Future<String> _draftKey() async {
    final deviceId = await sl<DeviceService>().getDeviceId();
    return 'draft_crear_registro_${deviceId}_$_turno';
  }

  Future<void> _cargarUltimoHorometro(String codigoTractor) async {
    final db = sl<AppDatabase>();
    List<dynamic> rows;
    try {
      rows = await db.customSelect(
        'SELECT horometro_final, implemento_final, implemento_id_erp, codigo_implemento '
        'FROM ultimo_horometro_tractores_local WHERE tractor_id_erp = ?',
        variables: [Variable.withString(codigoTractor)],
      ).get();
    } catch (e) {
      developer.log('[HOROMETRO] Error leyendo tabla: $e', name: 'CrearRegistro');
      return;
    }
    if (!mounted) return;
    if (rows.isNotEmpty) {
      final h       = rows.first.data['horometro_final'];
      final imp     = rows.first.data['implemento_final'];
      final impId   = rows.first.data['implemento_id_erp'];
      final impCod  = rows.first.data['codigo_implemento'];
      developer.log(
        '[HOROMETRO] Tractor=$codigoTractor | horometro_final=$h | '
        'implemento_final=$imp | implemento_id_erp=$impId (${impId.runtimeType}) | '
        'codigo_implemento=$impCod',
        name: 'CrearRegistro',
      );
      setState(() {
        _minHorometroTractor   = h   != null ? (h   as num).toDouble() : null;
        _minImplementoTractor  = imp != null ? (imp as num).toDouble() : null;
        _storedImplementoIdErp = impId != null ? (impId as num).toInt() : null;
        _storedImplementoCodigo = impCod?.toString();
      });
      developer.log(
        '[HOROMETRO] Guardado → _minHorometroTractor=$_minHorometroTractor | '
        '_minImplementoTractor=$_minImplementoTractor | '
        '_storedImplementoIdErp=$_storedImplementoIdErp | '
        '_storedImplementoCodigo=$_storedImplementoCodigo',
        name: 'CrearRegistro',
      );
    } else {
      developer.log(
        '[HOROMETRO] Tractor=$codigoTractor → SIN fila en ultimo_horometro_tractores_local',
        name: 'CrearRegistro',
      );
      setState(() {
        _minHorometroTractor    = null;
        _minImplementoTractor   = null;
        _storedImplementoIdErp  = null;
        _storedImplementoCodigo = null;
      });
    }
  }

  Future<void> _cargarBorrador() async {
    final key = await _draftKey();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || !mounted) return;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        if ((d['tractor_inicio'] as String?)?.isNotEmpty == true) {
          _tractorInicioCtrl.text = d['tractor_inicio']!;
        }
        if ((d['implemento_inicio'] as String?)?.isNotEmpty == true) {
          _implementoInicioCtrl.text = d['implemento_inicio']!;
        }
        if ((d['hora_salida_base'] as String?)?.isNotEmpty == true) {
          _horaSalidaBaseCtrl.text = d['hora_salida_base']!;
        }
        if ((d['hora_llegada_zona'] as String?)?.isNotEmpty == true) {
          _horaLlegadaZonaCtrl.text = d['hora_llegada_zona']!;
        }
        if ((d['supervisor_nombre'] as String?)?.isNotEmpty == true) {
          _supervisorNombreCtrl.text = d['supervisor_nombre']!;
        }
        if ((d['sublabor'] as String?) != null) {
          _sublaborSeleccionada = d['sublabor'] as String?;
        }
        _pendingDraft = d; // dropdowns se restauran cuando carga el catálogo
      });
    } catch (e, st) {
      developer.log('Error al cargar borrador', name: 'CrearRegistroPage', error: e, stackTrace: st);
    }
  }

  void _applyPendingDraft(CatalogoLoaded catState) {
    if (_pendingDraft == null || _draftRestaurado) return;
    _draftRestaurado = true;
    final d = _pendingDraft!;
    _pendingDraft = null;

    setState(() {
      final procesoId = d['proceso_id'] as int?;
      if (procesoId != null) {
        _proceso = catState.procesos
            .cast<Proceso?>()
            .firstWhere((p) => p?.id == procesoId, orElse: () => null);
      }
      final subprocesoId = d['subproceso_id'] as int?;
      if (subprocesoId != null) {
        _subproceso = catState.subprocesos
            .cast<Subproceso?>()
            .firstWhere((s) => s?.id == subprocesoId, orElse: () => null);
      }
      final cultivoId = d['cultivo_id'] as int?;
      if (cultivoId != null) {
        _cultivo = catState.cultivos
            .cast<Cultivo?>()
            .firstWhere((c) => c?.idErp == cultivoId, orElse: () => null);
      }
      final tractorId = d['tractor_id'] as int?;
      if (tractorId != null) {
        _tractor = catState.tractores
            .cast<Tractor?>()
            .firstWhere((t) => t?.idErp == tractorId, orElse: () => null);
      }
      final implementoId = d['implemento_id'] as int?;
      if (implementoId != null) {
        _implemento = catState.implementos
            .cast<Implemento?>()
            .firstWhere((i) => i?.idErp == implementoId, orElse: () => null);
      }
      final cajaId = d['caja_cambios_id'] as int?;
      if (cajaId != null) {
        _cajaCambios = catState.cajasCambios
            .cast<CajaCambios?>()
            .firstWhere((c) => c?.id == cajaId, orElse: () => null);
      }
    });

    if (mounted && _hayContenido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.restore_rounded, color: Colors.white, size: 16),
            SizedBox(width: 7),
            Text('Borrador restaurado. Puedes continuar.'),
          ]),
          backgroundColor: Color(0xFF1B4332),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _guardarBorrador() async {
    final key = await _draftKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        key,
        jsonEncode({
          'proceso_id': _proceso?.id,
          'subproceso_id': _subproceso?.id,
          'cultivo_id': _cultivo?.idErp,
          'tractor_id': _tractor?.idErp,
          'implemento_id': _implemento?.idErp,
          'caja_cambios_id': _cajaCambios?.id,
          'sublabor': _sublaborSeleccionada,
          'tractor_inicio': _tractorInicioCtrl.text,
          'implemento_inicio': _implementoInicioCtrl.text,
          'hora_salida_base': _horaSalidaBaseCtrl.text,
          'hora_llegada_zona': _horaLlegadaZonaCtrl.text,
          'supervisor_nombre': _supervisorNombreCtrl.text,
        }));
  }

  Future<void> _borrarBorrador() async {
    final key = await _draftKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // ─── Turno ────────────────────────────────────────────────────────────────

  void _autoSeleccionarTurno() {
    final hour = DateTime.now().hour;
    _turno = (hour >= 6 && hour < 14) ? 'dia' : 'noche';
  }

  Future<void> _cargarTurnoJornada() async {
    // En modo supervisor el turno NO se bloquea: el supervisor tiene acceso
    // total a todos los campos sin restricciones previas.
    if (widget.adminMode) return;

    final deviceId = await sl<DeviceService>().getDeviceId();
    final datos =
        await sl<StatusSyncManager>().obtenerDatosJornadaActiva(deviceId);
    if (datos != null && mounted) {
      setState(() {
        _turno = datos['turno'] as String;
        _turnoLocked = true;
      });
    }
  }

  // ─── Modo edición ─────────────────────────────────────────────────────────

  Future<void> _loadForEdit() async {
    setState(() => _loadingEditData = true);

    if (widget.registroPrefill != null) {
      _applyRegistroToForm(widget.registroPrefill!);
    } else {
      final result =
          await sl<RegistroRepository>().getRegistro(widget.registroId!);
      if (!mounted) return;
      result.fold(
        (failure) => _showSnackBar(
            'Error al cargar datos: ${failure.toString()}',
            isError: true),
        (registro) => _applyRegistroToForm(registro),
      );
    }

    final registroId = widget.registroPrefill?.id ?? widget.registroId;
    if (registroId != null) {
      final db = sl<AppDatabase>();
      final rows = await (db.select(db.subLaboresLocal)
            ..where((t) => t.registroId.equals(registroId)))
          .get();
      if (rows.isNotEmpty && mounted) {
        setState(() => _sublaborSeleccionada = rows.first.sublaborNombre);
      }
    }

    if (!mounted) return;
    setState(() => _loadingEditData = false);
  }

  void _applyRegistroToForm(RegistroDiario registro) {
    final catalogState = context.read<CatalogoBloc>().state;
    setState(() {
      // ── Campos que NO dependen del catálogo — siempre se aplican ──────────
      _fecha = registro.fecha;
      _turno = registro.turno;
      _tractorInicioCtrl.text =
          registro.horometro?.tractorInicio?.toString() ?? '';
      _implementoInicioCtrl.text =
          registro.horometro?.implementoInicio?.toString() ?? '';
      _horaSalidaBaseCtrl.text = registro.tiempoTurno?.horaSalidaTaller ?? '';
      _horaLlegadaZonaCtrl.text = registro.tiempoTurno?.horaLlegadaPunto ?? '';
      if (registro.supervisorNombre?.isNotEmpty == true) {
        _supervisorNombreCtrl.text = registro.supervisorNombre!;
      }

      if (catalogState is CatalogoLoaded) {
        // ── Catálogo disponible: resuelve dropdowns ahora ──────────────────
        _registroEditAplicado = true;
        _aplicarCatalogosAlRegistro(registro, catalogState);
      } else {
        // ── Catálogo aún no listo: guarda para aplicar cuando cargue ──────
        _pendingRegistroEdit = registro;
      }
    });
  }

  /// Resuelve todos los campos que requieren catálogo contra [cat] y los
  /// asigna al estado del formulario. Llamado tanto desde [_applyRegistroToForm]
  /// (si el catálogo ya está listo) como desde [_applyPendingRegistroEdit]
  /// (cuando el catálogo termina de cargar después del form).
  void _aplicarCatalogosAlRegistro(RegistroDiario registro, CatalogoLoaded cat) {
    _proceso = cat.procesos
        .cast<Proceso?>()
        .firstWhere((e) => e?.id == registro.procesoId, orElse: () => null);
    _cultivo = cat.cultivos.cast<Cultivo?>().firstWhere(
        (e) => e?.idErp == registro.cultivoIdErp,
        orElse: () => null);
    _tractor = cat.tractores.cast<Tractor?>().firstWhere(
        (e) => e?.idErp == registro.tractorIdErp,
        orElse: () => null);
    _implemento = cat.implementos.cast<Implemento?>().firstWhere(
        (e) => e?.idErp == registro.implementoIdErp,
        orElse: () => null);
    // Caja cambios: intenta por ID, si no disponible intenta por nombre
    _cajaCambios = registro.cajaCambiosId != null
        ? cat.cajasCambios.cast<CajaCambios?>().firstWhere(
            (e) => e?.id == registro.cajaCambiosId,
            orElse: () => null)
        : registro.cajaCambiosNombre != null
            ? cat.cajasCambios.cast<CajaCambios?>().firstWhere(
                (e) => e?.nombre == registro.cajaCambiosNombre,
                orElse: () => null)
            : null;
    // Subproceso: intenta por ID, si no disponible intenta por nombre
    _subproceso = registro.subprocesoId != null && registro.subprocesoId != 0
        ? cat.subprocesos.cast<Subproceso?>().firstWhere(
            (e) => e?.id == registro.subprocesoId,
            orElse: () => null)
        : registro.subprocesoNombre != null
            ? cat.subprocesos.cast<Subproceso?>().firstWhere(
                (e) => e?.nombre == registro.subprocesoNombre,
                orElse: () => null)
            : null;
    // En adminMode, pre-selecciona el operador original del registro
    if (widget.adminMode) {
      _operadorSeleccionado = cat.trabajadores
          .cast<Trabajador?>()
          .firstWhere(
            (t) => t?.idErp == registro.operadorIdErp,
            orElse: () => null,
          );
    }
  }

  /// Aplica los datos de [_pendingRegistroEdit] una vez que el catálogo ha cargado.
  /// Se llama desde el BlocBuilder, igual que [_applyPendingDraft].
  void _applyPendingRegistroEdit(CatalogoLoaded cat) {
    if (_pendingRegistroEdit == null || _registroEditAplicado) return;
    _registroEditAplicado = true;
    final r = _pendingRegistroEdit!;
    _pendingRegistroEdit = null;
    setState(() => _aplicarCatalogosAlRegistro(r, cat));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tractorInicioCtrl.dispose();
    _implementoInicioCtrl.dispose();
    _horaSalidaBaseCtrl.dispose();
    _horaLlegadaZonaCtrl.dispose();
    _supervisorNombreCtrl.dispose();
    super.dispose();
  }

  // ─── Buscador de operador (adminMode) ────────────────────────────────────

  /// Campo tappable que abre un bottom sheet con búsqueda de operadores.
  /// Evita el lag del DropdownButtonFormField cuando la lista es muy larga.
  Widget _buildOperadorSearchField(List<Trabajador> operadores) {
    return GestureDetector(
      onTap: () => _abrirBuscadorOperador(operadores),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _kShadow,
        ),
        child: Row(children: [
          const Icon(Icons.person_pin, color: Color(0xFF1B4332), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operador *',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  _operadorSeleccionado?.nombreCompleto ?? 'Buscar operador...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _operadorSeleccionado != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _operadorSeleccionado != null
                        ? const Color(0xFF1B4332)
                        : Colors.grey.shade500,
                  ),
                ),
                if (_operadorSeleccionado != null)
                  Text(
                    _operadorSeleccionado!.codTrabajador,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          const Icon(Icons.search, color: Color(0xFF1B4332), size: 20),
        ]),
      ),
    );
  }

  Future<void> _abrirBuscadorOperador(List<Trabajador> operadores) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OperadorSearchSheet(
        operadores: operadores,
        seleccionado: _operadorSeleccionado,
        onSelect: (t) {
          if (mounted) {
            setState(() => _operadorSeleccionado = t);
            _autoGuardar(debounce: true);
          }
        },
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 15)),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _fecha = date);
  }

  Future<void> _scanearTractor(List<Tractor> tractores) async {
    final code =
        await showScannerDialog(context, label: 'Escanear código de tractor');
    if (code == null || !mounted) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = tractores.cast<Tractor?>().firstWhere(
      (t) {
        final c = t!.codigoTractor.replaceAll(' ', '').trim().toUpperCase();
        final i =
            (t.codigoInterno ?? '').replaceAll(' ', '').trim().toUpperCase();
        final concat = i.isEmpty ? c : '$c-$i';
        return c == upper || i == upper || concat == upper;
      },
      orElse: () => null,
    );
    if (found != null) {
      setState(() {
        _tractor = found;
        _minHorometroTractor   = null;
        _minImplementoTractor  = null;
        _storedImplementoIdErp = null;
      });
      _cargarUltimoHorometro(found.codigoTractor);
      _autoGuardar();
    } else {
      _showSnackBar('Tractor "$upper" no encontrado en catálogo',
          isError: true);
    }
  }

  Future<void> _scanearImplemento(List<Implemento> implementos) async {
    final code = await showScannerDialog(context,
        label: 'Escanear código de implemento');
    if (code == null || !mounted) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = implementos.cast<Implemento?>().firstWhere(
      (t) {
        final c = t!.codigoImplemento.replaceAll(' ', '').trim().toUpperCase();
        final i =
            (t.codigoInterno ?? '').replaceAll(' ', '').trim().toUpperCase();
        final concat = i.isEmpty ? c : '$c-$i';
        return c == upper || i == upper || concat == upper;
      },
      orElse: () => null,
    );
    if (found != null) {
      setState(() => _implemento = found);
      _autoGuardar();
    } else {
      _showSnackBar('Implemento "$upper" no encontrado en catálogo',
          isError: true);
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final usuario = authState.usuario;

    if (_proceso == null || _cultivo == null || _tractor == null) {
      _showSnackBar('Complete: Proceso, Tractor y Cultivo son requeridos (*)',
          isError: true);
      return;
    }
    // En modo admin la validación de ERP se relaja: el operador viene del selector
    if (!widget.adminMode && usuario.trabajadorIdErp == null) {
      _showSnackBar('Usuario sin ID ERP asociado. Contacte al administrador.',
          isError: true);
      return;
    }
    if (widget.adminMode && _operadorSeleccionado == null) {
      _showSnackBar('Seleccione el operador del registro.', isError: true);
      return;
    }

    final deviceId = await sl<DeviceService>().getDeviceId();

    // Datos del operador: en adminMode usa el trabajador seleccionado;
    // en modo normal usa la sesión activa del operador.
    final int operadorIdErp = widget.adminMode
        ? _operadorSeleccionado!.idErp
        : usuario.trabajadorIdErp!;
    final String operadorCodigo = widget.adminMode
        ? _operadorSeleccionado!.codTrabajador
        : usuario.codigo;
    final String operadorNombreVal = widget.adminMode
        ? _operadorSeleccionado!.nombreCompleto
        : usuario.nombreCompleto;

    final String? supNombre = _supervisorNombreCtrl.text.trim().isNotEmpty
        ? _supervisorNombreCtrl.text.trim()
        : null;

    final params = CrearRegistroParams(
      fecha: _fecha,
      turno: _turno,
      procesoId: _proceso!.id,
      procesoNombre: _proceso!.nombre,
      procesoCodigo: _proceso!.codigo,
      subprocesoId: _subproceso?.id,
      subprocesoNombre: _subproceso?.nombre,
      cultivoIdErp: _cultivo!.idErp,
      cultivoNombreEspecie: _cultivo!.displayName,
      cultivoCodigoEspecie: _cultivo!.codigoEspecie,
      operadorIdErp: operadorIdErp,
      operadorCodigo: operadorCodigo,
      operadorNombre: operadorNombreVal,
      supervisorIdErp: null,
      supervisorCodigo: null,
      supervisorNombre: supNombre,
      tractorIdErp: _tractor!.idErp,
      tractorCodigo: _tractor!.codigoTractor,
      tractorDescripcion: _tractor!.descripcion,
      implementoIdErp: _implemento?.idErp,
      implementoCodigo: _implemento?.codigoImplemento,
      implementoDescripcion: _implemento?.descripcion,
      cajaCambiosId: _cajaCambios?.id,
      cajaCambiosNombre: _cajaCambios?.nombre,
      tractorInicio: double.tryParse(_tractorInicioCtrl.text),
      implementoInicio: double.tryParse(_implementoInicioCtrl.text),
      horaSalidaTaller:
          _horaSalidaBaseCtrl.text.isNotEmpty ? _horaSalidaBaseCtrl.text : null,
      horaLlegadaPunto: _horaLlegadaZonaCtrl.text.isNotEmpty
          ? _horaLlegadaZonaCtrl.text
          : null,
      dispositivoId: deviceId,
      createdByErp: operadorIdErp,
      sublaboresSeleccionadas:
          _sublaborSeleccionada != null ? [_sublaborSeleccionada!] : [],
    );

    if (!mounted) return;
    if (_isEdit) {
      context.read<RegistroBloc>().add(RegistroActualizarBasicoRequested(
            registroId: widget.registroId!,
            params: params,
          ));
    } else {
      context.read<RegistroBloc>().add(RegistroCrearRequested(params: params));
    }
  }

  // ─── Navegación ───────────────────────────────────────────────────────────

  Future<void> _onPopRequested() async {
    if (context.read<RegistroBloc>().state is RegistroLoading) return;
    if (widget.adminMode && _isEdit) {
      if (_huboCambios) {
        // Guarda a SQLite; el BlocListener hará context.pop(true) al terminar
        _submit();
        return;
      }
      if (mounted && context.canPop()) context.pop(false);
      return;
    }
    // Guarda el borrador silenciosamente — sin diálogo de confirmación
    if (!_isEdit && _hayContenido) _guardarBorrador();
    if (mounted) context.pop();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopRequested();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Column(
          children: [
            const OfflineBanner(),
            _buildAppBar(context),
            Expanded(
              child: BlocListener<RegistroBloc, RegistroState>(
                listener: (context, state) {
                  if (state is RegistroOperacionExitosa) {
                    if (!_isEdit) _borrarBorrador();
                    if (_isEdit) {
                      if (widget.adminMode) {
                        if (context.canPop()) context.pop(true);
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/operador/home');
                      }
                    } else {
                      // El registro ya existe en el home — el usuario lo toca para continuar
                      context.go('/operador/home');
                    }
                  } else if (state is RegistroError) {
                    _showSnackBar(state.message, isError: true);
                  }
                },
                child: BlocBuilder<CatalogoBloc, CatalogoState>(
                  builder: (context, catState) {
                    if (catState is! CatalogoLoaded || _loadingEditData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_pendingDraft != null) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _applyPendingDraft(catState));
                    }
                    if (_pendingRegistroEdit != null) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _applyPendingRegistroEdit(catState));
                    }
                    return _buildForm(context, catState);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: const Color(0xFF1B4332),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 4,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _onPopRequested,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Text(
            _isEdit ? 'Editar Registro' : 'Nuevo Registro',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const ConnectivityDot(),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, CatalogoLoaded cat) {
    final authState = context.read<AuthBloc>().state;
    final usuario = authState is AuthAuthenticated ? authState.usuario : null;

    final subprocesosFiltrados = _proceso == null
        ? <Subproceso>[]
        : cat.subprocesos
            .where((s) => s.procesoId == _proceso!.id && s.activo)
            .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Información General ───────────────────────────────────────────
          _SectionCard(
            title: 'Información General',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.calendar_today, color: Color(0xFF1B4332)),
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: _pickDate,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.brightness_medium,
                        color: Color(0xFF1B4332)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTurnoToggle()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Personal ──────────────────────────────────────────────────────
          _SectionCard(
            title: 'Personal',
            children: [
              if (widget.adminMode)
                // Admin puede cambiar el operador: buscador rápido (evita lag de dropdown largo)
                _buildOperadorSearchField(
                  cat.trabajadores.where((t) => t.esOperador && t.activo).toList(),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF1B4332).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin,
                          color: Color(0xFF1B4332), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Operador (tu sesión)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              usuario?.nombreCompleto ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4332)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock_outline,
                          size: 16, color: Color(0xFF1B4332)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: _kFieldFill,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _kShadow,
                ),
                child: TextFormField(
                  controller: _supervisorNombreCtrl,
                  onChanged: (_) => _autoGuardar(debounce: true),
                  decoration: InputDecoration(
                    labelText: 'Supervisor (opcional)',
                    hintText: 'Escriba el nombre del supervisor',
                    prefixIcon: const Icon(Icons.manage_accounts_outlined,
                        color: Color(0xFF1B4332), size: 20),
                    filled: true,
                    fillColor: _kFieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
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
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Proceso y Cultivo ─────────────────────────────────────────────
          _SectionCard(
            title: 'Proceso y Cultivo',
            children: [
              _buildDropdown<Proceso>(
                label: 'Proceso *',
                value: _proceso,
                prefixIcon: Icons.work_outline,
                items: cat.procesos
                    .where((p) => p.tipoRegistro == 'tractor')
                    .toList(),
                itemLabel: (p) => '${p.nombre} (${p.codigo})',
                onChanged: (v) {
                  setState(() {
                    _proceso = v;
                    _subproceso = null;
                    _sublaborSeleccionada = null;
                  });
                  _autoGuardar();
                },
                validator: (v) => v == null ? 'Campo requerido' : null,
              ),
              if (subprocesosFiltrados.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDropdown<Subproceso>(
                  label: 'Subproceso (opcional)',
                  value: _subproceso,
                  prefixIcon: Icons.account_tree_outlined,
                  items: subprocesosFiltrados,
                  itemLabel: (s) => '${s.nombre} (${s.codigo})',
                  onChanged: (v) {
                    setState(() => _subproceso = v);
                    _autoGuardar();
                  },
                ),
              ],
              if (_proceso != null && _proceso!.requiereSublabores) ...[
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'Sub-labor (opcional)',
                  value: _sublaborSeleccionada,
                  prefixIcon: Icons.label_outline,
                  items: _kSublaboresOpciones,
                  itemLabel: (s) => s,
                  onChanged: (v) {
                    setState(() => _sublaborSeleccionada = v);
                    _autoGuardar();
                  },
                ),
              ],
              const SizedBox(height: 16),
              _buildDropdown<Cultivo>(
                label: 'Cultivo *',
                value: _cultivo,
                prefixIcon: Icons.grass,
                items: cat.cultivos,
                itemLabel: (c) => c.displayName,
                onChanged: (v) {
                  setState(() => _cultivo = v);
                  _autoGuardar();
                },
                validator: (v) => v == null ? 'Campo requerido' : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Equipo y Maquinaria ───────────────────────────────────────────
          _SectionCard(
            title: 'Equipo y Maquinaria',
            children: [
              _buildDropdownWithScan<Tractor>(
                label: 'Tractor *',
                value: _tractor,
                prefixIcon: Icons.agriculture_outlined,
                items: cat.tractores,
                itemLabel: (t) {
                  final interno = (t.codigoInterno ?? '').trim();
                  final codigo = t.codigoTractor.trim();
                  return interno.isEmpty ? codigo : '$codigo-$interno';
                },
                onChanged: (v) {
                  setState(() {
                    _tractor = v;
                    _minHorometroTractor    = null;
                    _minImplementoTractor   = null;
                    _storedImplementoIdErp  = null;
                    _storedImplementoCodigo = null;
                  });
                  if (v != null) _cargarUltimoHorometro(v.codigoTractor);
                  _autoGuardar();
                },
                validator: (v) => v == null ? 'Campo requerido' : null,
                onScan: () => _scanearTractor(cat.tractores),
              ),
              const SizedBox(height: 16),
              _buildDropdownWithScan<Implemento>(
                label: 'Implemento',
                value: _implemento,
                prefixIcon: Icons.construction,
                items: cat.implementos,
                itemLabel: (i) {
                  final interno = (i.codigoInterno ?? '').trim();
                  final codigo = i.codigoImplemento.trim();
                  return interno.isEmpty ? codigo : '$codigo-$interno';
                },
                onChanged: (v) {
                  setState(() => _implemento = v);
                  if (v != null) {
                    developer.log(
                      '[IMPLEMENTO] Seleccionado → idErp=${v.idErp} | '
                      'codigoImplemento="${v.codigoImplemento}" | '
                      'codigoInterno="${v.codigoInterno}"',
                      name: 'CrearRegistro',
                    );
                    developer.log(
                      '[IMPLEMENTO] Comparando con stored → '
                      '_storedImplementoIdErp=$_storedImplementoIdErp | '
                      '_storedImplementoCodigo="$_storedImplementoCodigo" | '
                      '_minImplementoTractor=$_minImplementoTractor | '
                      'match_por_id=${_storedImplementoIdErp != null ? v.idErp == _storedImplementoIdErp : "N/A"} | '
                      'match_por_codigo=${_storedImplementoCodigo != null ? v.codigoImplemento.trim().toUpperCase() == _storedImplementoCodigo!.trim().toUpperCase() : "N/A"} | '
                      '_aplicarMinImplemento=$_aplicarMinImplemento',
                      name: 'CrearRegistro',
                    );
                  }
                  _autoGuardar();
                },
                onScan: () => _scanearImplemento(cat.implementos),
              ),
              const SizedBox(height: 16),
              _buildDropdown<CajaCambios>(
                label: 'Marcha de Trabajo',
                value: _cajaCambios,
                prefixIcon: Icons.settings_outlined,
                items: cat.cajasCambios,
                itemLabel: (c) => c.nombre,
                onChanged: (v) {
                  setState(() => _cajaCambios = v);
                  _autoGuardar();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Horómetros Iniciales ──────────────────────────────────────────
          _SectionCard(
            title: 'Horómetros Iniciales',
            children: [
              _buildTextField(
                controller: _tractorInicioCtrl,
                label: 'Horómetro Tractor *',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.av_timer,
                onChanged: (_) => _autoGuardar(debounce: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final val = double.tryParse(v.trim());
                  if (val == null) return 'Ingrese un número válido';
                  if (_minHorometroTractor != null &&
                      val < _minHorometroTractor!) {
                    return 'Debe ser mayor o igual a ${_minHorometroTractor!.toStringAsFixed(1)} (último registro)';
                  }
                  return null;
                },
              ),
              if (_minHorometroTractor != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tractor final: ${_minHorometroTractor!.toStringAsFixed(1)}'
                          '${_aplicarMinImplemento ? '  |  Implemento final: ${_minImplementoTractor!.toStringAsFixed(1)}' : ''}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color.fromARGB(255, 9, 94, 36)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildTextField(
                controller: _implementoInicioCtrl,
                label: 'Horómetro Implemento',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.timer_outlined,
                onChanged: (_) => _autoGuardar(debounce: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final val = double.tryParse(v.trim());
                  if (val == null) return 'Ingrese un número válido';
                  if (_aplicarMinImplemento && val < _minImplementoTractor!) {
                    return 'Debe ser mayor o igual a ${_minImplementoTractor!.toStringAsFixed(1)} (último registro)';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tiempos de Control ────────────────────────────────────────────
          _SectionCard(
            title: 'Tiempos de Control',
            children: [
              _buildTimeField(
                controller: _horaSalidaBaseCtrl,
                label: 'Hora salida base estacionamiento *',
                validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                freePick: true,
              ),
              const SizedBox(height: 16),
              // Campo opcional: se puede completar después desde el home.
              // El registro se guarda igual sin este campo.
              _buildTimeField(
                controller: _horaLlegadaZonaCtrl,
                label: 'Hora llegada a zona mezcla',
                hint: 'Toca para registrar al llegar',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Turno ────────────────────────────────────────────────────────────────

  Widget _buildTurnoToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTurnoChip('Día  06-14h', 'dia')),
            const SizedBox(width: 8),
            Expanded(child: _buildTurnoChip('Noche 14-22h', 'noche')),
          ],
        ),
        if (_turnoLocked)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Turno bloqueado por jornada activa',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTurnoChip(String label, String value) {
    final isSelected = _turno == value;
    final isDia = value == 'dia';
    return GestureDetector(
      onTap: _turnoLocked ? null : () => setState(() => _turno = value),
      child: Opacity(
        opacity: (_turnoLocked && !isSelected) ? 0.35 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDia ? const Color(0xFFEF6C00) : const Color(0xFF1565C0))
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDia ? const Color(0xFFEF6C00) : const Color(0xFF1565C0))
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDia ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Botón principal dinámico ─────────────────────────────────────────────

  Widget _buildSubmitButton() {
    // En modo admin edición no hay botón — el supervisor guarda desde EditorAdminPage
    if (widget.adminMode && _isEdit) return const SizedBox.shrink();

    return BlocBuilder<RegistroBloc, RegistroState>(
      builder: (context, state) {
        final loading = state is RegistroLoading;

        // Modo edición — siempre "ACTUALIZAR"
        if (_isEdit) {
          return _ActionButton(
            loading: loading,
            label: 'ACTUALIZAR',
            icon: Icons.check_circle_outline,
            onPressed: _submit,
          );
        }

        // Campos básicos completos → crear registro y volver al home
        if (_completoParaGuardar) {
          return _ActionButton(
            loading: loading,
            label: 'GUARDAR Y SALIR',
            icon: Icons.check_circle_outline,
            onPressed: _submit,
          );
        }

        // Campos incompletos → solo guardar borrador localmente
        return SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: loading
                ? null
                : () async {
                    await _guardarBorrador();
                    if (mounted) this.context.pop();
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('GUARDAR BORRADOR',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B4332),
              side: const BorderSide(color: Color(0xFF1B4332), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          ),
        );
      },
    );
  }

  // ─── Widgets de formulario ────────────────────────────────────────────────

  static const _kShadow = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 6, offset: Offset(0, 1)),
  ];
  static const _kFieldFill = Color(0xFFF5F5F5);

  Widget _buildDropdownWithScan<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    required VoidCallback onScan,
    IconData? prefixIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDropdown<T>(
            label: label,
            value: value,
            items: items,
            itemLabel: itemLabel,
            onChanged: onChanged,
            validator: validator,
            prefixIcon: prefixIcon,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _kShadow,
          ),
          child: IconButton(
            onPressed: onScan,
            tooltip: 'Escanear QR',
            icon: const Icon(
              Icons.qr_code_scanner,
              color: Color(0xFF1B4332),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kFieldFill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF1B4332), size: 20)
              : null,
          filled: true,
          fillColor: _kFieldFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
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
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kFieldFill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        inputFormatters: inputFormatters ??
            (keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true)
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF1B4332), size: 20)
              : null,
          filled: true,
          fillColor: _kFieldFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
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

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    bool freePick = false,
  }) {
    // En adminMode el admin edita libremente — nunca captura la hora actual.
    final canFreePick = freePick || widget.adminMode;

    return Container(
      decoration: BoxDecoration(
        color: _kFieldFill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
      ),
      child: TextFormField(
      controller: controller,
      readOnly: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.schedule_rounded, color: Color(0xFF1B4332), size: 20),
        filled: true,
        fillColor: _kFieldFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC53030), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC53030), width: 2),
        ),
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.touch_app_outlined,
                size: 18, color: Color(0xFF1B4332))
            : IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() => controller.clear());
                  _autoGuardar();
                },
              ),
      ),
      onTap: () async {
        if (canFreePick) {
          final partes = controller.text.split(':');
          final initial = partes.length == 2
              ? TimeOfDay(
                  hour: int.tryParse(partes[0]) ?? TimeOfDay.now().hour,
                  minute: int.tryParse(partes[1]) ?? TimeOfDay.now().minute,
                )
              : TimeOfDay.now();
          final picked =
              await showSpinnerTimePicker(context: context, initialTime: initial);
          if (picked != null && mounted) {
            setState(() {
              controller.text =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            });
            _autoGuardar();
          }
          return;
        }
        // Bloqueado: captura la hora exacta del toque y no permite editar después.
        if (controller.text.isNotEmpty) return;
        final now = TimeOfDay.now();
        setState(() {
          controller.text =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        });
        _autoGuardar();
      },
      ),
    );
  }
}

// ─── Widgets privados ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.loading,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4332),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 18, color: const Color(0xFF1B4332)),
                const SizedBox(width: 8),
                Text(title.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1B4332),
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
}

// ─── Buscador de operadores (bottom sheet) ────────────────────────────────────

class _OperadorSearchSheet extends StatefulWidget {
  final List<Trabajador> operadores;
  final Trabajador? seleccionado;
  final void Function(Trabajador) onSelect;

  const _OperadorSearchSheet({
    required this.operadores,
    required this.seleccionado,
    required this.onSelect,
  });

  @override
  State<_OperadorSearchSheet> createState() => _OperadorSearchSheetState();
}

class _OperadorSearchSheetState extends State<_OperadorSearchSheet> {
  final _searchCtrl = TextEditingController();
  late List<Trabajador> _filtrados;

  @override
  void initState() {
    super.initState();
    _filtrados = widget.operadores;
    _searchCtrl.addListener(_filtrar);
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? widget.operadores
          : widget.operadores.where((t) {
              return t.nombreCompleto.toLowerCase().contains(q) ||
                  t.codTrabajador.toLowerCase().contains(q) ||
                  (t.dni ?? '').contains(q);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 8),
              child: Row(children: [
                const Icon(Icons.person_search, color: Color(0xFF1B4332)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Seleccionar Operador',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
            ),
            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código...',
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF1B4332), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtrados.length} operador${_filtrados.length == 1 ? '' : 'es'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ),
            const Divider(height: 1),
            // Lista filtrada (usa ListView.builder — no construye todos los items)
            Expanded(
              child: _filtrados.isEmpty
                  ? const Center(
                      child: Text('Sin resultados',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _filtrados.length,
                      itemBuilder: (ctx, i) {
                        final t = _filtrados[i];
                        final isSelected =
                            widget.seleccionado?.idErp == t.idErp;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? const Color(0xFF1B4332)
                                : const Color(0xFFE8F5E9),
                            child: Text(
                              t.nombres.isNotEmpty
                                  ? t.nombres[0].toUpperCase()
                                  : 'O',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1B4332),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            t.nombreCompleto,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1B4332)
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            t.codTrabajador,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF1B4332))
                              : null,
                          onTap: () {
                            widget.onSelect(t);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }
}
