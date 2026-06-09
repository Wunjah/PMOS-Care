import '../entities/weight_entity.dart';

abstract class WeightRepository {
  Future<List<WeightEntity>> getWeights();
  Future<void> saveWeight(WeightEntity weight);
  Future<void> deleteWeight(String weightLogId);
  Future<void> syncOfflineData();
}
