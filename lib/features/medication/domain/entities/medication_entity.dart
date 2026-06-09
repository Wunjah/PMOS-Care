class MedicationEntity {
  final String id;
  final String name;
  final String dosage; // e.g., 500mg, 1 tablet
  final String timing; // breakfast, lunch, dinner, bedtime
  final bool isTakenToday;
  final DateTime lastTakenDate;
  final DateTime clientUpdatedTimestamp;

  const MedicationEntity({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timing,
    required this.isTakenToday,
    required this.lastTakenDate,
    required this.clientUpdatedTimestamp,
  });

  MedicationEntity copyWith({
    String? id,
    String? name,
    String? dosage,
    String? timing,
    bool? isTakenToday,
    DateTime? lastTakenDate,
    DateTime? clientUpdatedTimestamp,
  }) {
    return MedicationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      timing: timing ?? this.timing,
      isTakenToday: isTakenToday ?? this.isTakenToday,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
