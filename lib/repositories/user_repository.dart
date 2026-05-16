import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// --------------------------------------------------------------------------
/// UserRepository
/// --------------------------------------------------------------------------
/// Owns all Firestore reads and writes for the `users` collection.
///
/// NEW: Added profile completion attempt tracking to prevent infinite loops.
/// --------------------------------------------------------------------------
class UserRepository {
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
      
  CollectionReference<Map<String, dynamic>> get _metadata =>
      _firestore.collection('user_metadata');

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---- Write ---------------------------------------------------------------

  Future<void> createUserDocument(UserModel user) async {
    await _users.doc(user.uid).set({
      ...user.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'favorites': [],
    });
  }

  Future<void> updateUserDocument(UserModel user) async {
    await _users.doc(user.uid).set(
      {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        if (user.fcmToken != null) 'fcmToken': user.fcmToken,
        if (user.userType != null) 'userType': user.userType,
        if (user.course != null) 'course': user.course,
        if (user.yearLevel != null) 'yearLevel': user.yearLevel,
        if (user.communityRole != null) 'communityRole': user.communityRole,
        if (user.communitySince != null) 'communitySince': user.communitySince,
        if (user.profileCompletedAt != null) 'profileCompletedAt': user.profileCompletedAt,
      },
      SetOptions(merge: true),
    );
  }

  // ---- Profile Completion Attempt Tracking (NEW) --------------------------

  Future<void> setProfileCompletionAttempts(String uid, int attempts) async {
    await _metadata.doc(uid).set({
      'profile_completion_attempts': attempts,
      'last_attempt_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> getProfileCompletionAttempts(String uid) async {
    final doc = await _metadata.doc(uid).get();
    if (!doc.exists || doc.data() == null) return 0;
    return (doc.data()!['profile_completion_attempts'] as int?) ?? 0;
  }

  Future<void> incrementProfileCompletionAttempts(String uid) async {
    final current = await getProfileCompletionAttempts(uid);
    await setProfileCompletionAttempts(uid, current + 1);
  }

  Future<void> resetProfileCompletionAttempts(String uid) async {
    await _metadata.doc(uid).delete(); // Clean up on success
  }

  // ---- Read ----------------------------------------------------------------

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.data()!);
  }

  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  // ---- Favorites -----------------------------------------------------------

  Future<void> addFavorite({
    required String uid,
    required String itemId,
  }) async {
    await _users.doc(uid).update({
      'favorites': FieldValue.arrayUnion([itemId]),
    });
  }

  Future<void> removeFavorite({
    required String uid,
    required String itemId,
  }) async {
    await _users.doc(uid).update({
      'favorites': FieldValue.arrayRemove([itemId]),
    });
  }

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