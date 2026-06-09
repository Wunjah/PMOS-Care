import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/repositories/meal_log_repository.dart';
import '../../data/datasources/meal_log_local_datasource.dart';
import '../../data/datasources/meal_log_remote_datasource.dart';
import '../../data/repositories/meal_log_repository_impl.dart';

class FoodItem {
  final String id;
  final String name;
  final String localName;
  final String category;
  final String suitability;
  final String explanation;

  const FoodItem({
    required this.id,
    required this.name,
    required this.localName,
    required this.category,
    required this.suitability,
    required this.explanation,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        localName: json['local_name'] as String,
        category: json['category'] as String,
        suitability: json['pmos_suitability'] as String,
        explanation: json['explanation'] as String,
      );
}

class AdviceCard {
  final String id;
  final String title;
  final String body;
  final List<String> foodExamples;

  const AdviceCard({
    required this.id,
    required this.title,
    required this.body,
    required this.foodExamples,
  });

  factory AdviceCard.fromJson(Map<String, dynamic> json) => AdviceCard(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        foodExamples: List<String>.from(json['food_examples'] as List? ?? []),
      );
}

class AdviceSection {
  final String id;
  final String title;
  final String description;
  final List<AdviceCard> cards;

  const AdviceSection({
    required this.id,
    required this.title,
    required this.description,
    required this.cards,
  });

  factory AdviceSection.fromJson(Map<String, dynamic> json) => AdviceSection(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        cards: (json['cards'] as List)
            .map((c) => AdviceCard.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

final foodsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/cameroonian_foods.json');
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  return (data['foods'] as List)
      .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
      .toList();
});

final dietaryAdviceProvider = FutureProvider<List<AdviceSection>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/dietary_advice.json');
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  return (data['sections'] as List)
      .map((s) => AdviceSection.fromJson(s as Map<String, dynamic>))
      .toList();
});

// Meal Caching & Sync Providers
final mealHiveBoxProvider = Provider((ref) {
  return Hive.box('pmos_diet_box');
});

final mealLocalDataSourceProvider = Provider((ref) {
  return MealLogLocalDataSourceImpl(ref.watch(mealHiveBoxProvider));
});

final mealRemoteDataSourceProvider = Provider((ref) {
  return MealLogRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final mealRepositoryProvider = Provider((ref) {
  return MealLogRepositoryImpl(
    remoteDataSource: ref.watch(mealRemoteDataSourceProvider),
    localDataSource: ref.watch(mealLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

class MealLogState {
  final bool isLoading;
  final List<MealLogEntity> mealLogs;
  final String? errorMessage;

  MealLogState({
    required this.isLoading,
    required this.mealLogs,
    this.errorMessage,
  });

  MealLogState copyWith({
    bool? isLoading,
    List<MealLogEntity>? mealLogs,
    String? errorMessage,
  }) {
    return MealLogState(
      isLoading: isLoading ?? this.isLoading,
      mealLogs: mealLogs ?? this.mealLogs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MealLogNotifier extends StateNotifier<MealLogState> {
  final MealLogRepository _repository;

  MealLogNotifier({required MealLogRepository repository})
      : _repository = repository,
        super(MealLogState(isLoading: false, mealLogs: [])) {
    loadMealLogs();
  }

  Future<void> loadMealLogs() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.syncOfflineData();
      final list = await _repository.getMealLogs();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = MealLogState(isLoading: false, mealLogs: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load meal logs: $e');
    }
  }

  Future<void> addMealLog({
    required String mealType,
    required String foodName,
    required double calories,
    required double proteinGrams,
    required double fiberGrams,
    required double waterMl,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final entity = MealLogEntity(
        id: id,
        timestamp: date,
        mealType: mealType,
        foodName: foodName,
        calories: calories,
        proteinGrams: proteinGrams,
        fiberGrams: fiberGrams,
        waterMl: waterMl,
        clientUpdatedTimestamp: DateTime.now(),
      );
      await _repository.saveMealLog(entity);
      await loadMealLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save meal log: $e');
      rethrow;
    }
  }

  Future<void> removeMealLog(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteMealLog(id);
      await loadMealLogs();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete meal log: $e');
    }
  }
}

final mealLogStateNotifierProvider = StateNotifierProvider<MealLogNotifier, MealLogState>((ref) {
  return MealLogNotifier(repository: ref.watch(mealRepositoryProvider));
});
