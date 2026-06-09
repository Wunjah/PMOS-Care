import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/repositories/weight_repository.dart';
import '../../data/datasources/weight_local_datasource.dart';
import '../../data/datasources/weight_remote_datasource.dart';
import '../../data/repositories/weight_repository_impl.dart';

final weightHiveBoxProvider = Provider<Box>((ref) {
  return Hive.box('pmos_weight_box');
});

final weightLocalDataSourceProvider = Provider<WeightLocalDataSource>((ref) {
  return WeightLocalDataSourceImpl(ref.watch(weightHiveBoxProvider));
});

final weightRemoteDataSourceProvider = Provider<WeightRemoteDataSource>((ref) {
  return WeightRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepositoryImpl(
    remoteDataSource: ref.watch(weightRemoteDataSourceProvider),
    localDataSource: ref.watch(weightLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

class WeightState {
  final bool isLoading;
  final List<WeightEntity> weights;
  final String? errorMessage;

  WeightState({
    required this.isLoading,
    required this.weights,
    this.errorMessage,
  });

  WeightState copyWith({
    bool? isLoading,
    List<WeightEntity>? weights,
    String? errorMessage,
  }) {
    return WeightState(
      isLoading: isLoading ?? this.isLoading,
      weights: weights ?? this.weights,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class WeightNotifier extends StateNotifier<WeightState> {
  final WeightRepository _repository;

  WeightNotifier({required WeightRepository repository})
      : _repository = repository,
        super(WeightState(isLoading: false, weights: [])) {
    loadWeights();
  }

  Future<void> loadWeights() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final list = await _repository.getWeights();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = WeightState(isLoading: false, weights: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load weights: $e');
    }
  }

  Future<void> addWeight(double weightKg, double waistSizeInches, DateTime date) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final entity = WeightEntity(
        id: id,
        timestamp: date,
        weightKg: weightKg,
        waistSizeInches: waistSizeInches,
        clientUpdatedTimestamp: DateTime.now(),
      );
      await _repository.saveWeight(entity);
      await loadWeights();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save weight: $e');
      rethrow;
    }
  }

  Future<void> removeWeight(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteWeight(id);
      await loadWeights();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete weight: $e');
    }
  }
}

final weightStateNotifierProvider = StateNotifierProvider<WeightNotifier, WeightState>((ref) {
  return WeightNotifier(repository: ref.watch(weightRepositoryProvider));
});
