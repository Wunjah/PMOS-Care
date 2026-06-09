class MealLogEntity {
  final String id;
  final DateTime timestamp;
  final String mealType; // breakfast, lunch, dinner, snack, water
  final String foodName;
  final double calories;
  final double proteinGrams;
  final double fiberGrams;
  final double waterMl;
  final DateTime clientUpdatedTimestamp;

  const MealLogEntity({
    required this.id,
    required this.timestamp,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.proteinGrams,
    required this.fiberGrams,
    required this.waterMl,
    required this.clientUpdatedTimestamp,
  });

  MealLogEntity copyWith({
    String? id,
    DateTime? timestamp,
    String? mealType,
    String? foodName,
    double? calories,
    double? proteinGrams,
    double? fiberGrams,
    double? waterMl,
    DateTime? clientUpdatedTimestamp,
  }) {
    return MealLogEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      waterMl: waterMl ?? this.waterMl,
      clientUpdatedTimestamp: clientUpdatedTimestamp ?? this.clientUpdatedTimestamp,
    );
  }
}
