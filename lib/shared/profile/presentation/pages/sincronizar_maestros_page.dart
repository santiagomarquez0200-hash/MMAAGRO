import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_bloc.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_event.dart';
import 'package:agro_aplicaciones/shared/catalogos/presentation/blocs/catalogo_state.dart';

class SincronizarMaestrosPage extends StatefulWidget {
  const SincronizarMaestrosPage({super.key});

  @override
  State<SincronizarMaestrosPage> createState() =>
      _SincronizarMaestrosPageState();
}

class _SincronizarMaestrosPageState extends State<SincronizarMaestrosPage>
    with SingleTickerProviderStateMixin {
  // Ítems revelados progresivamente al finalizar sync
  final List<CatalogoSyncItem> _revealed = [];
  List<CatalogoSyncItem> _finalItems = [];
  bool _syncDone = false;
  bool _hasError = false;

  // Animación de la barra de progreso en el encabezado
  late final AnimationController _barCtrl;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);

    // Lanzar sync al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CatalogoBloc>()
          .add(const CatalogoSyncMaestrosRequested());
    });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  void _handleFinalizado(CatalogoSyncFinalizado state) {
    if (_syncDone) return;
    _syncDone = true;
    _hasError = state.hasErrors;
    // Guardar copia de los ítems para que el rebuild posterior (CatalogoLoading→Loaded)
    // no borre la lista mientras se revelan progresivamente.
    _finalItems = List.of(state.items);

    // Parar la animación indeterminada de la barra
    _barCtrl.stop();

    // Revelar ítems uno a uno con retardo escalonado
    for (int i = 0; i < _finalItems.length; i++) {
      Future.delayed(Duration(milliseconds: 180 * (i + 1)), () {
        if (!mounted) return;
        setState(() => _revealed.add(_finalItems[i]));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatalogoBloc, CatalogoState>(
      listener: (context, state) {
        if (state is CatalogoSyncFinalizado) {
          _handleFinalizado(state);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D241C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D241C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Sincronizar Maestros',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: BlocBuilder<CatalogoBloc, CatalogoState>(
          builder: (context, state) {
            // Si ya finalizó, ignorar estados posteriores (Loading/Loaded)
            // para no reemplazar la lista de ítems ya revelados.
            final isLoading = !_syncDone && state is CatalogoSyncEnProgreso;
            final isDone = _syncDone;

            return Column(
              children: [
                // ── Tarjeta de encabezado ───────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: _HeaderCard(
                    isLoading: isLoading,
                    hasError: isDone && _hasError,
                    barAnim: _barAnim,
                    allDone: isDone,
                    revealedCount: _revealed.length,
                    totalCount: isDone
                        ? _finalItems.length
                        : (state is CatalogoSyncEnProgreso)
                            ? state.items.length
                            : 0,
                  ),
                ),

                // ── Lista de ítems ──────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152E22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Builder(builder: (_) {
                      // Si ya finalizó usamos la copia cacheada; de lo contrario
                      // leemos del estado actual del BLoC.
                      final List<CatalogoSyncItem> items;
                      if (_syncDone) {
                        items = _finalItems;
                      } else if (state is CatalogoSyncEnProgreso) {
                        items = state.items;
                      } else if (state is CatalogoSyncFinalizado) {
                        items = state.items;
                      } else {
                        items = const [];
                      }

                      if (items.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF8CC53F)),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 60,
                          endIndent: 20,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          // ¿ya fue revelado?
                          final revealed = _revealed.any(
                              (r) => r.clave == item.clave);
                          final revealedItem = revealed
                              ? _revealed
                                  .firstWhere((r) => r.clave == item.clave)
                              : null;

                          return _SyncItemTile(
                            item: item,
                            isLoading: !revealed,
                            revealedCount: revealedItem?.count,
                            hasError: revealedItem?.hasError ?? false,
                            index: i,
                          );
                        },
                      );
                    }),
                  ),
                ),

                // ── Botón Continuar ─────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _syncDone
                      ? Padding(
                          key: const ValueKey('btn'),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.check_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'CONTINUAR',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8CC53F),
                                elevation: 4,
                                shadowColor:
                                    const Color(0xFF8CC53F).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty'), height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Tarjeta de encabezado con barra de progreso ─────────────────────────────

class _HeaderCard extends StatelessWidget {
  final bool isLoading;
  final bool allDone;
  final bool hasError;
  final Animation<double> barAnim;
  final int revealedCount;
  final int totalCount;

  const _HeaderCard({
    required this.isLoading,
    required this.allDone,
    required this.hasError,
    required this.barAnim,
    required this.revealedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalCount == 0 ? 0.0 : revealedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF152E22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? Colors.red.shade400.withValues(alpha: 0.4)
              : const Color(0xFF8CC53F).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícono animado
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? Colors.red.shade900.withValues(alpha: 0.3)
                  : const Color(0xFF8CC53F).withValues(alpha: 0.15),
            ),
            child: allDone
                ? Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.sync_rounded,
                    color: hasError
                        ? Colors.red.shade400
                        : const Color(0xFF8CC53F),
                    size: 26,
                  )
                : const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF8CC53F),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone
                      ? (hasError
                          ? 'Sync con errores'
                          : 'Sincronización completada')
                      : 'Sincronizando...',
                  style: TextStyle(
                    color: hasError ? Colors.red.shade300 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: allDone
                      ? LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            hasError
                                ? Colors.red.shade400
                                : const Color(0xFF8CC53F),
                          ),
                          minHeight: 6,
                        )
                      : AnimatedBuilder(
                          animation: barAnim,
                          builder: (_, __) => const LinearProgressIndicator(
                            value: null, // indeterminado
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF8CC53F),
                            ),
                            minHeight: 6,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  allDone
                      ? '${(progress * 100).toInt()}%'
                      : 'Descargando datos del servidor...',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile de ítem individual ──────────────────────────────────────────────────

class _SyncItemTile extends StatelessWidget {
  final CatalogoSyncItem item;
  final bool isLoading;
  final int? revealedCount;
  final bool hasError;
  final int index;

  const _SyncItemTile({
    required this.item,
    required this.isLoading,
    required this.revealedCount,
    required this.hasError,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: ListTile(
        key: ValueKey('$isLoading$revealedCount'),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLoading
                ? Colors.white10
                : hasError
                    ? Colors.red.shade900.withValues(alpha: 0.25)
                    : const Color(0xFF8CC53F).withValues(alpha: 0.15),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white38),
                )
              : Icon(
                  hasError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  color: hasError
                      ? Colors.red.shade400
                      : const Color(0xFF8CC53F),
                  size: 20,
                ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isLoading ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: isLoading
            ? null
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasError
                      ? Colors.red.shade900.withValues(alpha: 0.2)
                      : const Color(0xFF8CC53F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasError
                        ? Colors.red.shade700.withValues(alpha: 0.4)
                        : const Color(0xFF8CC53F).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '(${revealedCount ?? 0})',
                  style: TextStyle(
                    color: hasError
                        ? Colors.red.shade400
                        : const Color(0xFF8CC53F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
      ),
    );
  }
}
