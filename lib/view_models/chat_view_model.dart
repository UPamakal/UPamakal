import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/fcm_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final FCMService _fcmService;
  String _currentUserId;

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
    _configureForUser(currentUserId);
  }

  // Getters
  List<ChatRoomModel> get chatRooms => _chatRooms;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get error => _error;

  void updateCurrentUser(String userId) {
    if (userId == _currentUserId) return;
    _currentUserId = userId;
    _configureForUser(userId);
  }

  void _configureForUser(String userId) {
    _roomsSubscription?.cancel();
    _messagesSubscription?.cancel();

    if (userId.isEmpty) {
      _chatRooms = [];
      _isLoadingRooms = false;
      _error = null;
      notifyListeners();
      return;
    }

    _fcmService.initialize(userId);
    _listenToChatRooms();
  }

  void _listenToChatRooms() {
    _isLoadingRooms = true;
    notifyListeners();

    _roomsSubscription?.cancel();
    _roomsSubscription = _chatService.getChatRooms(_currentUserId).listen(
      (rooms) {
        _chatRooms = rooms
            .where((room) => room.participants.contains(_currentUserId))
            .toList();
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
    String chatType = 'listing',
  }) async {
    if (_currentUserId.isEmpty) {
      throw StateError('You must be logged in to start a conversation.');
    }

    return await _chatService.getOrCreateChatRoom(
      buyerId: _currentUserId,
      sellerId: sellerId,
      listingId: listingId,
      listingTitle: listingTitle,
      chatType: chatType,
    );
  }

  /// Send a message
  Future<void> sendMessage(String chatRoomId, String receiverId, String text) async {
    if (text.trim().isEmpty) return;
    if (_currentUserId.isEmpty) {
      throw StateError('You must be logged in to send a message.');
    }

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

  Future<ChatRoomModel> sendMessageInRoom(
    ChatRoomModel room,
    String receiverId,
    String text,
  ) async {
    if (text.trim().isEmpty) return room;
    if (_currentUserId.isEmpty) {
      throw StateError('You must be logged in to send a message.');
    }

    return _chatService.sendMessageInRoom(
      room: room,
      senderId: _currentUserId,
      receiverId: receiverId,
      text: text,
    );
  }

  /// Listen to messages in a room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _chatService.getMessages(chatRoomId);
  }

  /// Mark room as read
  Future<void> markAsRead(String chatRoomId) async {
    if (_currentUserId.isEmpty) return;
    await _chatService.markAsRead(chatRoomId, _currentUserId);
  }

  Future<ChatRoomModel?> getChatRoom(String chatRoomId) {
    return _chatService.getChatRoom(chatRoomId);
  }

  int get totalUnreadCount {
    return _chatRooms.fold<int>(
      0,
      (total, room) => total + (room.unreadCounts[_currentUserId] ?? 0),
    );
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
