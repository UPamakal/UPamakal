import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/fcm_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final FCMService _fcmService;
  final String _currentUserId;

  List<ChatRoomModel> _chatRooms = [];
  bool _isLoadingRooms = false;
  String? _error;

  StreamSubscription? _roomsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatViewModel({
    required ChatService chatService,
    required FCMService fcmService,
    required String currentUserId,
  })  : _chatService = chatService,
        _fcmService = fcmService,
        _currentUserId = currentUserId {
    _initializeFCM();
    _listenToChatRooms();
  }

  // Getters
  List<ChatRoomModel> get chatRooms => _chatRooms;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get error => _error;

  void _initializeFCM() {
    _fcmService.initialize(_currentUserId);
  }

  void _listenToChatRooms() {
    _isLoadingRooms = true;
    notifyListeners();

    _roomsSubscription?.cancel();
    _roomsSubscription = _chatService.getChatRooms(_currentUserId).listen(
      (rooms) {
        _chatRooms = rooms;
        _isLoadingRooms = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _isLoadingRooms = false;
        notifyListeners();
      },
    );
  }

  /// Get or create a chat room
  Future<ChatRoomModel> startConversation({
    required String sellerId,
    required String listingId,
    required String listingTitle,
  }) async {
    return await _chatService.getOrCreateChatRoom(
      buyerId: _currentUserId,
      sellerId: sellerId,
      listingId: listingId,
      listingTitle: listingTitle,
    );
  }

  /// Send a message
  Future<void> sendMessage(String chatRoomId, String receiverId, String text) async {
    if (text.trim().isEmpty) return;

    final message = MessageModel(
      id: '', // Will be set by Firestore doc ref
      chatRoomId: chatRoomId,
      senderId: _currentUserId,
      receiverId: receiverId,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _chatService.sendMessage(message);
  }

  /// Listen to messages in a room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _chatService.getMessages(chatRoomId);
  }

  /// Mark room as read
  Future<void> markAsRead(String chatRoomId) async {
    await _chatService.markAsRead(chatRoomId, _currentUserId);
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
