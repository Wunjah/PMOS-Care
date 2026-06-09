import '../../domain/entities/meal_log_entity.dart';

class MealLogModel extends MealLogEntity {
  const MealLogModel({
    required super.id,
    required super.timestamp,
    required super.mealType,
    required super.foodName,
    required super.calories,
    required super.proteinGrams,
    required super.fiberGrams,
    required super.waterMl,
    required super.clientUpdatedTimestamp,
  });

  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    return MealLogModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mealType: json['mealType'] as String? ?? 'snack',
      foodName: json['foodName'] as String? ?? '',
      calories: (json['calories'] as num? ?? 0).toDouble(),
      proteinGrams: (json['proteinGrams'] as num? ?? 0).toDouble(),
      fiberGrams: (json['fiberGrams'] as num? ?? 0).toDouble(),
      waterMl: (json['waterMl'] as num? ?? 0).toDouble(),
      clientUpdatedTimestamp: DateTime.parse(
        json['clientUpdatedTimestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'fiberGrams': fiberGrams,
      'waterMl': waterMl,
      'clientUpdatedTimestamp': clientUpdatedTimestamp.toIso8601String(),
    };
  }

  factory MealLogModel.fromEntity(MealLogEntity entity) {
    return MealLogModel(
      id: entity.id,
      timestamp: entity.timestamp,
      mealType: entity.mealType,
      foodName: entity.foodName,
      calories: entity.calories,
      proteinGrams: entity.proteinGrams,
      fiberGrams: entity.fiberGrams,
      waterMl: entity.waterMl,
      clientUpdatedTimestamp: entity.clientUpdatedTimestamp,
    );
  }
}
