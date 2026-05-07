import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../utils/constants.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatRoomModel chatRoom;

  const ChatDetailPage({super.key, required this.chatRoom});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read when entering the room
    Future.microtask(() {
      if (!mounted) return;
      final chatVM = context.read<ChatViewModel>();
      chatVM.markAsRead(widget.chatRoom.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatVM = context.read<ChatViewModel>();
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid ?? '';
    final receiverId = widget.chatRoom.getOtherParticipantId(currentUserId);

    chatVM.sendMessage(widget.chatRoom.id, receiverId, text);
    _messageController.clear();
    
    // Scroll to bottom after sending
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final currentUserId = authVM.user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 111, 63, 63),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatVM.getMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    // Logic to show/hide avatar and time
                    bool showAvatar = true;
                    if (index > 0) {
                      final prevMessage = messages[index - 1];
                      if (prevMessage.senderId == message.senderId) {
                        showAvatar = false;
                      }
                    }

                    return _buildMessageBubble(message, isMe, showAvatar);
                  },
                );
              },
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              widget.chatRoom.listingTitle.isNotEmpty 
                  ? widget.chatRoom.listingTitle[0].toUpperCase() 
                  : '?',
              style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.listingTitle,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Active now',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.person, size: 18, color: Colors.grey),
            )
          else if (!isMe)
            const SizedBox(width: 28),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : (showAvatar ? 0 : 20)),
                  bottomRight: Radius.circular(isMe ? (showAvatar ? 0 : 20) : 20),
                ),
                boxShadow: isMe ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.image, color: Colors.black),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
