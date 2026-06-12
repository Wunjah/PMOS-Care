import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/cycle_entity.dart';
import '../../domain/repositories/cycle_repository.dart';
import '../../domain/usecases/get_cycles_usecase.dart';
import '../../domain/usecases/save_cycle_usecase.dart';
import '../../domain/usecases/predict_next_cycle_usecase.dart';
import '../../data/datasources/cycle_local_datasource.dart';
import '../../data/datasources/cycle_remote_datasource.dart';
import '../../data/repositories/cycle_repository_impl.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final cycleHiveBoxProvider = Provider<Box>((ref) {
  return Hive.box('pmos_cycle_storage_box');
});

final cycleLocalDataSourceProvider = Provider<CycleLocalDataSource>((ref) {
  return CycleLocalDataSourceImpl(ref.watch(cycleHiveBoxProvider));
});

final cycleRemoteDataSourceProvider = Provider<CycleRemoteDataSource>((ref) {
  return CycleRemoteDataSourceImpl(
    ref.watch(firestoreProvider),
    FirebaseAuth.instance,
  );
});

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  return CycleRepositoryImpl(
    remoteDataSource: ref.watch(cycleRemoteDataSourceProvider),
    localDataSource: ref.watch(cycleLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

final getCyclesUsecaseProvider = Provider<GetCyclesUsecase>((ref) {
  return GetCyclesUsecase(ref.watch(cycleRepositoryProvider));
});

final saveCycleUsecaseProvider = Provider<SaveCycleUsecase>((ref) {
  return SaveCycleUsecase(ref.watch(cycleRepositoryProvider));
});

final predictNextCycleUsecaseProvider = Provider<PredictNextCycleUsecase>((ref) {
  return PredictNextCycleUsecase();
});

class CycleState {
  final bool isLoading;
  final List<CycleEntity> cycles;
  final DateTime? predictedNextDate;
  final String? errorMessage;

  CycleState({
    required this.isLoading,
    required this.cycles,
    this.predictedNextDate,
    this.errorMessage,
  });

  CycleState copyWith({
    bool? isLoading,
    List<CycleEntity>? cycles,
    DateTime? predictedNextDate,
    String? errorMessage,
  }) {
    return CycleState(
      isLoading: isLoading ?? this.isLoading,
      cycles: cycles ?? this.cycles,
      predictedNextDate: predictedNextDate ?? this.predictedNextDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CycleNotifier extends StateNotifier<CycleState> {
  final GetCyclesUsecase _getCycles;
  final SaveCycleUsecase _saveCycle;
  final PredictNextCycleUsecase _predictNextCycle;
  final CycleRepository _repository;

  CycleNotifier({
    required GetCyclesUsecase getCycles,
    required SaveCycleUsecase saveCycle,
    required PredictNextCycleUsecase predictNextCycle,
    required CycleRepository repository,
  })  : _getCycles = getCycles,
        _saveCycle = saveCycle,
        _predictNextCycle = predictNextCycle,
        _repository = repository,
        super(CycleState(isLoading: false, cycles: [])) {
    loadCycleLogs();
  }

  Future<void> loadCycleLogs() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final cyclesList = await _getCycles.execute();
      final prediction = _predictNextCycle.execute(cyclesList);

      state = CycleState(
        isLoading: false,
        cycles: cyclesList,
        predictedNextDate: prediction,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load cycles: $e');
    }
  }

  Future<void> addCycleLog({
    required DateTime startDate,
    DateTime? endDate,
    required FlowIntensity flowIntensity,
    required int painLevel,
    required List<String> symptoms,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newCycle = CycleEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startDate: startDate,
        endDate: endDate,
        flowIntensity: flowIntensity,
        painLevel: painLevel,
        symptoms: symptoms,
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      await _saveCycle.execute(newCycle);
      await loadCycleLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to log cycle: $e');
    }
  }

  Future<void> endActiveCycle(String cycleId, DateTime endDate) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final existing = state.cycles.firstWhere((c) => c.id == cycleId);
      final updated = CycleEntity(
        id: existing.id,
        startDate: existing.startDate,
        endDate: endDate,
        flowIntensity: existing.flowIntensity,
        painLevel: existing.painLevel,
        symptoms: existing.symptoms,
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );
      await _repository.updateCycle(updated);
      await loadCycleLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to end cycle: $e');
    }
  }

  Future<void> removeCycleLog(String cycleId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteCycle(cycleId);
      await loadCycleLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete log: $e');
    }
  }
}

final cycleStateNotifierProvider = StateNotifierProvider<CycleNotifier, CycleState>((ref) {
  return CycleNotifier(
    getCycles: ref.watch(getCyclesUsecaseProvider),
    saveCycle: ref.watch(saveCycleUsecaseProvider),
    predictNextCycle: ref.watch(predictNextCycleUsecaseProvider),
    repository: ref.watch(cycleRepositoryProvider),
  );
});
