import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

class PantryVisionService {
  final String _base = FirebaseConfig.backendUrl;

  Future<String?> _token() async =>
      await FirebaseAuth.instance.currentUser?.getIdToken();

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  /// Send a base64-encoded JPEG image to the backend.
  /// Returns a list of detected products: [{name, quantity, unit}]
  Future<List<Map<String, dynamic>>> analyzePantryPhoto(String base64Image) async {
    final response = await http.post(
      Uri.parse('$_base/api/pantry/analyze-photo'),
      headers: await _headers(),
      body: jsonEncode({'imageBase64': base64Image}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      throw Exception(body['error'] ?? 'Ошибка анализа фото');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>? ?? [];
    return products.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
