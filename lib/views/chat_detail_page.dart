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
import '../utils/constants.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatRoomModel chatRoom;
  final ListingModel? listing; // optional – if not provided, we fetch it

  const ChatDetailPage({super.key, required this.chatRoom, this.listing});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserRepository _userRepository = UserRepository();
  final ListingService _listingService = ListingService();

  late ChatRoomModel _chatRoom;
  String _otherParticipantName = 'User';
  bool _isSending = false;

  // Fetched listing (if not provided)
  ListingModel? _fetchedListing;
  bool _isLoadingListing = false;

  ListingModel? get _effectiveListing => widget.listing ?? _fetchedListing;

  @override
  void initState() {
    super.initState();
    _chatRoom = widget.chatRoom;

    // If listing not provided, fetch it
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
      if (otherUserId.isNotEmpty) {
        final user = await _userRepository.getUserById(otherUserId);
        if (!mounted) return;
        setState(() {
          _otherParticipantName = user?.getDisplayIdentifier() ?? 'User';
          if (_otherParticipantName.isEmpty) _otherParticipantName = 'User';
        });
      }
    });
  }

  Future<void> _fetchListing() async {
    if (_chatRoom.listingId.isEmpty) return;
    setState(() => _isLoadingListing = true);
    try {
      final listing = await _listingService.getListingById(_chatRoom.listingId);
      if (mounted) {
        setState(() {
          _fetchedListing = listing;
          _isLoadingListing = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch listing for chat: $e');
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

  void _fillQuickReply(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showOfferBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Make an Offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                prefixText: '₱ ',
                hintText: 'Enter your offer amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
              child: const Text('Send Offer', style: TextStyle(color: Colors.white)),
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
    final listing = _effectiveListing;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                _otherParticipantName.isNotEmpty ? _otherParticipantName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _otherParticipantName,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
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
      ),
      body: Column(
        children: [
          // Listing Preview Card – show while loading or when available
          if (listing != null)
            _buildListingPreviewCard(listing)
          else if (_isLoadingListing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatVM.getMessages(_chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    bool showAvatar = true;
                    if (index > 0 && messages[index - 1].senderId == message.senderId) {
                      showAvatar = false;
                    }
                    return _buildMessageBubble(message, isMe, showAvatar);
                  },
                );
              },
            ),
          ),
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildListingPreviewCard(ListingModel listing) {
    final primaryImage = listing.imageBase64 ??
        (listing.imageBase64List.isNotEmpty ? listing.imageBase64List.first : null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 50,
              height: 50,
              child: primaryImage != null
                  ? ImageService.base64ToImage(
                      primaryImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title.isNotEmpty ? listing.title : 'Item',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: listing.isSold ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: listing.isSold ? Colors.orange.shade200 : Colors.green.shade200),
            ),
            child: Text(
              listing.isSold ? 'Sold' : 'Available',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: listing.isSold ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                _otherParticipantName.isNotEmpty ? _otherParticipantName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF8B0000) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : (showAvatar ? 0 : 20)),
                  bottomRight: Radius.circular(isMe ? (showAvatar ? 0 : 20) : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _fillQuickReply('Is this still available?'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B0000)),
                    foregroundColor: const Color(0xFF8B0000),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Is this still available?', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _fillQuickReply('Can you lower the price?'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B0000)),
                    foregroundColor: const Color(0xFF8B0000),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Can you lower the price?', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showOfferBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: const Color(0xFF8B0000),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Send Offer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B0000),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSending ? Icons.hourglass_empty : Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}