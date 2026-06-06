import '../../domain/entities/symptom_entity.dart';

class SymptomModel extends SymptomEntity {
  const SymptomModel({
    required super.id,
    required super.timestamp,
    super.ferrimanGallweyScore,
    required super.acneSeverity,
    required super.alopeciaSeverity,
    required super.fatigueLevel,
    required super.mood,
    required super.cravings,
    required super.bloating,
    required super.pelvicPain,
    required super.acanthosisNigricans,
    required super.skinTags,
    required super.clientUpdatedTimestamp,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    final markers = json['insulinResistanceMarkers'] as Map<String, dynamic>? ?? {};
    return SymptomModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ferrimanGallweyScore: json['ferrimanGallweyScore'] as int?,
      acneSeverity: json['acneSeverity'] as String? ?? 'none',
      alopeciaSeverity: json['alopeciaSeverity'] as String? ?? 'none',
      fatigueLevel: json['fatigueLevel'] as int? ?? 1,
      mood: json['mood'] as String? ?? 'calm',
      cravings: List<String>.from(json['cravings'] as List? ?? []),
      bloating: json['bloating'] as bool? ?? false,
      pelvicPain: json['pelvicPain'] as int? ?? 1,
      acanthosisNigricans: markers['acanthosisNigricans'] as bool? ?? false,
      skinTags: markers['skinTags'] as bool? ?? false,
      clientUpdatedTimestamp: DateTime.parse(json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'ferrimanGallweyScore': ferrimanGallweyScore,
      'acneSeverity': acneSeverity,
      'alopeciaSeverity': alopeciaSeverity,
      'fatigueLevel': fatigueLevel,
      'mood': mood,
      'cravings': cravings,
      'bloating': bloating,
      'pelvicPain': pelvicPain,
      'insulinResistanceMarkers': {
        'acanthosisNigricans': acanthosisNigricans,
        'skinTags': skinTags,
      },
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory SymptomModel.fromEntity(SymptomEntity entity) {
    return SymptomModel(
      id: entity.id,
      timestamp: entity.timestamp,
      ferrimanGallweyScore: entity.ferrimanGallweyScore,
      acneSeverity: entity.acneSeverity,
      alopeciaSeverity: entity.alopeciaSeverity,
      fatigueLevel: entity.fatigueLevel,
      mood: entity.mood,
      cravings: entity.cravings,
      bloating: entity.bloating,
      pelvicPain: entity.pelvicPain,
      acanthosisNigricans: entity.acanthosisNigricans,
      skinTags: entity.skinTags,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
