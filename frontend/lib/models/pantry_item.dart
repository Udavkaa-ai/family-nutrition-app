class PantryItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;

  const PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory PantryItem.fromMap(String id, Map<String, dynamic> data) {
    return PantryItem(
      id: id,
      name: data['name'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };

  PantryItem copyWith({String? name, double? quantity, String? unit}) =>
      PantryItem(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
      );

  String get displayQuantity {
    final q = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return unit.isEmpty ? q : '$q $unit';
  }
}
