import '../entities/meal_log_entity.dart';

abstract class MealLogRepository {
  Future<List<MealLogEntity>> getMealLogs();
  Future<void> saveMealLog(MealLogEntity log);
  Future<void> deleteMealLog(String logId);
  Future<void> syncOfflineData();
}
