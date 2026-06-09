import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/medication_entity.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../data/datasources/medication_local_datasource.dart';
import '../../data/datasources/medication_remote_datasource.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../../../core/notifications/notification_service.dart';

final medicationHiveBoxProvider = Provider<Box>((ref) {
  return Hive.box('pmos_medication_box');
});

final medicationLocalDataSourceProvider = Provider<MedicationLocalDataSource>((ref) {
  return MedicationLocalDataSourceImpl(ref.watch(medicationHiveBoxProvider));
});

final medicationRemoteDataSourceProvider = Provider<MedicationRemoteDataSource>((ref) {
  return MedicationRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(
    remoteDataSource: ref.watch(medicationRemoteDataSourceProvider),
    localDataSource: ref.watch(medicationLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

class MedicationState {
  final bool isLoading;
  final List<MedicationEntity> medications;
  final String? errorMessage;

  MedicationState({
    required this.isLoading,
    required this.medications,
    this.errorMessage,
  });

  MedicationState copyWith({
    bool? isLoading,
    List<MedicationEntity>? medications,
    String? errorMessage,
  }) {
    return MedicationState(
      isLoading: isLoading ?? this.isLoading,
      medications: medications ?? this.medications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MedicationNotifier extends StateNotifier<MedicationState> {
  final MedicationRepository _repository;

  MedicationNotifier({required MedicationRepository repository})
      : _repository = repository,
        super(MedicationState(isLoading: false, medications: [])) {
    loadMedications();
  }

  Future<void> loadMedications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final list = await _repository.getMedications();
      
      // Auto-reset isTakenToday if date has changed
      final today = DateTime.now();
      final updatedList = <MedicationEntity>[];
      for (final med in list) {
        final lastTaken = med.lastTakenDate;
        final isDifferentDay = lastTaken.year != today.year ||
            lastTaken.month != today.month ||
            lastTaken.day != today.day;
        if (med.isTakenToday && isDifferentDay) {
          final resetMed = med.copyWith(isTakenToday: false);
          await _repository.saveMedication(resetMed);
          updatedList.add(resetMed);
        } else {
          updatedList.add(med);
        }
      }

      state = MedicationState(isLoading: false, medications: updatedList);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load medications: $e');
    }
  }

  Future<void> addMedication({
    required String name,
    required String dosage,
    required String timing,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final entity = MedicationEntity(
        id: id,
        name: name,
        dosage: dosage,
        timing: timing,
        isTakenToday: false,
        lastTakenDate: DateTime.now().subtract(const Duration(days: 1)),
        clientUpdatedTimestamp: DateTime.now(),
      );
      await _repository.saveMedication(entity);
      await NotificationService().scheduleMedicationReminder(entity);
      await loadMedications();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save medication: $e');
      rethrow;
    }
  }

  Future<void> toggleTaken(String id, bool taken) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = state.medications;
      final index = list.indexWhere((element) => element.id == id);
      if (index != -1) {
        final med = list[index];
        final updated = med.copyWith(
          isTakenToday: taken,
          lastTakenDate: taken ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1)),
          clientUpdatedTimestamp: DateTime.now(),
        );
        await _repository.saveMedication(updated);
        await loadMedications();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update medication: $e');
    }
  }

  Future<void> removeMedication(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteMedication(id);
      await NotificationService().cancelMedicationReminder(id);
      await loadMedications();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete medication: $e');
    }
  }
}

final medicationStateNotifierProvider = StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  return MedicationNotifier(repository: ref.watch(medicationRepositoryProvider));
});
