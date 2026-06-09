import '../../../../core/network/network_info.dart';
import '../../domain/entities/symptom_entity.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../datasources/symptom_local_datasource.dart';
import '../datasources/symptom_remote_datasource.dart';
import '../models/symptom_model.dart';

class SymptomRepositoryImpl implements SymptomRepository {
  final SymptomRemoteDataSource remoteDataSource;
  final SymptomLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SymptomRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<SymptomEntity>> getSymptoms() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSymptoms = await remoteDataSource.getRemoteSymptoms();
        await localDataSource.cacheSymptoms(remoteSymptoms);
        return remoteSymptoms;
      } catch (_) {
        return await localDataSource.getCachedSymptoms();
      }
    } else {
      return await localDataSource.getCachedSymptoms();
    }
  }

  @override
  Future<void> saveSymptom(SymptomEntity symptom) async {
    final symptomModel = SymptomModel.fromEntity(symptom);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleSymptom(symptomModel, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteSymptom(symptomModel);
      } catch (_) {
        await localDataSource.cacheSingleSymptom(symptomModel, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteSymptom(String symptomLogId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedSymptom(symptomLogId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteSymptom(symptomLogId);
      } catch (_) {
        await localDataSource.removeCachedSymptom(symptomLogId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteSymptom(id);
        await localDataSource.removeCachedSymptom(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsyncedSymptoms = await localDataSource.getUnsyncedSymptoms();
    for (final model in unsyncedSymptoms) {
      try {
        await remoteDataSource.saveRemoteSymptom(model);
        await localDataSource.cacheSingleSymptom(model, needsSync: false);
      } catch (_) {}
    }
  }
}
