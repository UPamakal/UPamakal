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

  /// Get an existing chat room, or return an unsaved draft room.
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

    // Do not create a Firestore document until the first message is sent.
    return ChatRoomModel(
      id: '',
      participants: [buyerId, sellerId],
      listingId: listingId,
      listingTitle: listingTitle,
      buyerId: buyerId,
      sellerId: sellerId,
      chatType: chatType,
      createdAt: DateTime.now(),
      unreadCounts: {buyerId: 0, sellerId: 0},
    );
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

  /// Persist a draft room if needed, then send the message.
  Future<ChatRoomModel> sendMessageInRoom({
    required ChatRoomModel room,
    required String senderId,
    required String receiverId,
    required String text,
    String senderName = 'User',
  }) async {
    final trimmedText = text.trim();
    if (senderId.isEmpty || receiverId.isEmpty || trimmedText.isEmpty) {
      throw ArgumentError('Message is missing required data.');
    }

    final batch = _firestore.batch();
    final isDraftRoom = room.id.isEmpty;
    final roomRef = isDraftRoom
        ? _firestore.collection('chat_rooms').doc()
        : _firestore.collection('chat_rooms').doc(room.id);
    final msgRef = roomRef.collection('messages').doc();

    batch.set(msgRef, {
      'chatRoomId': roomRef.id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmedText,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    if (isDraftRoom) {
      batch.set(roomRef, {
        'participants': room.participants,
        'listingId': room.listingId,
        'listingTitle': room.listingTitle,
        'buyerId': room.buyerId,
        'sellerId': room.sellerId,
        'chatType': room.chatType,
        'lastMessage': trimmedText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          for (final participantId in room.participants) participantId: 0,
          receiverId: 1,
        },
      });
    } else {
      batch.update(roomRef, {
        'lastMessage': trimmedText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.$receiverId': FieldValue.increment(1),
      });
    }

    final notifRef = _firestore
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .doc();
    batch.set(notifRef, {
      'type': 'chat_message',
      'title': senderName,
      'body': '${room.listingTitle}: $trimmedText',
      'listingId': room.listingId,
      'listingTitle': room.listingTitle,
      'chatRoomId': roomRef.id,
      'senderId': senderId,
      'senderName': senderName,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (!isDraftRoom) return room;

    return ChatRoomModel(
      id: roomRef.id,
      participants: room.participants,
      listingId: room.listingId,
      listingTitle: room.listingTitle,
      buyerId: room.buyerId,
      sellerId: room.sellerId,
      chatType: room.chatType,
      lastMessage: trimmedText,
      lastMessageTime: DateTime.now(),
      createdAt: DateTime.now(),
      unreadCounts: {
        for (final participantId in room.participants) participantId: 0,
        receiverId: 1,
      },
    );
  }

  /// Listen to messages in a chat room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    if (chatRoomId.isEmpty) {
      return Stream.value(<MessageModel>[]);
    }

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
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc.data(), doc.id))
          .where((room) => room.participants.contains(userId))
          .where((room) =>
              room.lastMessage != null && room.lastMessage!.trim().isNotEmpty)
          .toList();

      rooms.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt ?? DateTime(1970);
        final bTime = b.lastMessageTime ?? b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return rooms;
    });
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
