import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  UserModel? _user;
  bool _isLoading = false;
  bool _isLoadingProfileData = false;
  String? _errorMessage;
  bool _needsProfileCompletion = false;
  bool _wasProfileCompletionForced = false;

  AuthViewModel({required AuthService authService, UserRepository? userRepository})
      : _authService = authService,
        _userRepository = userRepository ?? UserRepository() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      _errorMessage = null;
      
      // FIXED: Set loading flag BEFORE notifying, so gate sees it before checking profile
      if (user != null) {
        _isLoadingProfileData = true;
      }
      
      notifyListeners();
      debugPrint("🔄 Auth state changed: ${user?.email ?? 'NULL'}");
      
      // Now start the async fetch
      if (user != null) {
        _loadFullProfileFromFirestore(user.uid);
      }
    });
  }

  // ---------------- Getters ----------------
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isLoadingProfileData => _isLoadingProfileData;
  String? get errorMessage => _errorMessage;
  bool get needsProfileCompletion => _needsProfileCompletion;
  bool get wasProfileCompletionForced => _wasProfileCompletionForced;

  // NEW: Manually refresh user data from Firestore (called when needed)
  Future<void> refreshUserFromFirestore() async {
    if (_user == null) return;
    await _loadFullProfileFromFirestore(_user!.uid);
  }

  // ---- Error reset ----------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfileCompletionFlag() {
    _needsProfileCompletion = false;
    _wasProfileCompletionForced = false;
    notifyListeners();
  }

  // NEW: Load full profile data from Firestore and merge with auth user
  Future<void> _loadFullProfileFromFirestore(String uid) async {
    _isLoadingProfileData = true;
    notifyListeners();
    
    try {
      final fullUser = await _userRepository.getUserById(uid);
      if (fullUser != null && _user != null) {
        // Merge Firestore profile data with the basic Firebase user data
        _user = _user!.copyWith(
          displayName: fullUser.displayName ?? _user!.displayName,
          photoURL: fullUser.photoURL ?? _user!.photoURL,
          userType: fullUser.userType,
          course: fullUser.course,
          yearLevel: fullUser.yearLevel,
          communityRole: fullUser.communityRole,
          communitySince: fullUser.communitySince,
          profileCompletedAt: fullUser.profileCompletedAt,
        );
        debugPrint("✅ Loaded full profile for ${_user!.email}");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load full profile from Firestore: $e");
      // Don't treat this as a critical error - user can still use the app
    } finally {
      _isLoadingProfileData = false;
      notifyListeners();
    }
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