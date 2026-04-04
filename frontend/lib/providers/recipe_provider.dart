import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

enum RecipeStatus { idle, loading, success, error }

class RecipeProvider extends ChangeNotifier {
  final RecipeService _service;

  List<Recipe> _recipes = [];
  RecipeStatus _status = RecipeStatus.idle;
  String? _errorMessage;

  RecipeProvider({RecipeService? service})
      : _service = service ?? RecipeService();

  List<Recipe> get recipes => _recipes;
  RecipeStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RecipeStatus.loading;

  Future<void> generateRecipes({
    required String familyId,
    required int cookTime,
    required String mealType,
    String wishText = '',
  }) async {
    _status = RecipeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipes = await _service.generateRecipes(
        familyId: familyId,
        cookTime: cookTime,
        mealType: mealType,
        wishText: wishText,
      );
      _status = RecipeStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = RecipeStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadRecipes(String familyId) async {
    _status = RecipeStatus.loading;
    notifyListeners();

    try {
      _recipes = await _service.getRecipes(familyId);
      _status = RecipeStatus.success;
    } catch (e) {
      _errorMessage = 'Не удалось загрузить рецепты';
      _status = RecipeStatus.error;
    }
    notifyListeners();
  }

  Future<void> deleteRecipe(String familyId, String recipeId) async {
    try {
      await _service.deleteRecipe(familyId, recipeId);
      _recipes.removeWhere((r) => r.id == recipeId);
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Не удалось удалить рецепт';
      notifyListeners();
    }
  }

  void reset() {
    _recipes = [];
    _status = RecipeStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
