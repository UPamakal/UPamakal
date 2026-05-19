import 'package:cloud_firestore/cloud_firestore.dart';

/// --------------------------------------------------------------------------
/// RatingModel
/// --------------------------------------------------------------------------
/// Represents a rating/review left by a user for a listing.
/// Ratings are aggregated to calculate seller's overall rating.
/// --------------------------------------------------------------------------
class RatingModel {
  final String id;
  final String listingId;
  final String sellerId;
  final String reviewerId;
  final String reviewerName;
  final double rating; // 1-5 stars
  final String? review; // Optional text review
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  static DateTime _convertTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  factory RatingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RatingModel(
      id: id,
      listingId: data['listingId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      rating: (data['rating'] ?? 5).toDouble(),
      review: data['review'] as String?,
      createdAt: _convertTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      if (review != null && review!.isNotEmpty) 'review': review,
      'createdAt': createdAt,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365}y ago';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}mo ago';
    } else if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() =>
      'RatingModel(id: $id, rating: $rating, seller: $sellerId)';
}
