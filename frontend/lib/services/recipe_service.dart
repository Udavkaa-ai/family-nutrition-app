import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import '../models/recipe.dart';

class RecipeService {
  final String _base = FirebaseConfig.backendUrl;

  Future<String?> _token() async => await FirebaseAuth.instance.currentUser?.getIdToken();

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  /// Generate 4 AI recipes for the family.
  Future<List<Recipe>> generateRecipes({
    required String familyId,
    required int cookTime,
    required String mealType,
    String wishText = '',
    List<String> selectedMemberIds = const [],
  }) async {
    final body = <String, dynamic>{
      'familyId': familyId,
      'cookTime': cookTime,
      'mealType': mealType,
      'wishText': wishText,
    };
    if (selectedMemberIds.isNotEmpty) body['selectedMemberIds'] = selectedMemberIds;

    final response = await http.post(
      Uri.parse('$_base/api/recipes/generate'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body)['error'] ?? 'Ошибка генерации рецептов';
      throw Exception(err);
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch saved recipes for the family.
  Future<List<Recipe>> getRecipes(String familyId) async {
    final response = await http.get(
      Uri.parse('$_base/api/recipes/$familyId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) throw Exception('Ошибка загрузки рецептов');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch only saved (Ням-ням!) recipes for the family.
  Future<List<Recipe>> getSavedRecipes(String familyId) async {
    final response = await http.get(
      Uri.parse('$_base/api/recipes/$familyId?saved=true'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception('Ошибка загрузки истории');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Mark a recipe as saved (add to История).
  Future<void> saveRecipe(String familyId, String recipeId) async {
    final response = await http.patch(
      Uri.parse('$_base/api/recipes/$familyId/$recipeId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      final err = (jsonDecode(response.body) as Map<String, dynamic>?)?['error']
          ?? 'Ошибка сохранения';
      throw Exception(err);
    }
  }

  /// Delete a recipe.
  Future<void> deleteRecipe(String familyId, String recipeId) async {
    await http.delete(
      Uri.parse('$_base/api/recipes/$familyId/$recipeId'),
      headers: await _headers(),
    );
  }
}
