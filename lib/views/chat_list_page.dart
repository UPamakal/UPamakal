import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_room_model.dart';
import '../repositories/user_repository.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../utils/constants.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final Map<String, String> _participantNames = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOtherParticipantName(ChatRoomModel room, String currentUserId) {
    final otherUserId = room.getOtherParticipantId(currentUserId);
    if (otherUserId.isEmpty || _participantNames.containsKey(otherUserId)) return;

    _participantNames[otherUserId] = 'User';
    _userRepository.getUserById(otherUserId).then((user) {
      if (!mounted) return;
      setState(() {
        _participantNames[otherUserId] = user?.getDisplayIdentifier() ?? 'User';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final currentUserId = authVM.user?.uid ?? '';
    final query = _searchController.text.trim().toLowerCase();
    final rooms = chatVM.chatRooms.where((room) {
      if (currentUserId.isEmpty || !room.participants.contains(currentUserId)) {
        return false;
      }

      _loadOtherParticipantName(room, currentUserId);
      final otherUserId = room.getOtherParticipantId(currentUserId);
      final otherName = _participantNames[otherUserId] ?? '';
      return query.isEmpty ||
          room.listingTitle.toLowerCase().contains(query) ||
          otherName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_outlined, color: Colors.black, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Active Chats List
          Expanded(
            child: chatVM.isLoadingRooms
                ? const Center(child: CircularProgressIndicator())
                : chatVM.error != null
                    ? _buildErrorState(chatVM.error!)
                : rooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return _buildChatTile(context, room, currentUserId);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat from a listing!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Could not load conversations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatRoomModel room, String currentUserId) {
    final unreadCount = room.unreadCounts[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final otherUserId = room.getOtherParticipantId(currentUserId);
    final otherName = _participantNames[otherUserId] ?? 'User';

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(chatRoom: room),
          ),
        );
      },
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          room.listingTitle.isNotEmpty ? room.listingTitle[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      title: Text(
        otherName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  room.lastMessage ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread ? Colors.black : Colors.grey[600],
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            room.lastMessageTime != null ? _formatTime(room.lastMessageTime!) : '',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: hasUnread
          ? Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(11)),
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat.MMMd().format(time);
    }
  }
}
