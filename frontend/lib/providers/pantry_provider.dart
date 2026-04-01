import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';

class PantryProvider extends ChangeNotifier {
  final PantryService _service;

  List<PantryItem> _items = [];
  bool _loading = false;
  String? _errorMessage;
  StreamSubscription<List<PantryItem>>? _sub;

  PantryProvider({PantryService? service}) : _service = service ?? PantryService();

  List<PantryItem> get items => _items;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// Call when family is known. Starts real-time sync.
  void startListening(String familyId) {
    _sub?.cancel();
    _sub = _service.itemsStream(familyId).listen(
      (items) {
        _items = items;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Ошибка синхронизации кладовой';
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _items = [];
    notifyListeners();
  }

  Future<bool> addItem(String familyId, {
    required String name,
    required double quantity,
    required String unit,
  }) async {
    _clearError();
    try {
      final id = _generateId();
      await _service.addItem(
        familyId,
        PantryItem(id: id, name: name.trim(), quantity: quantity, unit: unit.trim()),
      );
      return true;
    } catch (_) {
      _errorMessage = 'Не удалось добавить продукт';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(String familyId, PantryItem item) async {
    _clearError();
    try {
      await _service.updateItem(familyId, item);
      return true;
    } catch (_) {
      _errorMessage = 'Не удалось обновить продукт';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String familyId, String itemId) async {
    _clearError();
    try {
      await _service.deleteItem(familyId, itemId);
      return true;
    } catch (_) {
      _errorMessage = 'Не удалось удалить продукт';
      notifyListeners();
      return false;
    }
  }

  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(20, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
