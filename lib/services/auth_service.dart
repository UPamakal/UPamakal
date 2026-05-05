import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// --------------------------------------------------------------------------
/// AuthService
/// --------------------------------------------------------------------------
/// Data-access layer for authentication.  This is the only class
/// in the application that talks directly to Firebase Auth or
/// [GoogleSignIn].  ViewModels delegate to this service and never import
/// Firebase packages themselves — keeping the architecture cleanly
/// separated per MVVM.
///
/// Every public method returns domain objects or throws descriptive
/// exceptions so callers never see raw Firebase errors.
/// --------------------------------------------------------------------------
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Creates an [AuthService].  Parameters are optional so the default
  /// Firebase / Google Sign-In instances are used in production, but
  /// tests or mocks can inject alternatives.
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();
  // ---- Streams ------------------------------------------------------------
  /// Exposes Firebase's auth state as a stream of domain [UserModel]
  /// instances.  Views never see [FirebaseAuth.instance.authStateChanges]
  /// directly — they observe the ViewModel which pipes this stream.
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
  /// Returns the newly created [UserModel].
  /// Throws [FirebaseAuthException] on failure (handled by ViewModel).
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Optionally send email verification
    await credential.user?.sendEmailVerification();
    return UserModel.fromFirebaseUser(credential.user!);
  }

  /// Signs in an existing user with email and password.
  /// Returns the authenticated [UserModel].
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

  /// Sends a password reset email to the given address.
  /// Completes successfully even if the email is not registered
  /// (prevents user enumeration).
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // ---- Google Sign-In -----------------------------------------------------
  /// Initiates the platform-native Google Sign-In flow, then exchanges
  /// the Google credentials for a Firebase credential.
  /// Returns the authenticated [UserModel].
  /// Throws if the user cancels the flow or if an error occurs.
  Future<UserModel> signInWithGoogle() async {
    // 1. Trigger the Google Sign-In UI
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    // 2. User cancelled the flow — throw a descriptive exception
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
