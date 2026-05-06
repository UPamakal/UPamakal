import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({required AuthService authService})
      : _authService = authService {
    
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      _errorMessage = null;
      notifyListeners();

      debugPrint("🔄 Auth state changed: ${user?.email ?? 'NULL'}");
    });
  }

  // ---------------- Getters ----------------
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------- Error reset ----------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------- Email Sign Up ----------------
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _runWithLoading(() async {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );
    });
  }

  // ---------------- Email Sign In ----------------
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _runWithLoading(() async {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
    });
  }

  // ---------------- Google Sign In ----------------
  Future<bool> signInWithGoogle() async {
    return _runWithLoading(() async {
      await _authService.signInWithGoogle();
    });
  }

  // ---------------- Password Reset ----------------
  Future<bool> sendPasswordResetEmail({required String email}) async {
    return _runWithLoading(() async {
      await _authService.sendPasswordResetEmail(email: email);
    });
  }

  // ---------------- Sign Out ----------------
  Future<void> signOut() async {
    await _runWithLoading(() async {
      await _authService.signOut();

      _user = null;
      notifyListeners();
    });
  }

  // ---------------- Loading wrapper ----------------
  Future<bool> _runWithLoading(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      return true;
    } catch (e) {
      _errorMessage = _parseFirebaseError(e);
      debugPrint("🔥 Auth error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Error parser ----------------
  String _parseFirebaseError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network')) {
      return 'No internet connection.';
    }
    if (message.contains('user-not-found')) {
      return 'No account found.';
    }
    if (message.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    if (message.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (message.contains('email-already-in-use')) {
      return 'Email already exists.';
    }
    if (message.contains('weak-password')) {
      return 'Weak password.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Try again later.';
    }

    return 'Something went wrong.';
  }
}