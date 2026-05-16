import 'package:cloud_firestore/cloud_firestore.dart';

class UserActionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Attempt to globally take an action (mine/steal/grab). Returns true if successful (was not taken before).
  Future<bool> takeAction({
    required String listingId,
    required String action, // 'mine', 'steal', 'grab'
  }) async {
    final docRef = _firestore.collection('listings').doc(listingId);
    final fieldName = '${action}Taken';
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;
        final data = doc.data() as Map<String, dynamic>;
        final isTaken = data[fieldName] == true;
        if (isTaken) return false;
        transaction.update(docRef, {fieldName: true});
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Get current global lock status for all actions.
  Future<Map<String, bool>> getActionStatus(String listingId) async {
    final doc = await _firestore.collection('listings').doc(listingId).get();
    if (!doc.exists) return {'mine': false, 'steal': false, 'grab': false};
    final data = doc.data() as Map<String, dynamic>;
    return {
      'mine': data['mineTaken'] == true,
      'steal': data['stealTaken'] == true,
      'grab': data['grabTaken'] == true,
    };
  }

  /// Real-time stream of global lock status.
  Stream<Map<String, bool>> watchActionStatus(String listingId) {
    return _firestore.collection('listings').doc(listingId).snapshots().map((doc) {
      if (!doc.exists) return {'mine': false, 'steal': false, 'grab': false};
      final data = doc.data() as Map<String, dynamic>;
      return {
        'mine': data['mineTaken'] == true,
        'steal': data['stealTaken'] == true,
        'grab': data['grabTaken'] == true,
      };
    });
  }
}