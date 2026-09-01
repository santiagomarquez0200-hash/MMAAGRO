import 'package:equatable/equatable.dart';

abstract class CatalogoEvent extends Equatable {
  const CatalogoEvent();
  @override
  List<Object?> get props => [];
}

class CatalogoLoadRequested extends CatalogoEvent {
  const CatalogoLoadRequested();
}

class CatalogoSyncRequested extends CatalogoEvent {
  const CatalogoSyncRequested();
}

/// Sincronización detallada (usada por SincronizarMaestrosPage).
class CatalogoSyncMaestrosRequested extends CatalogoEvent {
  const CatalogoSyncMaestrosRequested();
}
