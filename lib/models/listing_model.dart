import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String? imageBase64; // Primary image as Base64
  final String category;
  final String condition;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final bool isSold;
  final List<String> imageBase64List; // Multiple images as Base64
  final bool isSaved;

  const ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    this.imageBase64,
    required this.category,
    required this.condition,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    this.isSold = false,
    this.imageBase64List = const [],
    this.isSaved = false,
  });

  static DateTime _convertTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  factory ListingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ListingModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      imageBase64: data['imageBase64'],
      category: data['category'] ?? 'Other',
      condition: data['condition'] ?? 'New',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      createdAt: _convertTimestamp(data['createdAt']),
      isSold: data['isSold'] ?? false,
      imageBase64List: List<String>.from(data['imageBase64List'] ?? []),
      isSaved: data['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'imageBase64': imageBase64,
      'category': category,
      'condition': condition,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt,
      'isSold': isSold,
      'imageBase64List': imageBase64List,
    };
  }

  ListingModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    String? imageBase64,
    String? category,
    String? condition,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    bool? isSold,
    List<String>? imageBase64List,
    bool? isSaved,
  }) {
    return ListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      imageBase64: imageBase64 ?? this.imageBase64,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      isSold: isSold ?? this.isSold,
      imageBase64List: imageBase64List ?? this.imageBase64List,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  String get formattedPrice => '₱${price.toStringAsFixed(0)}';

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