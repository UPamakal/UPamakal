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
    String chatType = 'listing',
  }) async {
    if (buyerId.isEmpty || sellerId.isEmpty) {
      throw ArgumentError('Both buyerId and sellerId are required.');
    }
    if (buyerId == sellerId) {
      throw ArgumentError('Users cannot start a chat with themselves.');
    }

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
      buyerId: buyerId,
      sellerId: sellerId,
      chatType: chatType,
      createdAt: DateTime.now(),
      unreadCounts: {buyerId: 0, sellerId: 0},
    );

    await newRoomRef.set({
      ...newRoom.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return newRoom;
  }

  /// Send a message in a chat room
  Future<void> sendMessage(MessageModel message) async {
    if (message.chatRoomId.isEmpty ||
        message.senderId.isEmpty ||
        message.receiverId.isEmpty) {
      throw ArgumentError('Message is missing required chat identifiers.');
    }

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
    if (userId.isEmpty) {
      return Stream.value(<ChatRoomModel>[]);
    }

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
    if (chatRoomId.isEmpty || userId.isEmpty) return;

    final roomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    final unreadMessages = await roomRef
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .limit(500)
        .get();

    final batch = _firestore.batch();
    batch.update(roomRef, {
      'unreadCounts.$userId': 0,
    });

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    if (chatRoomId.isEmpty) return null;

    final doc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ChatRoomModel.fromFirestore(doc.data()!, doc.id);
  }
}
