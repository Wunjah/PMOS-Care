import '../../../../core/network/network_info.dart';
import '../../domain/entities/cycle_entity.dart';
import '../../domain/repositories/cycle_repository.dart';
import '../datasources/cycle_local_datasource.dart';
import '../datasources/cycle_remote_datasource.dart';
import '../models/cycle_model.dart';

class CycleRepositoryImpl implements CycleRepository {
  final CycleRemoteDataSource remoteDataSource;
  final CycleLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CycleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<CycleEntity>> getCycles() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCycles = await remoteDataSource.getRemoteCycles();
        await localDataSource.cacheCycles(remoteCycles);
        return remoteCycles;
      } catch (_) {
        return await localDataSource.getCachedCycles();
      }
    } else {
      return await localDataSource.getCachedCycles();
    }
  }

  @override
  Future<void> saveCycle(CycleEntity cycle) async {
    final cycleModel = CycleModel.fromEntity(cycle);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleCycle(cycleModel, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteCycle(cycleModel);
      } catch (_) {
        await localDataSource.cacheSingleCycle(cycleModel, needsSync: true);
      }
    }
  }

  @override
  Future<void> updateCycle(CycleEntity cycle) async {
    final cycleModel = CycleModel.fromEntity(cycle);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleCycle(cycleModel, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.updateRemoteCycle(cycleModel);
      } catch (_) {
        await localDataSource.cacheSingleCycle(cycleModel, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedCycle(cycleId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteCycle(cycleId);
      } catch (_) {
        await localDataSource.removeCachedCycle(cycleId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteCycle(id);
        await localDataSource.removeCachedCycle(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsyncedCycles = await localDataSource.getUnsyncedCycles();
    for (final model in unsyncedCycles) {
      try {
        await remoteDataSource.saveRemoteCycle(model);
        await localDataSource.cacheSingleCycle(model, needsSync: false);
      } catch (_) {}
    }
  }
}
