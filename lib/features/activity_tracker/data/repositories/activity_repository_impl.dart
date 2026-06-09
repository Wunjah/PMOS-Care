import '../../../../core/network/network_info.dart';
import '../../domain/entities/activity_entity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_local_datasource.dart';
import '../datasources/activity_remote_datasource.dart';
import '../models/activity_model.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;
  final ActivityLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ActivityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<ActivityEntity>> getActivities() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteActivities = await remoteDataSource.getRemoteActivities();
        await localDataSource.cacheActivities(remoteActivities);
        return remoteActivities;
      } catch (_) {
        return await localDataSource.getCachedActivities();
      }
    } else {
      return await localDataSource.getCachedActivities();
    }
  }

  @override
  Future<void> saveActivity(ActivityEntity activity) async {
    final activityModel = ActivityModel.fromEntity(activity);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleActivity(activityModel, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteActivity(activityModel);
      } catch (_) {
        await localDataSource.cacheSingleActivity(activityModel, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteActivity(String activityLogId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedActivity(activityLogId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteActivity(activityLogId);
      } catch (_) {
        await localDataSource.removeCachedActivity(activityLogId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteActivity(id);
        await localDataSource.removeCachedActivity(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsyncedActivities = await localDataSource.getUnsyncedActivities();
    for (final model in unsyncedActivities) {
      try {
        await remoteDataSource.saveRemoteActivity(model);
        await localDataSource.cacheSingleActivity(model, needsSync: false);
      } catch (_) {}
    }
  }
}
