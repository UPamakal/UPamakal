import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/listing_model.dart';
import '../services/listing_service.dart';
import '../repositories/user_repository.dart';

/// --------------------------------------------------------------------------
/// FavoritesViewModel
/// --------------------------------------------------------------------------
/// Manages the state and logic for user's favorite listings.
/// Uses real-time Firestore listeners to sync favorites across devices.
/// --------------------------------------------------------------------------
class FavoritesViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final ListingService _listingService;
  final String _userId;

  List<String> _favoriteIds = [];
  List<ListingModel> _favoriteListings = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _listingsSubscription;

  FavoritesViewModel({
    required UserRepository userRepository,
    required ListingService listingService,
    required String userId,
  })  : _userRepository = userRepository,
        _listingService = listingService,
        _userId = userId {
    _listenToFavorites();
  }

  // ── Getters ─────────────────────────────────────────────────────────────

  List<ListingModel> get favoriteListings => _favoriteListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasFavorites => _favoriteListings.isNotEmpty;

  // ── Real-time listeners ─────────────────────────────────────────────────

  void _listenToFavorites() {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _userRepository.favoritesStream(_userId).listen(
      (favoriteIds) {
        _favoriteIds = favoriteIds;
        _loadFavoriteListings();
      },
      onError: (error) {
        _errorMessage = 'Failed to load favorites: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadFavoriteListings() async {
    if (_favoriteIds.isEmpty) {
      _favoriteListings = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Fetch all favorite listings in parallel
    final futures = _favoriteIds.map((id) => _listingService.getListingById(id));
    final results = await Future.wait(futures);
    
    _favoriteListings = results
        .whereType<ListingModel>()
        .where((listing) => !listing.isSold) // Only show active listings
        .toList();
    
    // Sort by most recently favorited (preserve order from favorites array)
    _favoriteListings.sort((a, b) {
      final aIndex = _favoriteIds.indexOf(a.id);
      final bIndex = _favoriteIds.indexOf(b.id);
      return aIndex.compareTo(bIndex);
    });
    
    _isLoading = false;
    notifyListeners();
  }

  // ── Public methods ──────────────────────────────────────────────────────

  /// Check if a listing is favorited
  bool isFavorite(String listingId) {
    return _favoriteIds.contains(listingId);
  }

  /// Toggle favorite status for a listing
  Future<bool> toggleFavorite(String listingId) async {
    try {
      if (isFavorite(listingId)) {
        await _userRepository.removeFavorite(uid: _userId, itemId: listingId);
        return false;
      } else {
        await _userRepository.addFavorite(uid: _userId, itemId: listingId);
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Refresh favorites manually
  Future<void> refreshFavorites() async {
    await _loadFavoriteListings();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _listingsSubscription?.cancel();
    super.dispose();
  }
}