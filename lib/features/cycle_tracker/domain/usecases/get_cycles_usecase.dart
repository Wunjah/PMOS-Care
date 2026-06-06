import '../entities/cycle_entity.dart';
import '../repositories/cycle_repository.dart';

class GetCyclesUsecase {
  final CycleRepository repository;

  GetCyclesUsecase(this.repository);

  Future<List<CycleEntity>> execute() async {
    return await repository.getCycles();
  }
}
