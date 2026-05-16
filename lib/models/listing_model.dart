import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String? imageBase64;
  final String category;
  final String condition;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final bool isSold;
  final List<String> imageBase64List;
  final bool isSaved;
  
  // Custom offer prices
  final double? minePrice;
  final double? stealPrice;
  final double? grabPrice;

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
    this.minePrice,
    this.stealPrice,
    this.grabPrice,
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
      minePrice: (data['minePrice'] as num?)?.toDouble(),
      stealPrice: (data['stealPrice'] as num?)?.toDouble(),
      grabPrice: (data['grabPrice'] as num?)?.toDouble(),
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
      if (minePrice != null) 'minePrice': minePrice,
      if (stealPrice != null) 'stealPrice': stealPrice,
      if (grabPrice != null) 'grabPrice': grabPrice,
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
    double? minePrice,
    double? stealPrice,
    double? grabPrice,
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
      minePrice: minePrice ?? this.minePrice,
      stealPrice: stealPrice ?? this.stealPrice,
      grabPrice: grabPrice ?? this.grabPrice,
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