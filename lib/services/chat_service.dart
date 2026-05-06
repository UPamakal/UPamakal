import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

/// --------------------------------------------------------------------------
/// ChatService
/// --------------------------------------------------------------------------
/// Handles all Firestore operations for the chat system.
/// --------------------------------------------------------------------------
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create a chat room between two users for a specific listing
  Future<ChatRoomModel> getOrCreateChatRoom({
    required String buyerId,
    required String sellerId,
    required String listingId,
    required String listingTitle,
  }) async {
    // Check for existing room
    final query = await _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: buyerId)
        .where('listingId', isEqualTo: listingId)
        .get();

    for (var doc in query.docs) {
      final room = ChatRoomModel.fromFirestore(doc.data(), doc.id);
      if (room.participants.contains(sellerId)) {
        return room;
      }
    }

    // Create new room if none exists
    final newRoomRef = _firestore.collection('chat_rooms').doc();
    final newRoom = ChatRoomModel(
      id: newRoomRef.id,
      participants: [buyerId, sellerId],
      listingId: listingId,
      listingTitle: listingTitle,
      unreadCounts: {buyerId: 0, sellerId: 0},
    );

    await newRoomRef.set(newRoom.toFirestore());
    return newRoom;
  }

  /// Send a message in a chat room
  Future<void> sendMessage(MessageModel message) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore
        .collection('chat_rooms')
        .doc(message.chatRoomId)
        .collection('messages')
        .doc();
    
    batch.set(msgRef, message.toFirestore());

    // Update chat room with last message and increment unread count for receiver
    final roomRef = _firestore.collection('chat_rooms').doc(message.chatRoomId);
    batch.update(roomRef, {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.${message.receiverId}': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Listen to messages in a chat room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Listen to chat rooms for a specific user
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Mark messages as read in a chat room
  Future<void> markAsRead(String chatRoomId, String userId) async {
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'unreadCounts.$userId': 0,
    });
  }
}
