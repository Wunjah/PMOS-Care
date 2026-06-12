import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../data/datasources/appointment_local_datasource.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../../../core/notifications/notification_service.dart';

final appointmentHiveBoxProvider = Provider<Box>((ref) {
  return Hive.box('pmos_appointment_box');
});

final appointmentLocalDataSourceProvider = Provider<AppointmentLocalDataSource>((ref) {
  return AppointmentLocalDataSourceImpl(ref.watch(appointmentHiveBoxProvider));
});

final appointmentRemoteDataSourceProvider = Provider<AppointmentRemoteDataSource>((ref) {
  return AppointmentRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepositoryImpl(
    remoteDataSource: ref.watch(appointmentRemoteDataSourceProvider),
    localDataSource: ref.watch(appointmentLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

class AppointmentState {
  final bool isLoading;
  final List<AppointmentEntity> appointments;
  final String? errorMessage;

  AppointmentState({
    required this.isLoading,
    required this.appointments,
    this.errorMessage,
  });

  AppointmentState copyWith({
    bool? isLoading,
    List<AppointmentEntity>? appointments,
    String? errorMessage,
  }) {
    return AppointmentState(
      isLoading: isLoading ?? this.isLoading,
      appointments: appointments ?? this.appointments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repository;

  AppointmentNotifier({required AppointmentRepository repository})
      : _repository = repository,
        super(AppointmentState(isLoading: false, appointments: [])) {
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final list = await _repository.getAppointments();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      state = AppointmentState(isLoading: false, appointments: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load appointments: $e');
    }
  }

  Future<String> bookAppointment({
    required String specialistName,
    required String specialistTitle,
    required String consultationType,
    required DateTime dateTime,
    required String specialistInitials,
    required int avatarColorValue,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final entity = AppointmentEntity(
        id: id,
        specialistName: specialistName,
        specialistTitle: specialistTitle,
        consultationType: consultationType,
        dateTime: dateTime,
        status: 'Scheduled',
        specialistInitials: specialistInitials,
        avatarColorValue: avatarColorValue,
        clientUpdatedTimestamp: DateTime.now(),
      );

      await _repository.saveAppointment(entity);
      await NotificationService().scheduleAppointmentReminder(entity);
      await loadAppointments();
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to book appointment: $e');
      rethrow;
    }
  }

  Future<void> cancelAppointment(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteAppointment(id);
      await NotificationService().cancelAppointmentReminder(id);
      await loadAppointments();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to cancel appointment: $e');
    }
  }
}

final appointmentStateNotifierProvider = StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  return AppointmentNotifier(repository: ref.watch(appointmentRepositoryProvider));
});
