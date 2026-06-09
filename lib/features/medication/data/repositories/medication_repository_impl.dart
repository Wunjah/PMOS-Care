import '../../../../core/network/network_info.dart';
import '../../domain/entities/medication_entity.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_datasource.dart';
import '../datasources/medication_remote_datasource.dart';
import '../models/medication_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationRemoteDataSource remoteDataSource;
  final MedicationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MedicationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<MedicationEntity>> getMedications() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMeds = await remoteDataSource.getRemoteMedications();
        await localDataSource.cacheMedications(remoteMeds);
        return remoteMeds;
      } catch (_) {
        return await localDataSource.getCachedMedications();
      }
    } else {
      return await localDataSource.getCachedMedications();
    }
  }

  @override
  Future<void> saveMedication(MedicationEntity medication) async {
    final model = MedicationModel.fromEntity(medication);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleMedication(model, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteMedication(model);
      } catch (_) {
        await localDataSource.cacheSingleMedication(model, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteMedication(String medicationId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedMedication(medicationId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteMedication(medicationId);
      } catch (_) {
        await localDataSource.removeCachedMedication(medicationId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteMedication(id);
        await localDataSource.removeCachedMedication(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsyncedMeds = await localDataSource.getUnsyncedMedications();
    for (final model in unsyncedMeds) {
      try {
        await remoteDataSource.saveRemoteMedication(model);
        await localDataSource.cacheSingleMedication(model, needsSync: false);
      } catch (_) {}
    }
  }
}
