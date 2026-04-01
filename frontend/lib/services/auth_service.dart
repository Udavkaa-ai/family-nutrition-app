import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Lazy getters — only accessed when a method is called,
  // safe to instantiate before Firebase.initializeApp().
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Register a new user and create their Firestore document.
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    await user.updateDisplayName(name);

    // Firestore write is best-effort: auth succeeds even if Firestore
    // isn't set up yet or security rules block the write.
    try {
      await _db.collection('users').doc(user.uid).set({
        'email': email,
        'name': name,
        'familyId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return user;
  }

  /// Sign in with email and password.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign out.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
