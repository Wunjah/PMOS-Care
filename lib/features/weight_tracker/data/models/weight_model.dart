import '../../domain/entities/weight_entity.dart';

class WeightModel extends WeightEntity {
  const WeightModel({
    required super.id,
    required super.timestamp,
    required super.weightKg,
    required super.waistSizeInches,
    required super.clientUpdatedTimestamp,
  });

  factory WeightModel.fromJson(Map<String, dynamic> json) {
    return WeightModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      waistSizeInches: (json['waistSizeInches'] as num).toDouble(),
      clientUpdatedTimestamp: DateTime.parse(
        json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'weightKg': weightKg,
      'waistSizeInches': waistSizeInches,
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory WeightModel.fromEntity(WeightEntity entity) {
    return WeightModel(
      id: entity.id,
      timestamp: entity.timestamp,
      weightKg: entity.weightKg,
      waistSizeInches: entity.waistSizeInches,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
