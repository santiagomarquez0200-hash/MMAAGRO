import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/injection_container.dart';

class VisualizarRegistroPage extends StatefulWidget {
  final String registroId;
  final RegistroDiario? registro;
  const VisualizarRegistroPage(
      {super.key, required this.registroId, this.registro});

  @override
  State<VisualizarRegistroPage> createState() => _VisualizarRegistroPageState();
}

class _VisualizarRegistroPageState extends State<VisualizarRegistroPage> {
  RegistroDiario? _registro;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.registro != null) {
      _registro = widget.registro;
      _cargando = false;
    } else {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    final result = await sl<RegistroRepository>().getRegistro(widget.registroId);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _error = 'No se pudo cargar el registro';
        _cargando = false;
      }),
      (r) => setState(() {
        _registro = r;
        _cargando = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        title: Text(
          _registro?.numeroRegistro ?? 'Visualizar Registro',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          if (_registro != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                _registro!.tipoRegistro == 'vehiculo'
                    ? Icons.directions_car_rounded
                    : Icons.agriculture_rounded,
                color: const Color(0xFF8CC53F),
              ),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : _buildContent(_registro!),
    );
  }

  Widget _buildContent(RegistroDiario r) {
    final esVehiculo = r.tipoRegistro == 'vehiculo';
    final fmt = DateFormat('dd/MM/yyyy');
    final formCode = esVehiculo ? 'MMA-FR-013' : 'MMA-FR-004';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Encabezado tipo formulario ─────────────────────────────────
        _buildFormHeader(r, formCode, fmt, esVehiculo),
        const SizedBox(height: 10),

        // ── Banner de estado ───────────────────────────────────────────
        _buildEstadoBanner(r),
        const SizedBox(height: 10),

        // ── Proceso + Equipo ───────────────────────────────────────────
        _buildProcesoEquipoCard(r, esVehiculo),
        const SizedBox(height: 10),

        // ── Turno (INICIO | FIN) ───────────────────────────────────────
        if (r.horometro != null || r.tiempoTurno != null)
          _buildTurnoCard(r, esVehiculo),
        if (r.horometro != null || r.tiempoTurno != null)
          const SizedBox(height: 10),

        // ── Vehículo extra (combustible, tancadas) ─────────────────────
        if (esVehiculo && r.vehiculoDetalle != null)
          _buildVehiculoExtrasCard(r),
        if (esVehiculo && r.vehiculoDetalle != null) const SizedBox(height: 10),

        // ── Paros ─────────────────────────────────────────────────────
        if (r.paros.isNotEmpty || r.parosVehiculo.isNotEmpty)
          _buildParosCard(r, esVehiculo),
        if (r.paros.isNotEmpty || r.parosVehiculo.isNotEmpty)
          const SizedBox(height: 10),

        // ── Checklist ─────────────────────────────────────────────────
        if (r.checklist.isNotEmpty) _buildChecklistCard(r.checklist),
        if (r.checklist.isNotEmpty) const SizedBox(height: 10),

        // ── Bines (cosecha) ───────────────────────────────────────────
        if (!esVehiculo && r.bines.isNotEmpty) _buildBinesCard(r.bines),
        if (!esVehiculo && r.bines.isNotEmpty) const SizedBox(height: 10),

        // ── Observaciones ─────────────────────────────────────────────
        if (r.observacionesMaq?.isNotEmpty ?? false)
          _buildObsCard(r.observacionesMaq!),
        if (r.observacionesMaq?.isNotEmpty ?? false) const SizedBox(height: 10),

        // ── Sincronización ────────────────────────────────────────────
        _buildSyncBanner(r),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Encabezado estilo formulario (réplica del header del PDF)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFormHeader(
      RegistroDiario r, String formCode, DateFormat fmt, bool esVehiculo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1B4332), width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo / empresa
            Container(
              width: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF7EE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('AK',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('AGROKASA',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332))),
                ],
              ),
            ),
            // Título
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      esVehiculo
                          ? 'CONTROL DIARIO DE OPERACIÓN DE CAMIONES'
                          : 'CONTROL DIARIO DE OPERACIONES AGRÍCOLAS',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332)),
                    ),
                  ],
                ),
              ),
            ),
            // Código / versión / fecha
            Container(
              width: 110,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFF1B4332))),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  _headerInfoCell(formCode, bold: true, bottomBorder: true),
                  _headerInfoCell('Versión: 01', bottomBorder: true),
                  _headerInfoCell(
                    esVehiculo
                        ? 'Aprobación: 06/06/2025'
                        : 'Aprobación: 02/02/2024',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerInfoCell(String text,
      {bool bold = false, bool bottomBorder = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        border: bottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFF1B4332)))
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 9,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF1B4332)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Banner de estado
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEstadoBanner(RegistroDiario r) {
    final (color, bg, icon) = switch (r.estado.toLowerCase()) {
      'aprobado'   => (const Color(0xFF1B5E20), const Color(0xFFE8F5E9), Icons.verified_rounded),
      'completado' => (const Color(0xFF0D47A1), const Color(0xFFE3F2FD), Icons.assignment_turned_in_rounded),
      'rechazado'  => (const Color(0xFFB71C1C), const Color(0xFFFFEBEE), Icons.cancel_rounded),
      _            => (const Color(0xFFE65100), const Color(0xFFFFF3E0), Icons.pending_actions_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(r.estado.toUpperCase(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 15)),
          const Spacer(),
          if (r.motivoRechazo?.isNotEmpty ?? false)
            Flexible(
              child: Text(r.motivoRechazo!,
                  style: TextStyle(color: color, fontSize: 11),
                  textAlign: TextAlign.end),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Proceso + Equipo + Personal
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProcesoEquipoCard(RegistroDiario r, bool esVehiculo) {
    final cod = r.procesoCodigo.toUpperCase();
    final nombre = r.procesoNombre.toUpperCase();

    // Opciones: [label, código-clave]
    final opcionesTractor = [
      ['APLICACIÓN',  'APLIC'],
      ['PODA',        'PODA'],
      ['TRITURADO',   'TRITU'],
      ['MELAZA',      'MELAZ'],
      ['COSECHA',     'COSEC'],
      ['RUFA',        'RUFA'],
      ['CARRETEO',    'CARRE'],
      ['OTRO',        'OTRO'],
    ];
    final opcionesVehiculo = [
      ['REGADO DE CAMINOS',         'REGAD'],
      ['TRASLADO DE MANGUERAS',     'MANGUERAS'],
      ['OTRO',                      'OTRO'],
      ['TRASLADO DE MATERIALES',    'MATERIALES'],
      ['ABASTECIMIENTO APLICACION', 'ABAST'],
    ];

    final opciones = esVehiculo ? opcionesVehiculo : opcionesTractor;
    // columnas por fila: 4 para tractor (8÷2), 3 para vehículo (ajuste visual)
    final cols = esVehiculo ? 3 : 4;

    bool isSelected(String clave) {
      if (clave == 'OTRO') {
        final otrosCodigos = opciones
            .where((o) => o[1] != 'OTRO')
            .map((o) => o[1]);
        return !otrosCodigos.any((c) => cod.contains(c) || nombre.contains(c));
      }
      return cod.contains(clave) || nombre.contains(clave);
    }

    Widget procesoCell(String label, String clave) {
      final sel = isSelected(clave);
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1B4332) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: sel ? const Color(0xFF1B4332) : Colors.grey.shade300,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: sel ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    // Partir opciones en filas de `cols` columnas
    final filas = <List<List<String>>>[];
    for (var i = 0; i < opciones.length; i += cols) {
      filas.add(opciones.sublist(i, (i + cols).clamp(0, opciones.length)));
    }

    return _card(
      icon: esVehiculo ? Icons.local_shipping_rounded : Icons.agriculture_rounded,
      title: 'Proceso y Equipo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grilla de procesos con selección resaltada
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              children: filas.map((fila) {
                // Si la fila tiene menos cols, rellenar con spacers
                final celdas = fila.map((o) => procesoCell(o[0], o[1])).toList();
                while (celdas.length < cols) {
                  celdas.add(const Expanded(child: SizedBox()));
                }
                return Row(children: celdas);
              }).toList(),
            ),
          ),
          // Cultivo debajo (solo tractor)
          if (!esVehiculo && r.cultivoNombreEspecie.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7EE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF8CC53F)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('CULTIVO',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4332))),
                  const SizedBox(width: 6),
                  Text(r.cultivoNombreEspecie,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF14532D))),
                ]),
              ),
            ]),
          ],
          const SizedBox(height: 10),
          _infoGrid([
            _InfoItem('Operador', r.operadorNombre, Icons.person_outline),
            _InfoItem('Supervisor', r.supervisorNombre ?? '-',
                Icons.supervisor_account_outlined),
            _InfoItem(
              esVehiculo ? 'Camión' : 'Tractor',
              _equipoLabel(r.tractorCodigo, r.tractorDescripcion),
              Icons.precision_manufacturing_outlined,
            ),
            if (r.implementoCodigo != null)
              _InfoItem(
                'Implemento',
                _equipoLabel(r.implementoCodigo!, r.implementoDescripcion),
                Icons.build_outlined,
              ),
            _InfoItem('Turno', r.turno.toUpperCase(), Icons.schedule_outlined),
            _InfoItem('Fecha',
                DateFormat('dd/MM/yyyy').format(r.fecha), Icons.calendar_today_outlined),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Turno INICIO | FIN (2 columnas, mirror del PDF)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTurnoCard(RegistroDiario r, bool esVehiculo) {
    final h = r.horometro;
    final t = r.tiempoTurno;
    final lotes = r.sectores
        .map((s) => s.loteCodigo)
        .where((l) => l.isNotEmpty)
        .join(', ');
    final sectores = r.sectores
        .map((s) => s.loteNombre)
        .where((s) => s.isNotEmpty)
        .join(', ');

    return _card(
      icon: Icons.access_time_rounded,
      title: 'Turno de Trabajo',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INICIO
          Expanded(
            child: _turnoColumn('INICIO', const Color(0xFF1B5E20), [
              if (h?.tractorInicio != null)
                _TurnoRow(
                  esVehiculo ? 'KM/Horón. Inicio' : 'Horóm. Tractor',
                  _fmtN(h!.tractorInicio),
                ),
              if (h?.implementoInicio != null)
                _TurnoRow(
                  esVehiculo ? 'Horóm. Impl. Inicio' : 'Horóm. Impl.',
                  _fmtN(h!.implementoInicio),
                ),
              if (t?.horaSalidaTaller != null)
                _TurnoRow('Salida taller', t!.horaSalidaTaller!),
              if (t?.horaLlegadaPunto != null)
                _TurnoRow(
                    esVehiculo ? 'Llegada zona' : 'Llegada punto',
                    t!.horaLlegadaPunto!),
              if (!esVehiculo && r.cajaCambiosNombre != null)
                _TurnoRow('Marcha trabajo', r.cajaCambiosNombre!),
              if (t?.horaRefrigerio != null)
                _TurnoRow('Refrigerio', t!.horaRefrigerio!),
            ]),
          ),
          Container(
              width: 1, height: 120, color: Colors.grey.shade200),
          const SizedBox(width: 8),
          // FIN
          Expanded(
            child: _turnoColumn('FIN', const Color(0xFF1B4332), [
              if (h?.tractorFinal != null)
                _TurnoRow(
                  esVehiculo ? 'KM/Horón. Final' : 'Horóm. Tractor',
                  _fmtN(h!.tractorFinal),
                ),
              if (h?.implementoFinal != null)
                _TurnoRow(
                  esVehiculo ? 'Horóm. Impl. Final' : 'Horóm. Impl.',
                  _fmtN(h!.implementoFinal),
                ),
              if (t?.horaSalidaPunto != null)
                _TurnoRow(
                    esVehiculo ? 'Retorno base' : 'Salida punto',
                    t!.horaSalidaPunto!),
              if (t?.horaLlegadaTaller != null)
                _TurnoRow('Llegada taller', t!.horaLlegadaTaller!),
              if (!esVehiculo && lotes.isNotEmpty)
                _TurnoRow('Lotes', lotes),
              if (!esVehiculo && sectores.isNotEmpty)
                _TurnoRow('Sectores', sectores),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _turnoColumn(
      String titulo, Color color, List<_TurnoRow> filas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
        ),
        const SizedBox(height: 6),
        ...filas.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(f.label,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ),
                  const SizedBox(width: 4),
                  Text(f.valor,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Extras vehículo
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVehiculoExtrasCard(RegistroDiario r) {
    final vd = r.vehiculoDetalle!;
    return _card(
      icon: Icons.local_gas_station_outlined,
      title: 'Datos del Camión',
      child: _infoGrid([
        if (vd.cantidadTancadas != null)
          _InfoItem('Tancadas / traslados',
              '${vd.cantidadTancadas}', Icons.water_drop_outlined),
        if (r.combustiblesVehiculo.isNotEmpty)
          _InfoItem('Cargas comb.',
              '${r.combustiblesVehiculo.length} carga(s)',
              Icons.ev_station_outlined),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Paros
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildParosCard(RegistroDiario r, bool esVehiculo) {
    final parosTractor = esVehiculo ? null : r.paros;

    return _card(
      icon: Icons.pause_circle_outline_rounded,
      title: esVehiculo
          ? 'Paros y Fallas (${r.parosVehiculo.length})'
          : 'Motivos de Paro (${r.paros.length})',
      child: Column(
        children: [
          if (!esVehiculo)
            ...parosTractor!.map((p) => _paroRow(
                  p.tipoParoNombre,
                  '${p.horaInicio} — ${p.horaFinal ?? 'En curso'}',
                  p.motivo,
                )),
          if (esVehiculo)
            ...r.parosVehiculo.asMap().entries.map((e) => _paroRow(
                  'Paro #${e.key + 1}',
                  '${e.value.horaInicio ?? ''} — ${e.value.horaFinal ?? 'En curso'}',
                  e.value.motivo,
                )),
        ],
      ),
    );
  }

  Widget _paroRow(String titulo, String horario, String? motivo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: const BoxDecoration(
                color: Color(0xFFEF6C00), shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text(horario,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
                if (motivo?.isNotEmpty ?? false)
                  Text(motivo!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFEF6C00))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Checklist con barra de progreso y detalle por categoría
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChecklistCard(List<ChecklistResultado> items) {
    final bien = items.where((i) => i.resultado == 'bien').length;
    final mal  = items.where((i) => i.resultado == 'mal').length;
    final na   = items.where((i) => i.resultado == 'na').length;
    final pct  = items.isEmpty ? 0.0 : bien / items.length;

    final categorias = <String>[];
    final porCat = <String, List<ChecklistResultado>>{};
    for (final item in items) {
      final cat = item.categoriaNombre.isNotEmpty
          ? item.categoriaNombre
          : 'General';
      if (!porCat.containsKey(cat)) {
        categorias.add(cat);
        porCat[cat] = [];
      }
      porCat[cat]!.add(item);
    }

    return _card(
      icon: Icons.checklist_rounded,
      title: 'Check List Diario',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen numérico
          Row(
            children: [
              _checkStat('BIEN', bien, const Color(0xFF2E7D32)),
              const SizedBox(width: 10),
              _checkStat('MAL', mal, const Color(0xFFC62828)),
              const SizedBox(width: 10),
              _checkStat('N/A', na, Colors.grey),
              const Spacer(),
              Text('${items.length} ítems',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: mal > 0
                  ? const Color(0xFFFFEBEE)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                pct == 1.0 ? const Color(0xFF2E7D32) : const Color(0xFF8CC53F),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).round()}% conforme',
              style: TextStyle(
                  fontSize: 10,
                  color: pct == 1.0
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade600)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Ítems MAL primero (si los hay)
          if (mal > 0) ...[
            Text('  ITEMS CON FALLA',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.red.shade600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            ...items
                .where((i) => i.resultado == 'mal')
                .map((i) => _checkItem(i)),
            const SizedBox(height: 8),
          ],
          // Categorías
          ...categorias.map((cat) {
            final catItems = porCat[cat]!;
            final catBien = catItems.where((i) => i.resultado == 'bien').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(cat.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.6)),
                  const Spacer(),
                  Text('$catBien/${catItems.length}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                ]),
                const SizedBox(height: 4),
                ...catItems.map((i) => _checkItem(i)),
                const SizedBox(height: 6),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _checkItem(ChecklistResultado item) {
    final (color, icon, bg) = switch (item.resultado) {
      'bien' => (const Color(0xFF2E7D32), Icons.check_rounded, const Color(0xFFE8F5E9)),
      'mal'  => (const Color(0xFFC62828), Icons.close_rounded, const Color(0xFFFFEBEE)),
      _      => (Colors.grey as Color, Icons.remove_rounded, const Color(0xFFF5F5F5)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.itemNombre.isNotEmpty
                  ? item.itemNombre
                  : 'Ítem ${item.itemId}',
              style: TextStyle(
                  fontSize: 11,
                  color: item.resultado == 'mal'
                      ? const Color(0xFFC62828)
                      : Colors.black87,
                  fontWeight: item.resultado == 'mal'
                      ? FontWeight.w600
                      : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkStat(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(
            child: Text('$count',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bines
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBinesCard(List<CosechaBin> bines) {
    final total = bines.fold(0, (s, b) => s + b.cantidad);
    return _card(
      icon: Icons.inventory_2_outlined,
      title: 'Producción Cosecha — Total: $total bines',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: bines
            .map((b) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(b.franjaHoraria,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF166534))),
                      Text('${b.cantidad}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14532D))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Observaciones
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildObsCard(String texto) {
    return _card(
      icon: Icons.notes_rounded,
      title: 'Observaciones de la maquinaria',
      child: Text(texto,
          style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Banner de sincronización
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSyncBanner(RegistroDiario r) {
    final ok = r.sincronizado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: ok ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: ok ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            ok ? 'Sincronizado con ERP' : 'Pendiente de sincronización',
            style: TextStyle(
                fontSize: 12,
                color: ok ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: const Color(0xFF1B4332)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1B4332))),
              ),
            ]),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => SizedBox(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                          Text(item.valor,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }


  String _equipoLabel(String codigo, String? desc) {
    if (desc == null || desc.isEmpty || desc == codigo) return codigo;
    return '$codigo — $desc';
  }

  String _fmtN(double? v) {
    if (v == null) return '-';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

class _InfoItem {
  final String label;
  final String valor;
  final IconData icon;
  const _InfoItem(this.label, this.valor, this.icon);
}

class _TurnoRow {
  final String label;
  final String valor;
  const _TurnoRow(this.label, this.valor);
}
