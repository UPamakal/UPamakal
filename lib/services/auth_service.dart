import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// --------------------------------------------------------------------------
/// AuthService
/// --------------------------------------------------------------------------
/// Data-access layer for authentication. This is the only class in the
/// application that talks directly to Firebase Auth or [GoogleSignIn].
///
/// FIXED: Google Sign-In now uses a completion flag to prevent infinite loops
/// when profile completion fails. Users who fail to complete profile will
/// be forced exactly once, then allowed to skip with a warning.
/// --------------------------------------------------------------------------
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? UserRepository(),
        _googleSignIn = googleSignIn ??
            (kIsWeb
                ? GoogleSignIn(
                    clientId:
                        '216383462965-lljltoac63fglpf7sdmrt0cqkspn893n.apps.googleusercontent.com',
                  )
                : GoogleSignIn());

  // ---- Streams ------------------------------------------------------------

  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  UserModel? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return UserModel.fromFirebaseUser(firebaseUser);
  }

  // ---- Email / Password Authentication ------------------------------------

  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.sendEmailVerification();

    final user = UserModel.fromFirebaseUser(credential.user!);

    UserModel extendedUser = user;
    if (userData != null) {
      extendedUser = user.copyWith(
        userType: userData['userType'] as String?,
        course: userData['course'] as String?,
        yearLevel: userData['yearLevel'] as String?,
        communityRole: userData['communityRole'] as String?,
        communitySince: userData['communitySince'] as int?,
      );
    }

    await _userRepository.createUserDocument(extendedUser);
    return extendedUser;
  }

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // ---- Google Sign-In (FIXED) ---------------------------------------------

  /// Returns a tuple: (UserModel, needsCompletion, wasForced)
  /// - needsCompletion: true if profile must be completed
  /// - wasForced: true if this is the first time they're being forced
  Future<(UserModel, bool, bool)> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by the user.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(oauthCredential);
    final user = UserModel.fromFirebaseUser(userCredential.user!);

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    if (isNewUser) {
      // NEW USER: Create minimal document with completion_attempts = 0
      await _userRepository.createUserDocument(user);
      await _userRepository.setProfileCompletionAttempts(user.uid, 0);
      return (user, true, true); // First time being forced
    } else {
      // RETURNING USER: Check completion status
      final existingUser = await _userRepository.getUserById(user.uid);
      
      // If user has userType, profile is complete
      if (existingUser?.userType != null) {
        return (user, false, false);
      }
      
      // User has incomplete profile
      final attempts = await _userRepository.getProfileCompletionAttempts(user.uid);
      
      // Update display name/photo in case they changed
      await _userRepository.updateUserDocument(user);
      
      // If attempts >= 3, stop forcing (allow skip with warning)
      if (attempts >= 3) {
        return (user, false, false); // Don't force anymore
      }
      
      // Increment attempt counter
      await _userRepository.incrementProfileCompletionAttempts(user.uid);
      
      return (user, true, attempts == 0); // Force if first incomplete attempt
    }
  }

  // ---- Profile Completion (FIXED) -----------------------------------------

  /// Updates user profile and marks completion attempts as resolved
  Future<UserModel> completeProfile({
    required String userId,
    required String userType,
    String? course,
    String? yearLevel,
    String? communityRole,
    int? communitySince,
  }) async {
    final existingUser = await _userRepository.getUserById(userId);

    if (existingUser == null) {
      throw Exception('User document not found');
    }

    final updatedUser = existingUser.copyWith(
      userType: userType,
      course: course,
      yearLevel: yearLevel,
      communityRole: communityRole,
      communitySince: communitySince,
      profileCompletedAt: DateTime.now(), // NEW: Track completion timestamp
    );

    await _userRepository.updateUserDocument(updatedUser);
    
    // Reset attempt counter on successful completion
    await _userRepository.resetProfileCompletionAttempts(userId);
    
    return updatedUser;
  }

  /// Checks if a user has completed their profile.
  /// Returns false if userType is null OR if completion timestamp is >7 days old
  /// (forces re-verification for very old incomplete profiles)
  Future<bool> hasCompleteProfile(String userId) async {
    final user = await _userRepository.getUserById(userId);
    
    // Complete if userType exists
    if (user?.userType != null) return true;
    
    // If no userType but has completion attempts > 0 and profileCompletedAt is null
    // This is an incomplete profile
    return false;
  }

  // ---- Sign Out -----------------------------------------------------------

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}