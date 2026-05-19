import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rating_model.dart';

/// --------------------------------------------------------------------------
/// ReviewService
/// --------------------------------------------------------------------------
/// Handles all rating and review operations:
/// - Submit ratings for listings
/// - Retrieve ratings by seller/listing
/// - Calculate average ratings
/// - Stream ratings in real-time
/// --------------------------------------------------------------------------
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a rating for a listing
  Future<RatingModel> submitRating({
    required String listingId,
    required String sellerId,
    required String reviewerId,
    required String reviewerName,
    required double rating,
    String? review,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if reviewer already rated this specific seller (across all listings)
      final existingSellerRating = await _firestore
          .collection('ratings')
          .where('sellerId', isEqualTo: sellerId)
          .where('reviewerId', isEqualTo: reviewerId)
          .get();

      if (existingSellerRating.docs.isNotEmpty) {
        throw Exception('You have already rated this seller');
      }

      // Still check for duplicate rating on the same listing for safety
      final existingListingRating = await _firestore
          .collection('ratings')
          .where('listingId', isEqualTo: listingId)
          .where('reviewerId', isEqualTo: reviewerId)
          .get();

      if (existingListingRating.docs.isNotEmpty) {
        throw Exception('You have already rated this listing');
      }

      final docRef = _firestore.collection('ratings').doc();
      final ratingModel = RatingModel(
        id: docRef.id,
        listingId: listingId,
        sellerId: sellerId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        rating: rating,
        review: review,
        createdAt: DateTime.now(),
      );

      await docRef.set(ratingModel.toFirestore());
      debugPrint('✅ Rating saved to Firestore: ${ratingModel.id}');

      // Update seller's average rating in users collection
      await _updateSellerAverageRating(sellerId);
      debugPrint('✅ Updated seller average rating for: $sellerId');

      return ratingModel;
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// Update the seller's average rating in the users collection
  Future<void> _updateSellerAverageRating(String sellerId) async {
    try {
      final averageRating = await getAverageRating(sellerId);
      debugPrint('📊 Calculated average rating for $sellerId: $averageRating');
      
      // Use set with merge to handle missing documents gracefully
      await _firestore.collection('users').doc(sellerId).set({
        'averageRating': averageRating,
      }, SetOptions(merge: true));
      debugPrint('💾 Firestore updated: users/$sellerId averageRating=$averageRating');
    } catch (e) {
      // Silently log error but don't fail the rating submission
      debugPrint('❌ Failed to update seller average rating: $e');
    }
  }

  /// Check if user has already rated this seller (across all listings)
  Future<bool> hasUserRatedSeller(
    String sellerId,
    String reviewerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('sellerId', isEqualTo: sellerId)
          .where('reviewerId', isEqualTo: reviewerId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all ratings for a specific seller (across all listings)
  Future<List<RatingModel>> getRatingsBySeller(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller ratings: $e');
    }
  }

  /// Get all ratings for a specific listing
  Future<List<RatingModel>> getRatingsByListing(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('listingId', isEqualTo: listingId)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch listing ratings: $e');
    }
  }

  /// Stream ratings for a seller in real-time
  Stream<List<RatingModel>> streamSellerRatings(String sellerId) {
    return _firestore
        .collection('ratings')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream ratings for a listing in real-time
  Stream<List<RatingModel>> streamListingRatings(String listingId) {
    return _firestore
        .collection('ratings')
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Calculate average rating for a seller
  Future<double> getAverageRating(String sellerId) async {
    try {
      final ratings = await getRatingsBySeller(sellerId);
      debugPrint('🔍 Found ${ratings.length} ratings for seller: $sellerId');
      
      if (ratings.isEmpty) {
        debugPrint('⚠️ No ratings found for $sellerId, returning 0.0');
        return 0.0;
      }

      final average = ratings.fold<double>(
            0,
            (sum, rating) => sum + rating.rating,
          ) /
          ratings.length;

      final result = double.parse(average.toStringAsFixed(2));
      debugPrint('📈 Average: $result (sum: ${ratings.fold<double>(0, (sum, rating) => sum + rating.rating)} / count: ${ratings.length})');
      return result;
    } catch (e) {
      debugPrint('❌ Error calculating average rating: $e');
      return 0.0;
    }
  }

  /// Stream average rating for a seller in real-time
  Stream<double> streamAverageRating(String sellerId) {
    debugPrint('🔌 StreamAverageRating starting for: $sellerId');
    
    return streamSellerRatings(sellerId).map((ratings) {
      debugPrint('📡 Stream update: ${ratings.length} ratings for $sellerId');
      
      if (ratings.isEmpty) {
        debugPrint('📡 Stream result: 0.0 (no ratings)');
        return 0.0;
      }
      
      final average = ratings.fold<double>(
            0,
            (sum, rating) => sum + rating.rating,
          ) /
          ratings.length;
      
      final result = double.parse(average.toStringAsFixed(2));
      debugPrint('📡 Stream result: $result');
      return result;
    });
  }

  /// Get count of ratings for a seller
  Future<int> getRatingCount(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('sellerId', isEqualTo: sellerId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream average rating and count for a seller
  Stream<Map<String, dynamic>> streamSellerRatingStats(String sellerId) {
    return _firestore
        .collection('ratings')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final ratings = snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc.data(), doc.id))
          .toList();

      if (ratings.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      final average = ratings.fold<double>(
            0,
            (sum, rating) => sum + rating.rating,
          ) /
          ratings.length;

      return {
        'average': double.parse(average.toStringAsFixed(2)),
        'count': ratings.length,
      };
    });
  }

  /// Check if user has already rated a specific listing
  Future<bool> hasUserRatedListing(
    String listingId,
    String reviewerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('listingId', isEqualTo: listingId)
          .where('reviewerId', isEqualTo: reviewerId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get rating breakdown (count of each star rating)
  Future<Map<int, int>> getRatingBreakdown(String sellerId) async {
    try {
      final ratings = await getRatingsBySeller(sellerId);
      final breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final rating in ratings) {
        final star = rating.rating.toInt();
        breakdown[star] = (breakdown[star] ?? 0) + 1;
      }

      return breakdown;
    } catch (e) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
  }

  /// Delete a rating (admin or rating owner)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _firestore.collection('ratings').doc(ratingId).delete();
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }

  /// Update an existing rating
  Future<void> updateRating({
    required String ratingId,
    required double rating,
    String? review,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      await _firestore.collection('ratings').doc(ratingId).update({
        'rating': rating,
        if (review != null) 'review': review,
      });
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }
}
