import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/activity_entity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../data/datasources/activity_local_datasource.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../data/repositories/activity_repository_impl.dart';

final activityHiveBoxProvider = Provider<Box>((ref) {
  return Hive.box('pmos_activity_box');
});

final activityLocalDataSourceProvider = Provider<ActivityLocalDataSource>((ref) {
  return ActivityLocalDataSourceImpl(ref.watch(activityHiveBoxProvider));
});

final activityRemoteDataSourceProvider = Provider<ActivityRemoteDataSource>((ref) {
  return ActivityRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(
    remoteDataSource: ref.watch(activityRemoteDataSourceProvider),
    localDataSource: ref.watch(activityLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

class ActivityState {
  final bool isLoading;
  final List<ActivityEntity> activities;
  final int currentStreak;
  final double totalCaloriesBurned;
  final String? errorMessage;

  ActivityState({
    required this.isLoading,
    required this.activities,
    required this.currentStreak,
    required this.totalCaloriesBurned,
    this.errorMessage,
  });

  ActivityState copyWith({
    bool? isLoading,
    List<ActivityEntity>? activities,
    int? currentStreak,
    double? totalCaloriesBurned,
    String? errorMessage,
  }) {
    return ActivityState(
      isLoading: isLoading ?? this.isLoading,
      activities: activities ?? this.activities,
      currentStreak: currentStreak ?? this.currentStreak,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  final ActivityRepository _repository;

  ActivityNotifier({required ActivityRepository repository})
      : _repository = repository,
        super(ActivityState(
          isLoading: false,
          activities: [],
          currentStreak: 0,
          totalCaloriesBurned: 0,
        )) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final list = await _repository.getActivities();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      final streak = _calculateStreak(list);
      final totalCals = list.fold<double>(0, (acc, item) => acc + item.caloriesBurned);

      state = ActivityState(
        isLoading: false,
        activities: list,
        currentStreak: streak,
        totalCaloriesBurned: totalCals,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load activities: $e');
    }
  }

  Future<void> addActivity({
    required String type,
    required int duration,
    required double calories,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final entity = ActivityEntity(
        id: id,
        timestamp: date,
        activityType: type,
        durationMinutes: duration,
        caloriesBurned: calories,
        clientUpdatedTimestamp: DateTime.now(),
      );
      await _repository.saveActivity(entity);
      await loadActivities();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save activity: $e');
      rethrow;
    }
  }

  Future<void> removeActivity(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteActivity(id);
      await loadActivities();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete activity: $e');
    }
  }

  int _calculateStreak(List<ActivityEntity> activities) {
    if (activities.isEmpty) return 0;

    // Extract unique dates (only day/month/year part) sorted descending
    final dates = activities
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    // If the latest log is before yesterday, streak is broken
    if (dates.first.isBefore(yesterday) && dates.first != today) {
      return 0;
    }

    int streak = 0;
    DateTime currentExpected = dates.first;

    for (final date in dates) {
      if (date == currentExpected) {
        streak++;
        currentExpected = currentExpected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

final activityStateNotifierProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier(repository: ref.watch(activityRepositoryProvider));
});
