import '../../../../core/network/network_info.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/repositories/meal_log_repository.dart';
import '../datasources/meal_log_local_datasource.dart';
import '../datasources/meal_log_remote_datasource.dart';
import '../models/meal_log_model.dart';

class MealLogRepositoryImpl implements MealLogRepository {
  final MealLogRemoteDataSource remoteDataSource;
  final MealLogLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MealLogRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<MealLogEntity>> getMealLogs() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLogs = await remoteDataSource.getRemoteMealLogs();
        await localDataSource.cacheMealLogs(remoteLogs);
        return remoteLogs;
      } catch (_) {
        return await localDataSource.getCachedMealLogs();
      }
    } else {
      return await localDataSource.getCachedMealLogs();
    }
  }

  @override
  Future<void> saveMealLog(MealLogEntity log) async {
    final model = MealLogModel.fromEntity(log);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleMealLog(model, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteMealLog(model);
      } catch (_) {
        await localDataSource.cacheSingleMealLog(model, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteMealLog(String logId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedMealLog(logId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteMealLog(logId);
      } catch (_) {
        await localDataSource.removeCachedMealLog(logId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteMealLog(id);
        await localDataSource.removeCachedMealLog(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsyncedLogs = await localDataSource.getUnsyncedMealLogs();
    for (final model in unsyncedLogs) {
      try {
        await remoteDataSource.saveRemoteMealLog(model);
        await localDataSource.cacheSingleMealLog(model, needsSync: false);
      } catch (_) {}
    }
  }
}
