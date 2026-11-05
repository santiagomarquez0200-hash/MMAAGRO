import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_bloc.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_event.dart';
import 'package:agro_aplicaciones/features/operador/presentation/blocs/registro_state.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_event.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_state.dart';
import 'package:agro_aplicaciones/shared/widgets/sync_indicator.dart';
import 'package:agro_aplicaciones/shared/widgets/sync_detail_dialog.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/core/utils/date_utils.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/firestore_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/daily_reset_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/gps_tracking_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/backup_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/connectivity_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRefreshing = false;
  bool _cerrandoJornada = false;
  bool _actualizandoProgreso = false; // guard: impide llamadas acumuladas del timer
  String? _jornadaActivaId;
  bool _jornadaLoading = false;
  double _jornadaProgressPct = 0.0;
  bool _alerta80Mostrada = false;
  bool _alerta95Mostrada = false;
  bool _alerta100Mostrada = false;
  String _turnoActual = 'dia';
  bool _extrasActivas = false;
  Timer? _progressTimer;
  Timer? _autoRefreshTimer;

  // Caché de la última lista conocida para no mostrar vacío mientras el estado
  // es RegistroOperacionExitosa / RegistroLoading entre la creación y el
  // siguiente emit del stream Drift.
  List<RegistroDiario> _cachedRegistros = [];

  // Constantes para checklist
  static const int _totalChecklistTractor = 32;
  static const int _totalChecklistVehiculo = 24;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Verificar que los maestros estén cargados. Si la BD local está vacía
    // (primer arranque sin sync previo), redirigir a la pantalla obligatoria
    // de sincronización. En logins posteriores los datos ya existen localmente.
    _verificarMaestros();
    // Reset diario a las 04:00 h: limpia datos de la jornada anterior.
    // _loadInitialData se llama UNA sola vez dentro del .then() para evitar la
    // race condition de doble suscripción al stream del BLoC.
    sl<DailyResetService>().runIfNeeded().then((_) {
      if (mounted) _loadInitialData();
    });
    _startAutoRefreshTimer();
    _cargarJornada();
    _iniciarProgressTimer();
  }

  /// Redirige a sincronización de maestros si la BD local está vacía.
  /// Solo impacta el PRIMER login: en usos posteriores los datos ya persisten.
  Future<void> _verificarMaestros() async {
    try {
      final db = sl<AppDatabase>();
      final tractores = await db.catalogoDao.getTractores();
      if (tractores.isEmpty && mounted) {
        context.go('/sincronizando');
      }
    } catch (_) {
      // Best-effort: si la consulta falla, continuar normalmente.
    }
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final operadorIdErp = authState.usuario.esOperador
          ? authState.usuario.trabajadorIdErp
          : null;
      context.read<RegistroBloc>().add(
            RegistrosWatchRequested(operadorIdErp: operadorIdErp),
          );
      context.read<SyncBloc>().add(const SyncWatchRequested());
    }
    _animationController.forward();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && !_isRefreshing) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    // No refrescar si ya hay un refresh o si se está cerrando la jornada.
    if (_isRefreshing || _cerrandoJornada) return;
    setState(() => _isRefreshing = true);
    // El stream Drift de RegistrosWatchRequested ya emite automáticamente cuando
    // cambia la BD — no se re-añade el evento para evitar acumulación infinita
    // de handlers en la cola del BLoC (bug de memory leak).
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  /// Verifica si el checklist está completo según el tipo de registro
  bool _isChecklistCompleto(RegistroDiario registro) {
    final totalItems = registro.tipoRegistro == 'vehiculo'
        ? _totalChecklistVehiculo
        : _totalChecklistTractor;
    return registro.checklist.length >= totalItems;
  }

  Future<void> _continuarRegistro(RegistroDiario registro) async {
    // Solo continuar si puede editarse: borrador Y no sincronizado
    if (registro.esBorrador && !registro.sincronizado) {
      // Vehículo: redirigir a la pantalla de edición de vehículo
      if (registro.tipoRegistro == 'vehiculo') {
        await context.push('/registro/vehiculo/${registro.id}/editar');
        if (mounted) _refreshData();
        return;
      }

      // Tractor: ir al último tab donde el usuario trabajó.
      // Si nunca abrió ningún tab, usar la lógica de flujo normal.
      final prefs = await SharedPreferences.getInstance();
      final ultimoTab = prefs.getString('ultimo_tab_${registro.id}');

      String destino;
      if (ultimoTab != null) {
        switch (ultimoTab) {
          case 'bines':
            destino =
                '/registro/${registro.id}/bines?turno=${registro.turno}';
          case 'paros':
            destino = '/registro/${registro.id}/paros';
          case 'cerrar_turno':
            destino = '/registro/${registro.id}/cerrar';
          default: // 'checklist' o desconocido
            destino = '/registro/${registro.id}/checklist';
        }
      } else {
        // Primera vez — flujo original basado en progreso
        final checklistCompleto = _isChecklistCompleto(registro);
        final requiereBines =
            registro.procesoCodigo.toUpperCase().contains('COSEC');
        final binesRegistrados = registro.bines.isNotEmpty;

        if (!checklistCompleto) {
          destino = '/registro/${registro.id}/checklist';
        } else if (requiereBines && !binesRegistrados) {
          destino =
              '/registro/${registro.id}/bines?turno=${registro.turno}';
        } else {
          destino = '/registro/${registro.id}/paros';
        }
      }

      if (!mounted) return;
      await context.push(destino);
      if (mounted) _refreshData();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                registro.estado == 'aprobado'
                    ? Icons.check_circle
                    : Icons.info_outline,
                color: Colors.white,
                size: 20),
            const SizedBox(width: 12),
            Text('Registro ${registro.estado.toUpperCase()}'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: registro.estado == 'aprobado'
            ? const Color(0xFF2E7D32)
            : const Color(0xFF1B4332),
      ),
    );
  }

  Future<void> _cargarJornada() async {
    final prefs = await SharedPreferences.getInstance();

    // Restaurar el estado de la jornada desde SQLite inmediatamente, sin
    // esperar el timer de 1 minuto. Esto cubre el caso de cierre/apagado:
    // el operador vuelve y ve su jornada activa al instante.
    final deviceId = await sl<DeviceService>().getDeviceId();
    final authNow = mounted ? context.read<AuthBloc>().state : null;
    final uidJornada = authNow is AuthAuthenticated
        ? authNow.usuario.idParaJornada
        : null;
    final datos = await sl<StatusSyncManager>()
        .obtenerDatosJornadaActiva(deviceId, usuarioId: uidJornada);
    if (!mounted) return;

    final savedRegistroId = prefs.getString('jornada_activa_id');

    if (datos != null) {
      final turno = datos['turno'] as String? ?? 'dia';
      final inicioRaw = datos['jornada_inicio_at'];
      final inicio = inicioRaw is DateTime
          ? inicioRaw
          : inicioRaw != null
              ? DateTime.tryParse(inicioRaw.toString())
              : null;
      final now = DateTime.now();
      final shiftStart = turno == 'noche'
          ? DateTime(now.year, now.month, now.day, 14, 0)
          : DateTime(now.year, now.month, now.day, 6, 0);
      final elapsed = now.difference(shiftStart);
      // clamp mínimo 0.01 para que el card muestre jornada activa
      final pct = (elapsed.inMinutes / (8 * 60)).clamp(0.01, 1.0);

      final restaurada = prefs.getBool('jornada_restaurada_notif') ?? false;
      if (restaurada) await prefs.remove('jornada_restaurada_notif');

      setState(() {
        _jornadaActivaId = savedRegistroId;
        _turnoActual = turno;
        _jornadaProgressPct = pct;
      });

      // Reactivar GPS si la jornada estaba activa cuando se cerró la app.
      // resumeIfActive lee MAX(secuencia) de SQLite para no duplicar puntos.
      if (savedRegistroId != null) {
        sl<GpsTrackingService>().resumeIfActive(savedRegistroId);
      }

      if (restaurada && mounted) {
        final turnoLabel = turno == 'noche' ? 'Noche' : 'Día';
        final horaInicio = inicio != null ? DateFormat('HH:mm').format(inicio) : '--:--';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.restore_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jornada activa restaurada — Turno $turnoLabel iniciada a las $horaInicio.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1565C0),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } else {
      setState(() {
        _jornadaActivaId = savedRegistroId;
      });
    }
  }

  Future<void> _activarHorasExtras() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final db = sl<AppDatabase>();
    final trabajadorLocal = await db.catalogoDao.getTrabajadorByCodigo(authState.usuario.codigo);
    final usuarioId = trabajadorLocal?.usuarioErpId;
    if (usuarioId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
    await prefs.setBool('extras_${usuarioId}_${_turnoActual}_$hoy', true);
    await prefs.setBool('bloquear_segundo_turno_${usuarioId}_$hoy', true);
    if (mounted) {
      setState(() => _extrasActivas = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horas extras activadas. Jornada extendida 6 horas adicionales.'),
          backgroundColor: Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _cerrarJornada() async {
    final syncState = context.read<SyncBloc>().state;
    final hasPending = syncState is SyncUpdated && syncState.pendingCount > 0;
    final authState = context.read<AuthBloc>().state;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        title: const Row(
          children: [
            Icon(Icons.stop_circle_outlined, color: Color(0xFFEF6C00), size: 20),
            SizedBox(width: 6),
            Text('Cerrar Jornada', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPending)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Tiene registros sin sincronizar.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              '¿Cerrar jornada? Se borrarán los datos locales del dispositivo.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancelar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              if (hasPending)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'sincronizar'),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 14),
                  label: const Text('SINCRONIZAR', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'extras'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('OTRAS EXTRAS', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'cerrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                child: const Text('CERRAR JORNADA'),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == 'sincronizar') { showSyncDetailDialog(context); return; }
    if (result == 'extras') { await _activarHorasExtras(); return; }
    if (result != 'cerrar') return;
    // Mutex: evita que un refresh o sync manual interfieran durante el cierre.
    if (_cerrandoJornada) return;
    _cerrandoJornada = true;

    setState(() => _jornadaLoading = true);
    try {
      if (authState is AuthAuthenticated) {
        final deviceId = await sl<DeviceService>().getDeviceId();
        final db = sl<AppDatabase>();
        final trabajadorLocal = await db.catalogoDao.getTrabajadorByCodigo(authState.usuario.codigo);
        final usuarioId = trabajadorLocal?.usuarioErpId;

        final jornadaData = await sl<StatusSyncManager>()
            .obtenerDatosJornadaActiva(deviceId, usuarioId: usuarioId);
        if (jornadaData != null && usuarioId != null && usuarioId > 0) {
          final inicioRaw = jornadaData['jornada_inicio_at'];
          final inicioAt = inicioRaw is DateTime
              ? inicioRaw
              : inicioRaw != null
                  ? DateTime.tryParse(inicioRaw.toString())
                  : null;
          if (inicioAt != null) {
            await sl<StatusSyncManager>().guardarYEnviar(
              usuarioId: usuarioId,
              dispositivoId: deviceId,
              turno: jornadaData['turno']?.toString() ?? 'dia',
              jornadaInicioAt: inicioAt,
              jornadaFinAt: DateTime.now(),
            );
          }
        }
        // Backup automático ANTES de borrar — garantiza que los datos
        // estén disponibles en el JSON aunque el usuario no lo pidió.
        await _generarBackupSilencioso(authState);
        await sl<StatusSyncManager>().limpiarDatosJornada(deviceId);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jornada_activa_id');

        // Limpiar la clave de "jornada iniciada" en SharedPreferences para el
        // turno actual. Sin esto, al ir a /bienvenida con el mismo usuario
        // autenticado, la verificación tieneJornadaParaUsuarioYTurno devuelve
        // true y redirige de vuelta a home (vacío), creando un loop.
        final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
        if (usuarioId != null) {
          await prefs.remove('jornada_${usuarioId}_${_turnoActual}_$hoy');
        }
      }

      // Cancelar timers ANTES de navegar para evitar callbacks en widget desmontado.
      _progressTimer?.cancel();
      _progressTimer = null;
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;

      if (mounted) {
        setState(() {
          _jornadaActivaId = null;
          _jornadaLoading = false;
          _jornadaProgressPct = 0.0;
          _alerta80Mostrada = false;
          _alerta95Mostrada = false;
          _alerta100Mostrada = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Jornada cerrada. Datos locales borrados. ¡Hasta el próximo turno!'),
            backgroundColor: Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        context.go('/pin');
      }
    } catch (e) {
      _cerrandoJornada = false;
      if (mounted) {
        setState(() => _jornadaLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar jornada: $e'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildJornadaCard(String registroId, bool tieneJornada) {
    final pct = tieneJornada ? _jornadaProgressPct : 0.0;
    final porcentaje = (pct * 100).toInt();
    final progColor = pct >= 1.0
        ? Colors.red.shade400
        : pct >= 0.95
            ? Colors.red.shade300
            : pct >= 0.80
                ? const Color(0xFFEF6C00)
                : const Color(0xFF8CC53F);
    final startLabel = _turnoActual == 'noche' ? '14:00' : '06:00';
    final endLabel = _extrasActivas
        ? (_turnoActual == 'noche' ? '08:00' : '00:00')
        : (_turnoActual == 'noche' ? '02:00' : '18:00');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tieneJornada
              ? [const Color(0xFF1B4332), const Color(0xFF2E7D32)]
              : [const Color(0xFF0D241C), const Color(0xFF1B4332)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha:0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _jornadaLoading
              ? null
              : tieneJornada
                  ? _cerrarJornada
                  : () => context.go('/bienvenida'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Left: icon + labels + linear bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tieneJornada
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_circle_outline_rounded,
                              color: progColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tieneJornada
                                    ? 'Jornada en curso'
                                    : 'Sin jornada activa',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                tieneJornada
                                    ? (pct >= 1.0
                                        ? '¡Jornada completa!'
                                        : 'Toca para cerrar')
                                    : 'Toca para iniciar',
                                style: TextStyle(
                                  color:
                                      pct >= 0.80 ? progColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (tieneJornada) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha:0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(startLabel,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                            Text(endLabel,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right: circular progress or chevron
                if (_jornadaLoading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF8CC53F),
                    ),
                  )
                else if (tieneJornada)
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withValues(alpha:0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$porcentaje%',
                              style: TextStyle(
                                color: progColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'turno',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 36,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _iniciarProgressTimer() {
    _actualizarProgresoJornada();
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _actualizarProgresoJornada();
    });
  }

  Future<void> _actualizarProgresoJornada() async {
    if (_actualizandoProgreso) return;
    _actualizandoProgreso = true;
    try {
      await _actualizarProgresoJornadaInternal();
    } finally {
      _actualizandoProgreso = false;
    }
  }

  Future<void> _actualizarProgresoJornadaInternal() async {
    final deviceId = await sl<DeviceService>().getDeviceId();
    final authNow = mounted ? context.read<AuthBloc>().state : null;
    final uidTimer = authNow is AuthAuthenticated
        ? authNow.usuario.idParaJornada
        : null;
    final datos = await sl<StatusSyncManager>()
        .obtenerDatosJornadaActiva(deviceId, usuarioId: uidTimer);
    if (!mounted) return;

    if (datos == null) {
      // Fallback: si SQLite no tiene registro (storage limpiado, login fresco)
      // verificar si hay flag en SharedPreferences para el turno actual.
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final db = sl<AppDatabase>();
        final trabajadorLocal = await db.catalogoDao.getTrabajadorByCodigo(authState.usuario.codigo);
        final usuarioId = trabajadorLocal?.usuarioErpId;
        if (usuarioId != null && usuarioId > 0) {
          final now = DateTime.now();
          final h = now.hour;
          final turno = (h >= 14 && h < 22) ? 'noche' : 'dia';
          final tieneFlag = await sl<StatusSyncManager>()
              .tieneJornadaParaUsuarioYTurno(usuarioId, turno);
          if (tieneFlag && mounted) {
            // Jornada activa confirmada por SharedPreferences aunque SQLite esté vacío.
            // Calcular progreso igual que si hubiera datos en SQLite.
            final shiftStart = turno == 'noche'
                ? DateTime(now.year, now.month, now.day, 14, 0)
                : DateTime(now.year, now.month, now.day, 6, 0);
            final elapsed = now.difference(shiftStart);
            // clamp mínimo 0.01 para que tieneJornadaActiva sea true
            final pct = (elapsed.inMinutes / (8 * 60)).clamp(0.01, 1.0);
            setState(() {
              _jornadaProgressPct = pct;
              _turnoActual = turno;
            });
            // Las alertas de 80%/95%/100% deben dispararse también en el path
            // de fallback (SQLite vacío, flag en SharedPreferences activo).
            _checkAlertas(pct);
            return;
          }
        }
      }
      // Sin jornada activa
      if (mounted) {
        setState(() {
          _jornadaProgressPct = 0.0;
          _alerta80Mostrada = false;
          _alerta95Mostrada = false;
          _alerta100Mostrada = false;
        });
      }
      return;
    }

    // Calcular progreso desde el inicio FIJO del turno
    final turno = datos['turno'] as String? ?? 'dia';
    final now = DateTime.now();
    final shiftStart = turno == 'noche'
        ? DateTime(now.year, now.month, now.day, 14, 0)
        : DateTime(now.year, now.month, now.day, 6, 0);
    final elapsed = now.difference(shiftStart);

    // Verificar si hay horas extras activas para este turno
    final authState = mounted ? context.read<AuthBloc>().state : null;
    bool extrasActivas = false;
    if (authState is AuthAuthenticated) {
      final db = sl<AppDatabase>();
      final trabajadorLocal = await db.catalogoDao.getTrabajadorByCodigo(authState.usuario.codigo);
      final usuarioId = trabajadorLocal?.usuarioErpId;
      if (usuarioId != null) {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        final hoy = DateFormat('yyyyMMdd').format(now);
        extrasActivas = prefs.getBool('extras_${usuarioId}_${turno}_$hoy') ?? false;
      }
    }
    // Normal = 8h, con extras = 14h (8h + 6h adicionales)
    final totalMinutos = extrasActivas ? (14 * 60) : (8 * 60);
    final pct = (elapsed.inMinutes / totalMinutos).clamp(0.0, 1.0);
    setState(() {
      _jornadaProgressPct = pct;
      _turnoActual = turno;
      _extrasActivas = extrasActivas;
    });

    // Verificar si hay datos pendientes de sincronizar
    if (!mounted) return;
    _checkAlertas(pct);
  }

  /// Evalúa los umbrales de la jornada y dispara alertas/cierre automático.
  /// Se llama tanto desde el path normal como desde el path fallback
  /// (SQLite vacío + flag en SharedPreferences) para garantizar que
  /// el cierre automático al 100% siempre se ejecuta.
  void _checkAlertas(double pct) {
    if (!mounted) return;
    final syncState = context.read<SyncBloc>().state;
    final hasPending =
        syncState is SyncUpdated && syncState.pendingCount > 0;

    // Alerta 80% — SnackBar no modal (solo si hay datos pendientes)
    if (pct >= 0.80 && !_alerta80Mostrada) {
      _alerta80Mostrada = true;
      if (mounted && hasPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu jornada está al 80%. Finaliza los registros pendientes y sincroniza antes del cierre.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF6C00),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 8),
          ),
        );
      }
    }

    // Alerta 95% — diálogo modal (solo si hay datos pendientes)
    if (pct >= 0.95 && !_alerta95Mostrada) {
      _alerta95Mostrada = true;
      if (hasPending) _mostrarAlerta95();
    }

    // Al llegar al 100% siempre se cierra la jornada automáticamente.
    // Si había pendientes, primero se registra el incumplimiento en Firestore.
    if (pct >= 1.0 && !_alerta100Mostrada) {
      _alerta100Mostrada = true;
      _cerrarJornadaAutomatica(registrarIncumplimiento: hasPending);
    }
  }

  void _mostrarAlerta95() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00)),
            SizedBox(width: 10),
            Expanded(child: Text('⚠️ Jornada al 95%')),
          ],
        ),
        content: const Text(
          'Si no sincronizas antes del 100%, se reportará al administrador.\n\n'
          '¡Cierra y envía todo ahora!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              showSyncDetailDialog(context);
            },
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('SINCRONIZAR AHORA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarJornadaAutomatica({bool registrarIncumplimiento = false}) async {
    if (!mounted || _cerrandoJornada) return;
    _cerrandoJornada = true;
    final authState = context.read<AuthBloc>().state;

    try {
      final deviceId = await sl<DeviceService>().getDeviceId();

      if (registrarIncumplimiento && authState is AuthAuthenticated &&
          authState.usuario.trabajadorIdErp != null) {
        try {
          await sl<FirestoreService>().registrarIncumplimiento(
            usuarioErpId: authState.usuario.trabajadorIdErp!,
            nombreUsuario: authState.usuario.nombreCompleto,
            fechaJornada: DateTime.now(),
            turno: _turnoActual,
            tipoIncumplimiento: 'jornada_100_pct',
            detalle:
                'El operador superó el 100% del turno sin sincronizar todos los registros.',
            dispositivoId: deviceId,
          ).timeout(const Duration(seconds: 10));
        } catch (_) {}
      }

      if (!mounted) return;

      if (authState is AuthAuthenticated) {
        final usuarioIdAuto = authState.usuario.idParaJornada;
        final jornadaData = await sl<StatusSyncManager>()
            .obtenerDatosJornadaActiva(deviceId, usuarioId: usuarioIdAuto);
        if (jornadaData != null && usuarioIdAuto != null && usuarioIdAuto > 0) {
          final inicioRaw = jornadaData['jornada_inicio_at'];
          final inicioAt = inicioRaw is DateTime
              ? inicioRaw
              : inicioRaw != null
                  ? DateTime.tryParse(inicioRaw.toString())
                  : null;
          if (inicioAt != null) {
            await sl<StatusSyncManager>().guardarYEnviar(
              usuarioId: usuarioIdAuto,
              dispositivoId: deviceId,
              turno: jornadaData['turno']?.toString() ?? 'dia',
              jornadaInicioAt: inicioAt,
              jornadaFinAt: DateTime.now(),
            );
          }
        }
        // Backup automático ANTES de borrar (cierre automático).
        await _generarBackupSilencioso(authState);
        await sl<StatusSyncManager>().limpiarDatosJornada(deviceId);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jornada_activa_id');
      if (authState is AuthAuthenticated) {
        final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
        // La clave se grabó con usuarioErpId en marcarJornadaIniciada — debe
        // borrarse con el mismo ID para que tieneJornadaParaUsuarioYTurno
        // devuelva false correctamente después del cierre automático.
        final usuarioErpId = authState.usuario.usuarioErpId;
        if (usuarioErpId != null) {
          await prefs.remove('jornada_${usuarioErpId}_${_turnoActual}_$hoy');
        }
      }

      // Cancelar timers ANTES de navegar para evitar callbacks en widget desmontado.
      _progressTimer?.cancel();
      _progressTimer = null;
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;

      if (mounted) {
        setState(() {
          _jornadaActivaId = null;
          _jornadaProgressPct = 0.0;
          _alerta80Mostrada = false;
          _alerta95Mostrada = false;
          _alerta100Mostrada = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(registrarIncumplimiento
                ? 'Jornada cerrada automáticamente. Se notificó al administrador por registros pendientes.'
                : 'Jornada completada y cerrada automáticamente. ¡Hasta el próximo turno!'),
            backgroundColor: registrarIncumplimiento
                ? const Color(0xFFC62828)
                : const Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/pin');
      }
    } catch (e) {
      _cerrandoJornada = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar jornada: $e'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistroBloc, RegistroState>(
      // Escucha eliminaciones (actualizar caché) y operaciones exitosas
      // (para arrancar/detener el rastreo GPS de trazabilidad de maquinaria).
      listenWhen: (_, state) =>
          state is RegistroEliminadoExitoso ||
          state is RegistroOperacionExitosa,
      listener: (context, state) {
        if (state is RegistroEliminadoExitoso) {
          // Actualizar caché antes de que Drift emita el nuevo stream
          setState(() {
            _cachedRegistros = _cachedRegistros
                .where((r) => r.id != state.registroId)
                .toList();
          });
          // Detener GPS si era el registro activo que se eliminó
          sl<GpsTrackingService>().stopTracking(state.registroId);
        }

        if (state is RegistroOperacionExitosa) {
          final gps = sl<GpsTrackingService>();
          if (state.mensaje.contains('creado')) {
            // Nuevo registro → iniciar rastreo GPS desde este momento.
            gps.startTracking(state.registro.id);
          } else if (state.mensaje.contains('cerrado') ||
              state.mensaje.contains('Turno')) {
            // Turno cerrado → detener GPS. La ruta completa se envía al
            // servidor como WKT en el payload de sincronización (v3).
            gps.stopTracking(state.registro.id);
          }
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF8CC53F),
        backgroundColor: Colors.white,
        displacement: 40,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildEnterpriseHeader(context),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<RegistroBloc, RegistroState>(
                builder: (context, state) {
                  // Solo mostrar jornadas/borradores del día agrícola actual.
                  // Registros de días anteriores quedan en SQLite (backup) pero
                  // no deben aparecer en el card de jornada del home.
                  final hoy = AppDateUtils.diaAgricolaActual;
                  final fuente = state is RegistrosLoaded ? state.registros : _cachedRegistros;
                  final enProgreso = fuente
                      .where((r) => r.esBorrador && !r.fecha.isBefore(hoy))
                      .toList();
                  final tieneJornadaActiva = _jornadaProgressPct > 0;
                  final registroJornada = _jornadaActivaId != null &&
                          enProgreso.any((r) => r.id == _jornadaActivaId)
                      ? enProgreso.firstWhere((r) => r.id == _jornadaActivaId)
                      : enProgreso.isNotEmpty
                          ? enProgreso.first
                          : null;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _buildJornadaCard(
                        registroJornada?.id ?? '', tieneJornadaActiva),
                  );
                },
              ),
            ),
            SliverFillRemaining(
              child: BlocBuilder<RegistroBloc, RegistroState>(
                builder: (context, state) {
                  if (state is RegistrosLoaded) {
                    // Filtrar: home solo muestra el día agrícola actual.
                    final hoy = AppDateUtils.diaAgricolaActual;
                    final hoyRegistros = state.registros
                        .where((r) => !r.fecha.isBefore(hoy))
                        .toList();
                    _cachedRegistros = state.registros;
                    return _buildMainContent(context, hoyRegistros);
                  }
                  if (state is RegistroLoading && !_isRefreshing) {
                    // Si ya tenemos datos cacheados, mostrarlos en vez de spinner
                    if (_cachedRegistros.isNotEmpty) {
                      final hoy = AppDateUtils.diaAgricolaActual;
                      return _buildMainContent(context,
                          _cachedRegistros.where((r) => !r.fecha.isBefore(hoy)).toList());
                    }
                    return _buildLoadingState();
                  }
                  if (state is RegistroError) {
                    return _buildErrorState(state.message);
                  }
                  // RegistroOperacionExitosa u otro estado transitorio:
                  // mostrar caché mientras el stream Drift emite la actualización.
                  if (_cachedRegistros.isNotEmpty) {
                    final hoy = AppDateUtils.diaAgricolaActual;
                    return _buildMainContent(context,
                        _cachedRegistros.where((r) => !r.fecha.isBefore(hoy)).toList());
                  }
                  // Si acabamos de guardar y el caché aún está vacío (primera
                  // carga tras context.go), mostrar spinner en vez de empty
                  // state — el stream Drift emitirá RegistrosLoaded de inmediato.
                  if (state is RegistroOperacionExitosa) return _buildLoadingState();
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCustomFAB(context),
      ),
    );
  }


  Widget _buildEnterpriseHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String nombreUsuario = "Operador";
    String? avatarInicial;

    if (authState is AuthAuthenticated) {
      final nombreCompleto = authState.usuario.nombreCompleto;
      final partes = nombreCompleto.split(' ');
      nombreUsuario = partes.isNotEmpty ? partes[0] : nombreCompleto;
      avatarInicial =
          nombreCompleto.isNotEmpty ? nombreCompleto[0].toUpperCase() : null;
    }

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D241C), Color(0xFF1B4332)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 28,
          left: 20,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8CC53F).withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Color(0xFF8CC53F), size: 28),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgriControl',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Agrokasa · MMA',
                          style:
                              TextStyle(color: Color(0xFFB7E4C7), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: sl<ConnectivityService>().onConnectivityChanged,
                      initialData: sl<ConnectivityService>().isOnline,
                      builder: (context, snapshot) {
                        final isOnline = snapshot.data ?? true;
                        return Tooltip(
                          message: isOnline
                              ? 'Con conexión'
                              : 'Sin conexión — modo offline',
                          child: Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline
                                  ? const Color(0xFF52B788)
                                  : const Color(0xFFFF6B6B),
                              boxShadow: [
                                BoxShadow(
                                  color: (isOnline
                                          ? const Color(0xFF52B788)
                                          : const Color(0xFFFF6B6B))
                                      .withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SyncIndicator(),
                    const SizedBox(width: 8),
                    // Su dia: que maquina le toca, que labor, donde y a que
                    // hora se la entregan. Antes esa informacion existia
                    // repartida en tres lados y en ninguno junta.
                    GestureDetector(
                      onTap: () => context.push('/operador/mi-dia'),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CC53F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.today_rounded,
                            color: Color(0xFF8CC53F), size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _mostrarBackupDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CC53F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.backup_rounded,
                            color: Color(0xFF8CC53F), size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/perfil'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF8CC53F), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1B4332),
                          child: Text(
                            avatarInicial ?? 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '¡Bienvenido!',
              style:
                  TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              nombreUsuario,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CC53F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Listo para trabajar',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha:0.7), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, List<RegistroDiario> registros) {
    if (registros.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: registros.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut),
          )),
          child: _RegistroCardEnterprise(
            registro: registros[index],
            onContinue: () => _continuarRegistro(registros[index]),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF8CC53F),
            ),
          ),
          SizedBox(height: 16),
          Text('Cargando registros...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final tieneJornada = _jornadaProgressPct > 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha:0.05), blurRadius: 20)
                ],
              ),
              child: Icon(
                tieneJornada
                    ? Icons.assignment_turned_in_rounded
                    : Icons.lock_clock_outlined,
                size: 64,
                color: tieneJornada
                    ? Colors.grey.shade300
                    : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tieneJornada ? 'No hay registros aún' : 'Sin jornada activa',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              tieneJornada
                  ? 'Toca el botón + para comenzar'
                  : 'Inicia tu jornada para poder crear registros',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 32),
            if (tieneJornada)
              ElevatedButton.icon(
                onPressed: () => _mostrarOpcionesNuevoRegistro(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CREAR PRIMER REGISTRO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.go('/bienvenida'),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('INICIAR JORNADA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8CC53F),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 56, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _refreshData(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
                if (_jornadaProgressPct > 0) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/registro/nuevo'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Registro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFAB(BuildContext context) {
    final tieneJornada = _jornadaProgressPct > 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (tieneJornada ? const Color(0xFF1B4332) : Colors.grey)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: tieneJornada
            ? () => _mostrarOpcionesNuevoRegistro(context)
            : () => _mostrarAvisoSinJornada(),
        backgroundColor:
            tieneJornada ? const Color(0xFF1B4332) : Colors.grey.shade500,
        elevation: 0,
        icon: Icon(
          tieneJornada ? Icons.add_rounded : Icons.lock_outline_rounded,
          color: tieneJornada ? const Color(0xFF8CC53F) : Colors.white70,
          size: 24,
        ),
        label: Text(
          tieneJornada ? 'NUEVO REGISTRO' : 'SIN JORNADA ACTIVA',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 13,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  /// Genera un backup automático y silencioso justo antes de borrar los datos
  /// de la jornada. Nunca lanza excepción — un fallo de backup no debe
  /// bloquear el cierre de jornada.
  Future<void> _generarBackupSilencioso(AuthAuthenticated authState) async {
    try {
      final operadorIdErp = authState.usuario.trabajadorIdErp;
      if (operadorIdErp == null) return;
      await sl<BackupService>().generarBackup(
        operadorIdErp: operadorIdErp,
        operadorCodigo: authState.usuario.codigo,
      );
    } catch (_) {
      // Silencioso: error de backup nunca interrumpe el cierre de jornada
    }
  }

  Future<void> _mostrarBackupDialog(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final usuario = authState.usuario;
    final operadorIdErp = usuario.trabajadorIdErp;
    final operadorCodigo = usuario.codigo;

    if (operadorIdErp == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede generar backup: ID de operador no disponible.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ── Loading tech dialog ──────────────────────────────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF8CC53F).withValues(alpha: 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8CC53F).withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8CC53F).withValues(alpha: 0.12),
                  border: Border.all(
                      color: const Color(0xFF8CC53F).withValues(alpha: 0.45),
                      width: 1.5),
                ),
                child: const Icon(Icons.backup_rounded,
                    color: Color(0xFF8CC53F), size: 34),
              ),
              const SizedBox(height: 20),
              const Text(
                'Generando Backup',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Leyendo SQLite local...',
                style: TextStyle(color: Color(0xFF8CC53F), fontSize: 12),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF8CC53F)),
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await sl<BackupService>().generarBackup(
        operadorIdErp: operadorIdErp,
        operadorCodigo: operadorCodigo,
      );

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      if (!mounted) return;
      final now = DateTime.now();
      final syncPct = result.totalRegistros > 0
          ? result.sincronizados / result.totalRegistros
          : 1.0;
      final rangoFechas = result.jornadas.length > 1
          ? '${result.jornadas.last.fecha.substring(5).replaceAll('-', '/')} – ${result.jornadas.first.fecha.substring(5).replaceAll('-', '/')}  ·  ${DateFormat('HH:mm').format(now)}'
          : DateFormat('dd/MM/yyyy · HH:mm').format(now);

      // ignore: use_build_context_synchronously
      await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.82,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1A10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF8CC53F).withValues(alpha: 0.35),
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8CC53F).withValues(alpha: 0.10),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8CC53F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF8CC53F)
                                .withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Color(0xFF8CC53F), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Backup generado',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            rangoFechas,
                            style: const TextStyle(
                                color: Color(0xFF8CC53F), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Métricas (4 tiles) ───────────────────────────────────────
                Row(
                  children: [
                    _backupMetricTile(
                      result.totalJornadas.toString(),
                      'DÍAS',
                      const Color(0xFF9C27B0),
                      Icons.calendar_month_rounded,
                    ),
                    const SizedBox(width: 6),
                    _backupMetricTile(
                      result.totalRegistros.toString(),
                      'TOTAL',
                      const Color(0xFF42A5F5),
                      Icons.assignment_outlined,
                    ),
                    const SizedBox(width: 6),
                    _backupMetricTile(
                      result.sincronizados.toString(),
                      'SYNC',
                      const Color(0xFF8CC53F),
                      Icons.cloud_done_rounded,
                    ),
                    const SizedBox(width: 6),
                    _backupMetricTile(
                      result.pendientes.toString(),
                      'PEND',
                      result.pendientes > 0
                          ? const Color(0xFFEF6C00)
                          : const Color(0xFF8CC53F),
                      result.pendientes > 0
                          ? Icons.cloud_upload_rounded
                          : Icons.cloud_done_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Barra de progreso general ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cobertura sync',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 11)),
                    Text(
                      '${(syncPct * 100).toInt()}%',
                      style: TextStyle(
                        color: syncPct >= 1.0
                            ? const Color(0xFF8CC53F)
                            : const Color(0xFFEF6C00),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: syncPct,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(
                      syncPct >= 1.0
                          ? const Color(0xFF8CC53F)
                          : const Color(0xFFEF6C00),
                    ),
                  ),
                ),

                // ── Cards por jornada (scrollable) ───────────────────────────
                if (result.jornadas.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Column(
                        children: result.jornadas
                            .map(_buildBackupJornadaCard)
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Divider(color: Colors.white12, height: 1),
                ],

                const SizedBox(height: 12),

                // ── Nota ────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.white38, size: 13),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'JSON v3.0 agrupado por jornada · Datos conservados 7 días.',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Acciones ─────────────────────────────────────────────────
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cerrar',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 13)),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await sl<BackupService>()
                            .compartirBackup(result.filePath);
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Compartir backup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8CC53F),
                        foregroundColor: const Color(0xFF0A1A10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _backupMetricTile(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.65),
                  fontSize: 8,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupJornadaCard(BackupJornadaResumen j) {
    final allSynced = j.pendientes == 0;
    final accentColor =
        allSynced ? const Color(0xFF8CC53F) : const Color(0xFFEF6C00);
    final pct =
        j.totalRegistros > 0 ? j.sincronizados / j.totalRegistros : 1.0;
    final parts = j.fecha.split('-');
    final mm = parts[1];
    final dd = parts[2];

    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        iconColor: accentColor,
        collapsedIconColor: Colors.white30,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding:
            const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    j.diaSemana.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '$dd/$mm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${j.totalRegistros} registro${j.totalRegistros != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_rounded,
                          size: 11, color: Color(0xFF8CC53F)),
                      const SizedBox(width: 3),
                      Text(
                        '${j.sincronizados} sync',
                        style: const TextStyle(
                            color: Color(0xFF8CC53F), fontSize: 10),
                      ),
                      if (j.pendientes > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.cloud_upload_rounded,
                            size: 11, color: Color(0xFFEF6C00)),
                        const SizedBox(width: 3),
                        Text(
                          '${j.pendientes} pend',
                          style: const TextStyle(
                              color: Color(0xFFEF6C00), fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cobertura de sincronización',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(accentColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAvisoSinJornada() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Debes iniciar una jornada antes de crear registros. '
                'Toca la tarjeta verde de arriba.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF37474F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'INICIAR',
          textColor: const Color(0xFF8CC53F),
          onPressed: () => context.go('/bienvenida'),
        ),
      ),
    );
  }

  void _mostrarOpcionesNuevoRegistro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de registro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona el tipo de registro a crear',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildOpcionRegistro(
                      context: context,
                      icono: Icons.agriculture_rounded,
                      titulo: 'Tractor',
                      subtitulo: 'Registro de labor con tractor',
                      color: const Color(0xFF1B4332),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/registro/nuevo');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOpcionRegistro(
                      context: context,
                      icono: Icons.directions_car_rounded,
                      titulo: 'Vehículo',
                      subtitulo: 'Registro MMA-FR-013',
                      color: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/registro/vehiculo/nuevo');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionRegistro({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha:0.25)),
        ),
        child: Column(
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET DE TARJETA DE REGISTRO (CORREGIDO)
// ============================================================================

class _RegistroCardEnterprise extends StatefulWidget {
  final RegistroDiario registro;
  final VoidCallback onContinue;

  const _RegistroCardEnterprise(
      {required this.registro, required this.onContinue});

  @override
  State<_RegistroCardEnterprise> createState() =>
      _RegistroCardEnterpriseState();
}

class _RegistroCardEnterpriseState extends State<_RegistroCardEnterprise> {
  // Última pantalla que el usuario visitó para este registro (SharedPreferences).
  // Se carga al montar — mientras carga se usa null (solo datos guardados).
  String? _ultimoTab;

  @override
  void initState() {
    super.initState();
    _cargarUltimoTab();
  }

  Future<void> _cargarUltimoTab() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = prefs.getString('ultimo_tab_${widget.registro.id}');
    if (mounted) setState(() => _ultimoTab = tab);
  }

  RegistroDiario get registro => widget.registro;
  bool get _esVehiculo => registro.tipoRegistro == 'vehiculo';

  /// Progreso en 4 pasos de 25% cada uno.
  /// Se toma el MAYOR entre el progreso basado en datos guardados
  /// y el progreso basado en la última pantalla visitada (ultimo_tab),
  /// así el usuario que usa "continuar" sin guardar igual ve avance.
  double get _progreso {
    if (!registro.esBorrador) return 1.0;
    if (_esVehiculo) return 0.25;

    // Progreso por datos realmente guardados
    double pctDatos = 0.25;
    if (registro.checklist.isNotEmpty) pctDatos += 0.25;
    if (registro.paros.isNotEmpty) pctDatos += 0.25;

    // Progreso mínimo garantizado por pantallas visitadas
    double pctVisitado = 0.25;
    switch (_ultimoTab) {
      case 'checklist':
        pctVisitado = 0.50;
      case 'paros':
      case 'bines':
      case 'sublabores':
      case 'marchas':
        pctVisitado = 0.75;
      case 'cerrar_turno':
        pctVisitado = 0.75; // visitó cerrar turno pero no guardó aún
    }

    return math.max(pctDatos, pctVisitado);
  }

  Color get _colorBase {
    switch (registro.estado.toLowerCase()) {
      case 'aprobado':
        return const Color(0xFF2E7D32);
      case 'completado':
        return const Color(0xFF1565C0);
      case 'rechazado':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFEF6C00);
    }
  }

  String get _estadoTexto {
    switch (registro.estado.toLowerCase()) {
      case 'aprobado':
        return 'APROBADO';
      case 'completado':
        return 'COMPLETADO';
      case 'rechazado':
        return 'RECHAZADO';
      default:
        return 'EN PROGRESO';
    }
  }

  IconData get _estadoIcono {
    switch (registro.estado.toLowerCase()) {
      case 'aprobado':
        return Icons.check_circle_rounded;
      case 'completado':
        return Icons.assignment_turned_in_rounded;
      case 'rechazado':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo puede editarse si está en progreso Y aún no fue sincronizado.
    // Una vez sincronizado solo queda Ver.
    final puedeEditar = registro.esBorrador && !registro.sincronizado;
    final porcentajeProgreso = _progreso;
    final tipoColor =
        _esVehiculo ? const Color(0xFF1565C0) : const Color(0xFF1B4332);
    final tipoLabel = _esVehiculo ? 'VEHÍCULO' : 'TRACTOR';
    final tipoIcon = _esVehiculo
        ? Icons.directions_car_rounded
        : Icons.agriculture_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _colorBase,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onContinue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: tipo badge + numero + status chip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: tipoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: tipoColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tipoIcon, size: 11, color: tipoColor),
                              const SizedBox(width: 4),
                              Text(
                                tipoLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: tipoColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            registro.numeroRegistro,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4332),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _colorBase,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_estadoIcono,
                                  size: 10, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _estadoTexto,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  // Body: info rows + checklist ring
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompactRow(
                                _esVehiculo
                                    ? Icons.directions_car_rounded
                                    : Icons.precision_manufacturing_rounded,
                                _esVehiculo ? 'Vehículo' : 'Tractor',
                                '${registro.tractorCodigo}-${registro.tractorDescripcion}',
                              ),
                              const SizedBox(height: 5),
                              _buildCompactRow(
                                _esVehiculo
                                    ? Icons.route_rounded
                                    : Icons.agriculture_rounded,
                                _esVehiculo ? 'Proceso' : 'Actividad',
                                _esVehiculo
                                    ? 'Registro Vehículo'
                                    : registro.procesoNombre,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactRow(
                                      Icons.calendar_today_rounded,
                                      'Fecha',
                                      AppDateUtils.toDisplay(registro.fecha),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactRow(
                                      Icons.wb_sunny_outlined,
                                      'Turno',
                                      registro.turno.toUpperCase(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              _buildCompactRow(
                                Icons.person_outline_rounded,
                                'Operador',
                                registro.operadorNombre,
                              ),
                              if (registro.cultivoNombreEspecie.isNotEmpty &&
                                  !_esVehiculo) ...[
                                const SizedBox(height: 5),
                                _buildCompactRow(
                                  Icons.eco_rounded,
                                  'Cultivo',
                                  registro.cultivoNombreEspecie,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusIndicator(porcentajeProgreso),
                      ],
                    ),
                  ),
                  // Bottom action bar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: registro.sincronizado
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: registro.sincronizado
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                registro.sincronizado
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_off_rounded,
                                size: 11,
                                color: registro.sincronizado
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                registro.sincronizado ? 'Sinc.' : 'Pendiente',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: registro.sincronizado
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Ver: siempre visible
                        _buildActionIconButton(
                          icon: Icons.visibility_rounded,
                          label: 'Ver',
                          color: const Color(0xFF1B4332),
                          onPressed: () =>
                              context.push('/registro/${registro.id}/ver'),
                        ),
                        // Editar / Eliminar: solo si en progreso y NO sincronizado.
                        // El botón "Continuar" fue eliminado — tocar la tarjeta ya navega.
                        if (puedeEditar) ...[
                          const SizedBox(width: 6),
                          _buildActionIconButton(
                            icon: Icons.edit_rounded,
                            label: 'Editar',
                            color: const Color(0xFF1565C0),
                            onPressed: () {
                              if (_esVehiculo) {
                                context.push(
                                    '/registro/vehiculo/${registro.id}/editar');
                              } else {
                                context
                                    .push('/registro/${registro.id}/editar');
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          _buildActionIconButton(
                            icon: Icons.delete_rounded,
                            label: 'Eliminar',
                            color: const Color(0xFFC62828),
                            onPressed: () => _confirmDelete(context, registro),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 5),
        Text('$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4332),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(double progress) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.grey.shade200,
              color:
                  progress >= 1.0 ? Colors.green : const Color(0xFF8CC53F),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332)),
              ),
              const Text('check',
                  style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext outerContext, RegistroDiario registro) {
    showDialog(
      context: outerContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar registro'),
        content: Text(
            '¿Estás seguro de eliminar ${registro.numeroRegistro}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              // Disparar eliminación en BLoC. El BlocListener en HomePage
              // actualizará _cachedRegistros antes de que el stream Drift emita.
              outerContext
                  .read<RegistroBloc>()
                  .add(RegistroEliminarRequested(registroId: registro.id));
              // Mostrar snackbar inmediatamente aquí para no depender del
              // BlocListener (evita posibles falsos positivos).
              ScaffoldMessenger.of(outerContext).showSnackBar(
                const SnackBar(
                  content: Row(children: [
                    Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Registro eliminado'),
                  ]),
                  backgroundColor: Color(0xFFC62828),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
