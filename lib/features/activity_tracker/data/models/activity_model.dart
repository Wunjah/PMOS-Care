import '../../domain/entities/activity_entity.dart';

class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.id,
    required super.timestamp,
    required super.activityType,
    required super.durationMinutes,
    required super.caloriesBurned,
    required super.clientUpdatedTimestamp,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      activityType: json['activityType'] as String? ?? 'walking',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
      clientUpdatedTimestamp: DateTime.parse(
        json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'activityType': activityType,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory ActivityModel.fromEntity(ActivityEntity entity) {
    return ActivityModel(
      id: entity.id,
      timestamp: entity.timestamp,
      activityType: entity.activityType,
      durationMinutes: entity.durationMinutes,
      caloriesBurned: entity.caloriesBurned,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
