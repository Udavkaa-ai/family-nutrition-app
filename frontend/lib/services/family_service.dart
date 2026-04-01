import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_member.dart';

class FamilyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Real-time stream of the current user's familyId from Firestore.
  Stream<String?> get familyIdStream {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => s.data()?['familyId'] as String?);
  }

  /// Real-time stream of family members for a given familyId.
  Stream<List<FamilyMember>> membersStream(String familyId) {
    return _db
        .collection('family_members')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FamilyMember.fromFirestore(d)).toList());
  }

  /// Fetch family data (name, inviteCode) once.
  Future<Map<String, dynamic>?> getFamily(String familyId) async {
    final doc = await _db.collection('families').doc(familyId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Add a new family member profile.
  Future<String> addMember(FamilyMember member) async {
    final ref = await _db.collection('family_members').add(member.toMap());
    return ref.id;
  }

  /// Update an existing family member profile.
  Future<void> updateMember(String memberId, Map<String, dynamic> updates) async {
    await _db.collection('family_members').doc(memberId).update(updates);
  }

  /// Delete a family member profile.
  Future<void> deleteMember(String memberId) async {
    await _db.collection('family_members').doc(memberId).delete();
  }
}
