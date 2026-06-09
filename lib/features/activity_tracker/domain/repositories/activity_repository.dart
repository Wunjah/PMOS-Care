import '../entities/activity_entity.dart';

abstract class ActivityRepository {
  Future<List<ActivityEntity>> getActivities();
  Future<void> saveActivity(ActivityEntity activity);
  Future<void> deleteActivity(String activityLogId);
  Future<void> syncOfflineData();
}
