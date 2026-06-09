class WeightEntity {
  final String id;
  final DateTime timestamp;
  final double weightKg;
  final double waistSizeInches;
  final DateTime clientUpdatedTimestamp;

  const WeightEntity({
    required this.id,
    required this.timestamp,
    required this.weightKg,
    required this.waistSizeInches,
    required this.clientUpdatedTimestamp,
  });

  WeightEntity copyWith({
    String? id,
    DateTime? timestamp,
    double? weightKg,
    double? waistSizeInches,
    DateTime? clientUpdatedTimestamp,
  }) {
    return WeightEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weightKg: weightKg ?? this.weightKg,
      waistSizeInches: waistSizeInches ?? this.waistSizeInches,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
