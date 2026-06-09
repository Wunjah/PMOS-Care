import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/core/network/network_info.dart';
import 'package:pmos_care/features/activity_tracker/data/models/activity_model.dart';
import 'package:pmos_care/features/activity_tracker/data/repositories/activity_repository_impl.dart';
import 'package:pmos_care/features/activity_tracker/domain/entities/activity_entity.dart';
import 'package:pmos_care/features/activity_tracker/presentation/providers/activity_provider.dart';
import 'package:pmos_care/features/activity_tracker/data/datasources/activity_local_datasource.dart';
import 'package:pmos_care/features/activity_tracker/data/datasources/activity_remote_datasource.dart';

class MockActivityLocalDataSource implements ActivityLocalDataSource {
  List<ActivityModel> cached = [];
  List<ActivityModel> unsynced = [];
  List<String> pendingDeletes = [];

  @override
  Future<List<ActivityModel>> getCachedActivities() async => cached;

  @override
  Future<void> cacheActivities(List<ActivityModel> activities) async {
    cached = List.from(activities);
  }

  @override
  Future<void> cacheSingleActivity(ActivityModel activity, {required bool needsSync}) async {
    cached.removeWhere((e) => e.id == activity.id);
    cached.add(activity);
    if (needsSync) {
      unsynced.removeWhere((e) => e.id == activity.id);
      unsynced.add(activity);
    } else {
      unsynced.removeWhere((e) => e.id == activity.id);
    }
  }

  @override
  Future<void> removeCachedActivity(String activityLogId, {required bool needsSyncDelete}) async {
    cached.removeWhere((e) => e.id == activityLogId);
    unsynced.removeWhere((e) => e.id == activityLogId);
    if (needsSyncDelete) {
      pendingDeletes.remove(activityLogId);
      pendingDeletes.add(activityLogId);
    } else {
      pendingDeletes.remove(activityLogId);
    }
  }

  @override
  Future<List<String>> getPendingDeletes() async => List.from(pendingDeletes);

  @override
  Future<List<ActivityModel>> getUnsyncedActivities() async => List.from(unsynced);

  @override
  Future<void> clearCache() async {
    cached.clear();
    unsynced.clear();
    pendingDeletes.clear();
  }
}

class MockActivityRemoteDataSource implements MockRemoteActivitySource {
  List<ActivityModel> remote = [];
  bool throwError = false;

  @override
  Future<List<ActivityModel>> getRemoteActivities() async {
    if (throwError) throw Exception("Remote error");
    return remote;
  }

  @override
  Future<void> saveRemoteActivity(ActivityModel activity) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == activity.id);
    remote.add(activity);
  }

  @override
  Future<void> deleteRemoteActivity(String activityLogId) async {
    if (throwError) throw Exception("Remote error");
    remote.removeWhere((e) => e.id == activityLogId);
  }
}

// Interface to match ActivityRemoteDataSource
abstract class MockRemoteActivitySource implements ActivityRemoteDataSource {}

class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;

  @override
  Stream<NetworkStatus> get networkStatusStream =>
      Stream.value(isConnectedValue ? NetworkStatus.online : NetworkStatus.offline);
}

void main() {
  late MockActivityLocalDataSource localDataSource;
  late MockActivityRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late ActivityRepositoryImpl repository;

  final sampleModel = ActivityModel(
    id: '1',
    timestamp: DateTime(2026, 6, 1),
    activityType: 'walking',
    durationMinutes: 30,
    caloriesBurned: 150.0,
    clientUpdatedTimestamp: DateTime(2026, 6, 1),
  );

  setUp(() {
    localDataSource = MockActivityLocalDataSource();
    remoteDataSource = MockActivityRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = ActivityRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
  });

  group('ActivityModel Unit Tests', () {
    test('should convert to and from JSON correctly', () {
      final json = sampleModel.toJson();
      final fromJson = ActivityModel.fromJson(json);
      expect(fromJson.id, equals(sampleModel.id));
      expect(fromJson.activityType, equals(sampleModel.activityType));
      expect(fromJson.durationMinutes, equals(sampleModel.durationMinutes));
      expect(fromJson.caloriesBurned, equals(sampleModel.caloriesBurned));
    });

    test('should map from entity', () {
      final entity = ActivityEntity(
        id: 'entity-1',
        timestamp: DateTime(2026, 6, 2),
        activityType: 'running',
        durationMinutes: 45,
        caloriesBurned: 400.0,
        clientUpdatedTimestamp: DateTime(2026, 6, 2),
      );
      final model = ActivityModel.fromEntity(entity);
      expect(model.id, equals(entity.id));
      expect(model.activityType, equals(entity.activityType));
      expect(model.durationMinutes, equals(entity.durationMinutes));
      expect(model.caloriesBurned, equals(entity.caloriesBurned));
    });
  });

  group('ActivityRepositoryImpl Unit Tests', () {
    test('should get activities from remote and cache them when online', () async {
      networkInfo.isConnectedValue = true;
      remoteDataSource.remote = [sampleModel];

      final result = await repository.getActivities();

      expect(result.first.id, equals('1'));
      expect(localDataSource.cached.first.id, equals('1'));
    });

    test('should get activities from cache when offline', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      final result = await repository.getActivities(); // calls getCachedActivities underlying

      expect(result.first.id, equals('1'));
    });

    test('should cache and upload to remote on saveActivity when online', () async {
      networkInfo.isConnectedValue = true;
      final entity = ActivityEntity(
        id: '2',
        timestamp: DateTime(2026, 6, 3),
        activityType: 'gym',
        durationMinutes: 60,
        caloriesBurned: 350.0,
        clientUpdatedTimestamp: DateTime(2026, 6, 3),
      );

      await repository.saveActivity(entity);

      expect(localDataSource.cached.any((e) => e.id == '2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == '2'), isTrue);
      expect(localDataSource.unsynced.any((e) => e.id == '2'), isFalse);
    });

    test('should cache and mark unsynced on saveActivity when offline', () async {
      networkInfo.isConnectedValue = false;
      final entity = ActivityEntity(
        id: '2',
        timestamp: DateTime(2026, 6, 3),
        activityType: 'gym',
        durationMinutes: 60,
        caloriesBurned: 350.0,
        clientUpdatedTimestamp: DateTime(2026, 6, 3),
      );

      await repository.saveActivity(entity);

      expect(localDataSource.cached.any((e) => e.id == '2'), isTrue);
      expect(remoteDataSource.remote.any((e) => e.id == '2'), isFalse);
      expect(localDataSource.unsynced.any((e) => e.id == '2'), isTrue);
    });

    test('should delete from remote and local when online on deleteActivity', () async {
      networkInfo.isConnectedValue = true;
      localDataSource.cached = [sampleModel];
      remoteDataSource.remote = [sampleModel];

      await repository.deleteActivity('1');

      expect(localDataSource.cached.isEmpty, isTrue);
      expect(remoteDataSource.remote.isEmpty, isTrue);
    });

    test('should mark pending delete and remove from cache when offline on deleteActivity', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];

      await repository.deleteActivity('1'); // Underlying calls delete cached activity

      expect(localDataSource.cached.isEmpty, isTrue);
      expect(localDataSource.pendingDeletes.contains('1'), isTrue);
    });
  });

  group('ActivityNotifier Streak & Loading Unit Tests', () {
    test('should load activities, calculate totals, and update state', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [sampleModel];
      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.activities.first.id, equals('1'));
      expect(notifier.state.totalCaloriesBurned, equals(150.0));
    });

    test('should calculate 0 streak when there are no activities', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.cached = [];
      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentStreak, equals(0));
    });

    test('should calculate streak when activity is only logged today', () async {
      networkInfo.isConnectedValue = false;
      final today = DateTime.now();
      localDataSource.cached = [
        ActivityModel(
          id: 't1',
          timestamp: today,
          activityType: 'walking',
          durationMinutes: 30,
          caloriesBurned: 100.0,
          clientUpdatedTimestamp: today,
        )
      ];
      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentStreak, equals(1));
    });

    test('should calculate streak when activity is only logged yesterday', () async {
      networkInfo.isConnectedValue = false;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      localDataSource.cached = [
        ActivityModel(
          id: 't2',
          timestamp: yesterday,
          activityType: 'walking',
          durationMinutes: 30,
          caloriesBurned: 100.0,
          clientUpdatedTimestamp: yesterday,
        )
      ];
      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentStreak, equals(1));
    });

    test('should calculate 0 streak when latest activity is older than yesterday', () async {
      networkInfo.isConnectedValue = false;
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      localDataSource.cached = [
        ActivityModel(
          id: 't3',
          timestamp: threeDaysAgo,
          activityType: 'walking',
          durationMinutes: 30,
          caloriesBurned: 100.0,
          clientUpdatedTimestamp: threeDaysAgo,
        )
      ];
      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentStreak, equals(0));
    });

    test('should calculate multiple day streaks correctly', () async {
      networkInfo.isConnectedValue = false;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      localDataSource.cached = [
        ActivityModel(id: 'a1', timestamp: today, activityType: 'gym', durationMinutes: 30, caloriesBurned: 200, clientUpdatedTimestamp: today),
        ActivityModel(id: 'a2', timestamp: yesterday, activityType: 'running', durationMinutes: 30, caloriesBurned: 200, clientUpdatedTimestamp: yesterday),
        ActivityModel(id: 'a3', timestamp: twoDaysAgo, activityType: 'walking', durationMinutes: 30, caloriesBurned: 200, clientUpdatedTimestamp: twoDaysAgo),
      ];

      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentStreak, equals(3));
    });

    test('should break streak on gaps', () async {
      networkInfo.isConnectedValue = false;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      // gap: 2 days ago is missing
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      localDataSource.cached = [
        ActivityModel(id: 'a1', timestamp: today, activityType: 'gym', durationMinutes: 30, caloriesBurned: 200, clientUpdatedTimestamp: today),
        ActivityModel(id: 'a2', timestamp: yesterday, activityType: 'running', durationMinutes: 30, caloriesBurned: 200, clientUpdatedTimestamp: yesterday),
        ActivityModel(id: 'a3', timestamp: threeDaysAgo, activityType: 'walking', durationMinutes: 30, caloriesBurned: 200, clientUpdatedTimestamp: threeDaysAgo),
      ];

      final notifier = ActivityNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentStreak, equals(2)); // streak of 2 days (today, yesterday)
    });
  });
}
