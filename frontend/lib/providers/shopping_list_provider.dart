import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../services/shopping_list_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final ShoppingListService _service;

  List<ShoppingList> _lists = [];
  ShoppingList? _active; // currently open list
  bool _loading = false;
  String? _errorMessage;

  ShoppingListProvider({ShoppingListService? service})
      : _service = service ?? ShoppingListService();

  List<ShoppingList> get lists => _lists;
  ShoppingList? get active => _active;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLists(String familyId) async {
    _setLoading(true);
    try {
      _lists = await _service.getLists(familyId);
      if (_lists.isNotEmpty) _active = _lists.first;
    } catch (_) {
      _errorMessage = 'Не удалось загрузить списки покупок';
    }
    _setLoading(false);
  }

  Future<bool> createFromRecipes({
    required String familyId,
    required List<String> recipeIds,
  }) async {
    _setLoading(true);
    try {
      final list = await _service.createList(familyId: familyId, recipeIds: recipeIds);
      _lists.insert(0, list);
      _active = list;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> createManual({
    required String familyId,
    required List<Map<String, dynamic>> items,
  }) async {
    _setLoading(true);
    try {
      final list = await _service.createList(familyId: familyId, items: items);
      _lists.insert(0, list);
      _active = list;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> toggleItem(int index, bool checked) async {
    if (_active == null) return;

    // Optimistic update
    final updatedItems = List<ShoppingListItem>.from(_active!.items);
    updatedItems[index] = updatedItems[index].copyWith(checked: checked);
    _active = ShoppingList(
      id: _active!.id,
      familyId: _active!.familyId,
      items: updatedItems,
      createdAt: _active!.createdAt,
    );
    notifyListeners();

    await _service.toggleItem(_active!.id, index, checked);
  }

  Future<void> deleteList(String listId) async {
    await _service.deleteList(listId);
    _lists.removeWhere((l) => l.id == listId);
    if (_active?.id == listId) _active = _lists.isNotEmpty ? _lists.first : null;
    notifyListeners();
  }

  void setActive(ShoppingList list) {
    _active = list;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
