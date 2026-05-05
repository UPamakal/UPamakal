import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// --------------------------------------------------------------------------
/// AuthViewModel
/// --------------------------------------------------------------------------
/// ViewModel (MVVM) that mediates between the authentication UI and
/// the [AuthService].  It holds all mutable UI state (loading flags,
/// error messages, current user) and notifies listeners via
/// [ChangeNotifier] so the view rebuilds reactively.
///
/// Key responsibilities:
///   - Expose the current [UserModel] and a convenient [isAuthenticated]
///     getter for the View layer.
///   - Accept user actions (sign up, sign in, Google sign-in, reset
///     password, sign out) and delegate to [AuthService].
///   - Translate [Exception]s into human-readable error messages stored
///     in [errorMessage].
/// --------------------------------------------------------------------------
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  // ---- Observable state ---------------------------------------------------
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  AuthViewModel({required AuthService authService})
    : _authService = authService {
    // Listen to Firebase auth state changes and keep local state in sync
    _authService.authStateChanges.listen((user) {
      _user = user;
      _errorMessage = null; // clear any stale error on state change
      notifyListeners();
    });
  }
  // ---- Public getters -----------------------------------------------------
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Clears the error message so the UI can dismiss error banners.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---- Email / Password Sign-Up -------------------------------------------
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

  // ---- Email / Password Sign-In -------------------------------------------
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

  // ---- Google Sign-In -----------------------------------------------------
  Future<bool> signInWithGoogle() async {
    return _runWithLoading(() async {
      await _authService.signInWithGoogle();
    });
  }

  // ---- Password Reset -----------------------------------------------------
  Future<bool> sendPasswordResetEmail({required String email}) async {
    return _runWithLoading(() async {
      await _authService.sendPasswordResetEmail(email: email);
    });
  }

  // ---- Sign Out -----------------------------------------------------------
  Future<void> signOut() async {
    await _runWithLoading(() async {
      await _authService.signOut();
    });
  }

  // ---- Internal helper ----------------------------------------------------
  /// Wraps an async operation with standard loading/error handling.
  /// - Sets _isLoading = true before execution.
  /// - Catches any [Exception], stores a user-friendly message in
  ///   [_errorMessage], and returns false to indicate failure.
  /// - Returns true on success.
  /// - Always calls [notifyListeners] so the UI reacts to state changes.
  Future<bool> _runWithLoading(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseFirebaseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Maps raw Firebase / generic exceptions to human-readable strings
  /// suitable for display in SnackBars or error labels.
  String _parseFirebaseError(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('network-request-failed') ||
        message.contains('network_error')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (message.contains('user-not-found') ||
        message.contains('no user found')) {
      return 'No account found with this email address.';
    }
    if (message.contains('wrong-password') ||
        message.contains('invalid password')) {
      return 'Incorrect password. Please try again.';
    }
    if (message.contains('invalid-email') || message.contains('malformed')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('email-already-in-use') ||
        message.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (message.contains('cancelled')) {
      return 'Sign-in was cancelled.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    // Generic fallback
    return 'Something went wrong. Please try again later.';
  }
}
