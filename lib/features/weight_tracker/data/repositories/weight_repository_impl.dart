import '../../../../core/network/network_info.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/weight_local_datasource.dart';
import '../datasources/weight_remote_datasource.dart';
import '../models/weight_model.dart';

class WeightRepositoryImpl implements WeightRepository {
  final WeightRemoteDataSource remoteDataSource;
  final WeightLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  WeightRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<WeightEntity>> getWeights() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteWeights = await remoteDataSource.getRemoteWeights();
        await localDataSource.cacheWeights(remoteWeights);
        return remoteWeights;
      } catch (_) {
        return await localDataSource.getCachedWeights();
      }
    } else {
      return await localDataSource.getCachedWeights();
    }
  }

  @override
  Future<void> saveWeight(WeightEntity weight) async {
    final weightModel = WeightModel.fromEntity(weight);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleWeight(weightModel, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteWeight(weightModel);
      } catch (_) {
        await localDataSource.cacheSingleWeight(weightModel, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteWeight(String weightLogId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedWeight(weightLogId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteWeight(weightLogId);
      } catch (_) {
        await localDataSource.removeCachedWeight(weightLogId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteWeight(id);
        await localDataSource.removeCachedWeight(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsyncedWeights = await localDataSource.getUnsyncedWeights();
    for (final model in unsyncedWeights) {
      try {
        await remoteDataSource.saveRemoteWeight(model);
        await localDataSource.cacheSingleWeight(model, needsSync: false);
      } catch (_) {}
    }
  }
}
