import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/core/network/network_info.dart';
import 'package:pmos_care/features/medication/data/models/medication_model.dart';
import 'package:pmos_care/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:pmos_care/features/medication/domain/entities/medication_entity.dart';
import 'package:pmos_care/features/medication/presentation/providers/medication_provider.dart';
import 'package:pmos_care/features/medication/data/datasources/medication_local_datasource.dart';
import 'package:pmos_care/features/medication/data/datasources/medication_remote_datasource.dart';

class MockMedicationLocalDataSource implements MedicationLocalDataSource {
  List<MedicationModel> cached = [];
  List<MedicationModel> unsynced = [];
  List<String> pendingDeletes = [];

  @override
  Future<List<MedicationModel>> getCachedMedications() async => cached;

  @override
  Future<void> cacheMedications(List<MedicationModel> medications) async {
    cached = List.from(medications);
  }

  @override
  Future<void> cacheSingleMedication(MedicationModel medication, {required bool needsSync}) async {
    cached.removeWhere((e) => e.id == medication.id);
    cached.add(medication);
    if (needsSync) {
      unsynced.removeWhere((e) => e.id == medication.id);
      unsynced.add(medication);
    } else {
      unsynced.removeWhere((e) => e.id == medication.id);
    }
  }

  @override
  Future<void> removeCachedMedication(String medicationId, {required bool needsSyncDelete}) async {
    cached.removeWhere((e) => e.id == medicationId);
    unsynced.removeWhere((e) => e.id == medicationId);
    if (needsSyncDelete) {
      pendingDeletes.remove(medicationId);
      pendingDeletes.add(medicationId);
    } else {
      pendingDeletes.remove(medicationId);
    }
  }

  @override
  Future<List<String>> getPendingDeletes() async => List.from(pendingDeletes);

  @override
  Future<List<MedicationModel>> getUnsyncedMedications() async => List.from(unsynced);

  @override
  Future<void> clearCache() async {
    cached.clear();
    unsynced.clear();
    pendingDeletes.clear();
  }
}

class MockMedicationRemoteDataSource implements MedicationRemoteDataSource {
  List<MedicationModel> remote = [];
  bool throwError = false;

  @override
  Future<List<MedicationModel>> getRemoteMedications() async {
    if (throwError) throw Exception("Remote error");
    return remote;
  }

  @override
  Future<void> saveRemoteMedication(MedicationModel medication) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == medication.id);
    remote.add(medication);
  }

  @override
  Future<void> deleteRemoteMedication(String medicationId) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == medicationId);
  }
}

class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;

  @override
  Stream<NetworkStatus> get networkStatusStream =>
      Stream.value(isConnectedValue ? NetworkStatus.online : NetworkStatus.offline);
}

void main() {
  late MockMedicationLocalDataSource localDataSource;
  late MockMedicationRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late MedicationRepositoryImpl repository;

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final sampleModel = MedicationModel(
    id: 'med-1',
    name: 'Metformin',
    dosage: '500mg',
    timing: 'breakfast',
    isTakenToday: true,
    lastTakenDate: DateTime.now(),
    clientUpdatedTimestamp: DateTime.now(),
  );

  setUp(() {
    localDataSource = MockMedicationLocalDataSource();
    remoteDataSource = MockMedicationRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = MedicationRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
  });

  group('MedicationModel Unit Tests', () {
    test('should convert to and from JSON correctly', () {
      final json = sampleModel.toJson();
      final fromJson = MedicationModel.fromJson(json);
      expect(fromJson.id, equals(sampleModel.id));
      expect(fromJson.name, equals(sampleModel.name));
      expect(fromJson.dosage, equals(sampleModel.dosage));
      expect(fromJson.isTakenToday, equals(sampleModel.isTakenToday));
    });

    test('should map from entity', () {
      final entity = MedicationEntity(
        id: 'entity-1',
        name: 'Inositol',
        dosage: '2000mg',
        timing: 'supper',
        isTakenToday: false,
        lastTakenDate: yesterday,
        clientUpdatedTimestamp: DateTime.now(),
      );
      final model = MedicationModel.fromEntity(entity);
      expect(model.id, equals(entity.id));
      expect(model.name, equals(entity.name));
      expect(model.dosage, equals(entity.dosage));
      expect(model.isTakenToday, equals(entity.isTakenToday));
    });
  });

  group('MedicationRepositoryImpl Unit Tests', () {
    test('should get medications from remote and cache them when online', () async {
      networkInfo.isConnectedValue = true;
      remoteDataSource.remote = [sampleModel];

      final result = await repository.getMedications();

      expect(result.first.id, equals('med-1'));
      expect(localDataSource.cached.first.id, equals('med-1'));
    });

    test('should get medications from cache when offline', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      final result = await repository.getMedications();

      expect(result.first.id, equals('med-1'));
    });

    test('should cache and upload to remote on saveMedication when online', () async {
      networkInfo.isConnectedValue = true;
      final entity = MedicationEntity(
        id: 'med-2',
        name: 'Spironolactone',
        dosage: '100mg',
        timing: 'lunch',
        isTakenToday: false,
        lastTakenDate: yesterday,
        clientUpdatedTimestamp: DateTime.now(),
      );

      await repository.saveMedication(entity);

      expect(localDataSource.cached.any((e) => e.id == 'med-2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == 'med-2'), isTrue);
      expect(localDataSource.unsynced.any((e) => e.id == 'med-2'), isFalse);
    });

    test('should delete from remote and local when online on deleteMedication', () async {
      networkInfo.isConnectedValue = true;
      localDataSource.cached = [sampleModel];
      remoteDataSource.remote = [sampleModel];

      await repository.deleteMedication('med-1');

      expect(localDataSource.cached.isEmpty, isTrue);
      expect(remoteDataSource.remote.isEmpty, isTrue);
    });
  });

  group('MedicationNotifier Unit Tests', () {
    test('should load medications and update state', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = MedicationNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.medications.first.id, equals('med-1'));
    });

    test('should auto-reset isTakenToday to false if date has changed', () async {
      networkInfo.isConnectedValue = false;
      
      // Let's create a medication logged as taken yesterday
      final takenYesterdayModel = MedicationModel(
        id: 'med-taken-yesterday',
        name: 'Metformin',
        dosage: '500mg',
        timing: 'breakfast',
        isTakenToday: true, // marked taken
        lastTakenDate: yesterday, // but last taken yesterday
        clientUpdatedTimestamp: yesterday,
      );
      localDataSource.cached = [takenYesterdayModel];

      final notifier = MedicationNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      // Verify that after loading, isTakenToday was reset to false
      expect(notifier.state.medications.first.isTakenToday, isFalse);
      // Verify that the updated medication was saved back to repository
      expect(localDataSource.cached.first.isTakenToday, isFalse);
    });

    test('should add medication and reload', () async {
      networkInfo.isConnectedValue = false;
      final notifier = MedicationNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      await notifier.addMedication(name: 'Inositol', dosage: '2000mg', timing: 'lunch');

      expect(notifier.state.medications.any((e) => e.name == 'Inositol'), isTrue);
    });

    test('should toggle taken status and update lastTakenDate', () async {
      networkInfo.isConnectedValue = false;
      final model = MedicationModel(
        id: 'med-toggle',
        name: 'Metformin',
        dosage: '500mg',
        timing: 'breakfast',
        isTakenToday: false,
        lastTakenDate: yesterday,
        clientUpdatedTimestamp: yesterday,
      );
      localDataSource.cached = [model];
      
      final notifier = MedicationNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      // Toggle taken to true
      await notifier.toggleTaken('med-toggle', true);

      expect(notifier.state.medications.first.isTakenToday, isTrue);
      // expect lastTakenDate to be close to now (same day/hour)
      expect(notifier.state.medications.first.lastTakenDate.day, equals(DateTime.now().day));
    });

    test('should remove medication and reload', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = MedicationNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      await notifier.removeMedication('med-1');

      expect(notifier.state.medications.isEmpty, isTrue);
    });
  });
}
