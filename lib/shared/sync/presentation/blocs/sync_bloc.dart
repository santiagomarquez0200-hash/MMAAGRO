import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';
import 'package:agro_aplicaciones/infrastructure/services/sync_manager.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final RegistroRepository _registroRepository;
  final SyncManager _syncManager;

  SyncBloc({
    required RegistroRepository registroRepository,
    required SyncManager syncManager,
  })  : _registroRepository = registroRepository,
        _syncManager = syncManager,
        super(const SyncInitial()) {
    on<SyncWatchRequested>(_onWatch);
    on<SyncManualRequested>(_onManualSync);
  }

  Future<void> _onWatch(
      SyncWatchRequested event, Emitter<SyncState> emit) async {
    await emit.forEach(
      _registroRepository.watchPendientesSincronizacion(),
      onData: (count) => SyncUpdated(pendingCount: count),
      onError: (_, __) => const SyncUpdated(pendingCount: 0),
    );
  }

  Future<void> _onManualSync(
      SyncManualRequested event, Emitter<SyncState> emit) async {
    final current = state;
    if (current is SyncUpdated) {
      emit(SyncUpdated(
        pendingCount: current.pendingCount,
        isSyncing: true,
        permanentlyFailedCount: current.permanentlyFailedCount,
      ));
    } else {
      // Estado inicial o desconocido — emitir isSyncing para que el indicador
      // muestre el spinner aunque aún no se haya recibido el primer conteo.
      emit(const SyncUpdated(pendingCount: 0, isSyncing: true));
    }

    final syncResult = await _syncManager.processOutbox();

    if (syncResult.succeeded > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_sync_at', DateTime.now().toIso8601String());
    }

    final pendingResult =
        await _registroRepository.getPendientesSincronizacion();
    final pendingCount = pendingResult.fold((_) => 0, (c) => c);

    emit(SyncUpdated(
      pendingCount: pendingCount,
      isSyncing: false,
      permanentlyFailedCount: syncResult.permanentlyFailed,
      lastSucceeded: syncResult.succeeded,
      lastFailed: syncResult.failed,
    ));
  }
}
