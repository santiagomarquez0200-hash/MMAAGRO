import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// MODELOS INTERNOS (Idénticos a RegistroVehiculoPage para consistencia)
// ──────────────────────────────────────────────────────────────────────────────

class _CombustibleRow {
  final String id;
  final TextEditingController glns;
  final TextEditingController horaInicio;
  final TextEditingController horaFinal;

  _CombustibleRow({required this.id, String? g, String? hi, String? hf})
      : glns = TextEditingController(text: g),
        horaInicio = TextEditingController(text: hi),
        horaFinal = TextEditingController(text: hf);

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

  _ParoRow({required this.id, String? m, String? hi, String? hf})
      : motivo = TextEditingController(text: m),
        horaInicio = TextEditingController(text: hi),
        horaFinal = TextEditingController(text: hf);

  void dispose() {
    motivo.dispose();
    horaInicio.dispose();
    horaFinal.dispose();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PÁGINA DE EDICIÓN
// ──────────────────────────────────────────────────────────────────────────────

class EditarRegistroVehiculoPage extends StatefulWidget {
  final String registroId;
  const EditarRegistroVehiculoPage({super.key, required this.registroId});

  @override
  State<EditarRegistroVehiculoPage> createState() =>
      _EditarRegistroVehiculoPageState();
}

class _EditarRegistroVehiculoPageState
    extends State<EditarRegistroVehiculoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  // ── 1. DATOS GENERALES ──
  DateTime _fecha = DateTime.now();
  String _turno = 'dia';
  String? _procesoVehiculo;
  Cultivo? _cultivo;
  Tractor? _tractor;
  Implemento? _implemento;
  int? _tractorIdErp;
  int? _implementoIdErp;
  int? _cultivoIdErp;
  final _supervisorNombreCtrl = TextEditingController();
  String _numeroRegistro = '';

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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final repository = sl<RegistroRepository>();
      final result = await repository.getRegistro(widget.registroId);

      result.fold(
        (failure) => setState(() {
          _error = 'No se pudo cargar el registro: $failure';
          _cargando = false;
        }),
        (registro) {
          setState(() {
            _numeroRegistro = registro.numeroRegistro;
            _fecha = registro.fecha;
            _turno = registro.turno;
            _procesoVehiculo = registro.procesoNombre;
            _observacionesCtrl.text = registro.observacionesMaq ?? '';
            _supervisorNombreCtrl.text = registro.supervisorNombre ?? '';

            // Cargar detalle vehículo
            if (registro.vehiculoDetalle != null) {
              final det = registro.vehiculoDetalle!;
              _kmCamionInicioCtrl.text = det.kmCamionInicio?.toString() ?? '';
              _kmCamionFinalCtrl.text = det.kmCamionFinal?.toString() ?? '';
              _kmImplementoInicioCtrl.text =
                  det.kmImplementoInicio?.toString() ?? '';
              _kmImplementoFinalCtrl.text =
                  det.kmImplementoFinal?.toString() ?? '';
              _horaSalidaBaseCtrl.text = det.horaSalidaBase ?? '';
              _horaLlegadaZonaCtrl.text = det.horaLlegadaZona ?? '';
              _horaRetornoBaseCtrl.text = det.horaRetornoBase ?? '';
              _horaLlegadaTallerCtrl.text = det.horaLlegadaTaller ?? '';
              _cantidadTancadasCtrl.text =
                  det.cantidadTancadas?.toString() ?? '';

              if (det.horaRefrigerio != null &&
                  det.horaRefrigerio!.contains(' - ')) {
                final partes = det.horaRefrigerio!.split(' - ');
                _horaRefrigerioInicioCtrl.text = partes[0];
                _horaRefrigerioFinCtrl.text = partes[1];
              }
            }

            // Cargar combustibles
            for (var c in registro.combustiblesVehiculo) {
              _combustibles.add(_CombustibleRow(
                id: const Uuid().v4(),
                g: c.glns?.toString(),
                hi: c.horaInicio,
                hf: c.horaFinal,
              ));
            }

            // Cargar paros
            for (var p in registro.parosVehiculo) {
              _paros.add(_ParoRow(
                id: const Uuid().v4(),
                m: p.motivo,
                hi: p.horaInicio,
                hf: p.horaFinal,
              ));
            }

            // Cargar checklist
            for (var res in registro.checklist) {
              _checklistResultados[res.itemId] = res.resultado;
            }

            _tractorIdErp = registro.tractorIdErp;
            _implementoIdErp = registro.implementoIdErp;
            _cultivoIdErp = registro.cultivoIdErp;

            _cargando = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: $e';
        _cargando = false;
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
    for (var r in _combustibles) r.dispose();
    for (var r in _paros) r.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : const Color(0xFF1B4332),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final t =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() => ctrl.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_procesoVehiculo == null || _tractor == null) {
      _showSnack('Tractor y Proceso son obligatorios', error: true);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final usuario = authState.usuario;

    setState(() => _guardando = true);
    try {
      final db = sl<AppDatabase>();
      final deviceId = await sl<DeviceService>().getDeviceId();
      final registroId = widget.registroId;

      await db.transaction(() async {
        // 1. Actualizar Registro Diario
        await (db.update(db.registrosDiariosLocal)
              ..where((t) => t.id.equals(registroId)))
            .write(
          RegistrosDiariosLocalCompanion(
            procesoNombre: Value(_procesoVehiculo!),
            procesoCodigo:
                Value(_procesoVehiculo!.substring(0, 4).toUpperCase()),
            tractorIdErp: Value(_tractor!.idErp),
            tractorCodigo: Value(_tractor!.codigoTractor),
            tractorDescripcion: Value(_tractor!.descripcion),
            implementoIdErp: Value(_implemento?.idErp),
            implementoCodigo: Value(_implemento?.codigoImplemento),
            implementoDescripcion: Value(_implemento?.descripcion),
            cultivoIdErp: Value(_cultivo?.idErp ?? 0),
            cultivoNombreEspecie: Value(_cultivo?.displayName ?? ''),
            supervisorIdErp: const Value(null),
            supervisorNombre: Value(_supervisorNombreCtrl.text.trim().isNotEmpty
                ? _supervisorNombreCtrl.text.trim()
                : null),
            supervisorCodigo: const Value(null),
            observacionesMaq: Value(_observacionesCtrl.text),
            estado: const Value('completado'),
            sincronizado: const Value(false),
          ),
        );

        // 2. Horómetros (KM)
        await (db.delete(db.horometrosLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
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

        // 3. Tiempos Turno
        await (db.delete(db.tiemposTurnoLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
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

        // 3. Combustibles
        await (db.delete(db.combustibleVehiculoLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
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

        // 4. Paros
        await (db.delete(db.parosEquiposLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        for (var row in _paros) {
          await db.into(db.parosEquiposLocal).insert(
                ParosEquiposLocalCompanion.insert(
                  id: const Uuid().v4(),
                  registroId: registroId,
                  tipoParoId: 0,
                  motivo: Value(row.motivo.text),
                  horaInicio: row.horaInicio.text,
                  horaFinal: Value(row.horaFinal.text),
                ),
              );
        }

        // 5. Checklist
        await (db.delete(db.checklistResultadosLocal)
              ..where((t) => t.registroId.equals(registroId)))
            .go();
        for (var entry in _checklistResultados.entries) {
          await db.into(db.checklistResultadosLocal).insert(
                ChecklistResultadosLocalCompanion.insert(
                  id: const Uuid().v4(),
                  registroId: registroId,
                  itemId: entry.key,
                  resultado: entry.value,
                ),
              );
        }

        // 6. Outbox
        final payload = {
          'id': registroId,
          'numero_registro': _numeroRegistro,
          'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
          'turno': _turno,
          'proceso_id': null,
          'proceso_vehiculo': _procesoVehiculo,
          'proceso_nombre': _procesoVehiculo,
          'proceso_codigo': _procesoVehiculo!.substring(0, 4).toUpperCase(),
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
          'tractor_id_erp': _tractor!.idErp,
          'tractor_codigo': _tractor!.codigoTractor,
          'tractor_descripcion': _tractor!.descripcion,
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
          'hora_refrigerio':
              '${_horaRefrigerioInicioCtrl.text} - ${_horaRefrigerioFinCtrl.text}',
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
          'checklist': _checklistResultados.entries
              .map((e) => ({'item_id': e.key, 'resultado': e.value}))
              .toList(),
          'dispositivo_id': deviceId,
          'created_by_erp': usuario.trabajadorIdErp ?? 0,
          'tipo_registro': 'vehiculo',
          'is_update': true,
        };

        // Elimina entradas viejas pendientes/fallidas para este registro
        // (evita que bloqueen el marcado de sincronizado tras el nuevo envío)
        await db.outboxDao.markAllDoneForRegistro(registroId);
        await db.outboxDao.insertEntry(OutboxEntriesCompanion.insert(
          registroLocalId: Value(registroId),
          endpoint: 'PUT /registros/vehiculo',
          method: 'POST',
          payloadJson: jsonEncode(payload),
        ));
      });

      _showSnack(
          'Edición de vehículo guardada. Sincroniza desde Registros Pendientes.');
      if (mounted) context.pop();
    } catch (e) {
      _showSnack('Error al guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: BlocBuilder<CatalogoBloc, CatalogoState>(
        builder: (context, state) {
          if (state is! CatalogoLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_tractorIdErp != null) {
            _tractor = state.tractores
                .where((t) => t.idErp == _tractorIdErp)
                .firstOrNull;
            _tractorIdErp = null;
          }
          if (_implementoIdErp != null) {
            _implemento = state.implementos
                .where((i) => i.idErp == _implementoIdErp)
                .firstOrNull;
            _implementoIdErp = null;
          }
          if (_cultivoIdErp != null) {
            _cultivo = state.cultivos
                .where((c) => c.idErp == _cultivoIdErp)
                .firstOrNull;
            _cultivoIdErp = null;
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
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xFF1B4332),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 8,
          right: 16),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar Vehículo',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(_numeroRegistro,
                    style: const TextStyle(
                        color: Color(0xFF8CC53F), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDatosGenerales(CatalogoLoaded state) {
    return _CardWrapper(
      title: '1. DATOS GENERALES',
      icon: Icons.assignment_outlined,
      children: [
        _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy').format(_fecha),
            Icons.calendar_today),
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
        _buildDropdown<Tractor>(
          label: 'Camión/Vehículo *',
          value: _tractor,
          items: state.tractores,
          itemLabel: (v) => '${v.codigoTractor}-${v.codigoTractor}',
          onChanged: (v) => setState(() => _tractor = v),
        ),
        const SizedBox(height: 16),
        _buildDropdown<Implemento>(
          label: 'Implemento (Opcional)',
          value: _implemento,
          items: state.implementos,
          itemLabel: (v) => '${v.codigoImplemento}-${v.descripcion}',
          onChanged: (v) => setState(() => _implemento = v),
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
        _buildNumField(_kmCamionInicioCtrl, 'KM Camion Inicio *'),
        const SizedBox(height: 16),
        _buildNumField(_kmImplementoInicioCtrl, 'KM Implemento Inicio'),
        const SizedBox(height: 16),
        _buildTimeField(_horaSalidaBaseCtrl, 'Hora Salida Base *'),
        const SizedBox(height: 16),
        _buildTimeField(_horaLlegadaZonaCtrl, 'Hora Llegada Zona *'),
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
              () => _combustibles.add(_CombustibleRow(id: const Uuid().v4())))),
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
              setState(() => _paros.add(_ParoRow(id: const Uuid().v4())))),
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
        _buildNumField(_kmCamionFinalCtrl, 'KM Camion Final *'),
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

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _guardando ? null : _save,
        icon: _guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save_rounded),
        label: Text(_guardando ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4332),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }

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

  Widget _buildTurnoToggle() {
    return Row(
      children: [
        Expanded(
            child: _buildTurnoChip(
                'Día', 'dia', Icons.wb_sunny_outlined, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildTurnoChip(
                'Noche', 'noche', Icons.nightlight_outlined, Colors.blue)),
      ],
    );
  }

  Widget _buildTurnoChip(
      String label, String value, IconData icon, Color color) {
    final isSel = _turno == value;
    return GestureDetector(
      onTap: () => setState(() => _turno = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.1) : Colors.white,
          border:
              Border.all(color: isSel ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSel ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSel ? color : Colors.grey,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
      {required String label,
      required T? value,
      required List<T> items,
      required String Function(T) itemLabel,
      required ValueChanged<T?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text('Seleccione...',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
              items: items
                  .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text(itemLabel(i),
                          style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumField(TextEditingController ctrl, String label,
      {IconData icon = Icons.speed, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
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
        prefixIcon: const Icon(Icons.access_time, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCombustibleItem(int index, _CombustibleRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Registro #${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      setState(() => _combustibles.removeAt(index))),
            ],
          ),
          const SizedBox(height: 8),
          _buildNumField(row.glns, 'Galones', icon: Icons.local_gas_station),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimeField(row.horaInicio, 'Hora Inicio')),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeField(row.horaFinal, 'Hora Final')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParoItem(int index, _ParoRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paro #${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => setState(() => _paros.removeAt(index))),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: row.motivo,
            decoration: InputDecoration(
                labelText: 'Motivo del paro',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimeField(row.horaInicio, 'Hora Inicio')),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeField(row.horaFinal, 'Hora Final')),
            ],
          ),
        ],
      ),
    );
  }
}

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
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B4332), size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332)))),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
