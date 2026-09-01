import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/usecases/usecase.dart';
import 'package:agro_aplicaciones/features/operador/domain/repositories/registro_repository.dart';

class GuardarChecklistUseCase implements UseCase<void, GuardarChecklistParams> {
  final RegistroRepository _repository;
  const GuardarChecklistUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(GuardarChecklistParams params) {
    return _repository.guardarChecklist(params.registroId, params.resultados);
  }
}

class GuardarChecklistParams extends Equatable {
  final String registroId;
  final List<ChecklistResultadoInput> resultados;

  const GuardarChecklistParams({
    required this.registroId,
    required this.resultados,
  });

  @override
  List<Object?> get props => [registroId];
}
