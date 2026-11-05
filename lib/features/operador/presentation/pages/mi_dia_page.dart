import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:agro_aplicaciones/features/operador/domain/entities/asignacion_dia.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/mi_dia_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';

// ─── Paleta MMA Agro — idéntica en todos los módulos ─────────────────────────
const _kDark = Color(0xFF0D241C);
const _kMid = Color(0xFF1B4332);
const _kLime = Color(0xFF8CC53F);
const _kBg = Color(0xFFF5F8F5);

/// MI DÍA — lo que el tractorista ve al entrar.
///
/// Contesta las cuatro preguntas que tiene al llegar: qué máquina me toca, qué
/// trabajo hago, dónde, y a qué hora me la entregan. Hasta ahora esa
/// información existía repartida en tres lados y en ninguno junta.
class MiDiaPage extends StatefulWidget {
  const MiDiaPage({super.key});

  @override
  State<MiDiaPage> createState() => _MiDiaPageState();
}

class _MiDiaPageState extends State<MiDiaPage> {
  DateTime _fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    // En el primer frame, porque leer AuthBloc desde initState directo no es
    // seguro antes de que el árbol esté montado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final u = auth.usuario;
    // Se mandan los dos identificadores y el SP decide: la programación guarda
    // el de Trabajadores, así que ese es el camino directo.
    context.read<MiDiaBloc>().add(MiDiaRequested(
          idTrabajador: u.trabajadorIdErp,
          idUsuario: u.usuarioErpId,
          fecha: _fecha,
        ));
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 15)),
      locale: const Locale('es'),
    );
    if (elegida == null || !mounted) return;
    setState(() => _fecha = elegida);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final esHoy = DateUtils.isSameDay(_fecha, DateTime.now());

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        title: Text(
          esHoy ? 'Mi día' : 'Mi día · ${DateFormat('dd/MM').format(_fecha)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      body: BlocBuilder<MiDiaBloc, MiDiaState>(
        builder: (context, state) {
          if (state is MiDiaLoading) {
            return const Center(child: CircularProgressIndicator(color: _kLime));
          }
          if (state is MiDiaError) {
            return _buildError(state.message);
          }
          if (state is! MiDiaLoaded) {
            return const SizedBox.shrink();
          }

          if (state.miDia.vacio) return _buildVacio();

          return RefreshIndicator(
            color: _kMid,
            onRefresh: () async => _cargar(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  _tituloFecha(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kMid,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.miDia.asignaciones.length == 1
                      ? 'Tienes 1 máquina asignada'
                      : 'Tienes ${state.miDia.asignaciones.length} máquinas asignadas',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                if (state.miDia.desdeCache)
                  _buildAvisoCache(state.miDia.sincronizadoAt),
                ...state.miDia.asignaciones.map(_buildTarjeta),
              ],
            ),
          );
        },
      ),
    );
  }

  String _tituloFecha() {
    final t = DateFormat("EEEE d 'de' MMMM", 'es').format(_fecha);
    return t.isEmpty ? '' : t[0].toUpperCase() + t.substring(1);
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
              'Sin conexión — se muestra lo guardado ($cuando). '
              'Confirme con su supervisor si hubo cambios.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TARJETA DE ASIGNACIÓN
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTarjeta(AsignacionDia a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado: la máquina y la hora ──────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: _kMid,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.agriculture_rounded, color: _kLime),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.implemento.isEmpty ? '(sin código)' : a.implemento,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      if (a.detalleMaquina.isNotEmpty)
                        Text(
                          a.detalleMaquina,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildHora(a),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Qué trabajo y dónde ────────────────────────────────
                _bloque('TU TRABAJO', [
                  _fila('Actividad', a.actividad),
                  _fila('Cultivo', a.cultivo),
                  _fila('Área', a.area),
                ]),
                _bloque('DÓNDE', [
                  _fila('Sublote', a.sublote),
                  _fila('Hectáreas', a.hectareas?.toStringAsFixed(2)),
                  _fila('Orden de trabajo', a.nroOt),
                ]),

                // ── Cómo: solo si la línea vino de una orden de Sanidad ─
                if (a.tieneDetalleAplicacion)
                  _bloque('CÓMO APLICAR', [
                    _fila('Modalidad', a.modalidad),
                    _fila('Marcha', a.marcha),
                    _fila('Presión', a.presion),
                    _fila('Mojamiento', a.mojamiento),
                    _fila('Indicación', a.observacionOrden),
                  ]),

                _bloque('ENTREGA', [
                  _fila('Turno', a.turno),
                  _fila('Tractor', a.tractor),
                  _fila('Hora prevista', a.horaPrevista),
                  _fila('Hora de salida', a.horaSalida),
                  _fila('Estado', a.estado),
                  _fila('Solicita', a.solicitante),
                  _fila('Observación', a.observacion),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHora(AsignacionDia a) {
    // Si ya salió se muestra la hora real; verlas juntas le dice si llegó a
    // tiempo o si la máquina todavía no pasó por garita.
    final texto = a.yaSalio
        ? 'Salió ${a.horaSalida ?? ''}'.trim()
        : (a.horaPrevista ?? 'Sin hora');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kLime.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: _kLime,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Un grupo de campos con su título. Si todos los campos del grupo están
  /// vacíos, el grupo no se dibuja: un encabezado sin contenido abajo se lee
  /// como que falta cargar algo.
  Widget _bloque(String titulo, List<Widget> filas) {
    final visibles = filas.whereType<_Fila>().toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        ...visibles,
        const SizedBox(height: 12),
      ],
    );
  }

  /// Devuelve un widget vacío cuando el dato no vino, para que `_bloque`
  /// pueda contar cuántos campos tiene realmente contenido.
  Widget _fila(String etiqueta, String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return const SizedBox.shrink();
    return _Fila(etiqueta: etiqueta, valor: v);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ESTADOS VACÍO Y ERROR
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildVacio() {
    return RefreshIndicator(
      color: _kMid,
      onRefresh: () async => _cargar(),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
            child: Column(
              children: [
                Icon(Icons.event_available_outlined,
                    size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No tienes máquinas asignadas para esta fecha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Si deberías tener una, consulta con tu supervisor: la '
                  'asignación se hace al programar la entrega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
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

/// Fila etiqueta/valor. Es un tipo propio y no un Row suelto para que
/// `_bloque` pueda distinguir los campos con contenido de los omitidos.
class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Fila({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              etiqueta,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
