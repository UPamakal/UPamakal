import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

enum SearchSortBy { relevance, priceLowHigh, priceHighLow, newest }

class SearchViewModel extends ChangeNotifier {
  final ListingService _listingService;

  String _searchQuery = '';
  List<ListingModel> _allResults = [];
  List<ListingModel> _filteredResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCondition;
  SearchSortBy _sortBy = SearchSortBy.relevance;
  final List<String> _recentSearches = [];

  StreamSubscription? _searchSubscription;
  Timer? _debounceTimer;

  static const int maxRecentSearches = 8;

  SearchViewModel({required ListingService listingService})
    : _listingService = listingService;

  // ── Getters ────────────────────────────────────────────────────────────

  List<ListingModel> get results => _filteredResults;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get selectedCondition => _selectedCondition;
  SearchSortBy get sortBy => _sortBy;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get hasQuery => _searchQuery.isNotEmpty;
  bool get hasResults => _filteredResults.isNotEmpty;
  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _selectedCondition != null;

  static const List<String> categories = [
    'Books',
    'Electronics',
    'Clothing',
    'Furniture',
    'Sports',
    'Food',
    'Services',
    'Other',
  ];

  static const List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Used',
  ];

  // ── Search ─────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _clearResults();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void submitSearch([String? query]) {
    _debounceTimer?.cancel();
    if (query != null) {
      _searchQuery = query;
    }
    if (_searchQuery.trim().isEmpty) return;

    _addToRecentSearches(_searchQuery.trim());
    _performSearch();
  }

  void _performSearch() {
    _searchSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _searchSubscription = _listingService
        .searchListings(_searchQuery.trim())
        .listen(
          (listings) {
            _allResults = listings;
            _applyFiltersAndSort();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Search failed. Please try again.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void browseCategory(String category) {
    _debounceTimer?.cancel();
    _searchSubscription?.cancel();

    // Set both category and query so hasQuery returns true,
    // which tells the UI to show _buildSearchResults instead of _buildBrowseState.
    _selectedCategory = category;
    _searchQuery = category;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _searchSubscription = _listingService
        .searchListings('') // Empty search to get all listings
        .listen(
          (listings) {
            _allResults = listings;
            _applyFiltersAndSort(); // Filters by _selectedCategory
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load listings. Please try again.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchSubscription?.cancel();
    _searchQuery = '';
    _selectedCategory = null;
    _clearResults();
  }

  void _clearResults() {
    _allResults = [];
    _filteredResults = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Recent Searches ────────────────────────────────────────────────────

  void _addToRecentSearches(String query) {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > maxRecentSearches) {
      _recentSearches.removeLast();
    }
    notifyListeners();
  }

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  // ── Filters & Sort ─────────────────────────────────────────────────────

  void setSelectedCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFiltersAndSort();
  }

  void setSelectedCondition(String? condition) {
    if (_selectedCondition == condition) return;
    _selectedCondition = condition;
    _applyFiltersAndSort();
  }

  void setSortBy(SearchSortBy sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _applyFiltersAndSort();
  }

  void clearAllFilters() {
    _selectedCategory = null;
    _minPrice = null;
    _maxPrice = null;
    _selectedCondition = null;
    _sortBy = SearchSortBy.relevance;
    _applyFiltersAndSort();
  }

  String get activeFilterCountLabel {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_selectedCondition != null) count++;
    return count > 0 ? '$count' : '';
  }

  void _applyFiltersAndSort() {
    var filtered = List<ListingModel>.from(_allResults);

    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where(
            (l) => l.category.toLowerCase() == _selectedCategory!.toLowerCase(),
          )
          .toList();
    }

    // Price range filter
    if (_minPrice != null) {
      filtered = filtered.where((l) => l.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((l) => l.price <= _maxPrice!).toList();
    }

    // Condition filter
    if (_selectedCondition != null) {
      filtered = filtered
          .where(
            (l) =>
                l.condition.toLowerCase() == _selectedCondition!.toLowerCase(),
          )
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case SearchSortBy.priceLowHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSortBy.priceHighLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SearchSortBy.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchSortBy.relevance:
      default:
        // Keep server order for relevance
        break;
    }

    _filteredResults = filtered;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchSubscription?.cancel();
    super.dispose();
  }
}