import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import '../models/meal_plan.dart';

class MealPlanService {
  final String _base = FirebaseConfig.backendUrl;

  Future<String?> _token() async => await FirebaseAuth.instance.currentUser?.getIdToken();

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  Future<MealPlan> generateMealPlan({
    required String familyId,
    required int days,
    required int budgetRub,
    required int maxCookMinutes,
    required String mode,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/meal-plan/generate'),
      headers: await _headers(),
      body: jsonEncode({
        'familyId': familyId,
        'days': days,
        'budgetRub': budgetRub,
        'maxCookMinutes': maxCookMinutes,
        'mode': mode,
      }),
    );

    if (response.statusCode != 200) {
      final err = (jsonDecode(response.body) as Map<String, dynamic>?)?['error']
          ?? 'Ошибка генерации плана';
      throw Exception(err);
    }

    return MealPlan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
