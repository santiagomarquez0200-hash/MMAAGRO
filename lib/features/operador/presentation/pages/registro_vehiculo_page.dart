import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';
import 'package:agro_aplicaciones/shared/widgets/scanner_dialog.dart';
import 'package:agro_aplicaciones/shared/widgets/spinner_time_picker.dart';
import 'package:drift/drift.dart' show UpdateKind, Value, Variable;
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';

// ──────────────────────────────────────────────────────────────────────────────
// MODELOS INTERNOS
// ──────────────────────────────────────────────────────────────────────────────

class _CombustibleRow {
  final String id;
  final TextEditingController glns;
  final TextEditingController horaInicio;
  final TextEditingController horaFinal;

  _CombustibleRow({required this.id})
      : glns = TextEditingController(),
        horaInicio = TextEditingController(),
        horaFinal = TextEditingController();

  void dispose() {
    glns.dispose();
    horaInicio.dispose();
    horaFinal.dispose();
  }
}

class _ParoRow {
  final String id;
  final TextEditingController motivo;
  final TextEditingController horaInicio;
  final TextEditingController horaFinal;

  _ParoRow({required this.id})
      : motivo = TextEditingController(),
        horaInicio = TextEditingController(),
        horaFinal = TextEditingController();

  void dispose() {
    motivo.dispose();
    horaInicio.dispose();
    horaFinal.dispose();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PÁGINA PRINCIPAL
// ──────────────────────────────────────────────────────────────────────────────

class RegistroVehiculoPage extends StatefulWidget {
  const RegistroVehiculoPage({super.key});

  @override
  State<RegistroVehiculoPage> createState() => _RegistroVehiculoPageState();
}

class _RegistroVehiculoPageState extends State<RegistroVehiculoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  bool _turnoLocked = false;

  // ── 1. DATOS GENERALES ──
  DateTime _fecha = DateTime.now();
  String _turno = 'dia';
  String? _procesoVehiculo;
  Cultivo? _cultivo;
  Vehiculo? _vehiculo;
  Implemento? _implemento;
  final _supervisorNombreCtrl = TextEditingController();

  final List<String> _procesosOptions = [
    'Regado de caminos',
    'Traslado de mangueras',
    'Traslado de materiales',
    'Abastecimiento',
    'Otro',
  ];

  // ── 2. INICIO DE TURNO ──
  final _kmCamionInicioCtrl = TextEditingController();
  final _kmImplementoInicioCtrl = TextEditingController();
  final _horaSalidaBaseCtrl = TextEditingController();
  final _horaLlegadaZonaCtrl = TextEditingController();
  final _cantidadTancadasCtrl = TextEditingController();

  // ── 3. COMBUSTIBLE ──
  final List<_CombustibleRow> _combustibles = [];

  // ── 4. PAROS MECÁNICOS ──
  final List<_ParoRow> _paros = [];

  // ── 5. CHECKLIST ──
  final Map<int, String> _checklistResultados = {};

  // ── 6. FIN DE TURNO ──
  final _kmCamionFinalCtrl = TextEditingController();
  final _kmImplementoFinalCtrl = TextEditingController();
  final _horaRefrigerioInicioCtrl = TextEditingController();
  final _horaRefrigerioFinCtrl = TextEditingController();
  final _horaRetornoBaseCtrl = TextEditingController();
  final _horaLlegadaTallerCtrl = TextEditingController();

  // ── 7. OBSERVACIONES ──
  final _observacionesCtrl = TextEditingController();

  // ── Último horómetro del tractor seleccionado (desde BD local) ──
  double? _ultimoHorometroFinal;
  double? _ultimoImplementoFinal;

  @override
  void initState() {
    super.initState();
    _cargarTurnoJornada();
  }

  Future<void> _cargarUltimoHorometro(int tractorIdErp) async {
    final db = sl<AppDatabase>();
    final rows = await db.customSelect(
      'SELECT horometro_final, implemento_final FROM ultimo_horometro_tractores_local WHERE tractor_id_erp = ?',
      variables: [Variable.withInt(tractorIdErp)],
    ).get();
    if (!mounted) return;
    if (rows.isNotEmpty) {
      final h = rows.first.data['horometro_final'];
      final imp = rows.first.data['implemento_final'];
      setState(() {
        _ultimoHorometroFinal = h != null ? (h as num).toDouble() : null;
        _ultimoImplementoFinal = imp != null ? (imp as num).toDouble() : null;
      });
    } else {
      setState(() {
        _ultimoHorometroFinal = null;
        _ultimoImplementoFinal = null;
      });
    }
  }

  Future<void> _cargarTurnoJornada() async {
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

  @override
  void dispose() {
    _kmCamionInicioCtrl.dispose();
    _kmImplementoInicioCtrl.dispose();
    _horaSalidaBaseCtrl.dispose();
    _horaLlegadaZonaCtrl.dispose();
    _cantidadTancadasCtrl.dispose();
    _kmCamionFinalCtrl.dispose();
    _kmImplementoFinalCtrl.dispose();
    _horaRefrigerioInicioCtrl.dispose();
    _horaRefrigerioFinCtrl.dispose();
    _horaRetornoBaseCtrl.dispose();
    _horaLlegadaTallerCtrl.dispose();
    _observacionesCtrl.dispose();
    _supervisorNombreCtrl.dispose();
    for (var r in _combustibles) {
      r.dispose();
    }
    for (var r in _paros) {
      r.dispose();
    }
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // LÓGICA DE NEGOCIO
  // ────────────────────────────────────────────────────────────────────────────

  Future<String> _generateNumeroRegistro() async {
    final dateStr = DateFormat('yyyyMMdd').format(_fecha);
    final prefix = 'RV-$dateStr-';
    // Usar contador atómico en SharedPreferences para sobrevivir limpiezas de
    // SQLite entre turnos y evitar colisiones de UNIQUE en el servidor.
    final prefs = await SharedPreferences.getInstance();
    final key = 'reg_seq_veh_$dateStr';
    final db = sl<AppDatabase>();
    final sqliteCount = (await db.select(db.registrosDiariosLocal).get())
        .where((r) => r.numeroRegistro.startsWith(prefix))
        .length;
    final storedSeq = prefs.getInt(key) ?? 0;
    final next = (storedSeq > sqliteCount ? storedSeq : sqliteCount) + 1;
    await prefs.setInt(key, next);
    return '$prefix${next.toString().padLeft(3, '0')}';
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : const Color(0xFF1B4332),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 15)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final partes = ctrl.text.split(':');
    final initial = partes.length == 2
        ? TimeOfDay(
            hour: int.tryParse(partes[0]) ?? TimeOfDay.now().hour,
            minute: int.tryParse(partes[1]) ?? TimeOfDay.now().minute,
          )
        : TimeOfDay.now();
    final t = await showSpinnerTimePicker(
      context: context,
      initialTime: initial,
    );
    if (t != null) {
      setState(() => ctrl.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    if (_procesoVehiculo == null || _vehiculo == null) {
      _showSnack('Vehículo y Proceso son obligatorios', error: true);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final usuario = authState.usuario;

    setState(() => _guardando = true);
    try {
      final db = sl<AppDatabase>();
      final deviceId = await sl<DeviceService>().getDeviceId();
      final registroId = const Uuid().v4();
      final numeroReg = await _generateNumeroRegistro();
      final checklistCatalog = await db.catalogoDao.getChecklistItems();
      final checklistById = {
        for (final item in checklistCatalog) item.id: item,
      };

      await db.transaction(() async {
        // 1. Registro Diario (Cabecera común)
        await db.into(db.registrosDiariosLocal).insert(
              RegistrosDiariosLocalCompanion.insert(
                id: registroId,
                numeroRegistro: Value(numeroReg),
                fecha: _fecha,
                turno: Value(_turno),
                procesoId: 0,
                procesoNombre: Value(_procesoVehiculo!),
                procesoCodigo:
                    Value(_procesoVehiculo!.substring(0, 4).toUpperCase()),
                operadorIdErp: usuario.trabajadorIdErp ?? 0,
                operadorNombre: Value(usuario.nombreCompleto),
                operadorCodigo: Value(usuario.codigo),
                supervisorIdErp: const Value(null),
                supervisorNombre: Value(
                    _supervisorNombreCtrl.text.trim().isNotEmpty
                        ? _supervisorNombreCtrl.text.trim()
                        : null),
                supervisorCodigo: const Value(null),
                tractorIdErp: _vehiculo!.idErp,
                tractorCodigo: Value(_vehiculo!.codigoVehiculo),
                tractorDescripcion: Value(_vehiculo!.descripcion),
                implementoIdErp: Value(_implemento?.idErp),
                implementoCodigo: Value(_implemento?.codigoImplemento),
                implementoDescripcion: Value(_implemento?.descripcion),
                cultivoIdErp: _cultivo?.idErp ?? 0,
                cultivoNombreEspecie: Value(_cultivo?.displayName ?? ''),
                tipoRegistro: const Value('vehiculo'),
                estado: const Value('completado'),
                observacionesMaq: Value(_observacionesCtrl.text),
                dispositivoId: Value(deviceId),
              ),
            );

        // 2. Datos de Horómetro (Kilometraje)
        await db.into(db.horometrosLocal).insert(
              HorometrosLocalCompanion.insert(
                id: const Uuid().v4(),
                registroId: registroId,
                tractorInicio: Value(double.tryParse(_kmCamionInicioCtrl.text)),
                tractorFinal: Value(double.tryParse(_kmCamionFinalCtrl.text)),
                implementoInicio:
                    Value(double.tryParse(_kmImplementoInicioCtrl.text)),
                implementoFinal:
                    Value(double.tryParse(_kmImplementoFinalCtrl.text)),
              ),
            );

        // 3. Tiempos de Turno
        await db.into(db.tiemposTurnoLocal).insert(
              TiemposTurnoLocalCompanion.insert(
                id: const Uuid().v4(),
                registroId: registroId,
                horaSalidaTaller: Value(_horaSalidaBaseCtrl.text),
                horaLlegadaPunto: Value(_horaLlegadaZonaCtrl.text),
                horaSalidaPunto: Value(_horaRetornoBaseCtrl.text),
                horaLlegadaTaller: Value(_horaLlegadaTallerCtrl.text),
                horaRefrigerio: Value(
                    '${_horaRefrigerioInicioCtrl.text} - ${_horaRefrigerioFinCtrl.text}'),
              ),
            );

        // 4. Combustibles
        for (var row in _combustibles) {
          await db.into(db.combustibleVehiculoLocal).insert(
                CombustibleVehiculoLocalCompanion.insert(
                  id: const Uuid().v4(),
                  registroId: registroId,
                  glns: Value(double.tryParse(row.glns.text)),
                  horaInicio: Value(row.horaInicio.text),
                  horaFinal: Value(row.horaFinal.text),
                ),
              );
        }

        // 5. Paros
        for (var row in _paros) {
          await db.into(db.parosEquiposLocal).insert(
                ParosEquiposLocalCompanion.insert(
                  id: const Uuid().v4(),
                  registroId: registroId,
                  tipoParoId: 0, // 0 para vehículo según IMPLEMENTAR.txt
                  motivo: Value(row.motivo.text),
                  horaInicio: row.horaInicio.text,
                  horaFinal: Value(row.horaFinal.text),
                ),
              );
        }

        // 5. Checklist
        for (var entry in _checklistResultados.entries) {
          final item = checklistById[entry.key];
          await db.into(db.checklistResultadosLocal).insert(
                ChecklistResultadosLocalCompanion.insert(
                  id: const Uuid().v4(),
                  registroId: registroId,
                  itemId: entry.key,
                  itemNombre: Value(item?.nombre ?? ''),
                  categoriaNombre: Value(item?.categoriaNombre ?? ''),
                  resultado: entry.value,
                ),
              );
        }

        // 6. Outbox
        final checklistItems = _checklistResultados.entries
            .map((e) => ({'item_id': e.key, 'resultado': e.value}))
            .toList();

        final payload = {
          'id': registroId,
          'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
          'turno': _turno,
          'proceso_id': null,
          'proceso_vehiculo': _procesoVehiculo,
          'cultivo_id_erp': _cultivo?.idErp,
          'cultivo_nombre_especie': _cultivo?.displayName ?? '',
          'cultivo_codigo_especie': '',
          'operador_id_erp': usuario.trabajadorIdErp ?? 0,
          'operador_codigo': usuario.codigo,
          'operador_nombre': usuario.nombreCompleto,
          'supervisor_id_erp': null,
          'supervisor_codigo': null,
          'supervisor_nombre': _supervisorNombreCtrl.text.trim().isNotEmpty
              ? _supervisorNombreCtrl.text.trim()
              : null,
          'numero_registro': numeroReg,
          'tractor_id_erp': _vehiculo!.idErp,
          'tractor_codigo': _vehiculo!.codigoVehiculo,
          'tractor_descripcion': _vehiculo!.descripcion,
          'implemento_id_erp': _implemento?.idErp,
          'implemento_codigo': _implemento?.codigoImplemento,
          'implemento_descripcion': _implemento?.descripcion,
          'km_camion_inicio': double.tryParse(_kmCamionInicioCtrl.text),
          'km_camion_final': double.tryParse(_kmCamionFinalCtrl.text),
          'km_implemento_inicio': double.tryParse(_kmImplementoInicioCtrl.text),
          'km_implemento_final': double.tryParse(_kmImplementoFinalCtrl.text),
          'hora_salida_base_td': _horaSalidaBaseCtrl.text,
          'hora_llegada_zona': _horaLlegadaZonaCtrl.text,
          'hora_retorno_base': _horaRetornoBaseCtrl.text,
          'hora_llegada_taller': _horaLlegadaTallerCtrl.text,
          'hora_refrigerio': (_horaRefrigerioInicioCtrl.text.isNotEmpty ||
                  _horaRefrigerioFinCtrl.text.isNotEmpty)
              ? '${_horaRefrigerioInicioCtrl.text} - ${_horaRefrigerioFinCtrl.text}'
              : null,
          'cantidad_tancadas': int.tryParse(_cantidadTancadasCtrl.text),
          'observaciones_maq': _observacionesCtrl.text,
          'combustibles': _combustibles
              .map((c) => ({
                    'glns': double.tryParse(c.glns.text),
                    'hora_inicio': c.horaInicio.text,
                    'hora_final': c.horaFinal.text
                  }))
              .toList(),
          'paros': _paros
              .map((p) => ({
                    'motivo': p.motivo.text,
                    'hora_inicio': p.horaInicio.text,
                    'hora_final': p.horaFinal.text
                  }))
              .toList(),
          'checklist': checklistItems,
          'dispositivo_id': deviceId,
          'created_by_erp': usuario.trabajadorIdErp ?? 0,
          'tipo_registro': 'vehiculo',
        };

        await db.outboxDao.insertEntry(OutboxEntriesCompanion.insert(
          registroLocalId: Value(registroId),
          endpoint: 'POST /registros/vehiculo',
          method: 'POST',
          payloadJson: jsonEncode(payload),
        ));
      });

      // Actualizar referencia de último horómetro para este tractor.
      // Se hace fuera de la transacción principal para no bloquearla,
      // y solo si el usuario registró un KM final.
      final kmFinal = double.tryParse(_kmCamionFinalCtrl.text);
      final impFinal = double.tryParse(_kmImplementoFinalCtrl.text);
      if (kmFinal != null) {
        await db.customUpdate(
          '''INSERT OR REPLACE INTO ultimo_horometro_tractores_local
             (tractor_id_erp, horometro_final, implemento_final, ultima_fecha, updated_at)
             VALUES (?, ?, ?, ?, strftime('%s','now') * 1000)''',
          variables: [
            Variable.withInt(_vehiculo!.idErp),
            Variable.withReal(kmFinal),
            Variable(impFinal),
            Variable.withString(DateFormat('yyyy-MM-dd').format(_fecha)),
          ],
          updateKind: UpdateKind.insert,
        );
      }

      _showSnack(
          'Registro de vehículo guardado. Sincroniza desde Registros Pendientes.');
      if (mounted) context.pop();
    } catch (e) {
      _showSnack('Error al guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // UI - CONSTRUCCIÓN
  // ────────────────────────────────────────────────────────────────────────────

  bool get _hayContenido =>
      _procesoVehiculo != null ||
      _vehiculo != null ||
      _cultivo != null ||
      _kmCamionInicioCtrl.text.isNotEmpty ||
      _horaSalidaBaseCtrl.text.isNotEmpty ||
      _observacionesCtrl.text.isNotEmpty;

  Future<void> _onPopRequested() async {
    if (_guardando) return;
    if (!_hayContenido) { context.pop(); return; }
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Los datos ingresados se perderán si sales ahora.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SALIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (salir == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _onPopRequested(); },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: BlocBuilder<CatalogoBloc, CatalogoState>(
        builder: (context, state) {
          if (state is! CatalogoLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehiculoChecklist = state.checklistItems
              .where((i) => i.tipoRegistro == 'vehiculo')
              .toList();

          return Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSectionDatosGenerales(state),
                        const SizedBox(height: 20),
                        _buildSectionInicioTurno(),
                        const SizedBox(height: 20),
                        _buildSectionCombustible(),
                        const SizedBox(height: 20),
                        _buildSectionParos(),
                        const SizedBox(height: 20),
                        _buildSectionChecklist(vehiculoChecklist),
                        const SizedBox(height: 20),
                        _buildSectionFinTurno(),
                        const SizedBox(height: 20),
                        _buildSectionObservaciones(),
                        const SizedBox(height: 32),
                        _buildBotonGuardar(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ), // Scaffold
    ); // PopScope
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SECCIONES UI
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B4332),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 16,
          left: 8,
          right: 16),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop()),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registro Vehículo',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('MMA-FR-013  •  Control diario de camión',
                  style: TextStyle(color: Color(0xFFB7D979), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDatosGenerales(CatalogoLoaded state) {
    final authState = context.read<AuthBloc>().state;
    final operador =
        authState is AuthAuthenticated ? authState.usuario.nombreCompleto : '—';

    return _CardWrapper(
      title: '1. DATOS GENERALES',
      icon: Icons.assignment_outlined,
      children: [
        _buildInfoRow('Operador', operador, Icons.person),
        const SizedBox(height: 12),
        _buildDateTile(),
        const SizedBox(height: 12),
        _buildTurnoToggle(),
        const SizedBox(height: 16),
        _buildDropdown<String>(
          label: 'Proceso Vehículo *',
          value: _procesoVehiculo,
          items: _procesosOptions,
          itemLabel: (v) => v,
          onChanged: (v) => setState(() => _procesoVehiculo = v),
        ),
        const SizedBox(height: 16),
        _buildDropdown<Cultivo>(
          label: 'Cultivo (Opcional)',
          value: _cultivo,
          items: state.cultivos,
          itemLabel: (v) => v.displayName,
          onChanged: (v) => setState(() => _cultivo = v),
        ),
        const SizedBox(height: 16),
        _buildDropdownWithScan<Vehiculo>(
          label: 'Camión/Vehículo *',
          value: _vehiculo,
          items: state.vehiculos,
          itemLabel: (v) {
            final interno = (v.codigoInterno ?? '').trim();
            final codigo = v.codigoVehiculo.trim();
            return interno.isEmpty ? codigo : '$codigo-$interno';
          },
          onChanged: (v) {
            setState(() {
              _vehiculo = v;
              _ultimoHorometroFinal = null;
              _ultimoImplementoFinal = null;
            });
            if (v != null) _cargarUltimoHorometro(v.idErp);
          },
          onScan: () => _handleScanVehiculo(state.vehiculos, (t) {
            setState(() {
              _vehiculo = t;
              _ultimoHorometroFinal = null;
              _ultimoImplementoFinal = null;
            });
            _cargarUltimoHorometro(t.idErp);
          }),
        ),
        if (_ultimoHorometroFinal != null) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed_rounded,
                    size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Último KM registrado: ${_ultimoHorometroFinal!.toStringAsFixed(1)}'
                    '${_ultimoImplementoFinal != null ? '  |  Implemento: ${_ultimoImplementoFinal!.toStringAsFixed(1)}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildDropdownWithScan<Implemento>(
          label: 'Implemento (Opcional)',
          value: _implemento,
          items: state.implementos,
          itemLabel: (v) {
            final interno = (v.codigoInterno ?? '').trim();
            final codigo = v.codigoImplemento.trim();
            return interno.isEmpty ? codigo : '$codigo-$interno';
          },
          onChanged: (v) => setState(() => _implemento = v),
          onScan: () => _handleScanImplemento(state.implementos),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _supervisorNombreCtrl,
          decoration: InputDecoration(
            labelText: 'Supervisor (Opcional)',
            hintText: 'Escriba el nombre del supervisor',
            prefixIcon:
                const Icon(Icons.supervisor_account, color: Color(0xFF1B4332)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionInicioTurno() {
    return _CardWrapper(
      title: '2. INICIO DE TURNO',
      icon: Icons.play_circle_outline,
      children: [
        _buildNumField(_kmCamionInicioCtrl, 'KM Camion Inicio *',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (_ultimoHorometroFinal != null) {
                final val = double.tryParse(v) ?? 0;
                if (val <= _ultimoHorometroFinal!) {
                  return 'Debe ser mayor a ${_ultimoHorometroFinal!.toStringAsFixed(1)} (último KM)';
                }
              }
              return null;
            }),
        const SizedBox(height: 16),
        _buildNumField(_kmImplementoInicioCtrl, 'KM Implemento Inicio'),
        const SizedBox(height: 16),
        _buildTimeField(_horaSalidaBaseCtrl, 'Hora Salida Base *',
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
        const SizedBox(height: 16),
        _buildTimeField(_horaLlegadaZonaCtrl, 'Hora Llegada Zona *',
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
        const SizedBox(height: 16),
        _buildNumField(_cantidadTancadasCtrl, 'Cantidad Tancadas',
            icon: Icons.local_gas_station),
      ],
    );
  }

  Widget _buildSectionCombustible() {
    return _CardWrapper(
      title: '3. COMBUSTIBLE',
      icon: Icons.ev_station,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF1B4332)),
        onPressed: () => setState(
            () => _combustibles.add(_CombustibleRow(id: const Uuid().v4()))),
      ),
      children: [
        if (_combustibles.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay registros',
                      style: TextStyle(color: Colors.grey)))),
        ..._combustibles
            .asMap()
            .entries
            .map((e) => _buildCombustibleItem(e.key, e.value)),
      ],
    );
  }

  Widget _buildSectionParos() {
    return _CardWrapper(
      title: '4. PAROS MECÁNICOS',
      icon: Icons.build_circle_outlined,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF1B4332)),
        onPressed: () =>
            setState(() => _paros.add(_ParoRow(id: const Uuid().v4()))),
      ),
      children: [
        if (_paros.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay registros',
                      style: TextStyle(color: Colors.grey)))),
        ..._paros.asMap().entries.map((e) => _buildParoItem(e.key, e.value)),
      ],
    );
  }

  Widget _buildSectionChecklist(List<ChecklistItem> items) {
    return _CardWrapper(
      title: '5. CHECKLIST DIARIO',
      icon: Icons.checklist_rtl,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final result = _checklistResultados[item.id] ?? 'na';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                      child: Text('${index + 1}. ${item.nombre}',
                          style: const TextStyle(fontSize: 14))),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'bien',
                          label: Text('Bien', style: TextStyle(fontSize: 12))),
                      ButtonSegment(
                          value: 'mal',
                          label: Text('Mal', style: TextStyle(fontSize: 12))),
                      ButtonSegment(
                          value: 'na',
                          label: Text('N/A', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {result},
                    onSelectionChanged: (val) => setState(
                        () => _checklistResultados[item.id] = val.first),
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      selectedBackgroundColor: result == 'bien'
                          ? Colors.green
                          : (result == 'mal' ? Colors.red : Colors.grey),
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionFinTurno() {
    return _CardWrapper(
      title: '6. FIN DE TURNO',
      icon: Icons.stop_circle_outlined,
      children: [
        _buildNumField(_kmCamionFinalCtrl, 'KM Camion Final *', validator: (v) {
          if (v == null || v.isEmpty) return 'Requerido';
          final start = double.tryParse(_kmCamionInicioCtrl.text) ?? 0;
          final end = double.tryParse(v) ?? 0;
          if (end < start) return 'Debe ser >= KM Inicio';
          return null;
        }),
        const SizedBox(height: 16),
        _buildNumField(_kmImplementoFinalCtrl, 'KM Implemento Final'),
        const SizedBox(height: 16),
        _buildTimeField(_horaRetornoBaseCtrl, 'Hora Retorno Base'),
        const SizedBox(height: 16),
        _buildTimeField(_horaLlegadaTallerCtrl, 'Hora Llegada Taller'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildTimeField(
                    _horaRefrigerioInicioCtrl, 'Refrigerio Inicio')),
            const SizedBox(width: 12),
            Expanded(
                child:
                    _buildTimeField(_horaRefrigerioFinCtrl, 'Refrigerio Fin')),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionObservaciones() {
    return _CardWrapper(
      title: '7. OBSERVACIONES',
      icon: Icons.comment_outlined,
      children: [
        TextFormField(
          controller: _observacionesCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Escriba observaciones...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // COMPONENTES REUTILIZABLES
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B4332)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF1B4332)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fecha',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(DateFormat('dd/MM/yyyy').format(_fecha),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnoToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTurnoChip('Día (06:00 - 14:00)', 'dia',
                    Icons.wb_sunny_outlined, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildTurnoChip('Noche (14:00 - 22:00)', 'noche',
                    Icons.nightlight_outlined, Colors.blue)),
          ],
        ),
        if (_turnoLocked)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 12,
                    color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Turno bloqueado por jornada activa',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTurnoChip(
      String label, String value, IconData icon, Color color) {
    final isSel = _turno == value;
    return GestureDetector(
      onTap: _turnoLocked ? null : () => setState(() => _turno = value),
      child: Opacity(
        opacity: (_turnoLocked && !isSel) ? 0.35 : 1.0,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.1) : Colors.white,
          border:
              Border.all(color: isSel ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSel ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSel ? color : Colors.grey,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNumField(TextEditingController ctrl, String label,
      {IconData icon = Icons.speed, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildTimeField(TextEditingController ctrl, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _pickTime(ctrl),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCombustibleItem(int index, _CombustibleRow row) {
    return Column(
      children: [
        _buildNumField(row.glns, 'GLNS', icon: Icons.local_gas_station),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTimeField(row.horaInicio, 'Hora Inicio')),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeField(row.horaFinal, 'Hora Final')),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () => setState(() => _combustibles.removeAt(index)),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildParoItem(int index, _ParoRow row) {
    return Column(
      children: [
        TextFormField(
          controller: row.motivo,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Motivo *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildTimeField(row.horaInicio, 'Hora Inicio *',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requerido' : null)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeField(row.horaFinal, 'Hora Final')),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () => setState(() => _paros.removeAt(index)),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4332),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _guardando ? null : _save,
        child: _guardando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('GUARDAR REGISTRO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // UTILIDADES
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items
          .map((i) => DropdownMenuItem(
              value: i,
              child: Text(itemLabel(i), style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownWithScan<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required VoidCallback onScan,
  }) {
    return Row(
      children: [
        Expanded(
            child: _buildDropdown<T>(
                label: label,
                value: value,
                items: items,
                itemLabel: itemLabel,
                onChanged: onChanged)),
        const SizedBox(width: 12),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1B4332)),
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: onScan,
        ),
      ],
    );
  }

  Future<void> _handleScanVehiculo(
      List<Vehiculo> vehiculos, void Function(Vehiculo) onFound) async {
    final code = await showScannerDialog(context, label: 'Escanear Vehículo');
    if (code == null) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = vehiculos.cast<Vehiculo?>().firstWhere(
          (v) {
            final c = v!.codigoVehiculo.replaceAll(' ', '').trim().toUpperCase();
            final i = (v.codigoInterno ?? '').replaceAll(' ', '').trim().toUpperCase();
            final concat = i.isEmpty ? c : '$c-$i';
            return c == upper || i == upper || concat == upper;
          },
          orElse: () => null,
        );
    if (found != null) {
      onFound(found);
    } else {
      _showSnack('Código "$upper" no encontrado', error: true);
    }
  }

  Future<void> _handleScanImplemento(List<Implemento> implementos) async {
    final code = await showScannerDialog(context, label: 'Escanear Implemento');
    if (code == null) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = implementos.cast<Implemento?>().firstWhere(
          (t) {
            final c = t!.codigoImplemento.replaceAll(' ', '').trim().toUpperCase();
            final i = (t.codigoInterno ?? '').replaceAll(' ', '').trim().toUpperCase();
            final concat = i.isEmpty ? c : '$c-$i';
            return c == upper || i == upper || concat == upper;
          },
          orElse: () => null,
        );
    if (found != null) {
      setState(() => _implemento = found);
    } else {
      _showSnack('Código "$upper" no encontrado', error: true);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CARD WRAPPER
// ──────────────────────────────────────────────────────────────────────────────

class _CardWrapper extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _CardWrapper(
      {required this.title,
      required this.icon,
      required this.children,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: const Color(0x221B4332),
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE3EAE3))),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: const Color(0xFF1B4332)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1B4332)))),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFE8EFE8)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
