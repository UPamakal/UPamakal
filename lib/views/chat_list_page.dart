import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_room_model.dart';
import '../repositories/user_repository.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'chat_detail_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  static const Color _primary = Color(0xFF8A0A0A);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _textGrey = Color(0xFF757575);

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
    if (otherUserId.isEmpty || _participantNames.containsKey(otherUserId)) {
      return;
    }

    _participantNames[otherUserId] = 'User';
    _userRepository.getUserById(otherUserId).then((user) {
      if (!mounted) return;
      setState(() {
        _participantNames[otherUserId] =
            user?.getDisplayIdentifier() ?? 'User';
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
      final otherName = _participantNames[otherUserId] ?? 'User';
      return query.isEmpty ||
          room.listingTitle.toLowerCase().contains(query) ||
          otherName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'chatListFab',
          onPressed: () {},
          backgroundColor: _primary,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      bottomNavigationBar: _buildBottomNavBar(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildRecentPeople(rooms, currentUserId),
            Expanded(
              child: chatVM.isLoadingRooms
                  ? const Center(child: CircularProgressIndicator())
                  : chatVM.error != null
                      ? _buildErrorState(chatVM.error!)
                      : rooms.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                              itemCount: rooms.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, index) {
                                return _buildConversationTile(
                                  context,
                                  rooms[index],
                                  currentUserId,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPamakal',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your Campus, Your Marketplace',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                top: -3,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 18, right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textAlignVertical: TextAlignVertical.center,
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: _textGrey),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPeople(List<ChatRoomModel> rooms, String currentUserId) {
    final recent = rooms.take(10).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent People',
            style: TextStyle(
              color: _textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final room = recent[index];
              final otherUserId = room.getOtherParticipantId(currentUserId);
              final name = _participantNames[otherUserId] ?? 'User';
              return SizedBox(
                width: 64,
                child: Column(
                  children: [
                    _buildAvatar(name, radius: 30),
                    const SizedBox(height: 7),
                    Text(
                      _firstName(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
  ) {
    final otherUserId = room.getOtherParticipantId(currentUserId);
    final otherName = _participantNames[otherUserId] ?? 'User';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(chatRoom: room)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(otherName, radius: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    room.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              room.lastMessageTime != null
                  ? '-${DateFormat.jm().format(room.lastMessageTime!)}'
                  : '',
              style: const TextStyle(color: _textGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 0,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
              ),
              _navItem(
                icon: Icons.search,
                label: 'Search',
                onTap: () {},
              ),
              const SizedBox(width: 54),
              _navItem(
                icon: Icons.chat_bubble,
                label: 'Messages',
                isActive: true,
                showDot: true,
                onTap: () {},
              ),
              _navItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool showDot = false,
  }) {
    final color = isActive ? _primary : _textGrey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (showDot)
                  Positioned(
                    top: -4,
                    right: -5,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _surfaceGrey,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _primary,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 14),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a chat from a listing',
            style: TextStyle(color: _textGrey),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: _textGrey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'User';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
