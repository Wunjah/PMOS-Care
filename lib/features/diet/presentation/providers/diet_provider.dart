import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
