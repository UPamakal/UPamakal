/// --------------------------------------------------------------------------
/// UserModel
/// --------------------------------------------------------------------------
/// A lightweight, immutable data class that represents an authenticated
/// user within the UPamakal domain. It decouples the rest of the app from
/// Firebase's [User] type so that the UI layer never directly depends on
/// Firebase objects — a key tenet of MVVM.
///
/// Firestore document:  `users/{uid}`
/// Fields added for future features:
///   • [createdAt]  — when the account was first created (set server-side)
///   • [favorites]  — list of item IDs the user has saved
/// --------------------------------------------------------------------------
class UserModel {
  /// Firebase Auth UID — stable across sessions.
  final String uid;

  /// User's email address (nullable for phone-only or anonymous auth).
  final String? email;

  /// Display name, often populated by Google Sign-In.
  final String? displayName;

  /// Profile photo URL, often populated by Google Sign-In.
  final String? photoURL;

  /// Whether the email has been verified.
  final bool emailVerified;

  /// FCM token for push notifications.
  final String? fcmToken;

  /// Timestamp of when the Firestore document was first created.
  /// Populated by [UserRepository] via [FieldValue.serverTimestamp()].
  /// Will be `null` when the model is built from Firebase Auth alone
  /// (e.g. in [authStateChanges]) because Auth carries no Firestore data.
  final DateTime? createdAt;

  /// List of item IDs the user has saved as favourites.
  /// Seeded as an empty list on account creation — ready for the
  /// favourites feature without any schema migration.
  final List<String> favorites;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.fcmToken,
    this.createdAt,
    this.favorites = const [],
  });

  // ---- Factory constructors -----------------------------------------------

  /// Maps a Firebase [User] (from `firebase_auth`) to a domain [UserModel].
  /// This is the only place where the Firebase User type is destructured —
  /// views never see it. Note: [createdAt] and [favorites] are not available
  /// from Firebase Auth; they are populated by [fromFirestore].
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid as String,
      email: firebaseUser.email as String?,
      displayName: firebaseUser.displayName as String?,
      photoURL: firebaseUser.photoURL as String?,
      emailVerified: (firebaseUser.emailVerified as bool?) ?? false,
    );
  }

  /// Builds a [UserModel] from a Firestore document map.
  /// Used by [UserRepository] when reading back a full user profile,
  /// including [createdAt] and [favorites].
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    // Firestore Timestamps need to be converted to DateTime.
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw != null) {
      // Works whether the value is a Firestore Timestamp or already a DateTime.
      try {
        createdAt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        createdAt = null;
      }
    }

    // Safely coerce the favorites list regardless of how it arrives.
    List<String> favorites = [];
    final rawFavs = data['favorites'];
    if (rawFavs is List) {
      favorites = List<String>.from(rawFavs);
    }

    return UserModel(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      createdAt: createdAt,
      favorites: favorites,
    );
  }

  // ---- Serialisation ------------------------------------------------------

  /// Converts this [UserModel] to a plain map suitable for Firestore.
  /// [createdAt] is intentionally excluded — it is set server-side by
  /// [UserRepository] using [FieldValue.serverTimestamp()].
  /// [favorites] is also excluded here and seeded separately in
  /// [UserRepository.createUserDocument] so the list is never accidentally
  /// overwritten by a profile update.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  // ---- Convenience helpers ------------------------------------------------

  /// Returns `true` when a non-empty display name is available.
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Returns `true` when [itemId] is in the user's saved favourites.
  bool isFavorite(String itemId) => favorites.contains(itemId);

  // ---- copyWith -----------------------------------------------------------

  /// Returns a new [UserModel] with the given fields replaced.
  /// Useful when updating state in the ViewModel without a full Firestore
  /// round-trip (e.g. after a local favorites toggle).
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    String? fcmToken,
    DateTime? createdAt,
    List<String>? favorites,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      favorites: favorites ?? this.favorites,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, displayName: $displayName, '
      'emailVerified: $emailVerified, favorites: ${favorites.length})';
}