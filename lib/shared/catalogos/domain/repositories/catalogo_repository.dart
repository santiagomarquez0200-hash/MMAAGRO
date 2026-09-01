import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';

abstract class CatalogoRepository {
  // ── Catálogos PostgreSQL ──
  Future<Either<Failure, List<Proceso>>> getProcesos();
  Future<Either<Failure, List<CajaCambios>>> getCajasCambios();
  Future<Either<Failure, List<TipoParo>>> getTiposParos();
  Future<Either<Failure, List<ChecklistItem>>> getChecklistItems();

  // ── Catálogos ERP ──
  Future<Either<Failure, List<Cultivo>>> getCultivos();
  Future<Either<Failure, List<Tractor>>> getTractores();
  Future<Either<Failure, List<Implemento>>> getImplementos();
  Future<Either<Failure, List<Vehiculo>>> getVehiculos();
  Future<Either<Failure, List<Trabajador>>> getTrabajadores();
  Future<Either<Failure, List<Lote>>> getLotes({int? fincaIdErp});
  Future<Either<Failure, List<Sector>>> getSectoresConLotes();

  // ── Catálogos MMA v3 ──
  Future<Either<Failure, List<Subproceso>>> getSubprocesos({int? procesoId});

  /// Sincroniza todos los catálogos (ERP + PostgreSQL) a la BD local.
  Future<Either<Failure, void>> sincronizarCatalogos();

  /// Cuenta cuántos registros hay en ultimo_horometro_tractores_local.
  Future<int> countUltimoHorometroTractores();

  /// Catálogo de fallas mecánicas.
  Future<Either<Failure, List<FallaMecanica>>> getFallasMecanicas();

  /// Cuenta cuántos tipos de falla mecánica hay en local.
  Future<int> countFallasMecanicas();

  // ── Búsqueda por código escaneado (QR / barras) — offline-first ──
  Future<Either<Failure, Trabajador?>> buscarTrabajadorPorCodigo(String codigo);
  Future<Either<Failure, Tractor?>> buscarTractorPorCodigo(String codigo);
  Future<Either<Failure, Implemento?>> buscarImplementoPorCodigo(String codigo);
}
