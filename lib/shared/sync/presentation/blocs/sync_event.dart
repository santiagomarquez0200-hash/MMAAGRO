import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncWatchRequested extends SyncEvent {
  const SyncWatchRequested();
}

class SyncManualRequested extends SyncEvent {
  const SyncManualRequested();
}
