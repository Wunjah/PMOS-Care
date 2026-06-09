import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/core/network/network_info.dart';
import 'package:pmos_care/features/weight_tracker/data/models/weight_model.dart';
import 'package:pmos_care/features/weight_tracker/data/repositories/weight_repository_impl.dart';
import 'package:pmos_care/features/weight_tracker/domain/entities/weight_entity.dart';
import 'package:pmos_care/features/weight_tracker/presentation/providers/weight_provider.dart';
import 'package:pmos_care/features/weight_tracker/data/datasources/weight_local_datasource.dart';
import 'package:pmos_care/features/weight_tracker/data/datasources/weight_remote_datasource.dart';

class MockWeightLocalDataSource implements WeightLocalDataSource {
  List<WeightModel> cached = [];
  List<WeightModel> unsynced = [];
  List<String> pendingDeletes = [];

  @override
  Future<List<WeightModel>> getCachedWeights() async => cached;

  @override
  Future<void> cacheWeights(List<WeightModel> weights) async {
    cached = List.from(weights);
  }

  @override
  Future<void> cacheSingleWeight(WeightModel weight, {required bool needsSync}) async {
    cached.removeWhere((e) => e.id == weight.id);
    cached.add(weight);
    if (needsSync) {
      unsynced.removeWhere((e) => e.id == weight.id);
      unsynced.add(weight);
    } else {
      unsynced.removeWhere((e) => e.id == weight.id);
    }
  }

  @override
  Future<void> removeCachedWeight(String weightLogId, {required bool needsSyncDelete}) async {
    cached.removeWhere((e) => e.id == weightLogId);
    unsynced.removeWhere((e) => e.id == weightLogId);
    if (needsSyncDelete) {
      pendingDeletes.remove(weightLogId);
      pendingDeletes.add(weightLogId);
    } else {
      pendingDeletes.remove(weightLogId);
    }
  }

  @override
  Future<List<String>> getPendingDeletes() async => List.from(pendingDeletes);

  @override
  Future<List<WeightModel>> getUnsyncedWeights() async => List.from(unsynced);

  @override
  Future<void> clearCache() async {
    cached.clear();
    unsynced.clear();
    pendingDeletes.clear();
  }
}

class MockWeightRemoteDataSource implements WeightRemoteDataSource {
  List<WeightModel> remote = [];
  bool throwError = false;

  @override
  Future<List<WeightModel>> getRemoteWeights() async {
    if (throwError) throw Exception("Remote error");
    return remote;
  }

  @override
  Future<void> saveRemoteWeight(WeightModel weight) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == weight.id);
    remote.add(weight);
  }

  @override
  Future<void> deleteRemoteWeight(String weightLogId) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == weightLogId);
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
  late MockWeightLocalDataSource localDataSource;
  late MockWeightRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late WeightRepositoryImpl repository;

  final sampleModel = WeightModel(
    id: '1',
    timestamp: DateTime(2026, 6, 1),
    weightKg: 70.5,
    waistSizeInches: 32.0,
    clientUpdatedTimestamp: DateTime(2026, 6, 1),
  );

  setUp(() {
    localDataSource = MockWeightLocalDataSource();
    remoteDataSource = MockWeightRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = WeightRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
  });

  group('WeightModel Unit Tests', () {
    test('should convert to and from JSON correctly', () {
      final json = sampleModel.toJson();
      final fromJson = WeightModel.fromJson(json);
      expect(fromJson.id, equals(sampleModel.id));
      expect(fromJson.weightKg, equals(sampleModel.weightKg));
      expect(fromJson.waistSizeInches, equals(sampleModel.waistSizeInches));
    });

    test('should map from entity', () {
      final entity = WeightEntity(
        id: 'entity-1',
        timestamp: DateTime(2026, 6, 2),
        weightKg: 68.0,
        waistSizeInches: 30.5,
        clientUpdatedTimestamp: DateTime(2026, 6, 2),
      );
      final model = WeightModel.fromEntity(entity);
      expect(model.id, equals(entity.id));
      expect(model.weightKg, equals(entity.weightKg));
      expect(model.waistSizeInches, equals(entity.waistSizeInches));
    });
  });

  group('WeightRepositoryImpl Unit Tests', () {
    test('should get weights from remote and cache them when online', () async {
      networkInfo.isConnectedValue = true;
      remoteDataSource.remote = [sampleModel];

      final result = await repository.getWeights();

      expect(result.first.id, equals('1'));
      expect(localDataSource.cached.first.id, equals('1'));
    });

    test('should get weights from cache when offline', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      final result = await repository.getWeights();

      expect(result.first.id, equals('1'));
    });

    test('should cache and upload to remote on saveWeight when online', () async {
      networkInfo.isConnectedValue = true;
      final entity = WeightEntity(
        id: '2',
        timestamp: DateTime(2026, 6, 3),
        weightKg: 65.0,
        waistSizeInches: 29.0,
        clientUpdatedTimestamp: DateTime(2026, 6, 3),
      );

      await repository.saveWeight(entity);

      expect(localDataSource.cached.any((e) => e.id == '2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == '2'), isTrue);
      expect(localDataSource.unsynced.any((e) => e.id == '2'), isFalse);
    });

    test('should cache and mark unsynced on saveWeight when offline', () async {
      networkInfo.isConnectedValue = false;
      final entity = WeightEntity(
        id: '2',
        timestamp: DateTime(2026, 6, 3),
        weightKg: 65.0,
        waistSizeInches: 29.0,
        clientUpdatedTimestamp: DateTime(2026, 6, 3),
      );

      await repository.saveWeight(entity);

      expect(localDataSource.cached.any((e) => e.id == '2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == '2'), isFalse);
      expect(localDataSource.unsynced.any((e) => e.id == '2'), isTrue);
    });

    test('should delete from remote and local when online on deleteWeight', () async {
      networkInfo.isConnectedValue = true;
      localDataSource.cached = [sampleModel];
      remoteDataSource.remote = [sampleModel];

      await repository.deleteWeight('1');

      expect(localDataSource.cached.isEmpty, isTrue);
      expect(remoteDataSource.remote.isEmpty, isTrue);
    });

    test('should mark pending delete and remove from cache when offline on deleteWeight', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      await repository.deleteWeight('1');

      expect(localDataSource.cached.isEmpty, isTrue);
      expect(localDataSource.pendingDeletes.contains('1'), isTrue);
    });

    test('should sync offline data correctly when coming back online', () async {
      networkInfo.isConnectedValue = true;
      localDataSource.unsynced = [sampleModel];
      localDataSource.pendingDeletes = ['old-id'];

      await repository.syncOfflineData();

      expect(remoteDataSource.remote.any((e) => e.id == '1'), isTrue);
      expect(localDataSource.unsynced.isEmpty, isTrue);
      expect(localDataSource.pendingDeletes.isEmpty, isTrue);
    });
  });

  group('WeightNotifier Unit Tests', () {
    test('should load weights and update state', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = WeightNotifier(repository: repository);

      // wait for loadWeights to complete (since it starts in constructor)
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.weights.first.id, equals('1'));
    });

    test('should add weight and reload', () async {
      networkInfo.isConnectedValue = false;
      final notifier = WeightNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      await notifier.addWeight(72.0, 31.0, DateTime(2026, 6, 5));

      expect(notifier.state.weights.any((e) => e.weightKg == 72.0), isTrue);
    });

    test('should remove weight and reload', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = WeightNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      await notifier.removeWeight('1');

      expect(notifier.state.weights.isEmpty, isTrue);
    });
  });
}
