class AppointmentEntity {
  final String id;
  final String specialistName;
  final String specialistTitle;
  final String consultationType;
  final DateTime dateTime;
  final String status;
  final String specialistInitials;
  final int avatarColorValue;
  final DateTime clientUpdatedTimestamp;

  const AppointmentEntity({
    required this.id,
    required this.specialistName,
    required this.specialistTitle,
    required this.consultationType,
    required this.dateTime,
    required this.status,
    required this.specialistInitials,
    required this.avatarColorValue,
    required this.clientUpdatedTimestamp,
  });

  AppointmentEntity copyWith({
    String? id,
    String? specialistName,
    String? specialistTitle,
    String? consultationType,
    DateTime? dateTime,
    String? status,
    String? specialistInitials,
    int? avatarColorValue,
    DateTime? clientUpdatedTimestamp,
  }) {
    return AppointmentEntity(
      id: id ?? this.id,
      specialistName: specialistName ?? this.specialistName,
      specialistTitle: specialistTitle ?? this.specialistTitle,
      consultationType: consultationType ?? this.consultationType,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      specialistInitials: specialistInitials ?? this.specialistInitials,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
