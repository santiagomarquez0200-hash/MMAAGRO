import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_event.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_state.dart';

/// Modal de sincronización: muestra en tiempo real el estado del outbox.
/// Usa un StreamBuilder sobre watchAllActive() para reflejar cualquier cambio
/// del outbox (sync manual, auto-sync por conectividad, retries).
Future<void> showSyncDetailDialog(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<SyncBloc>(),
      child: const _SyncDetailSheet(),
    ),
  );
}

// ─── Constantes de paleta ─────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B4332);
const _kLime = Color(0xFF8CC53F);

// ─── Clasificación de errores ────────────────────────────────────────────────

enum _ErrorTipo { red, timeout, sp, erp, bd, desconocido }

_ErrorTipo _clasificarError(String? msg) {
  if (msg == null || msg.isEmpty) return _ErrorTipo.desconocido;
  final l = msg.toLowerCase();
  if (l.contains('sin conexión') || l.contains('socket') ||
      l.contains('network') || l.contains('connection')) {
    return _ErrorTipo.red;
  }
  if (l.contains('timeout') || l.contains('time out')) {
    return _ErrorTipo.timeout;
  }
  if (l.contains('sp_') || l.contains('rechazó') ||
      l.contains('sin mensaje del sp') || l.contains('no retornó') ||
      l.contains('success') || l.contains('stored procedure') ||
      l.contains('procedimiento')) {
    return _ErrorTipo.sp;
  }
  if (l.contains('constraint') || l.contains('unique') ||
      l.contains('foreign key') || l.contains('tabla') ||
      l.contains('column') || l.contains('schema') ||
      l.contains('sqlite') || l.contains('drift')) {
    return _ErrorTipo.bd;
  }
  if (l.contains('http') || l.contains('401') || l.contains('403') ||
      l.contains('404') || l.contains('500') || l.contains('servidor') ||
      l.contains('api')) {
    return _ErrorTipo.erp;
  }
  return _ErrorTipo.desconocido;
}

String _errorTipoLabel(_ErrorTipo t) {
  switch (t) {
    case _ErrorTipo.red:         return 'SIN RED';
    case _ErrorTipo.timeout:     return 'TIMEOUT';
    case _ErrorTipo.sp:          return 'ERROR SP';
    case _ErrorTipo.erp:         return 'ERROR ERP';
    case _ErrorTipo.bd:          return 'ERROR BD';
    case _ErrorTipo.desconocido: return 'DESCONOCIDO';
  }
}

Color _errorTipoColor(_ErrorTipo t) {
  switch (t) {
    case _ErrorTipo.red:         return Colors.blueGrey;
    case _ErrorTipo.timeout:     return Colors.amber.shade700;
    case _ErrorTipo.sp:          return Colors.red.shade700;
    case _ErrorTipo.erp:         return Colors.deepOrange.shade700;
    case _ErrorTipo.bd:          return Colors.purple.shade700;
    case _ErrorTipo.desconocido: return Colors.grey.shade600;
  }
}

IconData _errorTipoIcon(_ErrorTipo t) {
  switch (t) {
    case _ErrorTipo.red:         return Icons.wifi_off_rounded;
    case _ErrorTipo.timeout:     return Icons.timer_off_rounded;
    case _ErrorTipo.sp:          return Icons.code_off_rounded;
    case _ErrorTipo.erp:         return Icons.cloud_off_rounded;
    case _ErrorTipo.bd:          return Icons.storage_rounded;
    case _ErrorTipo.desconocido: return Icons.help_outline_rounded;
  }
}

String _spName(String endpoint) {
  if (endpoint == '/registros' || endpoint == 'POST /registros/vehiculo' ||
      endpoint == '/registros/vehiculo' || endpoint == 'PUT /registros/vehiculo') {
    return 'SP_MMA_SINCRONIZAR_OFFLINE';
  }
  if (endpoint.contains('/checklist')) return 'SP_MMA_GUARDAR_CHECKLIST';
  if (endpoint.contains('/bines'))     return 'SP_MMA_REGISTRAR_BIN';
  if (endpoint.contains('/paros'))     return 'SP_MMA_REGISTRAR_PARO';
  if (endpoint.contains('/cerrar'))    return 'SP_MMA_CERRAR_TURNO';
  if (endpoint.contains('/aprobar'))   return 'SP_MMA_APROBAR_REGISTRO';
  if (endpoint.contains('portero') || endpoint.contains('lectura')) {
    return 'SP_MMA_REGISTRAR_LECTURA_PORTERO';
  }
  if (endpoint.contains('jornada'))    return 'SP_MMA_ACTUALIZAR_STATUS_JORNADA';
  return endpoint;
}

// ─── Sheet principal ──────────────────────────────────────────────────────────

class _SyncDetailSheet extends StatefulWidget {
  const _SyncDetailSheet();
  @override
  State<_SyncDetailSheet> createState() => _SyncDetailSheetState();
}

class _SyncDetailSheetState extends State<_SyncDetailSheet> {
  /// true mientras el sync manual está en curso (controla overlay y botón).
  bool _syncing = false;

  /// Se activa tras completar un sync manual para mostrar el banner de resultado.
  bool _syncJustCompleted = false;

  /// Stream reactivo: emite siempre que el outbox cambie (manual o automático).
  late final Stream<_OutboxData> _stream = sl<AppDatabase>()
      .outboxDao
      .watchAllActive()
      .asyncMap(_buildOutboxData);

  Future<_OutboxData> _buildOutboxData(List<OutboxEntry> all) async {
    final pending = all
        .where((e) => ['pending', 'failed', 'syncing'].contains(e.status))
        .toList();
    final permFailed = all
        .where((e) => e.status == 'permanently_failed')
        .toList();
    final prefs = await SharedPreferences.getInstance();
    final rawAt = prefs.getString('last_sync_at');
    final lastSyncAt = rawAt != null ? DateTime.tryParse(rawAt) : null;
    return _OutboxData(pending: pending, permFailed: permFailed, lastSyncAt: lastSyncAt);
  }

  // ─── Helpers de etiquetas ─────────────────────────────────────────────────

  String _operacionLabel(String endpoint, String method) {
    if (method == 'POST' && endpoint == '/registros') return 'Crear registro';
    if (method == 'POST' && endpoint == '/registros/vehiculo') {
      return 'Crear registro vehículo';
    }
    if (endpoint.contains('/checklist')) return 'Guardar checklist';
    if (endpoint.contains('/bines')) return 'Registrar bines';
    if (endpoint.contains('/paros')) return 'Registrar paro';
    if (endpoint.contains('/cerrar')) return 'Cerrar jornada';
    if (endpoint.contains('/aprobar')) return 'Aprobar / rechazar';
    if (endpoint.contains('jornada')) return 'Estado jornada';
    if (endpoint.contains('portero') || endpoint.contains('lectura')) {
      return 'Lectura portería';
    }
    return endpoint;
  }

  IconData _operacionIcon(String endpoint) {
    if (endpoint == '/registros' || endpoint == '/registros/vehiculo') {
      return Icons.add_circle_outline_rounded;
    }
    if (endpoint.contains('/checklist')) return Icons.checklist_rounded;
    if (endpoint.contains('/bines')) return Icons.inventory_2_outlined;
    if (endpoint.contains('/paros')) return Icons.pause_circle_outline_rounded;
    if (endpoint.contains('/cerrar')) return Icons.check_circle_outline_rounded;
    if (endpoint.contains('/aprobar')) return Icons.verified_outlined;
    if (endpoint.contains('jornada')) return Icons.access_time_rounded;
    if (endpoint.contains('portero') || endpoint.contains('lectura')) {
      return Icons.qr_code_scanner_rounded;
    }
    return Icons.sync_rounded;
  }

  Color _operacionColor(String endpoint) {
    if (endpoint == '/registros' || endpoint == '/registros/vehiculo') {
      return _kGreen;
    }
    if (endpoint.contains('/checklist')) return const Color(0xFF00695C);
    if (endpoint.contains('/bines')) return const Color(0xFF2E7D32);
    if (endpoint.contains('/paros')) return const Color(0xFFEF6C00);
    if (endpoint.contains('/cerrar')) return const Color(0xFF1565C0);
    if (endpoint.contains('/aprobar')) return const Color(0xFF6A1B9A);
    return Colors.grey.shade700;
  }

  String _statusLabel(String status, int retryCount) {
    switch (status) {
      case 'permanently_failed':
        return 'Fallo permanente';
      case 'failed':
        return 'Fallo (intento $retryCount)';
      case 'syncing':
        return 'Enviando…';
      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'permanently_failed':
        return Colors.red.shade900;
      case 'failed':
        return Colors.red.shade700;
      case 'syncing':
        return Colors.blue.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  // ─── Agrupación ───────────────────────────────────────────────────────────

  Map<String, List<OutboxEntry>> _agrupar(List<OutboxEntry> entries) {
    final map = <String, List<OutboxEntry>>{};
    for (final e in entries) {
      final key = e.registroLocalId ?? '—';
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _sincronizar() async {
    setState(() {
      _syncing = true;
      _syncJustCompleted = false;
    });
    final syncBloc = context.read<SyncBloc>();
    syncBloc.add(const SyncManualRequested());
    try {
      await syncBloc.stream
          .firstWhere((s) => s is SyncUpdated && !s.isSyncing)
          .timeout(const Duration(seconds: 90));
    } catch (_) {}
    if (mounted) {
      setState(() {
        _syncing = false;
        _syncJustCompleted = true;
      });
    }
  }

  Future<void> _retryEntry(int id) async {
    await sl<AppDatabase>().outboxDao.resetForRetry(id);
  }

  Future<void> _deleteEntry(int id) async {
    await sl<AppDatabase>().outboxDao.deleteEntry(id);
  }

  Future<void> _clearAllPermanent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpiar fallos permanentes'),
        content: const Text(
            'Se eliminarán todas las operaciones con fallo permanente. '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LIMPIAR'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await sl<AppDatabase>().outboxDao.clearPermFailed();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Expanded(
              child: BlocBuilder<SyncBloc, SyncState>(
                builder: (context, blocState) {
                  final isSyncing =
                      _syncing || (blocState is SyncUpdated && blocState.isSyncing);
                  final syncUpdated =
                      blocState is SyncUpdated ? blocState : null;

                  return StreamBuilder<_OutboxData>(
                    stream: _stream,
                    builder: (ctx, snap) {
                      // Spinner inicial mientras el stream emite por primera vez
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(color: _kLime));
                      }

                      final pending = snap.data!.pending;
                      final permFailed = snap.data!.permFailed;
                      final total = pending.length + permFailed.length;
                      final lastSyncAt = snap.data!.lastSyncAt;

                      return Stack(
                        children: [
                          Column(
                            children: [
                              // ── Header ──────────────────────────────────
                              _buildHeader(total, lastSyncAt, isSyncing),
                              const Divider(height: 1),

                              // ── Banner: sincronizando EN CURSO ──────────
                              if (isSyncing) _buildSyncingBanner(pending.length),

                              // ── Banner: resultado post-sync ─────────────
                              if (_syncJustCompleted && !isSyncing && syncUpdated != null)
                                _buildResultadoBanner(
                                  pendingAfter: total - permFailed.length,
                                  permFailedAfter: permFailed.length,
                                  syncState: syncUpdated,
                                ),

                              // ── Lista ────────────────────────────────────
                              Expanded(
                                child: total == 0 && !_syncJustCompleted
                                    ? _buildVacio()
                                    : total == 0 && _syncJustCompleted
                                        ? _buildVacioPostSync(syncUpdated)
                                        : ListView(
                                            controller: scrollCtrl,
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 12, 16, 16),
                                            children: [
                                              if (pending.isNotEmpty) ...[
                                                _sectionTitle(
                                                  isSyncing
                                                      ? Icons.cloud_sync_rounded
                                                      : Icons.cloud_upload_outlined,
                                                  isSyncing
                                                      ? Colors.blue.shade700
                                                      : Colors.orange.shade700,
                                                  isSyncing
                                                      ? 'Enviando al ERP'
                                                      : 'Por enviar',
                                                  pending.length,
                                                ),
                                                const SizedBox(height: 8),
                                                ..._buildGroupedCards(pending,
                                                    isPermanent: false,
                                                    isSyncing: isSyncing),
                                                const SizedBox(height: 16),
                                              ],
                                              if (permFailed.isNotEmpty) ...[
                                                Row(children: [
                                                  _sectionTitle(
                                                    Icons.error_outline_rounded,
                                                    Colors.red.shade700,
                                                    'Fallo permanente',
                                                    permFailed.length,
                                                  ),
                                                  const Spacer(),
                                                  TextButton.icon(
                                                    onPressed: _clearAllPermanent,
                                                    icon: Icon(Icons.delete_sweep,
                                                        size: 14,
                                                        color: Colors.red.shade700),
                                                    label: Text('Limpiar',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.red.shade700)),
                                                  ),
                                                ]),
                                                Text(
                                                  'El ERP rechazó estos datos (error de validación). '
                                                  'Reintenta individualmente o elimínalos.',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade500),
                                                ),
                                                const SizedBox(height: 8),
                                                ..._buildGroupedCards(permFailed,
                                                    isPermanent: true,
                                                    isSyncing: false),
                                              ],
                                            ],
                                          ),
                              ),

                              // ── Botón sincronizar ─────────────────────────
                              if (pending.isNotEmpty)
                                _buildSyncButton(pending.length, isSyncing),
                              if (total == 0) const SizedBox(height: 16),
                            ],
                          ),

                          // ── Overlay translúcido mientras se sincroniza ────
                          if (isSyncing)
                            Positioned.fill(
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.0),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────

  Widget _buildHeader(int total, DateTime? lastSyncAt, bool isSyncing) {
    String? lastSyncLabel;
    if (lastSyncAt != null) {
      final now = DateTime.now();
      final diff = now.difference(lastSyncAt);
      if (diff.inMinutes < 1) {
        lastSyncLabel = 'Último envío confirmado: hace un momento';
      } else if (diff.inMinutes < 60) {
        lastSyncLabel = 'Último envío confirmado: hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        lastSyncLabel =
            'Último envío confirmado: ${DateFormat('HH:mm').format(lastSyncAt)}';
      } else {
        lastSyncLabel =
            'Último envío confirmado: ${DateFormat('dd/MM HH:mm').format(lastSyncAt)}';
      }
    }

    final IconData headerIcon;
    final Color headerColor;
    final String headerTitle;
    final String? headerSub;

    if (isSyncing) {
      headerIcon = Icons.cloud_sync_rounded;
      headerColor = Colors.blue.shade700;
      headerTitle = 'Enviando al ERP…';
      headerSub = 'Por favor espere';
    } else if (total > 0) {
      headerIcon = Icons.cloud_upload_outlined;
      headerColor = Colors.orange.shade700;
      headerTitle = 'Datos pendientes de enviar';
      headerSub = '$total operación(es) en cola';
    } else {
      headerIcon = Icons.inbox_outlined;
      headerColor = Colors.grey.shade600;
      headerTitle = 'Sin operaciones pendientes';
      headerSub = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Icon(headerIcon, color: headerColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (headerSub != null)
                  Text(
                    headerSub,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                if (lastSyncLabel != null && !isSyncing)
                  Text(
                    lastSyncLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Banner visible MIENTRAS el sync está en curso — reemplaza los mensajes
  /// prematuros de éxito que confundían al usuario.
  Widget _buildSyncingBanner(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Procesando $count operación(es) — comunicando con el ERP',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800),
                ),
                Text(
                  'No cierre la aplicación. El resultado aparecerá aquí automáticamente.',
                  style:
                      TextStyle(fontSize: 11, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner de resultado que solo aparece DESPUÉS de que el ERP respondió.
  Widget _buildResultadoBanner({
    required int pendingAfter,
    required int permFailedAfter,
    required SyncUpdated syncState,
  }) {
    final succeeded = syncState.lastSucceeded ?? 0;
    final failed = syncState.lastFailed ?? 0;
    final allOk = pendingAfter == 0 && permFailedAfter == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: allOk ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: allOk ? Colors.green.shade200 : Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allOk ? Icons.check_circle_rounded : Icons.warning_rounded,
            color:
                allOk ? Colors.green.shade700 : Colors.orange.shade700,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allOk
                      ? '$succeeded operación(es) confirmadas por el ERP.'
                      : succeeded > 0
                          ? '$succeeded confirmada(s) · $failed con error · revisa la lista.'
                          : '$failed operación(es) no pudieron enviarse al ERP.',
                  style: TextStyle(
                      fontSize: 13,
                      color: allOk
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w600),
                ),
                if (!allOk)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Los datos siguen guardados localmente y se reintentarán automáticamente.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange.shade700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacío inicial — NO dice "sincronizado" porque no sabemos si el ERP
  /// recibió algo; simplemente no hay nada pendiente en este momento.
  Widget _buildVacio() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Sin operaciones pendientes',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No hay datos en cola para enviar al ERP.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ),
      ]),
    );
  }

  /// Estado vacío DESPUÉS de un sync exitoso — este SÍ confirma que todo llegó.
  Widget _buildVacioPostSync(SyncUpdated? state) {
    final succeeded = state?.lastSucceeded ?? 0;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_done_rounded, size: 60, color: Colors.green.shade400),
        const SizedBox(height: 12),
        Text('Todo enviado al ERP',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700)),
        const SizedBox(height: 4),
        Text(
          succeeded > 0
              ? '$succeeded operación(es) confirmadas por el servidor.'
              : 'Todos los datos fueron aceptados por el ERP.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ]),
    );
  }

  Widget _buildSyncButton(int pendingCount, bool isSyncing) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ElevatedButton.icon(
          onPressed: isSyncing ? null : _sincronizar,
          icon: isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_upload_rounded),
          label: Text(isSyncing
              ? 'Sincronizando…'
              : 'Sincronizar todo ($pendingCount)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, Color color, String label, int count) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text('$label ($count)',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color)),
    ]);
  }

  List<Widget> _buildGroupedCards(List<OutboxEntry> entries,
      {required bool isPermanent, required bool isSyncing}) {
    final grouped = _agrupar(entries);
    return grouped.entries.map((group) {
      final registroId = group.key;
      final items = group.value;
      final fecha = items.isNotEmpty
          ? DateFormat('dd/MM HH:mm')
              .format(items.first.timestamp.toLocal())
          : '';
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del grupo
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Icon(Icons.assignment_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Registro: ${registroId.length > 12 ? '${registroId.substring(0, 8)}…' : registroId}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Text(fecha,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ]),
            ),
            const Divider(height: 1),
            // Operaciones del grupo
            ...items.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final isLast = idx == items.length - 1;
              final opColor = _operacionColor(entry.endpoint);
              final isSyncingEntry = entry.status == 'syncing';
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (isSyncingEntry
                                    ? Colors.blue.shade600
                                    : opColor)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: isSyncingEntry
                              ? SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue.shade600),
                                )
                              : Icon(
                                  _operacionIcon(entry.endpoint),
                                  size: 15,
                                  color: opColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _operacionLabel(entry.endpoint, entry.method),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _spName(entry.endpoint),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.2),
                              ),
                              if (entry.errorMessage != null &&
                                  entry.errorMessage!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildErrorBadge(entry.errorMessage!, entry),
                              ],
                            ],
                          ),
                        ),
                        // Badge de estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(entry.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(entry.status, entry.retryCount),
                            style: TextStyle(
                                fontSize: 10,
                                color: _statusColor(entry.status),
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        // Botones para fallos permanentes
                        if (isPermanent) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _retryEntry(entry.id),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.refresh_rounded,
                                  size: 18,
                                  color: Colors.blue.shade600),
                            ),
                          ),
                          InkWell(
                            onTap: () => _deleteEntry(entry.id),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: Colors.grey.shade100),
                ],
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  // ─── Error badge ─────────────────────────────────────────────────────────

  Widget _buildErrorBadge(String errorMsg, OutboxEntry entry) {
    final tipo = _clasificarError(errorMsg);
    final color = _errorTipoColor(tipo);
    final icon = _errorTipoIcon(tipo);
    final label = _errorTipoLabel(tipo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (entry.retryCount > 0)
              Text(
                '${entry.retryCount} intento(s)',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                errorMsg,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.85),
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _mostrarDetalleError(errorMsg, entry, tipo),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Ver más',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _mostrarDetalleError(
      String errorMsg, OutboxEntry entry, _ErrorTipo tipo) {
    final color = _errorTipoColor(tipo);
    final icon = _errorTipoIcon(tipo);
    final label = _errorTipoLabel(tipo);
    final sp = _spName(entry.endpoint);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w800)),
                  Text('Diagnóstico de error',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _detalleRow(Icons.code_rounded, 'Stored Procedure', sp,
                  Colors.blueGrey.shade700),
              const SizedBox(height: 10),
              _detalleRow(Icons.route_rounded, 'Endpoint',
                  '${entry.method} ${entry.endpoint}', Colors.grey.shade700),
              const SizedBox(height: 10),
              _detalleRow(
                Icons.replay_rounded,
                'Intentos realizados',
                '${entry.retryCount}',
                entry.retryCount >= 3
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
              ),
              const SizedBox(height: 10),
              if (entry.registroLocalId != null) ...[
                _detalleRow(Icons.fingerprint_rounded, 'Registro ID',
                    entry.registroLocalId!, Colors.grey.shade700),
                const SizedBox(height: 10),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 13, color: color),
                      const SizedBox(width: 6),
                      Text('Mensaje del error',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25)),
                    ),
                    child: SelectableText(
                      errorMsg,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        height: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sugerenciaError(tipo),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade800,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detalleRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade800,
                fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  String _sugerenciaError(_ErrorTipo tipo) {
    switch (tipo) {
      case _ErrorTipo.red:
        return 'Sin conexión a internet. Asegúrate de tener red y vuelve a sincronizar.';
      case _ErrorTipo.timeout:
        return 'El servidor tardó demasiado en responder. El dato PUEDE haber llegado al ERP. '
            'Verifica en la BD antes de reintentar para evitar duplicados.';
      case _ErrorTipo.sp:
        return 'El Stored Procedure rechazó los datos. Revisa el mensaje: puede ser un campo '
            'nulo, un constraint de BD, una tabla inexistente o un parámetro con formato incorrecto.';
      case _ErrorTipo.erp:
        return 'Error HTTP del servidor ERP. Puede ser autenticación (401/403), recurso no '
            'encontrado (404), o error interno del servidor (500). Revisa la conexión con el ERP.';
      case _ErrorTipo.bd:
        return 'Error de base de datos en el servidor. Puede ser un constraint UNIQUE, '
            'FOREIGN KEY o schema desactualizado. Consultar al DBA.';
      case _ErrorTipo.desconocido:
        return 'Error no clasificado. Revisa el mensaje completo y los logs del servidor ERP '
            'para determinar la causa raíz.';
    }
  }
}

// ─── Auxiliares ───────────────────────────────────────────────────────────────

class _OutboxData {
  final List<OutboxEntry> pending;
  final List<OutboxEntry> permFailed;
  final DateTime? lastSyncAt;
  const _OutboxData(
      {required this.pending,
      required this.permFailed,
      this.lastSyncAt});
}
