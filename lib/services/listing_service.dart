import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import 'image_service.dart';

class ListingService {
  final ImageService _imageService = ImageService();

  Future<List<XFile>> pickImages({int maxCount = 3}) async {
    return await _imageService.pickImages(maxCount: maxCount);
  }

  Future<List<String>> convertImagesToBase64({
    required List<XFile> images,
  }) async {
    return await ImageService.imagesToBase64List(images);
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
    double? minePrice,
    double? stealPrice,
    double? grabPrice,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('listings').doc();
      final listingId = docRef.id;

      List<String> base64Images = [];
      String? primaryImageBase64;

      if (images.isNotEmpty) {
        base64Images = await convertImagesToBase64(images: images);
        primaryImageBase64 = base64Images.isNotEmpty ? base64Images.first : null;
      }

      final listing = ListingModel(
        id: listingId,
        title: title.trim(),
        description: description.trim(),
        price: price,
        location: location.trim(),
        imageBase64: primaryImageBase64,
        category: category,
        condition: condition,
        sellerId: seller.uid,
        sellerName: seller.displayName ?? (seller.email?.split('@').first ?? 'User'),
        createdAt: DateTime.now(),
        isSold: false,
        imageBase64List: base64Images,
        minePrice: minePrice,
        stealPrice: stealPrice,
        grabPrice: grabPrice,
        currentPrice: minePrice ?? price,
        currentOwnerId: null,
        status: 'available',
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
    double? minePrice,
    double? stealPrice,
    double? grabPrice,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('listings').doc();

      List<String> base64Images = [];
      if (images.isNotEmpty) {
        base64Images = await convertImagesToBase64(images: images);
      }

      final draftData = {
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'location': location.trim(),
        'category': category,
        'condition': condition,
        'sellerId': seller.uid,
        'sellerName': seller.displayName ?? (seller.email?.split('@').first ?? 'User'),
        'createdAt': DateTime.now(),
        'isSold': false,
        'isDraft': true,
        'imageBase64List': base64Images,
        'imageBase64': base64Images.isNotEmpty ? base64Images.first : null,
        if (minePrice != null) 'minePrice': minePrice,
        if (stealPrice != null) 'stealPrice': stealPrice,
        if (grabPrice != null) 'grabPrice': grabPrice,
      };

      await docRef.set(draftData);
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  Stream<List<ListingModel>> getAllListings() {
    return FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isSold'] == false && data['isDraft'] != true;
          })
          .map((doc) {
            final data = doc.data();
            return ListingModel.fromFirestore(data, doc.id);
          })
          .toList();
    });
  }

  Stream<List<ListingModel>> getListingsByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            if (data['isSold'] != false) return false;
            if (data['isDraft'] == true) return false;
            if (category != 'All Items' && data['category'] != category) return false;
            return true;
          })
          .map((doc) {
            final data = doc.data();
            return ListingModel.fromFirestore(data, doc.id);
          })
          .toList();
    });
  }

  Stream<List<ListingModel>> searchListings(String searchQuery) {
    return FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .where((doc) {
            final data = doc.data();
            if (data['isSold'] != false) return false;
            if (data['isDraft'] == true) return false;
            return true;
          })
          .map((doc) {
            final data = doc.data();
            return ListingModel.fromFirestore(data, doc.id);
          })
          .toList();
      
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
        final data = doc.data();
        return ListingModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  Future<ListingModel?> getListingById(String listingId) async {
    final doc = await FirebaseFirestore.instance.collection('listings').doc(listingId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return ListingModel.fromFirestore(data, doc.id);
    }
    return null;
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

  Future<void> updateListing({
    required String listingId,
    String? title,
    String? description,
    double? price,
    String? location,
    String? category,
    String? condition,
    double? minePrice,
    double? stealPrice,
    double? grabPrice,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (location != null) updates['location'] = location;
    if (category != null) updates['category'] = category;
    if (condition != null) updates['condition'] = condition;
    if (minePrice != null) updates['minePrice'] = minePrice;
    if (stealPrice != null) updates['stealPrice'] = stealPrice;
    if (grabPrice != null) updates['grabPrice'] = grabPrice;
    
    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance.collection('listings').doc(listingId).update(updates);
    }
  }

  /// Attempt to claim the item (Mine). Only allowed when there is no owner and status is 'available'.
  Future<bool> mineListing({
    required String listingId,
    required String userId,
    String actorName = 'Someone',
  }) async {
    final docRef = FirebaseFirestore.instance.collection('listings').doc(listingId);
    try {
      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;
        final status = (data['status'] as String?) ?? 'available';
        final currentOwner = data['currentOwnerId'] as String?;
        if (currentOwner != null) return false;
        if (status != 'available') return false;
        final minePrice = (data['minePrice'] as num?)?.toDouble();
        if (minePrice == null) return false;
        tx.update(docRef, {
          'currentPrice': minePrice,
          'currentOwnerId': userId,
          'status': 'active',
          'mineTaken': true,
        });
        final sellerId = data['sellerId'] as String? ?? '';
        final listingTitle = data['title'] as String? ?? 'Listing';
        if (userId != sellerId) {
          final notifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .collection('notifications')
              .doc();
          tx.set(notifRef, {
            'type': 'mine',
            'title': 'Someone mined your item',
            'body': '$actorName mined $listingTitle',
            'listingId': listingId,
            'listingTitle': listingTitle,
            'senderId': userId,
            'senderName': actorName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Attempt to steal by offering a higher amount. Validates amount and ownership. Uses transaction to avoid races.
  Future<bool> stealListing({
    required String listingId,
    required String userId,
    required double amount,
    String actorName = 'Someone',
  }) async {
    final docRef = FirebaseFirestore.instance.collection('listings').doc(listingId);
    try {
      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;
        final status = (data['status'] as String?) ?? 'available';
        if (status == 'grabbed' || status == 'completed') return false;
        final currentOwner = data['currentOwnerId'] as String?;
        if (currentOwner == userId) return false; // cannot steal own
        final currentPrice = (data['currentPrice'] as num?)?.toDouble() ?? (data['minePrice'] as num?)?.toDouble() ?? 0.0;
        final grabPrice = (data['grabPrice'] as num?)?.toDouble();
        if (amount <= currentPrice) return false;
        if (grabPrice != null && amount >= grabPrice) return false;
        tx.update(docRef, {
          'currentPrice': amount,
          'currentOwnerId': userId,
          'status': 'active',
          'stealTaken': true,
        });
        final sellerId = data['sellerId'] as String? ?? '';
        final listingTitle = data['title'] as String? ?? 'Listing';
        final previousOwner = data['currentOwnerId'] as String?;
        if (userId != sellerId) {
          final sellerNotifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .collection('notifications')
              .doc();
          tx.set(sellerNotifRef, {
            'type': 'steal',
            'title': 'Your item was outbid',
            'body': '$actorName placed a higher bid on $listingTitle',
            'listingId': listingId,
            'listingTitle': listingTitle,
            'senderId': userId,
            'senderName': actorName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (previousOwner != null && previousOwner != userId && previousOwner != sellerId) {
          final prevNotifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(previousOwner)
              .collection('notifications')
              .doc();
          tx.set(prevNotifRef, {
            'type': 'steal',
            'title': 'You were outbid!',
            'body': 'Someone placed a higher bid on $listingTitle',
            'listingId': listingId,
            'listingTitle': listingTitle,
            'senderId': userId,
            'senderName': actorName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Grab: immediate buyout at grabPrice. Transactional.
  Future<bool> grabListing({
    required String listingId,
    required String userId,
    String actorName = 'Someone',
  }) async {
    final docRef = FirebaseFirestore.instance.collection('listings').doc(listingId);
    try {
      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;
        final status = (data['status'] as String?) ?? 'available';
        if (status == 'grabbed' || status == 'completed') return false;
        final grabPrice = (data['grabPrice'] as num?)?.toDouble();
        if (grabPrice == null) return false;
        tx.update(docRef, {
          'currentPrice': grabPrice,
          'currentOwnerId': userId,
          'status': 'grabbed',
          'grabTaken': true,
        });
        final sellerId = data['sellerId'] as String? ?? '';
        final listingTitle = data['title'] as String? ?? 'Listing';
        final previousOwner = data['currentOwnerId'] as String?;
        if (userId != sellerId) {
          final sellerNotifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .collection('notifications')
              .doc();
          tx.set(sellerNotifRef, {
            'type': 'grab',
            'title': 'Your item was grabbed!',
            'body': '$actorName grabbed $listingTitle',
            'listingId': listingId,
            'listingTitle': listingTitle,
            'senderId': userId,
            'senderName': actorName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (previousOwner != null && previousOwner != userId && previousOwner != sellerId) {
          final prevNotifRef = FirebaseFirestore.instance
              .collection('users')
              .doc(previousOwner)
              .collection('notifications')
              .doc();
          tx.set(prevNotifRef, {
            'type': 'grab',
            'title': 'Item was grabbed!',
            'body': '$listingTitle was just grabbed by someone else',
            'listingId': listingId,
            'listingTitle': listingTitle,
            'senderId': userId,
            'senderName': actorName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        return true;
      });
    } catch (e) {
      return false;
    }
  }
}