import '../entities/cycle_entity.dart';

abstract class CycleRepository {
  Future<List<CycleEntity>> getCycles();
  Future<void> saveCycle(CycleEntity cycle);
  Future<void> updateCycle(CycleEntity cycle);
  Future<void> deleteCycle(String cycleId);
  Future<void> syncOfflineData();
}
