import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';
import 'package:agro_aplicaciones/infrastructure/services/status_sync_manager.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_event.dart';

/// Pantalla de bienvenida al turno.
///
/// Detecta si el operador llega antes, en hora o tarde al turno:
///   - Antes  → cuenta regresiva, botón deshabilitado hasta la hora de inicio.
///   - A tiempo/tarde → badge rojo con minutos de retraso, botón habilitado.
///   - Fuera de rango (fuera de los dos turnos) → muestra próximo turno.
class BienvenidaTurnoPage extends StatefulWidget {
  const BienvenidaTurnoPage({super.key});

  @override
  State<BienvenidaTurnoPage> createState() => _BienvenidaTurnoPageState();
}

class _BienvenidaTurnoPageState extends State<BienvenidaTurnoPage> {
  // ─── Estado ────────────────────────────────────────────────────────────────
  bool _checking = true;
  bool _saving = false;
  bool _sinIdErp = false;
  // true cuando _sinIdErp es por catálogo desactualizado (solución: re-sync)
  // false cuando es un problema de configuración permanente (contactar admin)
  bool _necesitaSincronizar = false;
  bool _bloqueadoPorExtras = false;

  // Turno detectado
  late String _turno; // 'dia' | 'noche'

  // true cuando son las 22:00–05:59 (ningún turno activo, esperando el próximo día)
  bool _esPeriodoEntreTurnos = false;

  // Estado de puntualidad
  late _EstadoPuntualidad _estadoPuntualidad;
  int _minutosRetraso = 0; // solo si es tardío
  Duration _countdownRemaining = Duration.zero; // solo si es anticipado

  Timer? _countdownTimer;
  Timer? _refreshTimer;

  // Diagnóstico: valores capturados en _verificarJornadaActiva para mostrar en el diálogo
  String _diagAuthErpId = 'no ejecutado';
  String _diagGetUsuarioErpId = 'no ejecutado';
  String _diagGetUsuarioError = '';

  // ─── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _detectarTurnoYPuntualidad();
    _verificarJornadaActiva();
    // Refrescar cada 60 s para re-evaluar si la hora de inicio llegó
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _detectarTurnoYPuntualidad();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ─── Detección de turno ────────────────────────────────────────────────────

  void _detectarTurnoYPuntualidad() {
    final now = DateTime.now();
    final h = now.hour;

    late DateTime turnoStart;

    if (h >= 6 && h < 14) {
      // Turno día activo
      _turno = 'dia';
      _esPeriodoEntreTurnos = false;
      turnoStart = DateTime(now.year, now.month, now.day, 6);
    } else if (h >= 14 && h < 22) {
      // Turno noche activo
      _turno = 'noche';
      _esPeriodoEntreTurnos = false;
      turnoStart = DateTime(now.year, now.month, now.day, 14);
    } else {
      // Periodo entre turnos: 22:00–05:59
      // El próximo turno es siempre DÍA a las 06:00.
      // Si son ≥ 22:00 el 06:00 es del día siguiente; si son < 06:00 es hoy.
      _turno = 'dia';
      _esPeriodoEntreTurnos = true;
      turnoStart = h >= 22
          ? DateTime(now.year, now.month, now.day + 1, 6)
          : DateTime(now.year, now.month, now.day, 6);
    }

    // Con turnoStart siempre en el futuro para el periodo entre turnos,
    // now.isBefore(turnoStart) es garantizadamente true en ese rango.
    if (now.isBefore(turnoStart)) {
      _estadoPuntualidad = _EstadoPuntualidad.anticipado;
      _countdownRemaining = turnoStart.difference(now);
      _iniciarCountdown(turnoStart);
    } else {
      _countdownTimer?.cancel();
      final minutosTranscurridos = now.difference(turnoStart).inMinutes;
      if (minutosTranscurridos <= 5) {
        _estadoPuntualidad = _EstadoPuntualidad.puntual;
        _minutosRetraso = 0;
      } else {
        _estadoPuntualidad = _EstadoPuntualidad.tarde;
        _minutosRetraso = minutosTranscurridos;
      }
    }

    if (mounted) setState(() {});
  }

  void _iniciarCountdown(DateTime target) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = target.difference(DateTime.now());
      if (remaining.isNegative) {
        _countdownTimer?.cancel();
        _detectarTurnoYPuntualidad();
      } else {
        setState(() => _countdownRemaining = remaining);
      }
    });
  }

  // ─── Verificar si ya hay jornada activa ────────────────────────────────────

  Future<void> _verificarJornadaActiva() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) context.go('/pin');
      return;
    }
    try {
      final authRepo = sl<AuthRepository>();
      final userResult = await authRepo.getUsuarioActual();
      final currentUser = userResult.fold((_) => null, (u) => u);

      final int? usuarioId =
          currentUser?.usuarioErpId ?? authState.usuario.usuarioErpId;

      // Guardar diagnóstico para mostrarlo en el diálogo
      _diagAuthErpId = authState.usuario.usuarioErpId?.toString() ?? 'null';
      _diagGetUsuarioErpId = userResult.fold(
        (l) => 'LEFT: ${l.message}',
        (u) => u == null ? 'Right(null)' : (u.usuarioErpId?.toString() ?? 'null'),
      );
      _diagGetUsuarioError = '';

      dev.log(
        '[BIENVENIDA] authState.usuarioErpId=${authState.usuario.usuarioErpId} '
        'getUsuarioActual=$_diagGetUsuarioErpId '
        'codigo="${authState.usuario.codigo}" '
        'usuarioIdFinal=$usuarioId',
        name: 'Bienvenida',
      );

      // Sincronizar el BLoC si el ID obtenido difiere del estado en memoria
      if (currentUser != null &&
          mounted &&
          currentUser.usuarioErpId != authState.usuario.usuarioErpId) {
        context.read<AuthBloc>().add(AuthUserUpdated(currentUser));
      }

      if (usuarioId == null || usuarioId <= 0) {
        if (mounted) {
          setState(() {
            _checking = false;
            _sinIdErp = true;
            _necesitaSincronizar = true;
          });
        }
        return;
      }
      final deviceId = await sl<DeviceService>().getDeviceId();
      final statusMgr = sl<StatusSyncManager>();

      // 1. Verificar por dispositivo+usuario (evita que la jornada de otro
      //    usuario en el mismo celular bloquee al usuario actual)
      final tieneJornadaDispositivo =
          await statusMgr.tieneJornadaActiva(deviceId, usuarioId: usuarioId);
      if (tieneJornadaDispositivo && mounted) {
        context.go('/operador/home');
        return;
      }

      // 2. Verificar por usuario+turno con SharedPreferences
      //    Persiste entre sesiones aunque se limpie la BD local o se reinicie la app.
      //    Garantiza 1 jornada por usuario por turno por día.
      _detectarTurnoYPuntualidad();
      final tieneJornadaParaTurno =
          await statusMgr.tieneJornadaParaUsuarioYTurno(usuarioId, _turno);
      if (tieneJornadaParaTurno && mounted) {
        context.go('/operador/home');
        return;
      }

      // 3. Verificar bloqueo por horas extras del turno anterior
      if (_turno == 'noche') {
        final prefs = await SharedPreferences.getInstance();
        final hoy = DateFormat('yyyyMMdd').format(DateTime.now());
        final bloqueado =
            prefs.getBool('bloquear_segundo_turno_${usuarioId}_$hoy') ?? false;
        if (bloqueado && mounted) {
          setState(() {
            _checking = false;
            _bloqueadoPorExtras = true;
          });
          return;
        }
      }

    } catch (e, st) {
      dev.log('[BIENVENIDA] Error en _verificarJornadaActiva: $e\n$st',
          name: 'Bienvenida', error: e);
    }
    if (mounted) setState(() => _checking = false);
  }

  // ─── Diagnóstico de ID ────────────────────────────────────────────────────

  Future<void> _diagnosticarIdUsuario() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final u = authState.usuario;

    final trabajadorIdErp = u.trabajadorIdErp;
    final usuarioErpId = u.usuarioErpId;
    final idParaJornada = u.idParaJornada;
    final codigo = u.codigo;

    final idOk = _diagGetUsuarioErpId != 'null' &&
        !_diagGetUsuarioErpId.startsWith('LEFT') &&
        _diagGetUsuarioErpId != 'Right(null)';

    final msg = '''
━━ ESTADO ACTUAL (BLoC) ━━
Código login    : $codigo
trabajadorIdErp : $trabajadorIdErp
usuarioErpId    : $usuarioErpId
idParaJornada   : $idParaJornada

━━ AL INICIAR PANTALLA ━━
authState.ErpId : $_diagAuthErpId
getUsuarioActual: $_diagGetUsuarioErpId
${_diagGetUsuarioError.isNotEmpty ? 'error: $_diagGetUsuarioError\n' : ''}
━━ RESULTADO ━━
sinIdErp        : $_sinIdErp
${idOk && !_sinIdErp ? '✅ ID encontrado ($_diagGetUsuarioErpId) y botón habilitado' : idOk && _sinIdErp ? '⚠ ID encontrado pero botón bloqueado — BUG ACTIVO' : '❌ ID no encontrado → sincroniza catálogos'}
''';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.manage_search_rounded, color: Color(0xFF26A69A)),
            SizedBox(width: 8),
            Text('ID de usuario', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SelectableText(
          msg.trim(),
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarJornada() async {
    if (_saving) return;
    if (_estadoPuntualidad == _EstadoPuntualidad.anticipado ||
        _sinIdErp) {
      return;
    }

    setState(() => _saving = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    // Mismo enfoque que _verificarJornadaActiva: leer desde SecureStorage
    // en lugar del BLoC para evitar la condición de carrera del primer arranque.
    final authRepo = sl<AuthRepository>();
    final userResult = await authRepo.getUsuarioActual();
    final currentUser = userResult.fold((_) => null, (u) => u);

    final int? usuarioId =
        currentUser?.usuarioErpId ?? authState.usuario.usuarioErpId;

    if (currentUser != null &&
        mounted &&
        currentUser.usuarioErpId != authState.usuario.usuarioErpId) {
      context.read<AuthBloc>().add(AuthUserUpdated(currentUser));
    }

    if (usuarioId == null || usuarioId <= 0) {
      if (mounted) {
        setState(() {
          _saving = false;
          _sinIdErp = true;
          _necesitaSincronizar = true;
        });
      }
      return;
    }

    try {
      final deviceId = await sl<DeviceService>().getDeviceId();
      final statusMgr = sl<StatusSyncManager>();

      final sincronizado = await statusMgr.guardarYEnviar(
        usuarioId: usuarioId,
        dispositivoId: deviceId,
        turno: _turno,
        jornadaInicioAt: DateTime.now(),
      );

      await statusMgr.marcarJornadaIniciada(usuarioId, _turno);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  sincronizado
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sincronizado
                        ? 'Jornada registrada y sincronizada con el servidor.'
                        : 'Jornada guardada localmente. Se enviará cuando haya conexión.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: sincronizado
                ? const Color(0xFF2D6A4F)
                : const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/operador/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al iniciar jornada: $e'),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D241C),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final authState = context.watch<AuthBloc>().state;
    final nombre =
        authState is AuthAuthenticated ? authState.usuario.nombres : 'Operador';

    final esDia = _turno == 'dia';
    final turnoLabel = _esPeriodoEntreTurnos
        ? 'PRÓXIMO TURNO (DÍA)'
        : esDia
            ? 'PRIMER TURNO (DÍA)'
            : 'SEGUNDO TURNO (NOCHE)';
    final horaLabel = esDia ? '06:00 – 14:00' : '14:00 – 22:00';
    final icon = _esPeriodoEntreTurnos
        ? Icons.bedtime_rounded
        : esDia
            ? Icons.wb_sunny_rounded
            : Icons.nightlight_round;
    final greeting = _esPeriodoEntreTurnos
        ? 'Buenas noches'
        : esDia
            ? 'Buenos días'
            : 'Buenas tardes';

    return Scaffold(
      backgroundColor: const Color(0xFF0D241C),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Botón salir — esquina superior derecha ────────────────────
            Positioned(
              top: 4,
              right: 4,
              child: Tooltip(
                message: 'Volver al menú',
                child: IconButton(
                  onPressed: () => context.go('/operador/home'),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 26),
                ),
              ),
            ),

            // ── Contenido principal ───────────────────────────────────────
            Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icono de turno
              Icon(icon, size: 72, color: const Color(0xFF8CC53F)),
              const SizedBox(height: 28),

              // Saludo
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Badge de puntualidad o bloqueo
              if (_sinIdErp)
                _buildSinIdErpBadge()
              else if (_bloqueadoPorExtras)
                _buildBloqueadoPorExtrasBadge()
              else
                _buildPuntualidadBadge(),

              const SizedBox(height: 24),

              // Tarjeta de turno
              _buildTurnoCard(turnoLabel, horaLabel),

              const SizedBox(height: 32),

              // Countdown (solo si anticipado)
              if (_estadoPuntualidad == _EstadoPuntualidad.anticipado)
                _buildCountdown(),

              // Tiempo de retraso grande (solo si tarde)
              if (_estadoPuntualidad == _EstadoPuntualidad.tarde)
                _buildRetrasoVisible(),

              const Spacer(),

              // Botón diagnóstico — muestra qué ID resuelve el APK para este usuario
              if (kDebugMode)
                TextButton.icon(
                  onPressed: _diagnosticarIdUsuario,
                  icon: const Icon(Icons.bug_report_outlined,
                      size: 16, color: Color(0xFF80CBC4)),
                  label: const Text('Verificar ID de usuario',
                      style: TextStyle(fontSize: 12, color: Color(0xFF80CBC4))),
                ),
              const SizedBox(height: 8),

              // Botón continuar
              ElevatedButton(
                onPressed: (_saving ||
                        _sinIdErp ||
                        _bloqueadoPorExtras ||
                        _estadoPuntualidad == _EstadoPuntualidad.anticipado)
                    ? null
                    : _iniciarJornada,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8CC53F),
                  disabledBackgroundColor:
                      const Color(0xFF8CC53F).withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _sinIdErp
                              ? (_necesitaSincronizar
                                  ? 'SINCRONIZA LOS CATÁLOGOS'
                                  : 'CUENTA SIN CONFIGURAR')
                              : _bloqueadoPorExtras
                                  ? 'TURNO BLOQUEADO POR HORAS EXTRAS'
                                  : _estadoPuntualidad ==
                                              _EstadoPuntualidad.anticipado
                                          ? 'ESPERA EL INICIO DEL TURNO'
                                          : 'INICIAR JORNADA',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets auxiliares ────────────────────────────────────────────────────

  Widget _buildSinIdErpBadge() {
    if (_necesitaSincronizar) {
      // El catálogo local no tiene usuario_id_erp aún: la solución es re-sync.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE65100).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFFFCC80).withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sync_problem_rounded,
                    color: Color(0xFFFFCC80), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Catálogos desactualizados. Sincroniza para poder iniciar jornada.',
                    style: TextStyle(
                        color: Color(0xFFFFE0B2), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context
                      .read<CatalogoBloc>()
                      .add(const CatalogoSyncRequested());
                  // Volver a sincronizar catálogos y luego regresar al flujo de login
                  context.go('/sincronizando');
                },
                icon: const Icon(Icons.sync_rounded,
                    size: 18, color: Color(0xFFFFCC80)),
                label: const Text('Sincronizar catálogos',
                    style: TextStyle(color: Color(0xFFFFCC80))),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: const Color(0xFFFFCC80).withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Problema permanente de configuración (sin ID en ERP).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFEF9A9A).withValues(alpha: 0.7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.badge_outlined, color: Color(0xFFEF9A9A), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu cuenta no tiene ID de ERP asignado. Contacta al administrador.',
              style: TextStyle(
                  color: Color(0xFFFFCDD2), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueadoPorExtrasBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.access_time_filled, color: Color(0xFF42A5F5), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El turno nocturno está bloqueado porque activaste horas extras en el turno anterior. Mañana tu jornada vuelve a la normalidad.',
              style: TextStyle(
                  color: Color(0xFFBBDEFB), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuntualidadBadge() {
    switch (_estadoPuntualidad) {
      case _EstadoPuntualidad.anticipado:
        final mensaje = _esPeriodoEntreTurnos
            ? 'Periodo entre turnos. El primer turno comienza a las 06:00.'
            : 'Te has anticipado. Tu jornada aún no comienza.';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _esPeriodoEntreTurnos
                    ? Icons.nightlight_round
                    : Icons.schedule_rounded,
                color: const Color(0xFF42A5F5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  mensaje,
                  style:
                      const TextStyle(color: Color(0xFF90CAF9), fontSize: 13),
                ),
              ),
            ],
          ),
        );
      case _EstadoPuntualidad.puntual:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4332).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8CC53F).withValues(alpha: 0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF8CC53F), size: 18),
              SizedBox(width: 8),
              Text(
                'Llegaste puntual. ¡Excelente!',
                style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 13),
              ),
            ],
          ),
        );
      case _EstadoPuntualidad.tarde:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFC62828).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF5350), size: 18),
              SizedBox(width: 8),
              Text(
                'Llegaste fuera del horario establecido.',
                style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 13),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTurnoCard(String turnoLabel, String horaLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8CC53F).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            turnoLabel,
            style: const TextStyle(
              color: Color(0xFF8CC53F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            horaLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final h = _countdownRemaining.inHours;
    final m = _countdownRemaining.inMinutes.remainder(60);
    final s = _countdownRemaining.inSeconds.remainder(60);
    final label = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          _esPeriodoEntreTurnos ? 'Próximo turno en' : 'Tu turno comienza en',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF42A5F5),
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRetrasoVisible() {
    final h = _minutosRetraso ~/ 60;
    final m = _minutosRetraso % 60;
    final label = h > 0 ? '$h h $m min' : '$m min';

    return Column(
      children: [
        const Text(
          'TIEMPO DE RETRASO',
          style: TextStyle(
            color: Color(0xFFEF5350),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEF5350),
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Enum auxiliar ──────────────────────────────────────────────────────────

enum _EstadoPuntualidad { anticipado, puntual, tarde }
