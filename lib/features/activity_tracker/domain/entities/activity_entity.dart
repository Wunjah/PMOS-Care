class ActivityEntity {
  final String id;
  final DateTime timestamp;
  final String activityType; // walking, running, home_workout, gym
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime clientUpdatedTimestamp;

  const ActivityEntity({
    required this.id,
    required this.timestamp,
    required this.activityType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.clientUpdatedTimestamp,
  });

  ActivityEntity copyWith({
    String? id,
    DateTime? timestamp,
    String? activityType,
    int? durationMinutes,
    double? caloriesBurned,
    DateTime? clientUpdatedTimestamp,
  }) {
    return ActivityEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      activityType: activityType ?? this.activityType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
