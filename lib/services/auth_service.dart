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
/// After every successful sign-up or first-time Google Sign-In it delegates
/// to [UserRepository] to persist a matching Firestore document. This keeps
/// all Firestore logic out of this class while still guaranteeing that every
/// authenticated user has a corresponding `users/{uid}` document.
///
/// ViewModels delegate to this service and never import Firebase packages
/// themselves — keeping the architecture cleanly separated per MVVM.
/// --------------------------------------------------------------------------
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  /// Creates an [AuthService].
  /// [userRepository] defaults to a standard [UserRepository] instance so
  /// callers only need to inject it during testing.
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

  /// Exposes Firebase's auth state as a stream of domain [UserModel] instances.
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  /// Returns the currently signed-in user (or null).
  UserModel? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return UserModel.fromFirebaseUser(firebaseUser);
  }

  // ---- Email / Password Authentication ------------------------------------

  /// Registers a new user with email and password, then creates a matching
  /// Firestore document via [UserRepository.createUserDocument].
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Send email verification immediately after account creation.
    await credential.user?.sendEmailVerification();

    final user = UserModel.fromFirebaseUser(credential.user!);

    // Persist user profile to Firestore. If this write fails the caller
    // receives the exception — the Firebase Auth account still exists so
    // a retry or subsequent sign-in can re-attempt the Firestore write.
    await _userRepository.createUserDocument(user);

    return user;
  }

  /// Signs in an existing user with email and password.
  /// No Firestore write needed here — the document was created at sign-up.
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

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // ---- Google Sign-In -----------------------------------------------------

  /// Exchanges Google credentials for a Firebase credential, then either
  /// creates a new Firestore document (first sign-in) or updates mutable
  /// profile fields (returning user).
  Future<UserModel> signInWithGoogle() async {
    // 1. Trigger the Google Sign-In UI.
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // 2. User cancelled the flow.
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by the user.');
    }

    // 3. Obtain the authentication tokens from Google.
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 4. Create a Firebase credential from the Google tokens.
    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 5. Sign into Firebase with the Google credential.
    final userCredential =
        await _firebaseAuth.signInWithCredential(oauthCredential);
    final user = UserModel.fromFirebaseUser(userCredential.user!);

    // 6. Persist to Firestore.
    //    • New user  → create a full document (sets createdAt + empty favorites)
    //    • Returning → merge-update only the mutable profile fields so that
    //      createdAt and favorites are never overwritten.
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (isNewUser) {
      await _userRepository.createUserDocument(user);
    } else {
      await _userRepository.updateUserDocument(user);
    }

    return user;
  }

  // ---- Sign Out -----------------------------------------------------------

  /// Signs out from both Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}