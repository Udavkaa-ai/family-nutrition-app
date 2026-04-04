import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import '../models/spoonacular_recipe.dart';

class SpoonacularService {
  final String _base = FirebaseConfig.backendUrl;

  Future<String?> _token() async =>
      await FirebaseAuth.instance.currentUser?.getIdToken();

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  /// Search Spoonacular recipes by query string.
  Future<List<SpoonacularRecipe>> searchRecipes(String query,
      {int number = 10}) async {
    final uri = Uri.parse('$_base/api/spoonacular/search').replace(
      queryParameters: {
        'query': query.isEmpty ? 'healthy' : query,
        'number': number.toString(),
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      throw Exception(body['error'] ?? 'Ошибка поиска рецептов');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['recipes'] as List<dynamic>? ?? [];
    return list
        .map((e) => SpoonacularRecipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
