import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room_model.dart';
import '../models/listing_model.dart';
import '../models/message_model.dart';
import '../repositories/user_repository.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../services/listing_service.dart';
import '../services/image_service.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatRoomModel chatRoom;
  final ListingModel? listing;

  const ChatDetailPage({super.key, required this.chatRoom, this.listing});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const Color _primary = Color(0xFF8A0A0A);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _buttonPink = Color(0xFFFADCDD);
  static const Color _statusGreenBg = Color(0xFFE0F2E9);
  static const Color _statusGreenText = Color(0xFF208B59);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserRepository _userRepository = UserRepository();
  final ListingService _listingService = ListingService();

  late ChatRoomModel _chatRoom;
  String _otherParticipantName = 'Eryl Joseph';
  bool _isSending = false;
  ListingModel? _fetchedListing;
  bool _isLoadingListing = false;

  ListingModel? get _effectiveListing => widget.listing ?? _fetchedListing;

  @override
  void initState() {
    super.initState();
    _chatRoom = widget.chatRoom;

    if (widget.listing == null && _chatRoom.listingId.isNotEmpty) {
      _fetchListing();
    }

    Future.microtask(() async {
      if (!mounted) return;
      final chatVM = context.read<ChatViewModel>();
      final authVM = context.read<AuthViewModel>();
      final currentUserId = authVM.user?.uid ?? '';

      if (_chatRoom.id.isNotEmpty) {
        unawaited(chatVM.markAsRead(_chatRoom.id));
      }

      final otherUserId = _chatRoom.getOtherParticipantId(currentUserId);
      if (otherUserId.isEmpty) return;

      final user = await _userRepository.getUserById(otherUserId);
      if (!mounted) return;
      setState(() {
        _otherParticipantName = user?.getDisplayIdentifier() ?? 'Eryl Joseph';
      });
    });
  }

  Future<void> _fetchListing() async {
    if (_chatRoom.listingId.isEmpty || _chatRoom.listingId.startsWith('profile:')) {
      return;
    }

    setState(() => _isLoadingListing = true);
    try {
      final listing = await _listingService.getListingById(_chatRoom.listingId);
      if (!mounted) return;
      setState(() {
        _fetchedListing = listing;
        _isLoadingListing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingListing = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final chatVM = context.read<ChatViewModel>();
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid ?? '';
    final receiverId = _chatRoom.getOtherParticipantId(currentUserId);

    setState(() => _isSending = true);
    try {
      final savedRoom = await chatVM.sendMessageInRoom(_chatRoom, receiverId, text);
      if (mounted && savedRoom.id != _chatRoom.id) {
        setState(() => _chatRoom = savedRoom);
      }
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }

    Timer(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _fillQuickReply(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  void _showOfferBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send Offer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '\u20B1 ',
                hintText: 'Enter your offer amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonPink,
                  foregroundColor: _primary,
                  elevation: 0,
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Send Offer',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final currentUserId = authVM.user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isLoadingListing)
            const LinearProgressIndicator(minHeight: 2)
          else
            _buildProductCard(),
          Expanded(
            child: Column(
              children: [
                _buildDateSeparator(),
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: chatVM.getMessages(_chatRoom.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(color: _textGrey, fontSize: 14),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUserId;
                          final showAvatar = !isMe &&
                              (index == 0 ||
                                  messages[index - 1].senderId !=
                                      message.senderId);
                          return _buildMessageBubble(message, isMe, showAvatar);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAvatar(_otherParticipantName, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _otherParticipantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    final listing = _effectiveListing;
    final title = listing?.title ?? _chatRoom.listingTitle;
    final productName = title.trim().isNotEmpty ? title.trim() : 'Casio FX-991EX';
    final price = listing?.formattedPrice ?? '\u20B1 850';
    final primaryImage = listing?.imageBase64 ??
        ((listing?.imageBase64List.isNotEmpty ?? false)
            ? listing!.imageBase64List.first
            : null);
    final isAvailable = listing?.isSold != true;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: primaryImage != null
                ? ImageService.base64ToImage(
                    primaryImage,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.calculate_outlined, color: _textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAvailable ? _statusGreenBg : _surfaceGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Sold',
              style: TextStyle(
                color: isAvailable ? _statusGreenText : _textGrey,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _surfaceGrey,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Today',
            style: TextStyle(color: _textGrey, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            _buildAvatar(_otherParticipantName, radius: 15)
          else if (!isMe)
            const SizedBox(width: 30),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _primary : _surfaceGrey,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _quickReplyButton('Is this still available'),
                  const SizedBox(width: 8),
                  _quickReplyButton('Can you lower the price?'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _showOfferBottomSheet,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _buttonPink,
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Send Offer',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _surfaceGrey,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _messageController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: _textGrey),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _isSending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(23),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSending ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickReplyButton(String text) {
    return OutlinedButton(
      onPressed: () => _fillQuickReply(text),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        side: const BorderSide(color: _primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
}
