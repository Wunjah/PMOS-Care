import '../../../../core/network/network_info.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_local_datasource.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;
  final AppointmentLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AppointmentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<AppointmentEntity>> getAppointments() async {
    if (await networkInfo.isConnected) {
      try {
        final remote = await remoteDataSource.getRemoteAppointments();
        await localDataSource.cacheAppointments(remote);
        return remote;
      } catch (_) {
        return await localDataSource.getCachedAppointments();
      }
    } else {
      return await localDataSource.getCachedAppointments();
    }
  }

  @override
  Future<void> saveAppointment(AppointmentEntity appointment) async {
    final model = AppointmentModel.fromEntity(appointment);
    final isConnected = await networkInfo.isConnected;

    await localDataSource.cacheSingleAppointment(model, needsSync: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.saveRemoteAppointment(model);
      } catch (_) {
        await localDataSource.cacheSingleAppointment(model, needsSync: true);
      }
    }
  }

  @override
  Future<void> deleteAppointment(String appointmentId) async {
    final isConnected = await networkInfo.isConnected;
    await localDataSource.removeCachedAppointment(appointmentId, needsSyncDelete: !isConnected);

    if (isConnected) {
      try {
        await remoteDataSource.deleteRemoteAppointment(appointmentId);
      } catch (_) {
        await localDataSource.removeCachedAppointment(appointmentId, needsSyncDelete: true);
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (!(await networkInfo.isConnected)) return;

    final pendingDeletes = await localDataSource.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remoteDataSource.deleteRemoteAppointment(id);
        await localDataSource.removeCachedAppointment(id, needsSyncDelete: false);
      } catch (_) {}
    }

    final unsynced = await localDataSource.getUnsyncedAppointments();
    for (final model in unsynced) {
      try {
        await remoteDataSource.saveRemoteAppointment(model);
        await localDataSource.cacheSingleAppointment(model, needsSync: false);
      } catch (_) {}
    }
  }
}
