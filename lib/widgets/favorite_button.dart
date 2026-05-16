import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/favorites_view_model.dart';
import '../repositories/user_repository.dart';
import '../services/listing_service.dart';
import '../utils/constants.dart';

/// --------------------------------------------------------------------------
/// FavoriteButton
/// --------------------------------------------------------------------------
/// A reusable heart button that toggles favorites for a listing.
/// Creates its own FavoritesViewModel when needed.
/// --------------------------------------------------------------------------
class FavoriteButton extends StatefulWidget {
  final String listingId;
  final String userId;
  final double size;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.listingId,
    required this.userId,
    this.size = 24,
    this.onToggle,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late FavoritesViewModel _favoritesVM;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _favoritesVM = FavoritesViewModel(
      userRepository: UserRepository(),
      listingService: ListingService(),
      userId: widget.userId,
    );
  }

  @override
  void dispose() {
    _favoritesVM.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final isNowFavorite = await _favoritesVM.toggleFavorite(widget.listingId);

      if (mounted) {
        final message = isNowFavorite
            ? 'Added to favorites'
            : 'Removed from favorites';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isNowFavorite ? Colors.green.shade700 : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onToggle?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _favoritesVM,
      builder: (context, _) {
        final isFavorite = _favoritesVM.isFavorite(widget.listingId);
        
        return GestureDetector(
          onTap: _toggleFavorite,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: widget.size,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
        );
      },
    );
  }
}