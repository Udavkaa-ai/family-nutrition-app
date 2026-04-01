import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListItem {
  final String name;
  final double quantity;
  final String unit;
  final bool checked;

  const ShoppingListItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> m) => ShoppingListItem(
        name: m['name'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        unit: m['unit'] as String? ?? '',
        checked: m['checked'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'checked': checked,
      };

  ShoppingListItem copyWith({bool? checked}) => ShoppingListItem(
        name: name,
        quantity: quantity,
        unit: unit,
        checked: checked ?? this.checked,
      );

  String get displayQuantity {
    final q = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return unit.isEmpty ? q : '$q $unit';
  }
}

class ShoppingList {
  final String id;
  final String familyId;
  final List<ShoppingListItem> items;
  final DateTime? createdAt;

  const ShoppingList({
    required this.id,
    required this.familyId,
    required this.items,
    this.createdAt,
  });

  factory ShoppingList.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return ShoppingList(
      id: id,
      familyId: data['familyId'] as String,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => ShoppingListItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  int get checkedCount => items.where((i) => i.checked).length;
  bool get isComplete => items.isNotEmpty && checkedCount == items.length;
}
