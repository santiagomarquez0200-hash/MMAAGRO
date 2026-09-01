import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/shared/widgets/connectivity_dot.dart';

class BinesPage extends StatefulWidget {
  final String registroId;
  final String turno;
  const BinesPage({
    super.key,
    required this.registroId,
    this.turno = 'dia',
  });

  @override
  State<BinesPage> createState() => _BinesPageState();
}

class _BinesPageState extends State<BinesPage> {
  late final Map<String, int> _bines;
  late final String _turnoFranja;
  bool _saving = false;
  // BUG-18: set to true when the final save starts so queued BLoC
  // auto-save events cannot overwrite the committed data.
  bool _guardandoFinal = false;

  @override
  void initState() {
    super.initState();
    final esNoche = widget.turno == 'noche';
    _turnoFranja = esNoche ? 'pm' : 'am';
    _bines = LinkedHashMap.fromEntries(
      (esNoche
              ? [
                  '14:00-15:00',
                  '15:00-16:00',
                  '16:00-17:00',
                  '17:00-18:00',
                  '18:00-19:00',
                  '19:00-20:00',
                  '20:00-21:00',
                  '21:00-22:00',
                ]
              : [
                  '06:00-07:00',
                  '07:00-08:00',
                  '08:00-09:00',
                  '09:00-10:00',
                  '10:00-11:00',
                  '11:00-12:00',
                  '12:00-13:00',
                  '13:00-14:00',
                ])
          .map((f) => MapEntry(f, 0)),
    );
    // Cargar cantidades ya guardadas desde SQLite (por si el usuario regresa
    // a esta pantalla después de haber ingresado datos).
    _cargarBinesExistentes();
    _guardarUltimoTab();
  }

  Future<void> _guardarUltimoTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_tab_${widget.registroId}', 'bines');
  }

  /// Lee los bines previamente guardados en SQLite y actualiza el mapa local.
  /// Los valores del mapa son mutables aunque sea `late final`, por lo que
  /// no es necesario reasignar la referencia.
  Future<void> _cargarBinesExistentes() async {
    final result =
        await sl<RegistroRepository>().getRegistro(widget.registroId);
    result.fold(
      (_) {},
      (registro) {
        if (!mounted) return;
        for (final bin in registro.bines) {
          if (_bines.containsKey(bin.franjaHoraria)) {
            _bines[bin.franjaHoraria] = bin.cantidad;
          }
        }
        setState(() {}); // Redibujar con los valores cargados
      },
    );
  }

  int get totalBines => _bines.values.reduce((a, b) => a + b);

  // Auto-guarda un bin inmediatamente al cambiar.
  // Usa el mismo evento BLoC que _guardarBines para que _cargarBinesExistentes
  // lo recupere si el usuario regresa a esta pantalla.
  void _autoSaveBin(String franja, int cantidad) {
    // BUG-18: skip if the final save is already in progress.
    if (_guardandoFinal) return;
    // BUG-17: dispatch even when cantidad == 0 so the repository deletes the
    // existing row. The repository skips the INSERT for cantidad == 0.
    context.read<RegistroBloc>().add(RegistroBinRequested(
          params: RegistrarBinParams(
            registroId: widget.registroId,
            franjaHoraria: franja,
            turno: _turnoFranja,
            cantidad: cantidad,
          ),
        ));
  }

  Future<void> _guardarBines() async {
    // BUG-18: prevent queued auto-save BLoC events from overwriting this save.
    setState(() {
      _saving = true;
      _guardandoFinal = true;
    });

    try {
      for (final entry in _bines.entries) {
        // BUG-17: process every bin, including zeros — the repository deletes
        // the row when cantidad == 0 and upserts otherwise.
        final result = await sl<RegistroRepository>().registrarBin(
          RegistrarBinParams(
            registroId: widget.registroId,
            franjaHoraria: entry.key,
            turno: _turnoFranja,
            cantidad: entry.value,
          ),
        );
        if (!mounted) return;
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }

      if (mounted) {
        context.go('/registro/${widget.registroId}/paros');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar bines: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D241C),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'PRODUCCIÓN DE BINES',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: const [ConnectivityDot()],
      ),
      body: BlocListener<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroError) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFC62828),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        child: Column(
          children: [
            _buildTotalCounter(),
            Expanded(
              child: Builder(builder: (context) {
                final binaKeys = _bines.keys.toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _bines.length,
                  itemBuilder: (context, index) {
                    final key = binaKeys[index];
                    return _BinStepCard(
                      franja: key,
                      cantidad: _bines[key]!,
                      onChanged: (value) {
                        setState(() => _bines[key] = value);
                        _autoSaveBin(key, value);
                      },
                    );
                  },
                );
              }),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCounter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_rounded,
              color: Color(0xFF1B4332), size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL COSECHADO',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$totalBines',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D241C)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Bines',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8CC53F)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _saving ? null : _guardarBines,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4332),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GUARDAR Y CONTINUAR',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BinStepCard extends StatelessWidget {
  final String franja;
  final int cantidad;
  final ValueChanged<int> onChanged;

  const _BinStepCard(
      {required this.franja, required this.cantidad, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: cantidad > 0
                ? const Color(0xFF8CC53F).withValues(alpha: 0.5)
                : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.access_time_rounded,
                size: 20, color: Color(0xFF1B4332)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              franja,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0D241C)),
            ),
          ),
          // Controles de Step
          Row(
            children: [
              _buildStepButton(Icons.remove,
                  () => cantidad > 0 ? onChanged(cantidad - 1) : null),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: cantidad > 0
                        ? const Color(0xFF1B4332)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              _buildStepButton(Icons.add, () => onChanged(cantidad + 1),
                  isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap,
      {bool isPrimary = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF1B4332) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: isPrimary ? Colors.white : Colors.black87, size: 20),
        ),
      ),
    );
  }
}
