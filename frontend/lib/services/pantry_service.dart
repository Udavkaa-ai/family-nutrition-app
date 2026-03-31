import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pantry_item.dart';

class PantryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Real-time stream of pantry items for the given family.
  Stream<List<PantryItem>> itemsStream(String familyId) {
    return _db
        .collection('pantry')
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return <PantryItem>[];
      final items = snap.docs.first.data()['items'] as Map<String, dynamic>? ?? {};
      return items.entries
          .map((e) => PantryItem.fromMap(e.key, e.value as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<DocumentReference> _getPantryRef(String familyId) async {
    final snap = await _db
        .collection('pantry')
        .where('familyId', '==', familyId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return snap.docs.first.reference;
    final ref = _db.collection('pantry').doc();
    await ref.set({'familyId': familyId, 'items': {}, 'updatedAt': FieldValue.serverTimestamp()});
    return ref;
  }

  Future<void> addItem(String familyId, PantryItem item) async {
    final ref = await _getPantryRef(familyId);
    await ref.update({
      'items.${item.id}': item.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(String familyId, PantryItem item) async {
    final ref = await _getPantryRef(familyId);
    await ref.update({
      'items.${item.id}.name': item.name,
      'items.${item.id}.quantity': item.quantity,
      'items.${item.id}.unit': item.unit,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String familyId, String itemId) async {
    final ref = await _getPantryRef(familyId);
    await ref.update({
      'items.$itemId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
