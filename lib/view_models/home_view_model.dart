import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

class HomeViewModel extends ChangeNotifier {
  final ListingService _listingService;
  
  List<ListingModel> _allListings = [];
  List<ListingModel> _filteredListings = [];
  String _selectedCategory = 'All Items';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  
  StreamSubscription? _listingsSubscription;
  
  HomeViewModel({required ListingService listingService})
      : _listingService = listingService {
    _setupListingsListener();
  }
  
  void _setupListingsListener() {
    _isLoading = true;
    notifyListeners();
    
    _listingsSubscription?.cancel();
    _listingsSubscription = _listingService.getAllListings().listen((listings) {
      _allListings = listings;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Failed to load listings: $error';
      _isLoading = false;
      notifyListeners();
    });
  }
  
  List<ListingModel> get listings => _filteredListings;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;
  bool get hasListings => _filteredListings.isNotEmpty;
  bool get isSearching => _searchQuery.isNotEmpty;
  
  // Expanded categories list
  static const List<String> categories = [
    'All Items',
    'Books', 
    'Electronics',
    'Clothing',
    'Furniture',
    'Sports',
    'Food',
    'Services',
    'Other'
  ];
  
  void setSelectedTab(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    notifyListeners();
  }
  
  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    
    _listingsSubscription?.cancel();
    
    if (category == 'All Items') {
      _listingsSubscription = _listingService.getAllListings().listen((listings) {
        _allListings = listings;
        _applyFilters();
        notifyListeners();
      }, onError: (error) {
        _errorMessage = 'Failed to load listings: $error';
        notifyListeners();
      });
    } else {
      _listingsSubscription = _listingService.getListingsByCategory(category).listen((listings) {
        _allListings = listings;
        _applyFilters();
        notifyListeners();
      }, onError: (error) {
        _errorMessage = 'Failed to load listings: $error';
        notifyListeners();
      });
    }
  }
  
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    
    _listingsSubscription?.cancel();
    
    if (query.isNotEmpty) {
      _listingsSubscription = _listingService.searchListings(query).listen((listings) {
        _allListings = listings;
        _applyFilters();
        notifyListeners();
      }, onError: (error) {
        _errorMessage = 'Failed to search listings: $error';
        notifyListeners();
      });
    } else {
      setSelectedCategory(_selectedCategory);
    }
  }
  
  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    setSelectedCategory(_selectedCategory);
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void _applyFilters() {
    _filteredListings = List.from(_allListings);
    notifyListeners();
  }
  
  Future<void> refreshListings() async {
    setSelectedCategory(_selectedCategory);
  }
  
  Future<bool> saveListing(String listingId) async {
    // In production, get userId from AuthViewModel
    return true;
  }
  
  void onListingTap(ListingModel listing) {
    debugPrint('Listing tapped: ${listing.title}');
  }
  
  @override
  void dispose() {
    _listingsSubscription?.cancel();
    super.dispose();
  }
}