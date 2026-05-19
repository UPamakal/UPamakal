import 'package:cloud_firestore/cloud_firestore.dart';

/// --------------------------------------------------------------------------
/// ChatRoomModel
/// --------------------------------------------------------------------------
/// Represents a conversation between two users about a specific listing.
/// --------------------------------------------------------------------------
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String listingId;
  final String listingTitle;
  final String buyerId;
  final String sellerId;
  final String chatType;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;
  final Map<String, int> unreadCounts;

  const ChatRoomModel({
    required this.id,
    required this.participants,
    required this.listingId,
    required this.listingTitle,
    required this.buyerId,
    required this.sellerId,
    this.chatType = 'listing',
    this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
    this.unreadCounts = const {},
  });

  /// Factory constructor for creating a chat room from Firestore document
  factory ChatRoomModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatRoomModel(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      listingId: data['listingId'] ?? '',
      listingTitle: data['listingTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      chatType: data['chatType'] ?? 'listing',
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  /// Convert ChatRoomModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'chatType': chatType,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'unreadCounts': unreadCounts,
    };
  }

  /// Returns the ID of the other participant
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}
