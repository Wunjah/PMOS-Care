import '../../domain/entities/appointment_entity.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentEntity>> getAppointments();
  Future<void> saveAppointment(AppointmentEntity appointment);
  Future<void> deleteAppointment(String appointmentId);
  Future<void> syncOfflineData();
}
