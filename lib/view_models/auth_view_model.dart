import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _needsProfileCompletion = false;
  bool _wasProfileCompletionForced = false;

  AuthViewModel({required AuthService authService})
      : _authService = authService {
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
  bool get needsProfileCompletion => _needsProfileCompletion;
  bool get wasProfileCompletionForced => _wasProfileCompletionForced;

  // ---------------- Error reset ----------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfileCompletionFlag() {
    _needsProfileCompletion = false;
    _wasProfileCompletionForced = false;
    notifyListeners();
  }

  // ---------------- Email Sign Up (UPDATED) ----------------
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,           // NEW parameter
    String? userType,
    String? course,
    String? yearLevel,
    String? communityRole,
    int? communitySince,
  }) async {
    final userData = <String, dynamic>{
      'displayName': displayName,
    };
    if (userType != null) userData['userType'] = userType;
    if (course != null) userData['course'] = course;
    if (yearLevel != null) userData['yearLevel'] = yearLevel;
    if (communityRole != null) userData['communityRole'] = communityRole;
    if (communitySince != null) userData['communitySince'] = communitySince;

    return _runWithLoading(() async {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        userData: userData,
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final (user, needsCompletion, wasForced) = await _authService.signInWithGoogle();
      _user = user;
      _needsProfileCompletion = needsCompletion;
      _wasProfileCompletionForced = wasForced;
      return true;
    } catch (e) {
      _errorMessage = _parseFirebaseError(e);
      debugPrint("🔥 Google Sign-In error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Profile Completion ----------------
  Future<bool> completeProfile({
    required String userType,
    String? course,
    String? yearLevel,
    String? communityRole,
    int? communitySince,
  }) async {
    if (_user == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return false;
    }

    return _runWithLoading(() async {
      final updatedUser = await _authService.completeProfile(
        userId: _user!.uid,
        userType: userType,
        course: course,
        yearLevel: yearLevel,
        communityRole: communityRole,
        communitySince: communitySince,
      );
      _user = updatedUser;
      _needsProfileCompletion = false;
      _wasProfileCompletionForced = false;
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
      _needsProfileCompletion = false;
      _wasProfileCompletionForced = false;
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
    if (message.contains('popup-closed-by-user')) {
      return 'Google Sign-In was cancelled.';
    }

    return 'Something went wrong.';
  }
}