import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/usecases/obtener_catalogos_usecase.dart';
import 'catalogo_event.dart';
import 'catalogo_state.dart';

const _tag = 'CatalogoBloc';

class CatalogoBloc extends Bloc<CatalogoEvent, CatalogoState> {
  final ObtenerProcesosUseCase _getProcesos;
  final ObtenerCultivosUseCase _getCultivos;
  final ObtenerTractoresUseCase _getTractores;
  final ObtenerImplementosUseCase _getImplementos;
  final ObtenerVehiculosUseCase _getVehiculos;
  final ObtenerTrabajadoresUseCase _getTrabajadores;
  final ObtenerSectoresUseCase _getSectores;
  final ObtenerCajasCambiosUseCase _getCajasCambios;
  final ObtenerTiposParoUseCase _getTiposParo;
  final ObtenerChecklistItemsUseCase _getChecklistItems;
  final SincronizarCatalogosUseCase _syncCatalogos;
  final ObtenerSubprocesosUseCase _getSubprocesos;
  final ContarHorometroTractoresUseCase _contarHorometros;
  final ObtenerFallasMecanicasUseCase _getFallasMecanicas;
  final ContarFallasMecanicasUseCase _contarFallasMecanicas;

  CatalogoBloc({
    required ObtenerProcesosUseCase getProcesos,
    required ObtenerCultivosUseCase getCultivos,
    required ObtenerTractoresUseCase getTractores,
    required ObtenerImplementosUseCase getImplementos,
    required ObtenerVehiculosUseCase getVehiculos,
    required ObtenerTrabajadoresUseCase getTrabajadores,
    required ObtenerSectoresUseCase getSectores,
    required ObtenerCajasCambiosUseCase getCajasCambios,
    required ObtenerTiposParoUseCase getTiposParo,
    required ObtenerChecklistItemsUseCase getChecklistItems,
    required SincronizarCatalogosUseCase syncCatalogos,
    required ObtenerSubprocesosUseCase getSubprocesos,
    required ContarHorometroTractoresUseCase contarHorometros,
    required ObtenerFallasMecanicasUseCase getFallasMecanicas,
    required ContarFallasMecanicasUseCase contarFallasMecanicas,
  })  : _getProcesos = getProcesos,
        _getCultivos = getCultivos,
        _getTractores = getTractores,
        _getImplementos = getImplementos,
        _getVehiculos = getVehiculos,
        _getTrabajadores = getTrabajadores,
        _getSectores = getSectores,
        _getCajasCambios = getCajasCambios,
        _getTiposParo = getTiposParo,
        _getChecklistItems = getChecklistItems,
        _syncCatalogos = syncCatalogos,
        _getSubprocesos = getSubprocesos,
        _contarHorometros = contarHorometros,
        _getFallasMecanicas = getFallasMecanicas,
        _contarFallasMecanicas = contarFallasMecanicas,
        super(const CatalogoInitial()) {
    on<CatalogoLoadRequested>(_onLoad);
    on<CatalogoSyncRequested>(_onSync);
    on<CatalogoSyncMaestrosRequested>(_onSyncMaestros);
  }

  Future<void> _onLoad(
      CatalogoLoadRequested event, Emitter<CatalogoState> emit) async {
    developer.log('leyendo catalogos desde SQLite...', name: _tag);
    emit(const CatalogoLoading());
    try {
      final results = await Future.wait([
        _getProcesos(const NoParams()),
        _getCultivos(const NoParams()),
        _getTractores(const NoParams()),
        _getImplementos(const NoParams()),
        _getVehiculos(const NoParams()),
        _getTrabajadores(const NoParams()),
        _getSectores(const NoParams()),
        _getCajasCambios(const NoParams()),
        _getTiposParo(const NoParams()),
        _getChecklistItems(const NoParams()),
        _getSubprocesos(const NoParams()),
        _getFallasMecanicas(const NoParams()),
      ]);

      final List<Proceso>        procesos        = results[0].fold((_) => [], (v) => v as List<Proceso>);
      final List<Cultivo>        cultivos        = results[1].fold((_) => [], (v) => v as List<Cultivo>);
      final List<Tractor>        tractores       = results[2].fold((_) => [], (v) => v as List<Tractor>);
      final List<Implemento>     implementos     = results[3].fold((_) => [], (v) => v as List<Implemento>);
      final List<Vehiculo>       vehiculos       = results[4].fold((_) => [], (v) => v as List<Vehiculo>);
      final List<Trabajador>     trabajadores    = results[5].fold((_) => [], (v) => v as List<Trabajador>);
      final List<Sector>         sectores        = results[6].fold((_) => [], (v) => v as List<Sector>);
      final List<CajaCambios>    cajasCambios    = results[7].fold((_) => [], (v) => v as List<CajaCambios>);
      final List<TipoParo>       tiposParo       = results[8].fold((_) => [], (v) => v as List<TipoParo>);
      final List<ChecklistItem>  checklistItems  = results[9].fold((_) => [], (v) => v as List<ChecklistItem>);
      final List<Subproceso>     subprocesos     = results[10].fold((_) => [], (v) => v as List<Subproceso>);
      final List<FallaMecanica>  fallasMecanicas = results[11].fold((_) => [], (v) => v as List<FallaMecanica>);

      developer.log(
        'SQLite cargado:\n'
        '  procesos=${procesos.length}  cultivos=${cultivos.length}  '
        'tractores=${tractores.length}  implementos=${implementos.length}\n'
        '  trabajadores=${trabajadores.length}  sectores=${sectores.length}  '
        'cajasCambios=${cajasCambios.length}  tiposParo=${tiposParo.length}  '
        'checklist=${checklistItems.length}',
        name: _tag,
      );

      if ((trabajadores as List).isEmpty) {
        developer.log(
          'trabajadores = 0, el login va a fallar hasta que se sincronicen los catalogos',
          name: _tag,
        );
      }

      emit(CatalogoLoaded(
        procesos:        (procesos        as List).cast(),
        cultivos:        (cultivos        as List).cast(),
        tractores:       (tractores       as List).cast(),
        implementos:     (implementos     as List).cast(),
        vehiculos:       (vehiculos       as List).cast(),
        trabajadores:    (trabajadores    as List).cast(),
        sectores:        (sectores        as List).cast(),
        cajasCambios:    (cajasCambios    as List).cast(),
        tiposParo:       (tiposParo       as List).cast(),
        checklistItems:  (checklistItems  as List).cast(),
        subprocesos:     (subprocesos     as List).cast(),
        fallasMecanicas: (fallasMecanicas as List).cast(),
      ));
    } catch (e) {
      developer.log('error cargando catalogos: $e', name: _tag, error: e);
      emit(CatalogoError(message: e.toString()));
    }
  }

  Future<void> _onSync(
      CatalogoSyncRequested event, Emitter<CatalogoState> emit) async {
    developer.log('iniciando sync de catalogos desde ERP...', name: _tag);
    emit(const CatalogoLoading());
    final result = await _syncCatalogos(const NoParams());
    result.fold(
      (failure) {
        developer.log('sync fallido: ${failure.message}', name: _tag);
        emit(CatalogoError(message: failure.message));
      },
      (_) {
        developer.log('sync exitoso, recargando desde SQLite', name: _tag);
        add(const CatalogoLoadRequested());
      },
    );
  }

  // Versión detallada del sync que calcula cuántos registros nuevos llegaron.
  // Si el ERP no cambió nada, el delta es 0 — no significa que falló.

  static const _syncItems = [
    CatalogoSyncItem(label: 'Cultivos',          clave: 'cultivos'),
    CatalogoSyncItem(label: 'Tractores',         clave: 'tractores'),
    CatalogoSyncItem(label: 'Implementos',       clave: 'implementos'),
    CatalogoSyncItem(label: 'Vehículos',         clave: 'vehiculos'),
    CatalogoSyncItem(label: 'Trabajadores',      clave: 'trabajadores'),
    CatalogoSyncItem(label: 'Lotes / Sectores',  clave: 'lotes'),
    CatalogoSyncItem(label: 'Procesos',          clave: 'procesos'),
    CatalogoSyncItem(label: 'Cajas de cambios',  clave: 'cajas_cambios'),
    CatalogoSyncItem(label: 'Tipos de paro',     clave: 'tipos_paro'),
    CatalogoSyncItem(label: 'Checklist',         clave: 'checklist'),
    CatalogoSyncItem(label: 'Subprocesos',       clave: 'subprocesos'),
    CatalogoSyncItem(label: 'Últ. Horómetros',  clave: 'horometro_tractores'),
    CatalogoSyncItem(label: 'Fallas Mecánicas', clave: 'fallas_mecanicas'),
  ];

  Future<void> _onSyncMaestros(
      CatalogoSyncMaestrosRequested event, Emitter<CatalogoState> emit) async {
    developer.log('sync maestros detallado iniciado', name: _tag);

    final before = await _leerCuentas();
    developer.log('conteos antes del sync: $before', name: _tag);

    emit(const CatalogoSyncEnProgreso(items: _syncItems));

    final result = await _syncCatalogos(const NoParams());

    if (result.isLeft()) {
      final msg = result.fold((f) => f.message, (_) => 'Error desconocido');
      developer.log('sync maestros fallido: $msg', name: _tag);
      final errorItems = _syncItems
          .map((i) => i.copyWith(count: 0, hasError: true))
          .toList();
      emit(CatalogoSyncFinalizado(items: errorItems, hasErrors: true));
      return;
    }

    final after = await _leerCuentas();
    developer.log('conteos despues del sync: $after', name: _tag);

    // El delta muestra registros nuevos. Si es 0, el dato ya estaba actualizado.
    final doneItems = _syncItems.map((i) {
      final delta = (after[i.clave] ?? 0) - (before[i.clave] ?? 0);
      return i.copyWith(count: delta < 0 ? 0 : delta);
    }).toList();

    emit(CatalogoSyncFinalizado(items: doneItems));
    developer.log('sync finalizado, deltas: '
        '${doneItems.map((i) => "${i.clave}:${i.count}").join(", ")}',
        name: _tag);

    // Recarga los catalogs en memoria para que el resto de la app los tenga frescos.
    add(const CatalogoLoadRequested());
  }

  Future<Map<String, int>> _leerCuentas() async {
    final results = await Future.wait([
      _getCultivos(const NoParams()),
      _getTractores(const NoParams()),
      _getImplementos(const NoParams()),
      _getVehiculos(const NoParams()),
      _getTrabajadores(const NoParams()),
      _getSectores(const NoParams()),
      _getProcesos(const NoParams()),
      _getCajasCambios(const NoParams()),
      _getTiposParo(const NoParams()),
      _getChecklistItems(const NoParams()),
      _getSubprocesos(const NoParams()),
      _contarHorometros(const NoParams()),
      _contarFallasMecanicas(const NoParams()),
    ]);
    return {
      'cultivos':             results[0].fold((_) => 0, (v) => (v as List).length),
      'tractores':            results[1].fold((_) => 0, (v) => (v as List).length),
      'implementos':          results[2].fold((_) => 0, (v) => (v as List).length),
      'vehiculos':            results[3].fold((_) => 0, (v) => (v as List).length),
      'trabajadores':         results[4].fold((_) => 0, (v) => (v as List).length),
      'lotes':                results[5].fold((_) => 0, (v) => (v as List).length),
      'procesos':             results[6].fold((_) => 0, (v) => (v as List).length),
      'cajas_cambios':        results[7].fold((_) => 0, (v) => (v as List).length),
      'tipos_paro':           results[8].fold((_) => 0, (v) => (v as List).length),
      'checklist':            results[9].fold((_) => 0, (v) => (v as List).length),
      'subprocesos':          results[10].fold((_) => 0, (v) => (v as List).length),
      'horometro_tractores':  results[11].fold((_) => 0, (v) => v as int),
      'fallas_mecanicas':     results[12].fold((_) => 0, (v) => v as int),
    };
  }
}
