import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:agro_aplicaciones/features/portero/domain/entities/maquina_programada.dart';
import 'package:agro_aplicaciones/features/portero/domain/repositories/portero_programa_repository.dart';
import 'package:agro_aplicaciones/features/portero/presentation/blocs/programa_bloc.dart';
import 'package:agro_aplicaciones/features/portero/presentation/blocs/programa_event.dart';
import 'package:agro_aplicaciones/features/portero/presentation/blocs/programa_state.dart';

// ─── Paleta MMA Agro — idéntica en todos los módulos ─────────────────────────
const _kDark = Color(0xFF0D241C); // AppBar / encabezados
const _kMid = Color(0xFF1B4332); // Verde primario — texto, iconos
const _kLime = Color(0xFF8CC53F); // Acento CTA — lima brillante
const _kBg = Color(0xFFF5F8F5); // Fondo general

/// LO QUE DEBE SALIR, PARA EL PORTERO.
///
/// Hasta ahora el APK solo escribía: registraba la lectura de cada máquina que
/// pasaba. Podía decir "salió la FAG-03", pero no "la FAG-03 tenía que salir".
/// Sin esa segunda mitad no había forma de notar que falta una máquina hasta
/// que el área reclama al día siguiente.
///
/// Esta pantalla es la lista contra la cual compara.
class ProgramaEntregaPage extends StatefulWidget {
  const ProgramaEntregaPage({super.key});

  @override
  State<ProgramaEntregaPage> createState() => _ProgramaEntregaPageState();
}

class _ProgramaEntregaPageState extends State<ProgramaEntregaPage> {
  DateTime _fecha = DateTime.now();

  /// Nulo = los dos turnos del día, que es como arranca: el portero de la
  /// mañana también necesita ver lo que quedó de la noche sin salir.
  String? _turno;

  final _buscarCtrl = TextEditingController();
  String _filtro = '';

  /// Oculta lo ya despachado. El portero trabaja contra lo pendiente; lo que
  /// salió solo estorba arriba.
  bool _soloPendientes = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _cargar() {
    context.read<ProgramaBloc>().add(
          ProgramaRequested(fecha: _fecha, turno: _turno),
        );
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      // Hacia atrás para revisar lo de días pasados; hacia adelante porque el
      // programa se publica con anticipación.
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es'),
    );
    if (elegida == null || !mounted) return;
    setState(() => _fecha = elegida);
    _cargar();
  }

  void _cambiarTurno(String? turno) {
    setState(() => _turno = turno);
    _cargar();
  }

  List<MaquinaProgramada> _visibles(ProgramaTurno programa) {
    final q = _filtro.trim().toUpperCase();
    return programa.maquinas.where((m) {
      if (_soloPendientes && m.yaSalio) return false;
      if (q.isEmpty) return true;
      return m.textoBusqueda.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Programa de entrega',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Cambiar fecha',
            onPressed: _elegirFecha,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Volver a descargar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: BlocBuilder<ProgramaBloc, ProgramaState>(
        builder: (context, state) {
          if (state is ProgramaLoading) {
            return const Center(child: CircularProgressIndicator(color: _kLime));
          }
          if (state is ProgramaError) {
            return _buildError(state.message);
          }
          if (state is! ProgramaLoaded) {
            return const SizedBox.shrink();
          }

          final visibles = _visibles(state.programa);

          return RefreshIndicator(
            color: _kMid,
            onRefresh: () async => _cargar(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCabecera(state.programa)),
                if (visibles.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildVacio(state.programa),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _buildTarjeta(visibles[i]),
                      ),
                      childCount: visibles.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CABECERA: fecha, turno, resumen y buscador
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildCabecera(ProgramaTurno programa) {
    final fechaTexto = DateFormat("EEEE d 'de' MMMM", 'es').format(_fecha);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // La primera letra en mayúscula: DateFormat en español la deja
            // minúscula y como título queda mal.
            fechaTexto.isEmpty
                ? ''
                : fechaTexto[0].toUpperCase() + fechaTexto.substring(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kMid,
            ),
          ),
          const SizedBox(height: 12),

          // ── Turno ──────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            children: [
              _chipTurno('Todo el día', null),
              _chipTurno('Día', 'DIA'),
              _chipTurno('Noche', 'NOCHE'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Aviso de datos descargados ─────────────────────────────────
          // Una lista vieja sin aviso es peor que no tener lista.
          if (programa.desdeCache) _buildAvisoCache(programa.sincronizadoAt),

          // ── Resumen ────────────────────────────────────────────────────
          Row(
            children: [
              _buildResumen(
                'Pendientes',
                programa.pendientes,
                Colors.orange.shade800,
                Icons.schedule_rounded,
              ),
              const SizedBox(width: 8),
              _buildResumen(
                'Ya salieron',
                programa.salidas,
                _kMid,
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _buildResumen(
                'Sin operador',
                programa.sinOperador,
                Colors.red.shade700,
                Icons.person_off_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Buscador ───────────────────────────────────────────────────
          TextField(
            controller: _buscarCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Buscar código, operador, lote…',
              prefixIcon: const Icon(Icons.search_rounded, color: _kMid),
              suffixIcon: _filtro.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _buscarCtrl.clear();
                        setState(() => _filtro = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            onChanged: (v) => setState(() => _filtro = v),
          ),
          const SizedBox(height: 4),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: _kLime,
            value: _soloPendientes,
            onChanged: (v) => setState(() => _soloPendientes = v),
            title: const Text(
              'Ver solo lo que falta salir',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipTurno(String etiqueta, String? valor) {
    final activo = _turno == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: activo,
      onSelected: (_) => _cambiarTurno(valor),
      selectedColor: _kMid,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: activo ? Colors.white : _kMid,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: activo ? _kMid : Colors.grey.shade300),
    );
  }

  Widget _buildAvisoCache(DateTime? sincronizadoAt) {
    final cuando = sincronizadoAt == null
        ? 'sin fecha de descarga'
        : 'descargado ${DateFormat('dd/MM HH:mm').format(sincronizadoAt)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión — se muestra el programa guardado ($cuando).',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(String etiqueta, int valor, Color color, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icono, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TARJETA DE MÁQUINA
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTarjeta(MaquinaProgramada m) {
    final salio = m.yaSalio;
    final color = salio
        ? _kMid
        : (m.sinOperador ? Colors.red.shade700 : Colors.orange.shade800);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        // Una banda del color del estado: el portero mira de lejos y con sol.
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Theme(
        // El ExpansionTile trae su propio divisor y color de ícono; se neutraliza
        // para que la tarjeta se vea igual abierta y cerrada.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              salio ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: color,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  m.implemento.isEmpty ? '(sin código)' : m.implemento,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _kMid,
                  ),
                ),
              ),
              _buildEtiquetaHora(m, color),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.detalleMaquina.isNotEmpty)
                  Text(
                    m.detalleMaquina,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      m.sinOperador
                          ? Icons.person_off_outlined
                          : Icons.person_outline_rounded,
                      size: 14,
                      color: m.sinOperador ? Colors.red.shade700 : _kMid,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        // Se dice SIN ASIGNAR y no se deja vacío: un guion más
                        // se lee como un dato que falta cargar, no como un
                        // pendiente real que alguien tiene que resolver.
                        m.sinOperador
                            ? 'SIN OPERADOR ASIGNADO'
                            : (m.operador ?? '—'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: m.sinOperador
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              m.sinOperador ? Colors.red.shade700 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _fila('Turno', m.turno),
                  _fila('Tractor', m.tractor),
                  _fila('Tipología', m.tipologia),
                  _fila('Identificación', m.identificacion),
                  const SizedBox(height: 6),
                  _fila('Área', m.area),
                  _fila('Cultivo', m.cultivo),
                  _fila('Actividad', m.actividad),
                  _fila('Sublote', m.sublote),
                  const SizedBox(height: 6),
                  _fila('Solicitud', m.solicitud),
                  _fila('Solicitante', m.solicitante),
                  const SizedBox(height: 6),
                  _fila('Hora prevista', m.horaPrevista),
                  _fila('Hora de salida', m.horaSalida),
                  _fila('Punto de salida', m.puntoSalida),
                  _fila('Horómetro', m.horometro?.toStringAsFixed(1)),
                  _fila('Estado', m.estado),
                  _fila('Motivo', m.motivoIncumplimiento),
                  _fila('Observación', m.observacion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtiquetaHora(MaquinaProgramada m, Color color) {
    final texto = m.yaSalio
        ? 'Salió ${m.horaSalida ?? ''}'.trim()
        : (m.horaPrevista ?? 'Sin hora');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Omite los campos vacíos en vez de mostrarlos con guion: el detalle ya es
  /// largo y una lista de guiones no aporta nada.
  Widget _fila(String etiqueta, String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              etiqueta,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ESTADOS VACÍO Y ERROR
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildVacio(ProgramaTurno programa) {
    // Se distingue "no hay programa" de "el filtro no deja ver nada": son dos
    // problemas distintos y el portero resuelve cada uno de otra forma.
    final porFiltro = programa.maquinas.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            porFiltro ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            porFiltro
                ? 'Ninguna máquina coincide con la búsqueda'
                : 'No hay máquinas programadas para esta fecha y turno',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          if (porFiltro) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _buscarCtrl.clear();
                setState(() {
                  _filtro = '';
                  _soloPendientes = false;
                });
              },
              child: const Text('Quitar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kMid,
                foregroundColor: Colors.white,
              ),
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
