import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/core/network/network_info.dart';
import 'package:pmos_care/features/diet/data/models/meal_log_model.dart';
import 'package:pmos_care/features/diet/data/repositories/meal_log_repository_impl.dart';
import 'package:pmos_care/features/diet/domain/entities/meal_log_entity.dart';
import 'package:pmos_care/features/diet/presentation/providers/diet_provider.dart';
import 'package:pmos_care/features/diet/data/datasources/meal_log_local_datasource.dart';
import 'package:pmos_care/features/diet/data/datasources/meal_log_remote_datasource.dart';

class MockMealLogLocalDataSource implements MealLogLocalDataSource {
  List<MealLogModel> cached = [];
  List<MealLogModel> unsynced = [];
  List<String> pendingDeletes = [];

  @override
  Future<List<MealLogModel>> getCachedMealLogs() async => cached;

  @override
  Future<void> cacheMealLogs(List<MealLogModel> logs) async {
    cached = List.from(logs);
  }

  @override
  Future<void> cacheSingleMealLog(MealLogModel log, {required bool needsSync}) async {
    cached.removeWhere((e) => e.id == log.id);
    cached.add(log);
    if (needsSync) {
      unsynced.removeWhere((e) => e.id == log.id);
      unsynced.add(log);
    } else {
      unsynced.removeWhere((e) => e.id == log.id);
    }
  }

  @override
  Future<void> removeCachedMealLog(String logId, {required bool needsSyncDelete}) async {
    cached.removeWhere((e) => e.id == logId);
    unsynced.removeWhere((e) => e.id == logId);
    if (needsSyncDelete) {
      pendingDeletes.remove(logId);
      pendingDeletes.add(logId);
    } else {
      pendingDeletes.remove(logId);
    }
  }

  @override
  Future<List<String>> getPendingDeletes() async => List.from(pendingDeletes);

  @override
  Future<List<MealLogModel>> getUnsyncedMealLogs() async => List.from(unsynced);

  @override
  Future<void> clearCache() async {
    cached.clear();
    unsynced.clear();
    pendingDeletes.clear();
  }
}

class MockMealLogRemoteDataSource implements MealLogRemoteDataSource {
  List<MealLogModel> remote = [];
  bool throwError = false;

  @override
  Future<List<MealLogModel>> getRemoteMealLogs() async {
    if (throwError) throw Exception("Remote error");
    return remote;
  }

  @override
  Future<void> saveRemoteMealLog(MealLogModel log) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == log.id);
    remote.add(log);
  }

  @override
  Future<void> deleteRemoteMealLog(String logId) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == logId);
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
  late MockMealLogLocalDataSource localDataSource;
  late MockMealLogRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late MealLogRepositoryImpl repository;

  final sampleModel = MealLogModel(
    id: 'meal-1',
    timestamp: DateTime(2026, 6, 1),
    mealType: 'breakfast',
    foodName: 'Cassava Fufu',
    calories: 300,
    proteinGrams: 2.0,
    fiberGrams: 4.0,
    waterMl: 0,
    clientUpdatedTimestamp: DateTime(2026, 6, 1),
  );

  setUp(() {
    localDataSource = MockMealLogLocalDataSource();
    remoteDataSource = MockMealLogRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = MealLogRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
  });

  group('MealLogModel Unit Tests', () {
    test('should convert to and from JSON correctly', () {
      final json = sampleModel.toJson();
      final fromJson = MealLogModel.fromJson(json);
      expect(fromJson.id, equals(sampleModel.id));
      expect(fromJson.foodName, equals(sampleModel.foodName));
      expect(fromJson.calories, equals(sampleModel.calories));
      expect(fromJson.proteinGrams, equals(sampleModel.proteinGrams));
      expect(fromJson.fiberGrams, equals(sampleModel.fiberGrams));
    });

    test('should map from entity', () {
      final entity = MealLogEntity(
        id: 'entity-1',
        timestamp: DateTime(2026, 6, 2),
        mealType: 'dinner',
        foodName: 'Ndole with Plantains',
        calories: 450,
        proteinGrams: 15.0,
        fiberGrams: 8.0,
        waterMl: 250,
        clientUpdatedTimestamp: DateTime(2026, 6, 2),
      );
      final model = MealLogModel.fromEntity(entity);
      expect(model.id, equals(entity.id));
      expect(model.foodName, equals(entity.foodName));
      expect(model.calories, equals(entity.calories));
      expect(model.proteinGrams, equals(entity.proteinGrams));
      expect(model.fiberGrams, equals(entity.fiberGrams));
      expect(model.waterMl, equals(entity.waterMl));
    });
  });

  group('MealLogRepositoryImpl Unit Tests', () {
    test('should get meal logs from remote and cache them when online', () async {
      networkInfo.isConnectedValue = true;
      remoteDataSource.remote = [sampleModel];

      final result = await repository.getMealLogs();

      expect(result.first.id, equals('meal-1'));
      expect(localDataSource.cached.first.id, equals('meal-1'));
    });

    test('should get meal logs from cache when offline', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      final result = await repository.getMealLogs();

      expect(result.first.id, equals('meal-1'));
    });

    test('should cache and upload to remote on saveMealLog when online', () async {
      networkInfo.isConnectedValue = true;
      final entity = MealLogEntity(
        id: 'meal-2',
        timestamp: DateTime(2026, 6, 3),
        mealType: 'lunch',
        foodName: 'Njama Njama',
        calories: 200,
        proteinGrams: 5.0,
        fiberGrams: 6.0,
        waterMl: 0,
        clientUpdatedTimestamp: DateTime(2026, 6, 3),
      );

      await repository.saveMealLog(entity);

      expect(localDataSource.cached.any((e) => e.id == 'meal-2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == 'meal-2'), isTrue);
      expect(localDataSource.unsynced.any((e) => e.id == 'meal-2'), isFalse);
    });

    test('should delete from remote and local when online on deleteMealLog', () async {
      networkInfo.isConnectedValue = true;
      localDataSource.cached = [sampleModel];
      remoteDataSource.remote = [sampleModel];

      await repository.deleteMealLog('meal-1');

      expect(localDataSource.cached.isEmpty, isTrue);
      expect(remoteDataSource.remote.isEmpty, isTrue);
    });
  });

  group('MealLogNotifier Unit Tests', () {
    test('should load meal logs and update state', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = MealLogNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.mealLogs.first.id, equals('meal-1'));
    });

    test('should add meal log and reload', () async {
      networkInfo.isConnectedValue = false;
      final notifier = MealLogNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      await notifier.addMealLog(
        mealType: 'dinner',
        foodName: 'Ndole with Plantains',
        calories: 450,
        proteinGrams: 15.0,
        fiberGrams: 8.0,
        waterMl: 250,
        date: DateTime(2026, 6, 5),
      );

      expect(notifier.state.mealLogs.any((e) => e.foodName == 'Ndole with Plantains'), isTrue);
    });

    test('should remove meal log and reload', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = MealLogNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      await notifier.removeMealLog('meal-1');

      expect(notifier.state.mealLogs.isEmpty, isTrue);
    });
  });
}
