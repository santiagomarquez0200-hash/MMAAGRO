import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/repositories/catalogo_repository.dart';

class ObtenerProcesosUseCase implements UseCase<List<Proceso>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerProcesosUseCase(this._repository);

  @override
  Future<Either<Failure, List<Proceso>>> call(NoParams params) =>
      _repository.getProcesos();
}

class ObtenerCultivosUseCase implements UseCase<List<Cultivo>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerCultivosUseCase(this._repository);

  @override
  Future<Either<Failure, List<Cultivo>>> call(NoParams params) =>
      _repository.getCultivos();
}

class ObtenerTractoresUseCase implements UseCase<List<Tractor>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerTractoresUseCase(this._repository);

  @override
  Future<Either<Failure, List<Tractor>>> call(NoParams params) =>
      _repository.getTractores();
}

class ObtenerImplementosUseCase implements UseCase<List<Implemento>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerImplementosUseCase(this._repository);

  @override
  Future<Either<Failure, List<Implemento>>> call(NoParams params) =>
      _repository.getImplementos();
}

class ObtenerTrabajadoresUseCase
    implements UseCase<List<Trabajador>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerTrabajadoresUseCase(this._repository);

  @override
  Future<Either<Failure, List<Trabajador>>> call(NoParams params) =>
      _repository.getTrabajadores();
}

class ObtenerSectoresUseCase implements UseCase<List<Sector>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerSectoresUseCase(this._repository);

  @override
  Future<Either<Failure, List<Sector>>> call(NoParams params) =>
      _repository.getSectoresConLotes();
}

class ObtenerChecklistItemsUseCase
    implements UseCase<List<ChecklistItem>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerChecklistItemsUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChecklistItem>>> call(NoParams params) =>
      _repository.getChecklistItems();
}

class ObtenerCajasCambiosUseCase implements UseCase<List<CajaCambios>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerCajasCambiosUseCase(this._repository);

  @override
  Future<Either<Failure, List<CajaCambios>>> call(NoParams params) =>
      _repository.getCajasCambios();
}

class ObtenerTiposParoUseCase implements UseCase<List<TipoParo>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerTiposParoUseCase(this._repository);

  @override
  Future<Either<Failure, List<TipoParo>>> call(NoParams params) =>
      _repository.getTiposParos();
}

class SincronizarCatalogosUseCase implements UseCase<void, NoParams> {
  final CatalogoRepository _repository;
  const SincronizarCatalogosUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.sincronizarCatalogos();
}

class ObtenerSubprocesosUseCase implements UseCase<List<Subproceso>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerSubprocesosUseCase(this._repository);

  @override
  Future<Either<Failure, List<Subproceso>>> call(NoParams params) =>
      _repository.getSubprocesos();
}

class ObtenerVehiculosUseCase implements UseCase<List<Vehiculo>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerVehiculosUseCase(this._repository);

  @override
  Future<Either<Failure, List<Vehiculo>>> call(NoParams params) =>
      _repository.getVehiculos();
}

class ContarHorometroTractoresUseCase implements UseCase<int, NoParams> {
  final CatalogoRepository _repository;
  const ContarHorometroTractoresUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    try {
      return Right(await _repository.countUltimoHorometroTractores());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

class ObtenerFallasMecanicasUseCase
    implements UseCase<List<FallaMecanica>, NoParams> {
  final CatalogoRepository _repository;
  const ObtenerFallasMecanicasUseCase(this._repository);

  @override
  Future<Either<Failure, List<FallaMecanica>>> call(NoParams params) =>
      _repository.getFallasMecanicas();
}

class ContarFallasMecanicasUseCase implements UseCase<int, NoParams> {
  final CatalogoRepository _repository;
  const ContarFallasMecanicasUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    try {
      return Right(await _repository.countFallasMecanicas());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

