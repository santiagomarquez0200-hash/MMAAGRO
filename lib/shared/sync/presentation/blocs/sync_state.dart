import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncUpdated extends SyncState {
  final int pendingCount;
  final bool isSyncing;
  final int permanentlyFailedCount;

  /// Resultado de la última pasada de sync (null = no se ha sincronizado aún).
  final int? lastSucceeded;
  final int? lastFailed;

  const SyncUpdated({
    required this.pendingCount,
    this.isSyncing = false,
    this.permanentlyFailedCount = 0,
    this.lastSucceeded,
    this.lastFailed,
  });

  bool get hasPermFailed => permanentlyFailedCount > 0;

  @override
  List<Object?> get props => [
        pendingCount,
        isSyncing,
        permanentlyFailedCount,
        lastSucceeded,
        lastFailed,
      ];
}
