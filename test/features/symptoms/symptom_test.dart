import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/core/network/network_info.dart';
import 'package:pmos_care/features/symptoms/data/models/symptom_model.dart';
import 'package:pmos_care/features/symptoms/data/repositories/symptom_repository_impl.dart';
import 'package:pmos_care/features/symptoms/domain/entities/symptom_entity.dart';
import 'package:pmos_care/features/symptoms/presentation/providers/symptom_provider.dart';
import 'package:pmos_care/features/symptoms/data/datasources/symptom_local_datasource.dart';
import 'package:pmos_care/features/symptoms/data/datasources/symptom_remote_datasource.dart';
import 'package:pmos_care/features/symptoms/domain/usecases/get_symptoms_usecase.dart';
import 'package:pmos_care/features/symptoms/domain/usecases/save_symptom_usecase.dart';

class MockSymptomLocalDataSource implements SymptomLocalDataSource {
  List<SymptomModel> cached = [];
  List<SymptomModel> unsynced = [];
  List<String> pendingDeletes = [];

  @override
  Future<List<SymptomModel>> getCachedSymptoms() async => cached;

  @override
  Future<void> cacheSymptoms(List<SymptomModel> symptoms) async {
    cached = List.from(symptoms);
  }

  @override
  Future<void> cacheSingleSymptom(SymptomModel symptom, {required bool needsSync}) async {
    cached.removeWhere((e) => e.id == symptom.id);
    cached.add(symptom);
    if (needsSync) {
      unsynced.removeWhere((e) => e.id == symptom.id);
      unsynced.add(symptom);
    } else {
      unsynced.removeWhere((e) => e.id == symptom.id);
    }
  }

  @override
  Future<void> removeCachedSymptom(String symptomLogId, {required bool needsSyncDelete}) async {
    cached.removeWhere((e) => e.id == symptomLogId);
    unsynced.removeWhere((e) => e.id == symptomLogId);
    if (needsSyncDelete) {
      pendingDeletes.remove(symptomLogId);
      pendingDeletes.add(symptomLogId);
    } else {
      pendingDeletes.remove(symptomLogId);
    }
  }

  @override
  Future<List<String>> getPendingDeletes() async => List.from(pendingDeletes);

  @override
  Future<List<SymptomModel>> getUnsyncedSymptoms() async => List.from(unsynced);

  @override
  Future<void> clearCache() async {
    cached.clear();
    unsynced.clear();
    pendingDeletes.clear();
  }
}

class MockSymptomRemoteDataSource implements SymptomRemoteDataSource {
  List<SymptomModel> remote = [];
  bool throwError = false;

  @override
  Future<List<SymptomModel>> getRemoteSymptoms() async {
    if (throwError) throw Exception("Remote error");
    return remote;
  }

  @override
  Future<void> saveRemoteSymptom(SymptomModel symptom) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == symptom.id);
    remote.add(symptom);
  }

  @override
  Future<void> deleteRemoteSymptom(String symptomLogId) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == symptomLogId);
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
  late MockSymptomLocalDataSource localDataSource;
  late MockSymptomRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late SymptomRepositoryImpl repository;

  final sampleModel = SymptomModel(
    id: 'symptom-1',
    timestamp: DateTime(2026, 6, 1),
    ferrimanGallweyScore: 12,
    acneSeverity: 'moderate',
    alopeciaSeverity: 'none',
    fatigueLevel: 3,
    mood: 'anxious',
    cravings: ['sugar', 'chocolate'],
    bloating: true,
    pelvicPain: 4,
    acanthosisNigricans: true,
    skinTags: false,
    clientUpdatedTimestamp: DateTime(2026, 6, 1),
  );

  setUp(() {
    localDataSource = MockSymptomLocalDataSource();
    remoteDataSource = MockSymptomRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = SymptomRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
  });

  group('SymptomModel Unit Tests', () {
    test('should convert to and from JSON correctly', () {
      final json = sampleModel.toJson();
      final fromJson = SymptomModel.fromJson(json);
      expect(fromJson.id, equals(sampleModel.id));
      expect(fromJson.ferrimanGallweyScore, equals(sampleModel.ferrimanGallweyScore));
      expect(fromJson.acneSeverity, equals(sampleModel.acneSeverity));
      expect(fromJson.acanthosisNigricans, equals(sampleModel.acanthosisNigricans));
      expect(fromJson.skinTags, equals(sampleModel.skinTags));
    });

    test('should map from entity', () {
      final entity = SymptomEntity(
        id: 'entity-1',
        timestamp: DateTime(2026, 6, 2),
        acneSeverity: 'severe',
        alopeciaSeverity: 'mild',
        fatigueLevel: 4,
        mood: 'happy',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: true,
        clientUpdatedTimestamp: DateTime.now(),
      );
      final model = SymptomModel.fromEntity(entity);
      expect(model.id, equals(entity.id));
      expect(model.acneSeverity, equals(entity.acneSeverity));
      expect(model.skinTags, equals(entity.skinTags));
    });
  });

  group('SymptomRepositoryImpl Unit Tests', () {
    test('should get symptoms from remote and cache them when online', () async {
      networkInfo.isConnectedValue = true;
      remoteDataSource.remote = [sampleModel];

      final result = await repository.getSymptoms();

      expect(result.first.id, equals('symptom-1'));
      expect(localDataSource.cached.first.id, equals('symptom-1'));
    });

    test('should get symptoms from cache when offline', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      final result = await repository.getSymptoms();

      expect(result.first.id, equals('symptom-1'));
    });

    test('should cache and upload to remote on saveSymptom when online', () async {
      networkInfo.isConnectedValue = true;
      final entity = SymptomEntity(
        id: 'symptom-2',
        timestamp: DateTime(2026, 6, 3),
        acneSeverity: 'none',
        alopeciaSeverity: 'none',
        fatigueLevel: 1,
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime(2026, 6, 3),
      );

      await repository.saveSymptom(entity);

      expect(localDataSource.cached.any((e) => e.id == 'symptom-2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == 'symptom-2'), isTrue);
      expect(localDataSource.unsynced.any((e) => e.id == 'symptom-2'), isFalse);
    });
  });

  group('SymptomNotifier Unit Tests', () {
    late GetSymptomsUsecase getSymptomsUsecase;
    late SaveSymptomUsecase saveSymptomUsecase;

    setUp(() {
      getSymptomsUsecase = GetSymptomsUsecase(repository);
      saveSymptomUsecase = SaveSymptomUsecase(repository);
    });

    test('should load symptoms and update state with descending timestamp order', () async {
      networkInfo.isConnectedValue = false;
      final olderSymptom = SymptomModel(
        id: 'old',
        timestamp: DateTime(2026, 6, 1),
        acneSeverity: 'none',
        alopeciaSeverity: 'none',
        fatigueLevel: 2,
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime(2026, 6, 1),
      );
      final newerSymptom = SymptomModel(
        id: 'new',
        timestamp: DateTime(2026, 6, 5),
        acneSeverity: 'none',
        alopeciaSeverity: 'none',
        fatigueLevel: 2,
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime(2026, 6, 5),
      );
      localDataSource.cached = [olderSymptom, newerSymptom];

      final notifier = SymptomNotifier(
        getSymptoms: getSymptomsUsecase,
        saveSymptom: saveSymptomUsecase,
        repository: repository,
      );
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.symptoms.first.id, equals('new'));
      expect(notifier.state.symptoms.last.id, equals('old'));
    });

    test('should add symptom and reload state', () async {
      networkInfo.isConnectedValue = false;
      final notifier = SymptomNotifier(
        getSymptoms: getSymptomsUsecase,
        saveSymptom: saveSymptomUsecase,
        repository: repository,
      );
      await Future.delayed(Duration.zero);

      final newEntity = SymptomEntity(
        id: 'logged',
        timestamp: DateTime(2026, 6, 6),
        acneSeverity: 'mild',
        alopeciaSeverity: 'none',
        fatigueLevel: 2,
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      await notifier.addSymptomLog(newEntity);

      expect(notifier.state.symptoms.any((e) => e.id == 'logged'), isTrue);
    });

    test('should delete symptom and reload state', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = SymptomNotifier(
        getSymptoms: getSymptomsUsecase,
        saveSymptom: saveSymptomUsecase,
        repository: repository,
      );
      await Future.delayed(Duration.zero);

      await notifier.removeSymptomLog('symptom-1');

      expect(notifier.state.symptoms.isEmpty, isTrue);
    });
  });
}
