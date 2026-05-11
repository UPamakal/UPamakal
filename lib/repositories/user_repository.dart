import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// --------------------------------------------------------------------------
/// UserRepository
/// --------------------------------------------------------------------------
/// Owns all Firestore reads and writes for the `users` collection.
/// This keeps [AuthService] focused purely on authentication while this
/// class handles persistence — a clean separation of concerns per MVVM.
///
/// Firestore document structure  →  `users/{uid}`
/// {
///   uid:           String   (Firebase Auth UID)
///   email:         String?
///   displayName:   String?
///   photoURL:      String?
///   emailVerified: bool
///   fcmToken:      String?
///   createdAt:     Timestamp
///   favorites:     List<String>   (itemIds — ready for a favorites feature)
/// }
/// --------------------------------------------------------------------------
class UserRepository {
  final FirebaseFirestore _firestore;

  /// Top-level collection reference.
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---- Write ---------------------------------------------------------------

  /// Creates a new user document in Firestore.
  ///
  /// Called once — right after [FirebaseAuth.createUserWithEmailAndPassword]
  /// or on the very first Google Sign-In for a given account.
  /// Sets [createdAt] to the server timestamp and seeds an empty [favorites]
  /// list so later array-union operations never fail on a missing field.
  Future<void> createUserDocument(UserModel user) async {
    await _users.doc(user.uid).set({
      ...user.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'favorites': [],
    });
  }

  /// Upserts the mutable fields of an existing user document.
  ///
  /// Safe to call on every Google Sign-In (the user may already exist).
  /// Uses [SetOptions(merge: true)] so only the listed fields are touched —
  /// `createdAt` and `favorites` are never overwritten.
  Future<void> updateUserDocument(UserModel user) async {
    await _users.doc(user.uid).set(
      {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        if (user.fcmToken != null) 'fcmToken': user.fcmToken,
      },
      SetOptions(merge: true),
    );
  }

  // ---- Read ----------------------------------------------------------------

  /// Fetches a user document by UID. Returns `null` if not found.
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.data()!);
  }

  /// Returns `true` if a document for [uid] already exists in Firestore.
  /// Used to distinguish new Google Sign-Ins from returning users.
  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  // ---- Favorites -----------------------------------------------------------
  // These stubs are ready to wire up once the favorites feature is built.

  /// Adds [itemId] to the user's `favorites` array (no duplicates via
  /// Firestore's [FieldValue.arrayUnion]).
  Future<void> addFavorite({
    required String uid,
    required String itemId,
  }) async {
    await _users.doc(uid).update({
      'favorites': FieldValue.arrayUnion([itemId]),
    });
  }

  /// Removes [itemId] from the user's `favorites` array.
  Future<void> removeFavorite({
    required String uid,
    required String itemId,
  }) async {
    await _users.doc(uid).update({
      'favorites': FieldValue.arrayRemove([itemId]),
    });
  }

  /// Streams the live favorites list for [uid].
  /// UI widgets can [StreamBuilder] directly on this for real-time updates.
  Stream<List<String>> favoritesStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return [];
      final data = doc.data()!;
      final raw = data['favorites'];
      if (raw is List) return List<String>.from(raw);
      return <String>[];
    });
  }
}