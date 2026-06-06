enum FlowIntensity { light, medium, heavy, spotting }

class CycleEntity {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity flowIntensity;
  final int painLevel; // 1-5
  final List<String> symptoms;
  final bool isPredicted;
  final DateTime clientUpdatedTimestamp;

  const CycleEntity({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.flowIntensity,
    required this.painLevel,
    required this.symptoms,
    required this.isPredicted,
    required this.clientUpdatedTimestamp,
  });

  CycleEntity copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    FlowIntensity? flowIntensity,
    int? painLevel,
    List<String>? symptoms,
    bool? isPredicted,
    DateTime? clientUpdatedTimestamp,
  }) {
    return CycleEntity(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      painLevel: painLevel ?? this.painLevel,
      symptoms: symptoms ?? this.symptoms,
      isPredicted: isPredicted ?? this.isPredicted,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
