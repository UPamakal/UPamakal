import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'chat_detail_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import '../services/image_service.dart';
import '../widgets/adaptive_favorite_button.dart';

class ListingDetailPage extends StatelessWidget {
  final ListingModel listing;

  const ListingDetailPage({super.key, required this.listing});

  Future<void> _openChat(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to message the seller'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (currentUserId == listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself about your own listing!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final chatVM = context.read<ChatViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final room = await chatVM.startConversation(
        sellerId: listing.sellerId,
        listingId: listing.id,
        listingTitle: listing.title,
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(chatRoom: room)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
      }
    }
  }

  void _showOfferModal(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make an offer'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (currentUserId == listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot make an offer on your own listing!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final initialOffer = (listing.price * 0.88).round();
    final lowOffer = (listing.price * 0.82).round();
    final highOffer = (listing.price * 0.94).round();
    final amountController = TextEditingController(
      text: initialOffer.toString(),
    );
    final messageController = TextEditingController(
      text:
          'Hi! I\'m interested in buying this today. Is ${_formatPeso(initialOffer)} okay?',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var selectedOffer = initialOffer;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateOffer(int offer) {
              setModalState(() {
                selectedOffer = offer;
                amountController.text = offer.toString();
                amountController.selection = TextSelection.fromPosition(
                  TextPosition(offset: amountController.text.length),
                );
                messageController.text =
                    'Hi! I\'m interested in buying this today. Is ${_formatPeso(offer)} okay?';
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    22,
                    22,
                    28 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Make an offer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Send your proposed price to the seller',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _OfferListingSummary(listing: listing),
                      const SizedBox(height: 28),
                      Container(
                        width: 210,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '₱',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    selectedOffer = parsed;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _OfferChip(
                            label: _formatPeso(lowOffer),
                            selected: selectedOffer == lowOffer,
                            onPressed: () => updateOffer(lowOffer),
                          ),
                          const SizedBox(width: 12),
                          _OfferChip(
                            label: _formatPeso(initialOffer),
                            selected: selectedOffer == initialOffer,
                            onPressed: () => updateOffer(initialOffer),
                          ),
                          const SizedBox(width: 12),
                          _OfferChip(
                            label: _formatPeso(highOffer),
                            selected: selectedOffer == highOffer,
                            onPressed: () => updateOffer(highOffer),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: 'Message to seller '),
                              TextSpan(
                                text: '(Optional)',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Offer sent: ${_formatPeso(selectedOffer)}',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Send Offer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      amountController.dispose();
      messageController.dispose();
    });
  }

  static String _formatPeso(num amount) => '₱${amount.round()}';

  Widget _buildListingImage(ListingModel listing, BuildContext context) {
    // Build unique list of images (avoid duplicates)
    final Set<String> uniqueImages = {};
    
    // Add primary image if exists
    if (listing.imageBase64 != null && listing.imageBase64!.isNotEmpty) {
      uniqueImages.add(listing.imageBase64!);
    }
    
    // Add images from list
    for (final img in listing.imageBase64List) {
      if (img.isNotEmpty) {
        uniqueImages.add(img);
      }
    }
    
    final images = uniqueImages.toList();
    final primaryImage = images.isNotEmpty ? images.first : null;

    if (images.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: Stack(
          children: [
            Center(
              child: Icon(
                listing.category == 'Books' ? Icons.menu_book : Icons.devices,
                size: 100,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            // Back button overlay (left side)
            Positioned(
              top: 48,
              left: 18,
              child: AdaptiveIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
                imageBase64: primaryImage,
                size: 40,
                iconSize: 20,
              ),
            ),
            // Action buttons overlay (right side)
            Positioned(
              top: 48,
              right: 18,
              child: Row(
                children: [
                  AdaptiveIconButton(
                    icon: Icons.share,
                    onPressed: () {},
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  if (context.read<AuthViewModel>().user != null)
                    AdaptiveFavoriteButton(
                      listingId: listing.id,
                      userId: context.read<AuthViewModel>().user!.uid,
                      imageBase64: null,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          itemBuilder: (_, i) => ImageService.base64ToImage(images[i], fit: BoxFit.cover),
        ),
        // Gradient overlay - now properly layered but DOES NOT cover buttons
        // because buttons are rendered AFTER this gradient in the Stack
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Image counter indicator
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${images.length} photos',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Back button overlay (left side) - rendered AFTER gradient
        Positioned(
          top: 48,
          left: 16,
          child: AdaptiveIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            imageBase64: primaryImage,
            size: 40,
            iconSize: 20,
          ),
        ),
        
        // Action buttons overlay (right side) - rendered AFTER gradient
        Positioned(
          top: 48,
          right: 16,
          child: Row(
            children: [
              AdaptiveIconButton(
                icon: Icons.share,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                imageBase64: primaryImage,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              if (context.read<AuthViewModel>().user != null)
                AdaptiveFavoriteButton(
                  listingId: listing.id,
                  userId: context.read<AuthViewModel>().user!.uid,
                  imageBase64: primaryImage,
                  size: 20,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSafeFirstChar(String str) {
    if (str.isEmpty) return '?';
    return str[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isSeller = authVM.user?.uid == listing.sellerId;
    final isLoggedIn = authVM.user != null;
    final primaryImage = listing.imageBase64 ?? listing.imageBase64List.firstOrNull;
    final sellerUser = UserModel(
      uid: listing.sellerId,
      displayName: listing.sellerName,
      email: null,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            // REMOVED: leading property - back button now in image overlay
            flexibleSpace: FlexibleSpaceBar(
              background: _buildListingImage(listing, context),
            ),
            actions: const [], // Actions moved to image overlay for adaptability
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.formattedPrice,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          listing.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.location,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.timeAgo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Seller Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: InkWell(
                      borderRadius: BorderRadius.circular(48),
                      onTap: () async {
                        final currentUid = authVM.user?.uid;
                        if (currentUid != null &&
                            currentUid == listing.sellerId) {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.logout,
                                      color: Colors.redAccent,
                                    ),
                                    title: const Text(
                                      'Sign Out',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      try {
                                        await authVM.signOut();
                                        if (!context.mounted) return;
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) => const LoginPage(),
                                          ),
                                          (_) => false,
                                        );
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to sign out: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                sellerId: listing.sellerId,
                                sellerUser: sellerUser,
                              ),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          _getSafeFirstChar(listing.sellerName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      listing.sellerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Member since 2023'),
                    trailing: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              sellerId: listing.sellerId,
                              sellerUser: sellerUser,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Profile'),
                    ),
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(
                    height: 100 + MediaQuery.of(context).padding.bottom,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: isSeller
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openChat(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline),
                          SizedBox(width: 8),
                          Text(
                            'Chat Seller',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showOfferModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Make Offer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ListingIntentButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ListingIntentButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OfferListingSummary extends StatelessWidget {
  final ListingModel listing;

  const _OfferListingSummary({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: _buildThumbnailImage(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Seller: ${listing.sellerName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                listing.formattedPrice,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'ORIGINAL',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage() {
    if (listing.imageBase64 != null && listing.imageBase64!.isNotEmpty) {
      return ImageService.base64ToImage(
        listing.imageBase64!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      );
    } else if (listing.imageBase64List.isNotEmpty) {
      return ImageService.base64ToImage(
        listing.imageBase64List.first,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        color: AppColors.primaryLight,
        child: Icon(
          listing.category == 'Books'
              ? Icons.menu_book
              : Icons.devices,
          color: AppColors.primary,
        ),
      );
    }
  }
}

class _OfferChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _OfferChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: selected ? AppColors.primaryLight : Colors.white,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}