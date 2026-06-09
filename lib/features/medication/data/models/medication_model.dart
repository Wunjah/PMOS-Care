import '../../domain/entities/medication_entity.dart';

class MedicationModel extends MedicationEntity {
  const MedicationModel({
    required super.id,
    required super.name,
    required super.dosage,
    required super.timing,
    required super.isTakenToday,
    required super.lastTakenDate,
    required super.clientUpdatedTimestamp,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      timing: json['timing'] as String? ?? 'breakfast',
      isTakenToday: json['isTakenToday'] as bool? ?? false,
      lastTakenDate: DateTime.parse(
        json['lastTakenDate'] as String? ?? DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
      clientUpdatedTimestamp: DateTime.parse(
        json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'timing': timing,
      'isTakenToday': isTakenToday,
      'lastTakenDate': lastTakenDate.toIso8601String(),
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory MedicationModel.fromEntity(MedicationEntity entity) {
    return MedicationModel(
      id: entity.id,
      name: entity.name,
      dosage: entity.dosage,
      timing: entity.timing,
      isTakenToday: entity.isTakenToday,
      lastTakenDate: entity.lastTakenDate,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
