/// --------------------------------------------------------------------------
/// UserModel
/// --------------------------------------------------------------------------
/// A lightweight, immutable data class that represents an authenticated
/// user within the UPamakal domain.  It decouples the rest of the app
/// from Firebase's [User] type so that the UI layer never directly
/// depends on Firebase objects — a key tenet of MVVM.
/// --------------------------------------------------------------------------
class UserModel {
  /// Firebase Auth UID — stable across sessions
  final String uid;

  /// User's email address (nullable for phone-only or anonymous auth)
  final String? email;

  /// Display name, often populated by Google Sign-In
  final String? displayName;

  /// Profile photo URL, often populated by Google Sign-In
  final String? photoURL;

  /// Whether the email has been verified
  final bool emailVerified;
  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
  });

  /// Factory constructor that maps a Firebase [User] (from firebase_auth)
  /// to our domain [UserModel].  This is the only place where the
  /// Firebase User type is destructured — views never see it.
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  /// Returns true
  /// when we have a reasonable display name to show.
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
  @override
  String toString() =>
      'UserModel(uid: uid,email:uid, email: uid,email:email, displayName: $displayName)';
}
