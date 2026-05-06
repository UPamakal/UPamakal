import 'package:cloud_firestore/cloud_firestore.dart';

/// --------------------------------------------------------------------------
/// listing_model.dart
/// --------------------------------------------------------------------------
/// Updated ListingModel with condition field and improved Firestore support.
/// --------------------------------------------------------------------------
class ListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String? imageUrl;
  final String category;
  final String condition;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final bool isSold;
  final List<String> imageUrls;
  final bool isSaved;

  const ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    this.imageUrl,
    required this.category,
    required this.condition,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    this.isSold = false,
    this.imageUrls = const [],
    this.isSaved = false,
  });

  /// Helper function to safely convert Firestore Timestamp to DateTime
  static DateTime _convertTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  /// Factory constructor for creating a listing from Firestore document
  factory ListingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ListingModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'Other',
      condition: data['condition'] ?? 'New',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      createdAt: _convertTimestamp(data['createdAt']),  // FIXED HERE
      isSold: data['isSold'] ?? false,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isSaved: data['isSaved'] ?? false,
    );
  }

  /// Convert ListingModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'imageUrl': imageUrl,
      'category': category,
      'condition': condition,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt,
      'isSold': isSold,
      'imageUrls': imageUrls,
    };
  }

  /// Create a copy of this listing with updated fields
  ListingModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    String? imageUrl,
    String? category,
    String? condition,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    bool? isSold,
    List<String>? imageUrls,
    bool? isSaved,
  }) {
    return ListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      isSold: isSold ?? this.isSold,
      imageUrls: imageUrls ?? this.imageUrls,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Formatted price string
  String get formattedPrice => '₱${price.toStringAsFixed(0)}';

  /// Time ago string (e.g., "2 days ago")
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 7) {
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
  String toString() => 'ListingModel(id: $id, title: $title, price: $price)';
}