import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_bloc.dart';
import 'package:agro_aplicaciones/shared/sync/presentation/blocs/sync_state.dart';
import 'package:agro_aplicaciones/shared/widgets/sync_detail_dialog.dart';

/// Ícono de nube en el AppBar que refleja el estado del outbox en tiempo real.
/// Al pulsarlo abre [showSyncDetailDialog] con el detalle de operaciones pendientes.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final pending = state is SyncUpdated ? state.pendingCount : 0;
        final isSyncing = state is SyncUpdated && state.isSyncing;
        final permFailed =
            state is SyncUpdated ? state.permanentlyFailedCount : 0;
        final hasAlert = permFailed > 0;

        return InkWell(
          onTap: () => showSyncDetailDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSyncing
                      ? Icons.cloud_sync_rounded
                      : hasAlert
                          ? Icons.cloud_off_outlined
                          : pending > 0
                              ? Icons.cloud_upload_outlined
                              : Icons.cloud_done_outlined,
                  color: hasAlert ? Colors.red.shade300 : Colors.white,
                ),
                if (pending > 0 || hasAlert)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasAlert
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        hasAlert ? '!' : '$pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
