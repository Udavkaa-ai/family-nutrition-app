import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    // Listen to Firebase auth state
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _clearError();
    try {
      await _authService.register(name: name, email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _clearError();
    try {
      await _authService.login(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<bool> resetPassword(String email) async {
    _clearError();
    try {
      await _authService.resetPassword(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    }
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Пароль слишком слабый (минимум 6 символов)';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return 'Ошибка авторизации. Попробуйте ещё раз';
    }
  }
}
