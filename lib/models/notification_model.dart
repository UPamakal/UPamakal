import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? listingId;
  final String? listingTitle;
  final String? chatRoomId;
  final String senderId;
  final String? senderName;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.listingId,
    this.listingTitle,
    this.chatRoomId,
    required this.senderId,
    this.senderName,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      listingId: data['listingId'] as String?,
      listingTitle: data['listingTitle'] as String?,
      chatRoomId: data['chatRoomId'] as String?,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] as String?,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'title': title,
      'body': body,
      if (listingId != null) 'listingId': listingId,
      if (listingTitle != null) 'listingTitle': listingTitle,
      if (chatRoomId != null) 'chatRoomId': chatRoomId,
      'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      listingId: listingId,
      listingTitle: listingTitle,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
