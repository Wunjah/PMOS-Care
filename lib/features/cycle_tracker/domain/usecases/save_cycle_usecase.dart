import '../entities/cycle_entity.dart';
import '../repositories/cycle_repository.dart';

class SaveCycleUsecase {
  final CycleRepository repository;

  SaveCycleUsecase(this.repository);

  Future<void> execute(CycleEntity cycle) async {
    if (cycle.endDate != null && cycle.endDate!.isBefore(cycle.startDate)) {
      throw Exception('End date cannot occur before the cycle start date.');
    }
    return await repository.saveCycle(cycle);
  }
}
