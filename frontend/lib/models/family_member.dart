import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String? id;
  final String familyId;
  final String name;
  final List<String> dietaryPreferences;
  final List<String> dislikedIngredients;
  final List<String> preferredCuisines;
  final String cookingLevel;

  const FamilyMember({
    this.id,
    required this.familyId,
    required this.name,
    this.dietaryPreferences = const [],
    this.dislikedIngredients = const [],
    this.preferredCuisines = const [],
    this.cookingLevel = 'medium',
  });

  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      familyId: data['familyId'] as String,
      name: data['name'] as String,
      dietaryPreferences: List<String>.from(data['dietaryPreferences'] ?? []),
      dislikedIngredients: List<String>.from(data['dislikedIngredients'] ?? []),
      preferredCuisines: List<String>.from(data['preferredCuisines'] ?? []),
      cookingLevel: data['cookingLevel'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'name': name,
        'dietaryPreferences': dietaryPreferences,
        'dislikedIngredients': dislikedIngredients,
        'preferredCuisines': preferredCuisines,
        'cookingLevel': cookingLevel,
        'createdAt': FieldValue.serverTimestamp(),
      };

  FamilyMember copyWith({
    String? name,
    List<String>? dietaryPreferences,
    List<String>? dislikedIngredients,
    List<String>? preferredCuisines,
    String? cookingLevel,
  }) =>
      FamilyMember(
        id: id,
        familyId: familyId,
        name: name ?? this.name,
        dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
        dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
        preferredCuisines: preferredCuisines ?? this.preferredCuisines,
        cookingLevel: cookingLevel ?? this.cookingLevel,
      );
}
