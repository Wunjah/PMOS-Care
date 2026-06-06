import '../../domain/entities/cycle_entity.dart';

class CycleModel extends CycleEntity {
  const CycleModel({
    required super.id,
    required super.startDate,
    super.endDate,
    required super.flowIntensity,
    required super.painLevel,
    required super.symptoms,
    required super.isPredicted,
    required super.clientUpdatedTimestamp,
  });

  factory CycleModel.fromJson(Map<String, dynamic> json) {
    return CycleModel(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      flowIntensity: FlowIntensity.values.firstWhere(
        (e) => e.name == json['flowIntensity'],
        orElse: () => FlowIntensity.medium,
      ),
      painLevel: json['painLevel'] as int? ?? 1,
      symptoms: List<String>.from(json['symptoms'] as List? ?? []),
      isPredicted: json['isPredicted'] as bool? ?? false,
      clientUpdatedTimestamp: DateTime.parse(json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'flowIntensity': flowIntensity.name,
      'painLevel': painLevel,
      'symptoms': symptoms,
      'isPredicted': isPredicted,
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory CycleModel.fromEntity(CycleEntity entity) {
    return CycleModel(
      id: entity.id,
      startDate: entity.startDate,
      endDate: entity.endDate,
      flowIntensity: entity.flowIntensity,
      painLevel: entity.painLevel,
      symptoms: entity.symptoms,
      isPredicted: entity.isPredicted,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
