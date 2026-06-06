class SymptomEntity {
  final String id; // formatted as YYYY-MM-DD
  final DateTime timestamp;
  final int? ferrimanGallweyScore; // 0-36 hirsutism scale
  final String acneSeverity; // none, mild, moderate, severe
  final String alopeciaSeverity; // none, mild, moderate, severe
  final int fatigueLevel; // 1-5
  final String mood; // happy, irritable, anxious, depressed, calm
  final List<String> cravings;
  final bool bloating;
  final int pelvicPain; // 1-5
  final bool acanthosisNigricans;
  final bool skinTags;
  final DateTime clientUpdatedTimestamp;

  const SymptomEntity({
    required this.id,
    required this.timestamp,
    this.ferrimanGallweyScore,
    required this.acneSeverity,
    required this.alopeciaSeverity,
    required this.fatigueLevel,
    required this.mood,
    required this.cravings,
    required this.bloating,
    required this.pelvicPain,
    required this.acanthosisNigricans,
    required this.skinTags,
    required this.clientUpdatedTimestamp,
  });

  SymptomEntity copyWith({
    String? id,
    DateTime? timestamp,
    int? ferrimanGallweyScore,
    String? acneSeverity,
    String? alopeciaSeverity,
    int? fatigueLevel,
    String? mood,
    List<String>? cravings,
    bool? bloating,
    int? pelvicPain,
    bool? acanthosisNigricans,
    bool? skinTags,
    DateTime? clientUpdatedTimestamp,
  }) {
    return SymptomEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      ferrimanGallweyScore: ferrimanGallweyScore ?? this.ferrimanGallweyScore,
      acneSeverity: acneSeverity ?? this.acneSeverity,
      alopeciaSeverity: alopeciaSeverity ?? this.alopeciaSeverity,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      mood: mood ?? this.mood,
      cravings: cravings ?? this.cravings,
      bloating: bloating ?? this.bloating,
      pelvicPain: pelvicPain ?? this.pelvicPain,
      acanthosisNigricans: acanthosisNigricans ?? this.acanthosisNigricans,
      skinTags: skinTags ?? this.skinTags,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
