import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/search_view_model.dart';
import '../view_models/user_search_view_model.dart';
import '../models/listing_model.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import '../widgets/user_search_card.dart';
import 'listing_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isPeopleTab = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Auto-focus after first frame so the keyboard appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchVM = context.watch<SearchViewModel>();
    final userSearchVM = context.watch<UserSearchViewModel>();

    final activeQuery = _isPeopleTab ? userSearchVM.searchQuery : searchVM.searchQuery;
    if (_searchController.text != activeQuery) {
      _searchController.text = activeQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context, searchVM, userSearchVM),
            if (!_isPeopleTab && searchVM.hasQuery)
              _buildFilterBar(context, searchVM),
            Expanded(
              child: _isPeopleTab
                  ? _buildPeopleResults(context, userSearchVM)
                  : (searchVM.hasQuery
                      ? _buildSearchResults(context, searchVM)
                      : _buildBrowseState(context, searchVM)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildSearchHeader(
    BuildContext context,
    SearchViewModel searchVM,
    UserSearchViewModel userSearchVM,
  ) {
    final hasQuery = _isPeopleTab
        ? userSearchVM.hasQuery
        : searchVM.hasQuery;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (hasQuery)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      if (_isPeopleTab) {
                        userSearchVM.clearSearch();
                      } else {
                        searchVM.clearSearch();
                      }
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  if (_isPeopleTab) {
                    userSearchVM.setSearchQuery(value);
                  } else {
                    searchVM.setSearchQuery(value);
                  }
                },
                onSubmitted: (value) {
                  if (_isPeopleTab) {
                    userSearchVM.submitSearch();
                  } else {
                    searchVM.submitSearch();
                  }
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _isPeopleTab
                      ? 'Search people...'
                      : 'Search books, gadgets...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            if (_isPeopleTab) {
                              userSearchVM.clearSearch();
                            } else {
                              searchVM.clearSearch();
                            }
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tab toggle
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _tabItem(
                    label: 'Listings',
                    isSelected: !_isPeopleTab,
                    onTap: () {
                      if (_isPeopleTab) {
                        setState(() {
                          _isPeopleTab = false;
                        });
                        userSearchVM.clearSearch();
                        _searchController.clear();
                      }
                    },
                  ),
                  _tabItem(
                    label: 'People',
                    isSelected: _isPeopleTab,
                    onTap: () {
                      if (!_isPeopleTab) {
                        setState(() {
                          _isPeopleTab = true;
                        });
                        searchVM.clearSearch();
                        _searchController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF800000) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleResults(BuildContext context, UserSearchViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.submitSearch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!vm.hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No people found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different name or email',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${vm.results.length} result${vm.results.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: vm.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                UserSearchCard(user: vm.results[index]),
          ),
        ),
      ],
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, SearchViewModel searchVM) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _filterChip(
              context,
              label: searchVM.selectedCategory ?? 'Category',
              icon: Icons.category_outlined,
              isActive: searchVM.selectedCategory != null,
              onTap: () => _showCategoryPicker(context, searchVM),
            ),
            const SizedBox(width: 8),
            _filterChip(
              context,
              label: _priceLabel(searchVM),
              icon: Icons.attach_money,
              isActive: searchVM.minPrice != null || searchVM.maxPrice != null,
              onTap: () => _showPriceSheet(context, searchVM),
            ),
            const SizedBox(width: 8),
            _filterChip(
              context,
              label: searchVM.selectedCondition ?? 'Condition',
              icon: Icons.info_outline,
              isActive: searchVM.selectedCondition != null,
              onTap: () => _showConditionPicker(context, searchVM),
            ),
            const SizedBox(width: 8),
            _filterChip(
              context,
              label: _sortLabel(searchVM.sortBy),
              icon: Icons.sort,
              isActive: searchVM.sortBy != SearchSortBy.relevance,
              onTap: () => _showSortPicker(context, searchVM),
            ),
            if (searchVM.hasActiveFilters) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => searchVM.clearAllFilters(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Clear${searchVM.activeFilterCountLabel.isNotEmpty ? " (${searchVM.activeFilterCountLabel})" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _priceLabel(SearchViewModel vm) {
    if (vm.minPrice != null && vm.maxPrice != null) {
      return '₱${vm.minPrice!.toInt()} - \$${vm.maxPrice!.toInt()}';
    } else if (vm.minPrice != null) {
      return '≥ ₱${vm.minPrice!.toInt()}';
    } else if (vm.maxPrice != null) {
      return '≤ ₱${vm.maxPrice!.toInt()}';
    }
    return 'Price';
  }

  String _sortLabel(SearchSortBy sort) {
    switch (sort) {
      case SearchSortBy.priceLowHigh:
        return 'Price ↑';
      case SearchSortBy.priceHighLow:
        return 'Price ↓';
      case SearchSortBy.newest:
        return 'Newest';
      case SearchSortBy.relevance:
      default:
        return 'Sort';
    }
  }

  // ── Results ────────────────────────────────────────────────────────────

  Widget _buildSearchResults(BuildContext context, SearchViewModel searchVM) {
    if (searchVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchVM.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              searchVM.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => searchVM.submitSearch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!searchVM.hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${searchVM.results.length} result${searchVM.results.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: searchVM.results.length,
            itemBuilder: (context, index) =>
                _buildResultCard(context, searchVM.results[index], searchVM),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    ListingModel listing,
    SearchViewModel searchVM,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFF0F0F0),
                    child: _buildListingImage(listing),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.formattedPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.condition,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingImage(ListingModel listing) {
    if (listing.imageBase64 != null && listing.imageBase64!.isNotEmpty) {
      return ImageService.base64ToImage(listing.imageBase64!, fit: BoxFit.cover);
    } else if (listing.imageBase64List.isNotEmpty) {
      return ImageService.base64ToImage(listing.imageBase64List.first,
          fit: BoxFit.cover);
    } else {
      return Center(
        child: Icon(
          listing.category == 'Books' ? Icons.menu_book : Icons.devices,
          size: 52,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      );
    }
  }

  // ── Browse State (no query) ────────────────────────────────────────────

    Widget _buildBrowseState(BuildContext context, SearchViewModel searchVM) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchVM.recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => searchVM.clearRecentSearches(),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: searchVM.recentSearches.map((query) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = query;
                      searchVM.submitSearch(query);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            query,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => searchVM.removeRecentSearch(query),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ],
            const Text(
              'Browse Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemCount: SearchViewModel.categories.length,
              itemBuilder: (context, index) {
                final category = SearchViewModel.categories[index];
                return GestureDetector(
                  onTap: () {
                    if (searchVM.hasQuery) {
                      // Already have results — just filter them locally
                      searchVM.setSelectedCategory(category);
                    } else {
                      // No results loaded yet — fetch all then filter by category.
                      // Also sync the text field so it matches _searchQuery in the VM.
                      _searchController.text = category;
                      searchVM.browseCategory(category);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          _categoryIcon(category),
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Books':
        return Icons.menu_book;
      case 'Electronics':
        return Icons.devices;
      case 'Clothing':
        return Icons.checkroom;
      case 'Furniture':
        return Icons.chair;
      case 'Sports':
        return Icons.sports_soccer;
      case 'Food':
        return Icons.restaurant;
      case 'Services':
        return Icons.handyman;
      default:
        return Icons.category;
    }
  }

  // ── Bottom Sheets ──────────────────────────────────────────────────────

  /// Drag handle used at the top of every bottom sheet.
  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Category Picker ────────────────────────────────────────────────────

  void _showCategoryPicker(BuildContext context, SearchViewModel searchVM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // StatefulBuilder lets the sheet rebuild when selectedCategory changes
      // so checkmarks update without closing and reopening the sheet.
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _sheetHandle(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _categoryOption(
                  label: 'All Categories',
                  icon: Icons.apps,
                  isSelected: searchVM.selectedCategory == null,
                  onTap: () {
                    // setSelectedCategory(null) has an early-return guard when
                    // _selectedCategory is already null, which is fine — the
                    // sheet still closes correctly.
                    searchVM.setSelectedCategory(null);
                    // No submitSearch() — setSelectedCategory calls
                    // _applyFiltersAndSort internally (local filter, no network).
                    Navigator.pop(ctx);
                  },
                ),
                ...SearchViewModel.categories.map((cat) {
                  return _categoryOption(
                    label: cat,
                    icon: _categoryIcon(cat),
                    isSelected: searchVM.selectedCategory == cat,
                    onTap: () {
                      searchVM.setSelectedCategory(cat);
                      // No submitSearch() — local filter only.
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ── Price Sheet ────────────────────────────────────────────────────────

  void _showPriceSheet(BuildContext context, SearchViewModel searchVM) {
    // Local controllers pre-filled with current values
    final minController = TextEditingController(
      text: searchVM.minPrice != null
          ? searchVM.minPrice!.toInt().toString()
          : '',
    );
    final maxController = TextEditingController(
      text: searchVM.maxPrice != null
          ? searchVM.maxPrice!.toInt().toString()
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows sheet to resize for keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          // Pushes the sheet up when the keyboard appears
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const Text(
                    'Filter by Price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _priceField(
                          controller: minController,
                          label: 'Min Price',
                          hint: 'e.g. 10',
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '–',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _priceField(
                          controller: maxController,
                          label: 'Max Price',
                          hint: 'e.g. 500',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Clear button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            searchVM.setPriceRange(null, null);
                            // No submitSearch() — setPriceRange calls
                            // _applyFiltersAndSort internally (local, no network).
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final min = double.tryParse(minController.text);
                            final max = double.tryParse(maxController.text);
                            searchVM.setPriceRange(min, max);
                            // No submitSearch() — setPriceRange calls
                            // _applyFiltersAndSort internally (local, no network).
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _priceField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixText: '₱ ',
            prefixStyle:
                const TextStyle(color: Colors.black87, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Condition Picker ───────────────────────────────────────────────────

  void _showConditionPicker(BuildContext context, SearchViewModel searchVM) {
    // Labels must exactly match SearchViewModel.conditions for filter matching.
    const conditions = [
      ('New', Icons.fiber_new_outlined, 'Sealed or unused, in original packaging'),
      ('Like New', Icons.star_outline, 'Used once or twice, no signs of wear'),
      ('Good', Icons.thumb_up_outlined, 'Minor signs of use, fully functional'),
      ('Fair', Icons.thumbs_up_down_outlined, 'Visible wear but works perfectly'),
      ('Used', Icons.build_outlined, 'Shows wear, fully functional'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _sheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Select Condition',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              // "Any" option
              _conditionOption(
                label: 'Any Condition',
                subtitle: 'Show all listings',
                icon: Icons.layers_outlined,
                isSelected: searchVM.selectedCondition == null,
                onTap: () {
                  searchVM.setSelectedCondition(null);
                  // No submitSearch() — setSelectedCondition calls
                  // _applyFiltersAndSort internally (local filter, no network).
                  Navigator.pop(ctx);
                },
              ),
              ...conditions.map((c) {
                final (label, icon, subtitle) = c;
                return _conditionOption(
                  label: label,
                  subtitle: subtitle,
                  icon: icon,
                  isSelected: searchVM.selectedCondition == label,
                  onTap: () {
                    searchVM.setSelectedCondition(label);
                    // No submitSearch() — local filter only.
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _conditionOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ── Sort Picker ────────────────────────────────────────────────────────

  void _showSortPicker(BuildContext context, SearchViewModel searchVM) {
    const sortOptions = [
      (SearchSortBy.relevance, 'Most Relevant', Icons.auto_awesome_outlined),
      (SearchSortBy.newest, 'Newest First', Icons.schedule_outlined),
      (SearchSortBy.priceLowHigh, 'Price: Low to High', Icons.arrow_upward),
      (SearchSortBy.priceHighLow, 'Price: High to Low', Icons.arrow_downward),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _sheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...sortOptions.map((opt) {
                final (sortBy, label, icon) = opt;
                final isSelected = searchVM.sortBy == sortBy;
                return InkWell(
                  onTap: () {
                    searchVM.setSortBy(sortBy);
                    // No submitSearch() — setSortBy calls _applyFiltersAndSort
                    // internally (local re-sort only, no network call).
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check,
                              size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}