import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';

abstract class CatalogoState extends Equatable {
  const CatalogoState();
  @override
  List<Object?> get props => [];
}

/// Un ítem de catálogo dentro del flujo de sincronización detallada.
/// [count] == null → todavía cargando; int → finalizado (nuevos registros).
class CatalogoSyncItem {
  final String label;
  final String clave;
  final int? count;
  final bool hasError;

  const CatalogoSyncItem({
    required this.label,
    required this.clave,
    this.count,
    this.hasError = false,
  });

  CatalogoSyncItem copyWith({int? count, bool? hasError}) => CatalogoSyncItem(
        label: label,
        clave: clave,
        count: count ?? this.count,
        hasError: hasError ?? this.hasError,
      );

  @override
  bool operator ==(Object other) =>
      other is CatalogoSyncItem &&
      other.label == label &&
      other.count == count &&
      other.hasError == hasError;

  @override
  int get hashCode => Object.hash(label, count, hasError);
}

/// Sincronización detallada en curso — muestra spinners por ítem.
class CatalogoSyncEnProgreso extends CatalogoState {
  final List<CatalogoSyncItem> items;
  const CatalogoSyncEnProgreso({required this.items});
  @override
  List<Object?> get props => [items];
}

/// Sincronización detallada completada — cada ítem tiene su delta de registros.
class CatalogoSyncFinalizado extends CatalogoState {
  final List<CatalogoSyncItem> items;
  final bool hasErrors;
  const CatalogoSyncFinalizado({required this.items, this.hasErrors = false});
  @override
  List<Object?> get props => [items, hasErrors];
}

class CatalogoInitial extends CatalogoState {
  const CatalogoInitial();
}

class CatalogoLoading extends CatalogoState {
  const CatalogoLoading();
}

class CatalogoLoaded extends CatalogoState {
  final List<Proceso> procesos;
  final List<Cultivo> cultivos;
  final List<Tractor> tractores;
  final List<Implemento> implementos;
  final List<Vehiculo> vehiculos;
  final List<Trabajador> trabajadores;
  final List<Sector> sectores;
  final List<CajaCambios> cajasCambios;
  final List<TipoParo> tiposParo;
  final List<ChecklistItem> checklistItems;
  final List<Subproceso> subprocesos;
  final List<FallaMecanica> fallasMecanicas;

  const CatalogoLoaded({
    required this.procesos,
    required this.cultivos,
    required this.tractores,
    required this.implementos,
    this.vehiculos = const [],
    required this.trabajadores,
    required this.sectores,
    required this.cajasCambios,
    required this.tiposParo,
    required this.checklistItems,
    this.subprocesos = const [],
    this.fallasMecanicas = const [],
  });

  @override
  List<Object?> get props => [
        procesos,
        cultivos,
        tractores,
        implementos,
        vehiculos,
        trabajadores,
        sectores,
        cajasCambios,
        tiposParo,
        checklistItems,
        subprocesos,
        fallasMecanicas,
      ];
}

class CatalogoError extends CatalogoState {
  final String message;
  const CatalogoError({required this.message});
  @override
  List<Object?> get props => [message];
}
