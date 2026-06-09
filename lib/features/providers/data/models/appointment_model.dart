import '../../domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.specialistName,
    required super.specialistTitle,
    required super.consultationType,
    required super.dateTime,
    required super.status,
    required super.specialistInitials,
    required super.avatarColorValue,
    required super.clientUpdatedTimestamp,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      specialistName: json['specialistName'] as String? ?? '',
      specialistTitle: json['specialistTitle'] as String? ?? '',
      consultationType: json['consultationType'] as String? ?? 'Video Consultation',
      dateTime: DateTime.parse(json['dateTime'] as String),
      status: json['status'] as String? ?? 'Scheduled',
      specialistInitials: json['specialistInitials'] as String? ?? '',
      avatarColorValue: json['avatarColorValue'] as int? ?? 0xFF008080,
      clientUpdatedTimestamp: DateTime.parse(json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specialistName': specialistName,
      'specialistTitle': specialistTitle,
      'consultationType': consultationType,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'specialistInitials': specialistInitials,
      'avatarColorValue': avatarColorValue,
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory AppointmentModel.fromEntity(AppointmentEntity entity) {
    return AppointmentModel(
      id: entity.id,
      specialistName: entity.specialistName,
      specialistTitle: entity.specialistTitle,
      consultationType: entity.consultationType,
      dateTime: entity.dateTime,
      status: entity.status,
      specialistInitials: entity.specialistInitials,
      avatarColorValue: entity.avatarColorValue,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
