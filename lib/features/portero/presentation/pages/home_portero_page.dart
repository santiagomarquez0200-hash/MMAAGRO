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
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_event.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_state.dart';
import 'package:agro_aplicaciones/shared/widgets/scanner_dialog.dart';
import 'package:agro_aplicaciones/shared/widgets/sync_detail_dialog.dart';
import 'package:drift/drift.dart' show Value, ComparableExpr, OrderingTerm;
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/device_service.dart';

// ─── Paleta MMA Agro — idéntica en todos los módulos ─────────────────────────
const _kDark        = Color(0xFF0D241C);  // AppBar / encabezados
const _kMid         = Color(0xFF1B4332);  // Verde primario — texto, iconos
const _kGreen       = Color(0xFF2E7D32);  // Verde secundario / gradiente
const _kLime        = Color(0xFF8CC53F);  // Acento CTA — lima brillante
const _kBg          = Color(0xFFF5F8F5);  // Fondo general

class HomePorteroPage extends StatefulWidget {
  const HomePorteroPage({super.key});

  @override
  State<HomePorteroPage> createState() => _HomePorteroPageState();
}

class _HomePorteroPageState extends State<HomePorteroPage> {
  // ── Campos del formulario ──────────────────────────────────────────────────
  Tractor? _tractorLeido;
  DateTime? _tractorLeidoAt;

  Implemento? _implementoLeido;
  DateTime? _implementoLeidoAt;

  Trabajador? _trabajadorLeido;
  DateTime? _trabajadorLeidoAt;

  Cultivo? _cultivoSeleccionado;
  // P3: indica si el catálogo de cultivos tiene ítems.
  // Si está vacío (error de red al sincronizar), el cultivo se vuelve opcional
  // para no bloquear completamente al portero.
  bool _hayCultivos = true;

  final _comentarioCtrl = TextEditingController();
  bool _guardando = false;
  bool _mostrarValidacion = false;

  // P4: cooldown para evitar recargas múltiples en un mismo ciclo de sync
  DateTime? _ultimoReloadHistorial;

  // ── Historial del día (se carga desde SQLite al iniciar) ────────────────────
  final List<_LecturaItem> _lecturasHoy = [];
  final Set<String> _expandedPares = {};

  @override
  void initState() {
    super.initState();
    _cargarHistorialDelDia();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PAREADO DE LECTURAS: agrupa cada SALIDA con su ENTRADA correspondiente
  // ──────────────────────────────────────────────────────────────────────────

  List<_ParLectura> get _pares {
    // Ordenar ascendente para parear cronológicamente
    final ordenadas = [..._lecturasHoy]
      ..sort((a, b) => a.horaRegistro.compareTo(b.horaRegistro));
    final salidas = ordenadas.where((l) => l.tipo == 'SALIDA').toList();
    final entradas = ordenadas.where((l) => l.tipo == 'ENTRADA').toList();
    final usadas = <String>{};
    final pares = <_ParLectura>[];
    for (final salida in salidas) {
      if (salida.tractorIdErp == null || salida.trabajadorIdErp == null) continue;
      _LecturaItem? match;
      for (final entrada in entradas) {
        if (usadas.contains(entrada.id)) continue;
        if (entrada.tractorIdErp == null || entrada.trabajadorIdErp == null) continue;
        if (entrada.tractorIdErp == salida.tractorIdErp &&
            entrada.trabajadorIdErp == salida.trabajadorIdErp &&
            entrada.horaRegistro.isAfter(salida.horaRegistro)) {
          match = entrada;
          usadas.add(entrada.id);
          break;
        }
      }
      pares.add(_ParLectura(salida: salida, entrada: match));
    }
    // Más reciente primero
    pares.sort((a, b) =>
        b.salida.horaRegistro.compareTo(a.salida.horaRegistro));
    return pares;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CARGA DEL HISTORIAL DESDE SQLITE (PERSISTENCIA ENTRE SESIONES)
  // ──────────────────────────────────────────────────────────────────────────

  static const _kComentarioEntrada = 'ENTRADA A BASE';
  static const _kComentarioSalida  = 'SALIDA DE BASE'; // usado en _guardarLectura

  Future<void> _cargarHistorialDelDia() async {
    final db = sl<AppDatabase>();
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia    = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    // ── Batch 1: últimos 100 registros del día (evita OOM en turnos largos) ──
    final registros = await (db.select(db.porteroLecturasLocal)
          ..where((t) => t.createdAt.isBetweenValues(inicioDia, finDia))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(100))
        .get();

    // ── Batch 2: nombres de trabajadores (1 query para todos) ────────────
    final allTrabajadores = await db.select(db.trabajadoresLocal).get();
    final trabajadoresMap = <int, String>{
      for (final t in allTrabajadores) t.idErp: t.nombres,
    };

    // ── Batch 3: entradas HOY (1 query para detectar retornos) ───────────
    // ANTES: sin filtro de fecha → tractores que retornaron AYER aparecían
    // como "retornados" hoy, bloqueando el botón de nueva entrada a base.
    final entradasHoy = await (db.select(db.porteroLecturasLocal)
          ..where((t) => t.comentario
              .equals(_kComentarioEntrada))
          ..where((t) =>
              t.createdAt.isBetweenValues(inicioDia, finDia)))
        .get();

    // Set de "tractorId_trabajadorId" que ya tienen ENTRADA HOY
    final retornosHoy = <String>{
      for (final e in entradasHoy)
        if (e.tractorIdErp != null && e.trabajadorIdErp != null)
          '${e.tractorIdErp}_${e.trabajadorIdErp}',
    };

    // ── Construir items ───────────────────────────────────────────────────
    final List<_LecturaItem> items = registros.map((reg) {
      // Comparación case-insensitive para no depender de mayúsculas
      final esEntrada = reg.comentario?.toUpperCase() ==
          _kComentarioEntrada.toUpperCase();
      final tipo = esEntrada ? 'ENTRADA' : 'SALIDA';

      final operadorNombre = reg.trabajadorIdErp != null
          ? trabajadoresMap[reg.trabajadorIdErp!]
          : null;

      final tieneRetorno = !esEntrada &&
          reg.tractorIdErp != null &&
          reg.trabajadorIdErp != null &&
          retornosHoy.contains(
              '${reg.tractorIdErp}_${reg.trabajadorIdErp}');

      return _LecturaItem(
        id: reg.id,
        tipo: tipo,
        tractor: reg.tractorCodigo,
        tractorIdErp: reg.tractorIdErp,
        tractorHora: reg.tractorLeidoAt,
        implemento: reg.implementoCodigo,
        implementoIdErp: reg.implementoIdErp,
        implementoHora: reg.implementoLeidoAt,
        operador: operadorNombre,
        trabajadorIdErp: reg.trabajadorIdErp,
        trabajadorCodigo: reg.trabajadorCodigo,
        operadorHora: reg.operadorLeidoAt,
        cultivo: reg.cultivoNombre,
        cultivoIdErp: reg.cultivoIdErp,
        comentario: reg.comentario,
        horaRegistro: reg.createdAt,
        sincronizado: reg.sincronizado,
        expanded: false,
        tieneRetorno: tieneRetorno,
      );
    }).toList();

    // Ordenar por hora descendente (más reciente primero)
    items.sort((a, b) => b.horaRegistro.compareTo(a.horaRegistro));

    if (mounted) {
      setState(() {
        _lecturasHoy.clear();
        _lecturasHoy.addAll(items);
        // P-05: Eliminar de _expandedPares los IDs que ya no existen en los
        // registros cargados para evitar state huérfano.
        final currentIds = items.map((r) => r.id).toSet();
        _expandedPares.removeWhere((id) => !currentIds.contains(id));
      });
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : _kGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ESCANEOS Y SELECCIONES MANUALES
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _escanearTractor(List<Tractor> tractores) async {
    final code = await showScannerDialog(context, label: 'Escanear Tractor');
    if (code == null || !mounted) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = tractores.cast<Tractor?>().firstWhere(
          (t) {
            final c =
                t!.codigoTractor.replaceAll(' ', '').trim().toUpperCase();
            final i =
                (t.codigoInterno ?? '').replaceAll(' ', '').trim().toUpperCase();
            final concat = i.isEmpty ? c : '$c-$i';
            return c == upper || i == upper || concat == upper;
          },
          orElse: () => null,
        );
    if (found != null) {
      setState(() {
        _tractorLeido = found;
        _tractorLeidoAt = DateTime.now();
      });
      _showSnack('Tractor ${found.codigoTractor} registrado');
    } else {
      _showSnack('Tractor "$upper" no encontrado en catálogo', error: true);
    }
  }

  Future<void> _escanearImplemento(List<Implemento> implementos) async {
    final code = await showScannerDialog(context, label: 'Escanear Implemento');
    if (code == null || !mounted) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = implementos.cast<Implemento?>().firstWhere(
          (t) {
            final c =
                t!.codigoImplemento.replaceAll(' ', '').trim().toUpperCase();
            final i =
                (t.codigoInterno ?? '').replaceAll(' ', '').trim().toUpperCase();
            final concat = i.isEmpty ? c : '$c-$i';
            return c == upper || i == upper || concat == upper;
          },
          orElse: () => null,
        );
    if (found != null) {
      setState(() {
        _implementoLeido = found;
        _implementoLeidoAt = DateTime.now();
      });
      _showSnack('Implemento ${found.codigoImplemento} registrado');
    } else {
      _showSnack('Implemento "$upper" no encontrado en catálogo', error: true);
    }
  }

  Future<void> _escanearOperador(List<Trabajador> trabajadores) async {
    final code = await showScannerDialog(context, label: 'Escanear Operador');
    if (code == null || !mounted) return;
    final upper = code.replaceAll(' ', '').trim().toUpperCase();
    final found = trabajadores.cast<Trabajador?>().firstWhere(
          (t) =>
              t!.codTrabajador.replaceAll(' ', '').trim().toUpperCase() ==
              upper,
          orElse: () => null,
        );
    if (found != null) {
      setState(() {
        _trabajadorLeido = found;
        _trabajadorLeidoAt = DateTime.now();
      });
      _showSnack('Operador ${found.nombreCompleto} registrado');
    } else {
      _showSnack('Operador "$upper" no encontrado en catálogo', error: true);
    }
  }

  Future<void> _seleccionarTractorManual(List<Tractor> tractores) async {
    final found = await _showListPicker<Tractor>(
      titulo: 'Seleccionar Tractor',
      items: tractores,
      itemLabel: (t) => '${t.codigoTractor} — ${t.descripcion}',
      itemSub: (t) => t.codigoInterno ?? '',
    );
    if (found != null && mounted) {
      setState(() {
        _tractorLeido = found;
        _tractorLeidoAt = DateTime.now();
      });
      _showSnack('Tractor ${found.codigoTractor} seleccionado');
    }
  }

  Future<void> _seleccionarImplementoManual(
      List<Implemento> implementos) async {
    final found = await _showListPicker<Implemento>(
      titulo: 'Seleccionar Implemento',
      items: implementos,
      itemLabel: (i) => '${i.codigoImplemento} — ${i.descripcion}',
      itemSub: (i) => i.codigoInterno ?? '',
    );
    if (found != null && mounted) {
      setState(() {
        _implementoLeido = found;
        _implementoLeidoAt = DateTime.now();
      });
      _showSnack('Implemento ${found.codigoImplemento} seleccionado');
    }
  }

  Future<void> _seleccionarOperadorManual(List<Trabajador> trabajadores) async {
    final found = await _showListPicker<Trabajador>(
      titulo: 'Seleccionar Operador',
      items: trabajadores.where((t) => t.activo).toList(),
      itemLabel: (t) => t.nombreCompleto,
      itemSub: (t) => t.codTrabajador,
    );
    if (found != null && mounted) {
      setState(() {
        _trabajadorLeido = found;
        _trabajadorLeidoAt = DateTime.now();
      });
      _showSnack('Operador ${found.nombreCompleto} seleccionado');
    }
  }

  Future<T?> _showListPicker<T>({
    required String titulo,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemSub,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ListPickerSheet<T>(
        titulo: titulo,
        items: items,
        itemLabel: itemLabel,
        itemSub: itemSub,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VALIDACIÓN
  // ──────────────────────────────────────────────────────────────────────────

  // Cultivo es requerido solo cuando el catálogo tiene ítems disponibles.
  // Si el catálogo está vacío (fallo de sincronización), se vuelve opcional
  // para no bloquear al portero indefinidamente.
  bool get _formularioValido =>
      _tractorLeido != null &&
      _implementoLeido != null &&
      _trabajadorLeido != null &&
      (_cultivoSeleccionado != null || !_hayCultivos);

  List<String> get _camposFaltantes {
    final f = <String>[];
    if (_tractorLeido == null) f.add('Tractor');
    if (_implementoLeido == null) f.add('Implemento');
    if (_trabajadorLeido == null) f.add('Operador');
    if (_cultivoSeleccionado == null && _hayCultivos) f.add('Cultivo');
    return f;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGISTRO DE SALIDA DE BASE (mañana - cuando el equipo SALE al campo)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _registrarSalidaBase() async {
    setState(() => _mostrarValidacion = true);
    if (!_formularioValido) {
      _showSnack('Faltan: ${_camposFaltantes.join(', ')}', error: true);
      return;
    }

    await _guardarLectura('SALIDA');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGISTRO DE ENTRADA A BASE (tarde - cuando el equipo REGRESA del campo)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _registrarEntradaBase(_LecturaItem salidaItem) async {
    setState(() => _guardando = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      final usuario = authState.usuario;

      final porteroIdErp = usuario.trabajadorIdErp;
      if (porteroIdErp == null || porteroIdErp <= 0) {
        _showSnack('El usuario no tiene ID ERP configurado. Contacte al administrador.', error: true);
        return;
      }

      final db = sl<AppDatabase>();

      // P-04: Evitar duplicar ENTRADA para el mismo tractor+trabajador en el día.
      if (salidaItem.tractorIdErp != null && salidaItem.trabajadorIdErp != null) {
        final hoy = DateTime.now();
        final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
        final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
        // P-04: Busca duplicado filtrando por fecha en la query y el resto en Dart
        // para evitar el operador & de Drift en columnas nullable.
        final todayRows = await (db.select(db.porteroLecturasLocal)
              ..where((t) => t.createdAt.isBetweenValues(inicioDia, finDia)))
            .get();
        final existing = todayRows
            .where((r) =>
                r.tractorIdErp == salidaItem.tractorIdErp &&
                r.trabajadorIdErp == salidaItem.trabajadorIdErp &&
                r.comentario == _kComentarioEntrada)
            .toList();
        if (existing.isNotEmpty) {
          _showSnack('Ya existe una entrada registrada para este equipo hoy');
          return;
        }
      }

      final deviceId = await sl<DeviceService>().getDeviceId();
      final id = const Uuid().v4();
      final now = DateTime.now();

      final payload = {
        'id': id,
        'portero_id_erp': usuario.trabajadorIdErp,
        'tractor_id_erp': salidaItem.tractorIdErp,
        'tractor_codigo': salidaItem.tractor,
        'tractor_leido_at': now.toIso8601String(),
        'implemento_id_erp': salidaItem.implementoIdErp,
        'implemento_codigo': salidaItem.implemento,
        'implemento_leido_at': now.toIso8601String(),
        'trabajador_id_erp': salidaItem.trabajadorIdErp,
        'trabajador_codigo': salidaItem.trabajadorCodigo,
        'operador_leido_at': now.toIso8601String(),
        'cultivo_id_erp': salidaItem.cultivoIdErp,
        'cultivo_nombre': salidaItem.cultivo,
        'comentario': 'ENTRADA A BASE',
        'dispositivo_id': deviceId,
      };

      // Transacción atómica: local + outbox juntos o ninguno.
      // Si el segundo insert falla, el registro no queda huérfano (sin outbox).
      await db.transaction(() async {
        await db.into(db.porteroLecturasLocal).insert(
              PorteroLecturasLocalCompanion.insert(
                id: id,
                porteroIdErp: porteroIdErp,
                tractorIdErp: Value(salidaItem.tractorIdErp),
                tractorCodigo: Value(salidaItem.tractor),
                tractorLeidoAt: Value(now),
                implementoIdErp: Value(salidaItem.implementoIdErp),
                implementoCodigo: Value(salidaItem.implemento),
                implementoLeidoAt: Value(now),
                trabajadorIdErp: Value(salidaItem.trabajadorIdErp),
                trabajadorCodigo: Value(salidaItem.trabajadorCodigo),
                operadorLeidoAt: Value(now),
                cultivoIdErp: Value(salidaItem.cultivoIdErp),
                cultivoNombre: Value(salidaItem.cultivo),
                comentario: const Value('ENTRADA A BASE'),
                dispositivoId: Value(deviceId),
              ),
            );
        await db.outboxDao.insertEntry(OutboxEntriesCompanion(
          registroLocalId: Value(id),
          endpoint: const Value('POST /portero/lecturas'),
          method: const Value('POST'),
          payloadJson: Value(jsonEncode(payload)),
        ));
      });

      // Recargar historial desde SQLite
      await _cargarHistorialDelDia();

      // Sincronizar automáticamente con el servidor
      if (mounted) {
        context.read<SyncBloc>().add(const SyncManualRequested());
      }

      _showSnack('Entrada a base registrada. Sincronizando con el servidor...');
    } catch (e) {
      _showSnack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GUARDADO GENÉRICO (local + outbox)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _guardarLectura(String tipo) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final usuario = authState.usuario;

    // Guard: si el portero no tiene ID ERP no podemos registrar nada útil.
    final porteroIdErp = usuario.trabajadorIdErp;
    if (porteroIdErp == null || porteroIdErp <= 0) {
      _showSnack('El usuario no tiene ID ERP configurado. Contacte al administrador.', error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      final db = sl<AppDatabase>();
      final deviceId = await sl<DeviceService>().getDeviceId();
      final id = const Uuid().v4();
      final comentario = _comentarioCtrl.text.isNotEmpty
          ? _comentarioCtrl.text
          : (tipo == 'SALIDA' ? _kComentarioSalida : _kComentarioEntrada);

      final payload = {
        'id': id,
        'portero_id_erp': porteroIdErp,
        'tractor_id_erp': _tractorLeido?.idErp,
        'tractor_codigo': _tractorLeido?.codigoTractor,
        'tractor_leido_at': _tractorLeidoAt?.toIso8601String(),
        'implemento_id_erp': _implementoLeido?.idErp,
        'implemento_codigo': _implementoLeido?.codigoImplemento,
        'implemento_leido_at': _implementoLeidoAt?.toIso8601String(),
        'trabajador_id_erp': _trabajadorLeido?.idErp,
        'trabajador_codigo': _trabajadorLeido?.codTrabajador,
        'operador_leido_at': _trabajadorLeidoAt?.toIso8601String(),
        'cultivo_id_erp': _cultivoSeleccionado?.idErp,
        'cultivo_nombre': _cultivoSeleccionado?.displayName,
        'comentario': comentario,
        'dispositivo_id': deviceId,
      };

      // Transacción atómica: local + outbox juntos o ninguno.
      await db.transaction(() async {
        await db.into(db.porteroLecturasLocal).insert(
              PorteroLecturasLocalCompanion.insert(
                id: id,
                porteroIdErp: porteroIdErp,
                tractorIdErp: Value(_tractorLeido?.idErp),
                tractorCodigo: Value(_tractorLeido?.codigoTractor),
                tractorLeidoAt: Value(_tractorLeidoAt),
                implementoIdErp: Value(_implementoLeido?.idErp),
                implementoCodigo: Value(_implementoLeido?.codigoImplemento),
                implementoLeidoAt: Value(_implementoLeidoAt),
                trabajadorIdErp: Value(_trabajadorLeido?.idErp),
                trabajadorCodigo: Value(_trabajadorLeido?.codTrabajador),
                operadorLeidoAt: Value(_trabajadorLeidoAt),
                cultivoIdErp: Value(_cultivoSeleccionado?.idErp),
                cultivoNombre: Value(_cultivoSeleccionado?.displayName),
                comentario: Value(comentario),
                dispositivoId: Value(deviceId),
              ),
            );
        await db.outboxDao.insertEntry(OutboxEntriesCompanion(
          registroLocalId: Value(id),
          endpoint: const Value('POST /portero/lecturas'),
          method: const Value('POST'),
          payloadJson: Value(jsonEncode(payload)),
        ));
      });

      // Recargar historial desde SQLite
      await _cargarHistorialDelDia();

      // Limpiar formulario
      setState(() {
        _tractorLeido = null;
        _tractorLeidoAt = null;
        _implementoLeido = null;
        _implementoLeidoAt = null;
        _trabajadorLeido = null;
        _trabajadorLeidoAt = null;
        _cultivoSeleccionado = null;
        _comentarioCtrl.clear();
        _mostrarValidacion = false;
      });

      // Sincronizar automáticamente con el servidor
      if (mounted) {
        context.read<SyncBloc>().add(const SyncManualRequested());
      }

      _showSnack(tipo == 'SALIDA'
          ? 'Salida registrada. Sincronizando con el servidor...'
          : 'Registro guardado. Sincronizando con el servidor...');
    } catch (e) {
      _showSnack('Error al registrar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _onSyncSuccess() {
    // Debounce: ignorar llamadas repetidas dentro de 2 segundos.
    // El SyncBloc puede emitir SyncUpdated(pendingCount:0) varias veces en un
    // mismo ciclo de sincronización, lo que dispararía múltiples cargas N+1.
    final ahora = DateTime.now();
    if (_ultimoReloadHistorial != null &&
        ahora.difference(_ultimoReloadHistorial!).inSeconds < 5) {
      return;
    }
    _ultimoReloadHistorial = ahora;
    _cargarHistorialDelDia();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state is SyncUpdated &&
            !state.isSyncing &&
            state.pendingCount == 0) {
          _onSyncSuccess();
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kDark,
          foregroundColor: Colors.white,
          title: const Text(
            'Control de Ingreso',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            BlocBuilder<SyncBloc, SyncState>(
              builder: (context, syncState) {
                final syncing = syncState is SyncUpdated && syncState.isSyncing;
                return IconButton(
                  icon: syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  tooltip:
                      syncing ? 'Sincronizando...' : 'Sincronizar con servidor',
                  onPressed: syncing
                      ? null
                      : () => showSyncDetailDialog(context),
                );
              },
            ),
            // Lo que DEBE SALIR este turno. El registro de lecturas de
            // abajo solo escribe; sin esta lista no hay con que comparar.
            IconButton(
              icon: const Icon(Icons.assignment_turned_in_outlined),
              tooltip: 'Programa de entrega del turno',
              onPressed: () => context.push('/portero/programa'),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Mi perfil / Cerrar sesión',
              onPressed: () => context.push('/perfil'),
            ),
          ],
        ),
        body: BlocConsumer<CatalogoBloc, CatalogoState>(
          listener: (context, catState) {
            if (catState is CatalogoLoaded) {
              setState(() => _hayCultivos = catState.cultivos.isNotEmpty);
            }
          },
          builder: (context, catState) {
            if (catState is! CatalogoLoaded) {
              return const Center(
                  child: CircularProgressIndicator(color: _kLime));
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildFormulario(catState)),
                if (_lecturasHoy.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildHistorialHeader()),
                  if (_lecturasHoy.length >= 100)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.amber.withValues(alpha: 0.2),
                          child: const Text(
                            '⚠️ Mostrando los últimos 100 registros del día',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _buildParCard(_pares[i]),
                      ),
                      childCount: _pares.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FORMULARIO
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildFormulario(CatalogoLoaded cat) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mostrarValidacion && !_formularioValido)
            _buildValidacionBanner(),
          _buildScanGrid(cat),
          const SizedBox(height: 14),
          _buildCultivoPicker(cat.cultivos),
          const SizedBox(height: 14),
          TextFormField(
            controller: _comentarioCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Observaciones (opcional)',
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon:
                  const Icon(Icons.comment_outlined, color: Color(0xFF1B4332)),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _registrarSalidaBase,
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Icon(Icons.logout_rounded, size: 22),
              label: Text(
                _guardando ? 'Registrando...' : 'REGISTRAR SALIDA DE BASE',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.8),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _formularioValido
                    ? _kLime
                    : _kMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildValidacionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Obligatorio: ${_camposFaltantes.join(', ')}',
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanGrid(CatalogoLoaded cat) {
    final faltantes = _mostrarValidacion ? _camposFaltantes : <String>[];
    return Column(
      children: [
        _buildDualActionTile(
          icono: Icons.agriculture_rounded,
          titulo: 'Tractor',
          valor: _tractorLeido?.codigoTractor,
          detalle: _tractorLeido?.descripcion,
          hora: _tractorLeidoAt,
          color: _kMid,
          requerido: faltantes.contains('Tractor'),
          onScan: () => _escanearTractor(cat.tractores),
          onSelect: () => _seleccionarTractorManual(cat.tractores),
          onClear: () => setState(() {
            _tractorLeido = null;
            _tractorLeidoAt = null;
          }),
        ),
        const SizedBox(height: 10),
        _buildDualActionTile(
          icono: Icons.construction_rounded,
          titulo: 'Implemento',
          valor: _implementoLeido?.codigoImplemento,
          detalle: _implementoLeido?.descripcion,
          hora: _implementoLeidoAt,
          color: const Color(0xFF1565C0),
          requerido: faltantes.contains('Implemento'),
          onScan: () => _escanearImplemento(cat.implementos),
          onSelect: () => _seleccionarImplementoManual(cat.implementos),
          onClear: () => setState(() {
            _implementoLeido = null;
            _implementoLeidoAt = null;
          }),
        ),
        const SizedBox(height: 10),
        _buildDualActionTile(
          icono: Icons.person_rounded,
          titulo: 'Operador',
          valor: _trabajadorLeido?.nombreCompleto,
          detalle: _trabajadorLeido?.codTrabajador,
          hora: _trabajadorLeidoAt,
          color: const Color(0xFF6A1B9A),
          requerido: faltantes.contains('Operador'),
          onScan: () => _escanearOperador(cat.trabajadores),
          onSelect: () => _seleccionarOperadorManual(cat.trabajadores),
          onClear: () => setState(() {
            _trabajadorLeido = null;
            _trabajadorLeidoAt = null;
          }),
        ),
      ],
    );
  }

  Widget _buildDualActionTile({
    required IconData icono,
    required String titulo,
    required String? valor,
    String? detalle,
    required DateTime? hora,
    required Color color,
    required bool requerido,
    required VoidCallback onScan,
    required VoidCallback onSelect,
    required VoidCallback onClear,
  }) {
    final ok = valor != null;
    final borderColor = requerido
        ? Colors.red.shade400
        : ok
            ? color.withValues(alpha: 0.4)
            : Colors.grey.shade200;
    final bgColor = requerido
        ? Colors.red.shade50
        : ok
            ? color.withValues(alpha: 0.06)
            : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: requerido ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : icono,
            color: requerido
                ? Colors.red.shade400
                : ok
                    ? color
                    : Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: requerido
                        ? Colors.red.shade600
                        : ok
                            ? color
                            : Colors.grey.shade600,
                  ),
                ),
                if (ok) ...[
                  Text(
                    valor,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detalle != null && detalle.isNotEmpty)
                    Text(
                      detalle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (hora != null)
                    Text(
                      DateFormat('HH:mm').format(hora),
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                ] else
                  Text(
                    'Sin seleccionar',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          if (ok)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
              color: Colors.grey.shade400,
              tooltip: 'Limpiar',
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: 4),
          _buildActionBtn(
            icon: Icons.qr_code_scanner,
            label: 'QR',
            color: color,
            onTap: onScan,
          ),
          const SizedBox(width: 6),
          _buildActionBtn(
            icon: Icons.list_rounded,
            label: 'Lista',
            color: color,
            onTap: onSelect,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCultivoPicker(List<Cultivo> cultivos) {
    final requerido = _mostrarValidacion && _cultivoSeleccionado == null;
    return DropdownButtonFormField<Cultivo>(
      initialValue: _cultivoSeleccionado,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Cultivo *',
        filled: true,
        fillColor: requerido ? Colors.red.shade50 : Colors.white,
        prefixIcon: Icon(Icons.eco_rounded,
            color: requerido ? Colors.red.shade400 : _kGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: requerido ? Colors.red.shade400 : Colors.grey.shade400,
            width: requerido ? 1.5 : 1,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem<Cultivo>(
            value: null, child: Text('-- Seleccionar cultivo --')),
        ...cultivos.map((c) => DropdownMenuItem<Cultivo>(
              value: c,
              child: Text(c.displayName, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _cultivoSeleccionado = v),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HISTORIAL
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHistorialHeader() {
    final pares = _pares;
    final pendientes = pares.where((p) => p.entrada == null).length;
    final completos = pares.where((p) => p.entrada != null).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.list_alt_rounded,
              color: Color(0xFF1B4332), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Hoy: $completos completo${completos != 1 ? 's' : ''}'
              '${pendientes > 0 ? ' · $pendientes pendiente${pendientes != 1 ? 's' : ''}' : ''}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1B4332)),
            ),
          ),
          if (pendientes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pendientes sin retorno',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de par SALIDA + RETORNO ────────────────────────────────────────

  Widget _buildParCard(_ParLectura par) {
    final salida = par.salida;
    final entrada = par.entrada;
    final pendiente = entrada == null;
    final expanded = _expandedPares.contains(salida.id);

    final horasSin = pendiente
        ? DateTime.now().difference(salida.horaRegistro).inHours
        : 0;
    final conRetraso = pendiente && horasSin >= 4;

    // ── Paleta por cultivo ──────────────────────────────────────────────────
    final cultivoColors = _cultivoColor(salida.cultivo);
    final Color borderColor = cultivoColors.$1;
    final Color headerBg    = cultivoColors.$2;

    // Badge de estado (encima del color de cultivo)
    final Color badgeColor;
    final String badgeLabel;
    if (conRetraso) {
      badgeColor = const Color(0xFFC62828);
      badgeLabel = 'RETRASO ${horasSin}h';
    } else if (pendiente) {
      badgeColor = const Color(0xFFE65100);
      badgeLabel = 'PENDIENTE';
    } else {
      badgeColor = _kGreen;
      badgeLabel = 'COMPLETO';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: borderColor.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera coloreada ───────────────────────────────────────────
            InkWell(
              onTap: () => setState(() {
                if (expanded) {
                  _expandedPares.remove(salida.id);
                } else {
                  _expandedPares.add(salida.id);
                }
              }),
              child: Container(
                color: headerBg,
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.agriculture_rounded,
                          size: 16, color: borderColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salida.tractor ?? 'Sin tractor',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: borderColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (salida.cultivo != null)
                            Text(
                              salida.cultivo!,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            // ── Filas SALIDA / RETORNO ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  _buildParRow(
                    icon: Icons.logout_rounded,
                    label: 'SALIDA DE BASE',
                    hora: salida.horaRegistro,
                    sincronizado: salida.sincronizado,
                    rowBg: headerBg,
                    iconColor: borderColor,
                    labelColor: borderColor,
                  ),
                  const SizedBox(height: 6),
                  _buildParRow(
                    icon: Icons.login_rounded,
                    label: 'RETORNO A BASE',
                    hora: entrada?.horaRegistro,
                    sincronizado: entrada?.sincronizado,
                    rowBg: pendiente
                        ? const Color(0xFFFFF3E0)
                        : headerBg,
                    iconColor: pendiente
                        ? const Color(0xFFE65100)
                        : borderColor,
                    labelColor: pendiente
                        ? const Color(0xFFBF360C)
                        : borderColor,
                    pending: pendiente,
                  ),
                  // Botón de retorno siempre visible cuando está pendiente
                  if (pendiente) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _guardando
                            ? null
                            : () => _registrarEntradaBase(salida),
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: Text(
                          conRetraso
                              ? 'REGISTRAR RETORNO (${horasSin}h de retraso)'
                              : 'REGISTRAR RETORNO A BASE',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: conRetraso
                              ? const Color(0xFFC62828)
                              : _kMid,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Detalles expandidos ──────────────────────────────────────────
            if (expanded) ...[
              Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DETALLES',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade500,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (salida.implemento != null)
                          _infoBadge(Icons.construction_rounded,
                              salida.implemento!, null,
                              const Color(0xFF1565C0)),
                        if (salida.operador != null)
                          _infoBadge(Icons.person_rounded,
                              salida.operador!, null,
                              const Color(0xFF6A1B9A)),
                        if (salida.cultivo != null)
                          _infoBadge(Icons.eco_rounded,
                              salida.cultivo!, null,
                              _kGreen),
                        _infoBadge(
                            Icons.logout_rounded,
                            'Salida ${DateFormat('HH:mm').format(salida.horaRegistro)}',
                            null,
                            _kMid),
                        if (entrada != null)
                          _infoBadge(
                              Icons.login_rounded,
                              'Retorno ${DateFormat('HH:mm').format(entrada.horaRegistro)}',
                              null,
                              Colors.green.shade700),
                      ],
                    ),
                    if (salida.comentario != null &&
                        salida.comentario!.isNotEmpty &&
                        salida.comentario != 'SALIDA DE BASE') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(salida.comentario!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParRow({
    required IconData icon,
    required String label,
    required DateTime? hora,
    required bool? sincronizado,
    required Color rowBg,
    required Color iconColor,
    required Color labelColor,
    bool pending = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: labelColor,
                letterSpacing: 0.3),
          ),
          const SizedBox(width: 10),
          if (!pending && hora != null)
            Text(
              DateFormat('HH:mm').format(hora),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: labelColor),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SIN REGISTRAR',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w900),
              ),
            ),
          const Spacer(),
          if (sincronizado != null)
            Icon(
              sincronizado
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_upload_outlined,
              color: sincronizado
                  ? _kGreen
                  : Colors.grey.shade400,
              size: 18,
            ),
        ],
      ),
    );
  }

  // Devuelve (borderColor, headerBg) según el nombre del cultivo.
  // Coincidencia parcial e insensible a mayúsculas para cubrir variantes
  // como "Espárrago Verde", "ESPARRAGO", "Palta Hass", etc.
  (Color, Color) _cultivoColor(String? cultivo) {
    if (cultivo == null) {
      return (const Color(0xFF546E7A), const Color(0xFFECEFF1)); // gris azulado
    }
    final c = cultivo.toLowerCase();

    if (c.contains('esparr') || c.contains('espárr')) {
      // Espárrago → morado claro
      return (const Color(0xFF7B1FA2), const Color(0xFFF3E5F5));
    }
    if (c.contains('palta') || c.contains('aguacat')) {
      // Palta → verde oscuro
      return (const Color(0xFF1B5E20), const Color(0xFFE8F5E9));
    }
    if (c.contains('arándano') || c.contains('arandano') || c.contains('blueberr')) {
      // Arándano → azul-índigo
      return (const Color(0xFF283593), const Color(0xFFE8EAF6));
    }
    if (c.contains('uva') || c.contains('vid')) {
      // Uva → violeta
      return (const Color(0xFF4A148C), const Color(0xFFEDE7F6));
    }
    if (c.contains('mango')) {
      // Mango → naranja intenso
      return (const Color(0xFFE65100), const Color(0xFFFFF3E0));
    }
    if (c.contains('limón') || c.contains('limon') || c.contains('cítrico') || c.contains('citrico')) {
      // Limón → amarillo-verde
      return (const Color(0xFF827717), const Color(0xFFF9FBE7));
    }
    if (c.contains('mandarin') || c.contains('naranj')) {
      // Mandarina / Naranja → naranja
      return (const Color(0xFFBF360C), const Color(0xFFFBE9E7));
    }
    if (c.contains('caña') || c.contains('cana') || c.contains('azucar')) {
      // Caña de azúcar → marrón cálido
      return (const Color(0xFF4E342E), const Color(0xFFEFEBE9));
    }
    if (c.contains('quinua') || c.contains('quínua')) {
      // Quinua → teal
      return (const Color(0xFF00695C), const Color(0xFFE0F2F1));
    }
    if (c.contains('papa') || c.contains('patata')) {
      // Papa → tierra
      return (const Color(0xFF6D4C41), const Color(0xFFEFEBE9));
    }
    // Default: gris azulado neutro
    return (const Color(0xFF37474F), const Color(0xFFECEFF1));
  }

  Widget _infoBadge(IconData icon, String texto, DateTime? hora, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(texto,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              if (hora != null)
                Text(
                  DateFormat('HH:mm:ss').format(hora),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
            ],
          ),
        ],
      ),
    );
  }

}


// ──────────────────────────────────────────────────────────────────────────
// LIST PICKER SHEET
// ──────────────────────────────────────────────────────────────────────────

class _ListPickerSheet<T> extends StatefulWidget {
  final String titulo;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T) itemSub;

  const _ListPickerSheet({
    required this.titulo,
    required this.items,
    required this.itemLabel,
    required this.itemSub,
  });

  @override
  State<_ListPickerSheet<T>> createState() => _ListPickerSheetState<T>();
}

class _ListPickerSheetState<T> extends State<_ListPickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final filtered = widget.items.where((item) {
      return widget.itemLabel(item).toLowerCase().contains(q) ||
          widget.itemSub(item).toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Text(
            widget.titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1B4332)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _q = v),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Sin resultados'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return ListTile(
                        title: Text(widget.itemLabel(item)),
                        subtitle: Text(widget.itemSub(item),
                            style: const TextStyle(fontSize: 12)),
                        onTap: () => Navigator.pop(context, item),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// MODELOS (memoria)
// ──────────────────────────────────────────────────────────────────────────

class _ParLectura {
  final _LecturaItem salida;
  final _LecturaItem? entrada; // null = retorno pendiente

  const _ParLectura({required this.salida, this.entrada});
}

class _LecturaItem {
  final String id;
  final String tipo; // 'SALIDA' | 'ENTRADA'
  final String? tractor;
  final int? tractorIdErp;
  final DateTime? tractorHora;
  final String? implemento;
  final int? implementoIdErp;
  final DateTime? implementoHora;
  final String? operador;
  final int? trabajadorIdErp;
  final String? trabajadorCodigo;
  final DateTime? operadorHora;
  final String? cultivo;
  final int? cultivoIdErp;
  final String? comentario;
  final DateTime horaRegistro;
  final bool sincronizado;
  final bool expanded;
  final bool
      tieneRetorno; // Solo aplica para SALIDA: indica si ya se registró el retorno

  const _LecturaItem({
    required this.id,
    required this.tipo,
    this.tractor,
    this.tractorIdErp,
    this.tractorHora,
    this.implemento,
    this.implementoIdErp,
    this.implementoHora,
    this.operador,
    this.trabajadorIdErp,
    this.trabajadorCodigo,
    this.operadorHora,
    this.cultivo,
    this.cultivoIdErp,
    this.comentario,
    required this.horaRegistro,
    required this.sincronizado,
    required this.expanded,
    required this.tieneRetorno,
  });

  _LecturaItem copyWith({
    bool? sincronizado,
    bool? expanded,
    bool? tieneRetorno,
  }) =>
      _LecturaItem(
        id: id,
        tipo: tipo,
        tractor: tractor,
        tractorIdErp: tractorIdErp,
        tractorHora: tractorHora,
        implemento: implemento,
        implementoIdErp: implementoIdErp,
        implementoHora: implementoHora,
        operador: operador,
        trabajadorIdErp: trabajadorIdErp,
        trabajadorCodigo: trabajadorCodigo,
        operadorHora: operadorHora,
        cultivo: cultivo,
        cultivoIdErp: cultivoIdErp,
        comentario: comentario,
        horaRegistro: horaRegistro,
        sincronizado: sincronizado ?? this.sincronizado,
        expanded: expanded ?? this.expanded,
        tieneRetorno: tieneRetorno ?? this.tieneRetorno,
      );
}
