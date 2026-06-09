import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/symptom_entity.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../../domain/usecases/get_symptoms_usecase.dart';
import '../../domain/usecases/save_symptom_usecase.dart';
import '../../data/datasources/symptom_local_datasource.dart';
import '../../data/datasources/symptom_remote_datasource.dart';
import '../../data/repositories/symptom_repository_impl.dart';

final symptomHiveBoxProvider = Provider<Box>((ref) {
  return Hive.box('pmos_symptom_box');
});

final symptomLocalDataSourceProvider = Provider<SymptomLocalDataSource>((ref) {
  return SymptomLocalDataSourceImpl(ref.watch(symptomHiveBoxProvider));
});

final symptomRemoteDataSourceProvider = Provider<SymptomRemoteDataSource>((ref) {
  return SymptomRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepositoryImpl(
    remoteDataSource: ref.watch(symptomRemoteDataSourceProvider),
    localDataSource: ref.watch(symptomLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

final getSymptomsUsecaseProvider = Provider<GetSymptomsUsecase>((ref) {
  return GetSymptomsUsecase(ref.watch(symptomRepositoryProvider));
});

final saveSymptomUsecaseProvider = Provider<SaveSymptomUsecase>((ref) {
  return SaveSymptomUsecase(ref.watch(symptomRepositoryProvider));
});

class SymptomState {
  final bool isLoading;
  final List<SymptomEntity> symptoms;
  final String? errorMessage;

  SymptomState({
    required this.isLoading,
    required this.symptoms,
    this.errorMessage,
  });

  SymptomState copyWith({
    bool? isLoading,
    List<SymptomEntity>? symptoms,
    String? errorMessage,
  }) {
    return SymptomState(
      isLoading: isLoading ?? this.isLoading,
      symptoms: symptoms ?? this.symptoms,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SymptomNotifier extends StateNotifier<SymptomState> {
  final GetSymptomsUsecase _getSymptoms;
  final SaveSymptomUsecase _saveSymptom;
  final SymptomRepository _repository;

  SymptomNotifier({
    required GetSymptomsUsecase getSymptoms,
    required SaveSymptomUsecase saveSymptom,
    required SymptomRepository repository,
  })  : _getSymptoms = getSymptoms,
        _saveSymptom = saveSymptom,
        _repository = repository,
        super(SymptomState(isLoading: false, symptoms: [])) {
    loadSymptomLogs();
  }

  Future<void> loadSymptomLogs() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final symptomsList = await _getSymptoms.execute();
      
      // Sort symptoms with latest first
      symptomsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      state = SymptomState(
        isLoading: false,
        symptoms: symptomsList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load symptoms: $e');
    }
  }

  Future<void> addSymptomLog(SymptomEntity symptom) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _saveSymptom.execute(symptom);
      await loadSymptomLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to log symptoms: $e');
      rethrow;
    }
  }

  Future<void> removeSymptomLog(String logId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteSymptom(logId);
      await loadSymptomLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete symptom: $e');
    }
  }
}

final symptomStateNotifierProvider = StateNotifierProvider<SymptomNotifier, SymptomState>((ref) {
  return SymptomNotifier(
    getSymptoms: ref.watch(getSymptomsUsecaseProvider),
    saveSymptom: ref.watch(saveSymptomUsecaseProvider),
    repository: ref.watch(symptomRepositoryProvider),
  );
});
