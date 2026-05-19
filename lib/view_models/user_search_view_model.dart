import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserSearchViewModel extends ChangeNotifier {
  final UserService _userService;

  String _searchQuery = '';
  List<UserModel> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  final List<String> _recentSearches = [];

  StreamSubscription? _searchSubscription;
  Timer? _debounceTimer;

  static const int maxRecentSearches = 8;

  UserSearchViewModel({required UserService userService})
      : _userService = userService;

  List<UserModel> get results => _results;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get hasQuery => _searchQuery.isNotEmpty;
  bool get hasResults => _results.isNotEmpty;

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

    _searchSubscription = _userService
        .searchUsers(_searchQuery.trim())
        .listen(
          (users) {
            _results = users;
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

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchSubscription?.cancel();
    _searchQuery = '';
    _clearResults();
  }

  void _clearResults() {
    _results = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchSubscription?.cancel();
    super.dispose();
  }
}
