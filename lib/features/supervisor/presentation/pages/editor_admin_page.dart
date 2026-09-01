import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/injection_container.dart';

class EditorAdminPage extends StatefulWidget {
  final String registroId;
  final RegistroDiario? registro;

  const EditorAdminPage({
    super.key,
    required this.registroId,
    this.registro,
  });

  @override
  State<EditorAdminPage> createState() => _EditorAdminPageState();
}

class _EditorAdminPageState extends State<EditorAdminPage> {
  static const _kGreen = Color(0xFF1B5E20);
  static const _kGreenLight = Color(0xFF2E7D32);
  static const _kBg = Color(0xFFF4F6F9);

  bool _cargando = true;
  String? _errorInit;
  bool _syncing = false;

  /// Copia local del registro — se actualiza cuando una sub-página guarda cambios.
  /// Evita que los subtítulos de las secciones queden desactualizados.
  RegistroDiario? _registroLocal;

  /// Secciones que el supervisor modificó en esta sesión de edición.
  final Set<String> _seccionesEditadas = {};

  /// Mensaje real retornado por el SP tras la última sincronización exitosa.
  String? _mensajeUltimaSync;

  /// Timestamp de la última sincronización exitosa.
  DateTime? _ultimaSincronizacion;

  bool get _hayPendientes => _seccionesEditadas.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _registroLocal = widget.registro;
    _initLocalData();
  }

  Future<void> _initLocalData() async {
    final r = widget.registro;
    if (r == null) {
      setState(() => _cargando = false);
      return;
    }
    final result = await sl<RegistroRepository>().upsertRegistroFromRemote(r);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _cargando = false;
        _errorInit = failure.message;
      }),
      (_) => setState(() => _cargando = false),
    );
  }

  /// Recarga el registro desde SQLite local para refrescar los subtítulos de
  /// secciones después de que una sub-página guarda cambios.
  Future<void> _reloadRegistroLocal() async {
    final result = await sl<RegistroRepository>().getRegistro(widget.registroId);
    if (!mounted) return;
    result.fold(
      (_) => null, // En error mantener los datos actuales
      (r) => setState(() => _registroLocal = r),
    );
  }

  Future<void> _resync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final result =
        await sl<RegistroRepository>().resyncAdminEdit(widget.registroId);
    if (!mounted) return;
    setState(() => _syncing = false);
    result.fold(
      (f) => _mostrarErrorSync(f.message),
      (mensaje) => _mostrarExitoSync(mensaje),
    );
  }

  void _mostrarErrorSync(String errorMsg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMsg,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ));
  }

  void _mostrarExitoSync(String mensajeSP) {
    final ahora = DateTime.now();
    setState(() {
      _seccionesEditadas.clear();
      _mensajeUltimaSync = mensajeSP.isNotEmpty ? mensajeSP : 'Registro sincronizado correctamente.';
      _ultimaSincronizacion = ahora;
    });
    _mostrarDialogSyncExito(mensajeSP, ahora);
  }

  void _mostrarDialogSyncExito(String mensajeSP, DateTime cuando) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        // Usa el ancho disponible del diálogo respetando márgenes laterales.
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.zero,
          // scrollable evita overflow en pantallas pequeñas
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header verde ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_done_rounded,
                        color: Colors.white, size: 36),
                    SizedBox(height: 6),
                    Text(
                      'Sincronización exitosa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Mensaje del SP ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogRow(
                      Icons.message_outlined,
                      'Respuesta del servidor',
                      mensajeSP.isNotEmpty
                          ? mensajeSP
                          : 'Registro procesado correctamente.',
                    ),
                    const SizedBox(height: 10),
                    _dialogRow(
                      Icons.schedule_rounded,
                      'Sincronizado a las',
                      DateFormat('HH:mm:ss · dd/MM/yyyy').format(cuando),
                    ),
                  ],
                ),
              ),
              // ── Botón cerrar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Aceptar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _kGreenLight),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label:\n',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigatePage(String route,
      {Object? extra, required String seccion}) async {
    final huboC = await context.push<bool>(route, extra: extra);
    if (!mounted) return;
    if (huboC == true) {
      setState(() => _seccionesEditadas.add(seccion));
      // Recargar datos locales para refrescar subtítulos de secciones.
      _reloadRegistroLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar _registroLocal (se actualiza al volver de sub-páginas) para que
    // los subtítulos reflejen los datos más recientes guardados en SQLite.
    final r = _registroLocal;
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: Text(
          r != null ? 'Editar Registro ${r.numeroRegistro}' : 'Editar Registro',
          // r ya apunta a _registroLocal que se actualiza dinámicamente
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: _hayPendientes ? Colors.white : Colors.white38,
                  ),
                  if (_hayPendientes)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: _hayPendientes
                  ? 'Sincronizar ${_seccionesEditadas.length} sección(es) modificada(s)'
                  : 'Sin cambios pendientes',
              onPressed: _hayPendientes ? _resync : null,
            ),
        ],
      ),
      body: _cargando
          ? _buildLoading()
          : _errorInit != null
              ? _buildError()
              : _buildContent(r, fmt),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kGreen),
          SizedBox(height: 16),
          Text('Cargando datos del registro...',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Error al cargar datos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorInit ?? '',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _errorInit = null;
                });
                _initLocalData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RegistroDiario? r, DateFormat fmt) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (r != null) _buildInfoCard(r, fmt),
        if (r != null) const SizedBox(height: 12),

        // ── Banner de cambios pendientes ───────────────────────────────────
        if (_hayPendientes) ...[
          _buildPendientesBanner(),
          const SizedBox(height: 12),
        ],

        // ── Banner de última sincronización ───────────────────────────────
        if (_ultimaSincronizacion != null && !_hayPendientes) ...[
          _buildUltimaSyncBanner(),
          const SizedBox(height: 12),
        ],

        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Selecciona la sección que deseas editar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
        ),

        _SectionTile(
          icon: Icons.assignment_outlined,
          color: const Color(0xFF1565C0),
          title: 'Datos del Registro',
          subtitle: r != null
              ? '${r.procesoCodigo} · ${r.tractorCodigo} · ${fmt.format(r.fecha)}'
              : 'Proceso, tractor, horómetros de inicio',
          badge: r != null ? _estadoBadge(r.estado) : null,
          editada: _seccionesEditadas.contains('datos'),
          onTap: () => _navigatePage(
            '/registro/${widget.registroId}/editar?admin=true',
            extra: r,
            seccion: 'datos',
          ),
        ),
        const SizedBox(height: 10),

        _SectionTile(
          icon: Icons.checklist_rounded,
          color: const Color(0xFF2E7D32),
          title: 'Checklist',
          subtitle: r != null
              ? r.checklist.isEmpty
                  ? 'Sin ítems registrados'
                  : '${r.checklist.length} ítems · ${r.checklist.where((c) => c.esBien).length} bien · ${r.checklist.where((c) => c.esMal).length} mal'
              : 'Revisión de tractor e implemento',
          editada: _seccionesEditadas.contains('checklist'),
          onTap: () => _navigatePage(
            '/registro/${widget.registroId}/checklist?admin=true',
            extra: r,
            seccion: 'checklist',
          ),
        ),
        const SizedBox(height: 10),

        _SectionTile(
          icon: Icons.timer_off_outlined,
          color: const Color(0xFFB71C1C),
          title: 'Paros',
          subtitle: r != null
              ? r.paros.isEmpty
                  ? 'Sin paros registrados'
                  : '${r.paros.length} paro(s) · ${r.totalMinParos} min total'
              : 'Paros de tractor o equipo',
          editada: _seccionesEditadas.contains('paros'),
          onTap: () => _navigatePage(
            '/registro/${widget.registroId}/paros?admin=true',
            extra: r,
            seccion: 'paros',
          ),
        ),
        const SizedBox(height: 10),

        _SectionTile(
          icon: Icons.lock_clock_outlined,
          color: const Color(0xFF6A1B9A),
          title: 'Cierre de Turno',
          subtitle: r != null
              ? _subtitleCierre(r)
              : 'Horómetros finales, horas de regreso, lotes',
          editada: _seccionesEditadas.contains('cierre'),
          onTap: () => _navigatePage(
            '/registro/${widget.registroId}/cerrar?admin=true',
            seccion: 'cierre',
          ),
        ),

        const SizedBox(height: 20),
        _buildSyncButton(),
        if (_hayPendientes) ...[
          const SizedBox(height: 10),
          _buildDescartarButton(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDescartarButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmarDescartar,
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Descartar cambios'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _confirmarDescartar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF57F17), size: 22),
            SizedBox(width: 8),
            Text('Descartar cambios',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Se revertirán todas las ediciones y el registro quedará como estaba antes de editar.\n\nNo aparecerá nada pendiente de sincronizar. ¿Deseas continuar?',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    // Restaurar en SQLite el estado original del servidor (widget.registro)
    // para que ningún campo editado quede como "pendiente por enviar".
    final original = widget.registro;
    if (original != null) {
      setState(() => _syncing = true); // reusar el indicador de carga del AppBar
      final result =
          await sl<RegistroRepository>().upsertRegistroFromRemote(original);
      if (!mounted) return;
      setState(() => _syncing = false);
      result.fold(
        (f) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al revertir: ${f.message}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ));
          return; // No limpiar marcadores si falló la reversión
        },
        (_) {
          // Reversión exitosa: limpiar marcadores y refrescar vista
          setState(() {
            _seccionesEditadas.clear();
            _registroLocal = original; // subtítulos vuelven al estado original
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cambios revertidos — registro restaurado'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        },
      );
    }
  }

  Widget _buildPendientesBanner() {
    final secciones = _seccionesEditadas.map(_nombreSeccion).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded,
              color: Color(0xFFF57F17), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cambios sin sincronizar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D3A00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secciones,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7D5700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimaSyncBanner() {
    final horaFmt =
        DateFormat('HH:mm:ss · dd/MM/yyyy').format(_ultimaSincronizacion!);
    final msgSP = _mensajeUltimaSync;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.cloud_done_rounded,
                color: Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sincronizado con el servidor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 2),
                if (msgSP != null && msgSP.isNotEmpty)
                  Text(
                    msgSP,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                Text(
                  horaFmt,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF33691E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    final canSync = _hayPendientes && !_syncing;
    final label = _syncing
        ? 'Sincronizando...'
        : _hayPendientes
            ? 'Sincronizar ${_seccionesEditadas.length} cambio(s)'
            : 'Sin cambios pendientes';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSync ? _resync : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hayPendientes ? _kGreen : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_syncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(
                Icons.cloud_upload_rounded,
                size: 18,
                color: _hayPendientes ? Colors.white : Colors.white54,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _hayPendientes ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(RegistroDiario r, DateFormat fmt) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1.2),
      ),
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Resumen del registro',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _estadoBadge(r.estado),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.person_outline, 'Operador', r.operadorNombre),
            _infoRow(Icons.agriculture_outlined, 'Tractor', r.tractorCodigo),
            _infoRow(Icons.work_outline, 'Proceso', r.procesoNombre),
            _infoRow(Icons.calendar_today_outlined, 'Fecha',
                '${fmt.format(r.fecha)} · ${r.turno}'),
            if (r.supervisorNombre?.isNotEmpty == true)
              _infoRow(Icons.supervisor_account_outlined, 'Supervisor',
                  r.supervisorNombre!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    Color bg;
    Color fg;
    String label;
    switch (estado) {
      case 'aprobado':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Aprobado';
        break;
      case 'completado':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        label = 'Completado';
        break;
      case 'rechazado':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'Rechazado';
        break;
      default:
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF92400E);
        label = 'Borrador';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  String _subtitleCierre(RegistroDiario r) {
    final h = r.horometro;
    final tt = r.tiempoTurno;
    if (h?.tractorFinal != null && tt?.horaLlegadaTaller != null) {
      return 'Horóm. final: ${h!.tractorFinal} · Llegada: ${tt!.horaLlegadaTaller}';
    }
    if (h?.tractorFinal != null) {
      return 'Horómetro final: ${h!.tractorFinal}';
    }
    return 'Horómetros finales, horas de regreso, lotes';
  }

  String _nombreSeccion(String key) {
    switch (key) {
      case 'datos':
        return 'Datos del registro';
      case 'checklist':
        return 'Checklist';
      case 'paros':
        return 'Paros';
      case 'cierre':
        return 'Cierre de turno';
      default:
        return key;
    }
  }
}

// ─── Tile de sección ──────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? badge;
  final bool editada;
  final VoidCallback onTap;

  const _SectionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.editada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: editada
                  ? const Color(0xFFFFCC02)
                  : Colors.grey.shade200,
              width: editada ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap evita overflow cuando title + badge + chip
                    // no caben en una línea en pantallas pequeñas.
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A202C))),
                        if (badge != null) badge!,
                        // Indicador amarillo de "modificado"
                        if (editada)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFFFCC02), width: 1),
                            ),
                            child: const Text(
                              'Modificado',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
