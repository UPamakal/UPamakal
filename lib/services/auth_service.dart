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
/// FIXED: Email/password sign-up now accepts a display name from userData.
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

    // Base user from Firebase
    UserModel user = UserModel.fromFirebaseUser(credential.user!);

    // Merge any extra fields (including displayName)
    if (userData != null) {
      user = user.copyWith(
        displayName: userData['displayName'] as String? ?? user.displayName,
        userType: userData['userType'] as String?,
        course: userData['course'] as String?,
        yearLevel: userData['yearLevel'] as String?,
        communityRole: userData['communityRole'] as String?,
        communitySince: userData['communitySince'] as int?,
      );
    }

    // Fallback: if displayName is still null, derive from email
    if (user.displayName == null || user.displayName!.isEmpty) {
      user = user.copyWith(displayName: email.trim().split('@').first);
    }

    await _userRepository.createUserDocument(user);
    return user;
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

  // ---- Google Sign-In -----------------------------------------------------

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
      await _userRepository.createUserDocument(user);
      await _userRepository.setProfileCompletionAttempts(user.uid, 0);
      return (user, true, true);
    } else {
      final existingUser = await _userRepository.getUserById(user.uid);
      if (existingUser?.userType != null) {
        return (user, false, false);
      }
      final attempts = await _userRepository.getProfileCompletionAttempts(user.uid);
      await _userRepository.updateUserDocument(user);
      if (attempts >= 3) {
        return (user, false, false);
      }
      await _userRepository.incrementProfileCompletionAttempts(user.uid);
      return (user, true, attempts == 0);
    }
  }

  // ---- Profile Completion ------------------------------------------------

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
      profileCompletedAt: DateTime.now(),
    );

    await _userRepository.updateUserDocument(updatedUser);
    await _userRepository.resetProfileCompletionAttempts(userId);
    return updatedUser;
  }

  Future<bool> hasCompleteProfile(String userId) async {
    final user = await _userRepository.getUserById(userId);
    if (user?.userType != null) return true;
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