import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import '../models/shopping_list.dart';

class ShoppingListService {
  final String _base = FirebaseConfig.backendUrl;

  Future<String?> _token() async => await FirebaseAuth.instance.currentUser?.getIdToken();

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  Future<ShoppingList> createList({
    required String familyId,
    List<Map<String, dynamic>> items = const [],
    List<String> recipeIds = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/shopping-lists'),
      headers: await _headers(),
      body: jsonEncode({'familyId': familyId, 'items': items, 'recipeIds': recipeIds}),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Ошибка создания списка');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ShoppingList.fromMap(data['id'] as String, {'familyId': familyId, ...data});
  }

  Future<List<ShoppingList>> getLists(String familyId) async {
    final response = await http.get(
      Uri.parse('$_base/api/shopping-lists/$familyId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) throw Exception('Ошибка загрузки списков');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => ShoppingList.fromMap(e['id'] as String, e as Map<String, dynamic>)).toList();
  }

  Future<void> toggleItem(String listId, int index, bool checked) async {
    await http.put(
      Uri.parse('$_base/api/shopping-lists/$listId/items/$index'),
      headers: await _headers(),
      body: jsonEncode({'checked': checked}),
    );
  }

  Future<void> deleteList(String listId) async {
    await http.delete(
      Uri.parse('$_base/api/shopping-lists/$listId'),
      headers: await _headers(),
    );
  }
}
