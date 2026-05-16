import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import '../../view_models/favorites_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/listing_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../views/listing_detail_page.dart';
import '../views/home_page.dart';
import '../../models/listing_model.dart';
import '../../repositories/user_repository.dart';
import '../widgets/animated_grid_item.dart';
import '../widgets/adaptive_favorite_button.dart';

/// --------------------------------------------------------------------------
/// FavoritesPage - Editorial/Magazine Aesthetic
/// --------------------------------------------------------------------------
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final userId = authVM.user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Sign in to view favorites',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => FavoritesViewModel(
        userRepository: UserRepository(),
        listingService: ListingService(),
        userId: userId,
      ),
      child: const _FavoritesPageContent(),
    );
  }
}

class _FavoritesPageContent extends StatefulWidget {
  const _FavoritesPageContent();

  @override
  State<_FavoritesPageContent> createState() => _FavoritesPageContentState();
}

class _FavoritesPageContentState extends State<_FavoritesPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesVM = context.watch<FavoritesViewModel>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildEditorialAppBar(context, favoritesVM, isDarkMode),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await favoritesVM.refreshFavorites();
                      _staggerController.reset();
                      _staggerController.forward();
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeaderSection(context, favoritesVM, isDarkMode),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: _buildDynamicGrid(context, favoritesVM),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                  if (favoritesVM.isLoading && favoritesVM.favoriteListings.isEmpty)
                    _buildLoadingOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialAppBar(
    BuildContext context,
    FavoritesViewModel favoritesVM,
    bool isDarkMode,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withValues(alpha: 0.8) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CURATED',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FAVORITES',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.only(top: 6),
                color: AppColors.primary,
              ),
            ],
          ),
          if (favoritesVM.hasFavorites)
            TextButton(
              onPressed: () =>
                  _showClearFavoritesDialog(context, favoritesVM),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: Colors.red.shade400,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 18),
                  const SizedBox(width: 4),
                  const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    FavoritesViewModel favoritesVM,
    bool isDarkMode,
  ) {
    if (!favoritesVM.hasFavorites && !favoritesVM.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your collection',
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.8,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${favoritesVM.favoriteListings.length} saved items',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicGrid(
    BuildContext context,
    FavoritesViewModel favoritesVM,
  ) {
    if (favoritesVM.errorMessage != null) {
      return SliverFillRemaining(
        child: _buildErrorState(context, favoritesVM),
      );
    }

    if (!favoritesVM.hasFavorites) {
      return SliverFillRemaining(
        child: _buildEmptyState(context),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final listing = favoritesVM.favoriteListings[index];
          return AnimatedGridItem(
            index: index,
            animationController: _staggerController,
            startDelay: 0.03,
            interval: 0.04,
            child: FavoriteCard(
              listing: listing,
              viewModel: favoritesVM,
              isTall: false,
              scrollController: _scrollController,
            ),
          );
        },
        childCount: favoritesVM.favoriteListings.length,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FavoritesViewModel favoritesVM) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            favoritesVM.errorMessage!,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => favoritesVM.clearError(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 72,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start hearting items you love',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => route.isFirst,
                );
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Marketplace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.8),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  void _showClearFavoritesDialog(
      BuildContext context, FavoritesViewModel favoritesVM) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Clear all favorites?',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will remove ${favoritesVM.favoriteListings.length} items from your collection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final listingsToRemove =
                            List.of(favoritesVM.favoriteListings);
                        for (final listing in listingsToRemove) {
                          await favoritesVM.toggleFavorite(listing.id);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All favorites cleared'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Redesigned favorite card component with adaptive styling
class FavoriteCard extends StatelessWidget {
  final ListingModel listing;
  final FavoritesViewModel viewModel;
  final bool isTall;
  final ScrollController scrollController;

  const FavoriteCard({
    super.key,
    required this.listing,
    required this.viewModel,
    required this.isTall,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Image(
                      image: _getImageProvider(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          listing.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: AdaptiveFavoriteButton(
                        listingId: listing.id,
                        userId: viewModel.userId,
                        imageBase64: listing.imageBase64 ?? 
                            (listing.imageBase64List.isNotEmpty 
                                ? listing.imageBase64List.first 
                                : null),
                        size: 20,
                        showBackground: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: isTall ? 15 : 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.formattedPrice,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 11,
                                color: isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                listing.location,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          listing.condition,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: isDarkMode
                                ? Colors.white54
                                : Colors.black54,
                          ),
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

  ImageProvider _getImageProvider() {
    if (listing.imageBase64 != null && listing.imageBase64!.isNotEmpty) {
      return ImageService.base64ToImageProvider(listing.imageBase64!);
    } else if (listing.imageBase64List.isNotEmpty) {
      return ImageService.base64ToImageProvider(listing.imageBase64List.first);
    } else {
      return const AssetImage('assets/images/UPamakal.png');
    }
  }
}