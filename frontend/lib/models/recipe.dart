import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  final String name;
  final double quantity;
  final String unit;

  const Ingredient({required this.name, required this.quantity, required this.unit});

  factory Ingredient.fromMap(Map<String, dynamic> m) => Ingredient(
        name: m['name'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unit: m['unit'] as String? ?? '',
      );
}

class Recipe {
  final String id;
  final String familyId;
  final String name;
  final int timeMinutes;
  final String difficulty;
  final String description;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String source;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.familyId,
    required this.name,
    required this.timeMinutes,
    required this.difficulty,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.source,
    this.createdAt,
  });

  factory Recipe.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return Recipe(
      id: id,
      familyId: data['familyId'] as String,
      name: data['name'] as String,
      timeMinutes: (data['timeMinutes'] as num?)?.toInt() ?? 30,
      difficulty: data['difficulty'] as String? ?? 'medium',
      description: data['description'] as String? ?? '',
      ingredients: (data['ingredients'] as List<dynamic>? ?? [])
          .map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
          .toList(),
      instructions: List<String>.from(data['instructions'] ?? []),
      source: data['source'] as String? ?? 'ai',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      Recipe.fromMap(json['id'] as String, json);

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':   return 'Просто';
      case 'medium': return 'Средне';
      case 'hard':   return 'Сложно';
      default:       return difficulty;
    }
  }
}
