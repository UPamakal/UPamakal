import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Required for platform check
import '../models/user_model.dart';

/// --------------------------------------------------------------------------
/// AuthService
/// --------------------------------------------------------------------------
/// Data-access layer for authentication. This is the only class
/// in the application that talks directly to Firebase Auth or
/// [GoogleSignIn]. ViewModels delegate to this service and never import
/// Firebase packages themselves — keeping the architecture cleanly
/// separated per MVVM.
/// --------------------------------------------------------------------------
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Creates an [AuthService]. 
  /// The constructor now explicitly provides the clientId for Web platforms 
  /// to satisfy the assertion check that was previously causing a crash.
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            (kIsWeb
                ? GoogleSignIn(
                    clientId: '216383462965-lljltoac63fglpf7sdmrt0cqkspn893n.apps.googleusercontent.com',
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
  /// Registers a new user with email and password.
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return UserModel.fromFirebaseUser(credential.user!);
  }

  /// Signs in an existing user with email and password.
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
  /// Exchanges Google credentials for a Firebase credential.
  Future<UserModel> signInWithGoogle() async {
    // 1. Trigger the Google Sign-In UI
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    // 2. User cancelled the flow
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by the user.');
    }
    
    // 3. Obtain the authentication tokens from Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    
    // 4. Create a Firebase credential from the Google tokens
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // 5. Sign into Firebase with the Google credential
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return UserModel.fromFirebaseUser(userCredential.user!);
  }

  // ---- Sign Out -----------------------------------------------------------
  /// Signs out from both Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }
}