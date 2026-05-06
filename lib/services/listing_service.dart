import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import 'cloudinary_service.dart';

class ListingService {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  Future<List<XFile>> pickImages({int maxCount = 5}) async {
    final List<XFile> images = [];
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFiles != null) {
      images.addAll(pickedFiles.take(maxCount));
    }

    return images;
  }

  Future<List<String>> uploadImages({
    required List<XFile> images,
    required String sellerId,
    required String listingId,
  }) async {
    final List<String> imageUrls = [];

    for (final image in images) {
      final imageUrl = await _cloudinaryService.uploadImage(
        image: image,
        folder: 'upamakal/listings/$sellerId/$listingId',
      );
      
      if (imageUrl != null) {
        imageUrls.add(imageUrl);
      }
    }

    return imageUrls;
  }

  // NO COMPOSITE INDEX NEEDED - filters in memory
  Stream<List<ListingModel>> getAllListings() {
    return FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            // Filter in memory instead of using .where()
            return data['isSold'] == false && data['isDraft'] != true;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListingModel.fromFirestore(data, doc.id);
          })
          .toList();
    });
  }

  // NO COMPOSITE INDEX NEEDED - filters in memory
  Stream<List<ListingModel>> getListingsByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            // Filter in memory
            if (data['isSold'] != false) return false;
            if (data['isDraft'] == true) return false;
            if (category != 'All Items' && data['category'] != category) return false;
            return true;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListingModel.fromFirestore(data, doc.id);
          })
          .toList();
    });
  }

  // NO COMPOSITE INDEX NEEDED - filters in memory
  Stream<List<ListingModel>> searchListings(String searchQuery) {
    return FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .where((doc) {
            final data = doc.data();
            // First filter by isSold and isDraft
            if (data['isSold'] != false) return false;
            if (data['isDraft'] == true) return false;
            return true;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListingModel.fromFirestore(data, doc.id);
          })
          .toList();
      
      // Apply search filter in memory
      if (searchQuery.isEmpty) return listings;
      
      return listings.where((listing) {
        return listing.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            listing.description.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  Stream<List<ListingModel>> getListingsBySeller(String sellerId) {
    return FirebaseFirestore.instance
        .collection('listings')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ListingModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  Future<ListingModel?> getListingById(String listingId) async {
    final doc = await FirebaseFirestore.instance.collection('listings').doc(listingId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return ListingModel.fromFirestore(data, doc.id);
    }
    return null;
  }

  Future<ListingModel> createListing({
    required String title,
    required String description,
    required double price,
    required String location,
    required String category,
    required String condition,
    required UserModel seller,
    List<XFile> images = const [],
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('listings').doc();
      final listingId = docRef.id;

      List<String> imageUrls = [];
      String? primaryImageUrl;

      if (images.isNotEmpty) {
        imageUrls = await uploadImages(
          images: images,
          sellerId: seller.uid,
          listingId: listingId,
        );
        primaryImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
      }

      final listing = ListingModel(
        id: listingId,
        title: title.trim(),
        description: description.trim(),
        price: price,
        location: location.trim(),
        imageUrl: primaryImageUrl,
        category: category,
        condition: condition,
        sellerId: seller.uid,
        sellerName: seller.displayName ?? 
            (seller.email?.split('@').first ?? 'User'),
        createdAt: DateTime.now(),
        isSold: false,
        imageUrls: imageUrls,
      );

      await docRef.set(listing.toFirestore());

      return listing;
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  Future<void> saveDraft({
    required String title,
    required String description,
    required double price,
    required String location,
    required String category,
    required String condition,
    required UserModel seller,
    List<XFile> images = const [],
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('listings').doc();
      final listingId = docRef.id;

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await uploadImages(
          images: images,
          sellerId: seller.uid,
          listingId: listingId,
        );
      }

      final draftData = {
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'location': location.trim(),
        'category': category,
        'condition': condition,
        'sellerId': seller.uid,
        'sellerName': seller.displayName ?? 
            (seller.email?.split('@').first ?? 'User'),
        'createdAt': DateTime.now(),
        'isSold': false,
        'isDraft': true,
        'imageUrls': imageUrls,
        'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      };

      await docRef.set(draftData);
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(listingId).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  Future<void> markAsSold(String listingId, bool isSold) async {
    await FirebaseFirestore.instance.collection('listings').doc(listingId).update({
      'isSold': isSold,
    });
  }

  Future<void> saveToListing(String userId, String listingId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.set({
      'savedListings': FieldValue.arrayUnion([listingId]),
    }, SetOptions(merge: true));
  }

  Future<void> unsaveListing(String userId, String listingId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'savedListings': FieldValue.arrayRemove([listingId]),
    });
  }

  Future<void> reportListing({
    required String listingId,
    required String reporterId,
    required String reason,
    String? additionalDetails,
  }) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'listingId': listingId,
      'reporterId': reporterId,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'createdAt': DateTime.now(),
      'status': 'pending',
    });
  }

  Future<void> updateListing({
    required String listingId,
    String? title,
    String? description,
    double? price,
    String? location,
    String? category,
    String? condition,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (location != null) updates['location'] = location;
    if (category != null) updates['category'] = category;
    if (condition != null) updates['condition'] = condition;
    
    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance.collection('listings').doc(listingId).update(updates);
    }
  }
}