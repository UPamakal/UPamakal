import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'chat_detail_page.dart';
import 'profile_page.dart';
import 'edit_listing_page.dart';
import '../services/image_service.dart';
import '../services/user_action_service.dart';
import '../widgets/favorite_button.dart';

const double _defaultMineMultiplier = 0.85;
const double _defaultStealMultiplier = 1.25;
const double _defaultGrabMultiplier = 1.50;

class ListingDetailPage extends StatefulWidget {
  final ListingModel listing;
  const ListingDetailPage({super.key, required this.listing});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final UserActionService _actionService = UserActionService();
  late Stream<Map<String, bool>> _lockStatusStream;

  @override
  void initState() {
    super.initState();
    _lockStatusStream = _actionService.watchActionStatus(widget.listing.id);
  }

  Future<void> _handleAction(String action, int amount) async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authVM.user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use this feature')),
      );
      return;
    }
    if (userId == widget.listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot perform actions on your own listing')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} this item?'),
        content: Text('Are you sure you want to $action this item for ₱$amount?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B0000)),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _actionService.takeAction(
      listingId: widget.listing.id,
      action: action,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action offer of ₱$amount sent to seller!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sorry, someone already ${action}ed this item.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to message the seller'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (currentUserId == widget.listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself about your own listing!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final chatVM = context.read<ChatViewModel>();
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final room = await chatVM.startConversation(
        sellerId: widget.listing.sellerId,
        listingId: widget.listing.id,
        listingTitle: widget.listing.title,
      );
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(chatRoom: room)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
      }
    }
  }

  void _showOfferModal(BuildContext context, {int? presetAmount}) {
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to make an offer')));
      return;
    }
    if (currentUserId == widget.listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot make an offer on your own listing!')));
      return;
    }
    final initialOffer = presetAmount ?? (widget.listing.price * 0.88).round();
    final lowOffer = (widget.listing.price * 0.75).round();
    final highOffer = (widget.listing.price * 0.90).round();
    final amountController = TextEditingController(text: initialOffer.toString());
    final messageController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var selectedOffer = initialOffer;
        return StatefulBuilder(builder: (ctx, setModalState) {
          void updateOffer(int offer) {
            setModalState(() {
              selectedOffer = offer;
              amountController.text = offer.toString();
              amountController.selection = TextSelection.fromPosition(TextPosition(offset: amountController.text.length));
            });
          }
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Make an Offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _OfferListingSummary(listing: widget.listing),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(prefixText: '₱ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OfferChip(label: '₱$lowOffer', selected: selectedOffer == lowOffer, onPressed: () => updateOffer(lowOffer)),
                      const SizedBox(width: 12),
                      _OfferChip(label: '₱$initialOffer', selected: selectedOffer == initialOffer, onPressed: () => updateOffer(initialOffer)),
                      const SizedBox(width: 12),
                      _OfferChip(label: '₱$highOffer', selected: selectedOffer == highOffer, onPressed: () => updateOffer(highOffer)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: 'Optional message to seller...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer sent: ₱${amountController.text}')));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Send Offer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() { amountController.dispose(); messageController.dispose(); });
  }

  String _getSafeFirstChar(String str) => str.isEmpty ? '?' : str[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isSeller = authVM.user?.uid == widget.listing.sellerId;
    final currentUserId = authVM.user?.uid;
    final primaryImage = widget.listing.imageBase64 ?? (widget.listing.imageBase64List.isNotEmpty ? widget.listing.imageBase64List.first : null);
    final sellerUser = UserModel(uid: widget.listing.sellerId, displayName: widget.listing.sellerName, email: null);

    final mineAmount = widget.listing.minePrice?.toInt() ?? (widget.listing.price * _defaultMineMultiplier).round();
    final stealAmount = widget.listing.stealPrice?.toInt() ?? (widget.listing.price * _defaultStealMultiplier).round();
    final grabAmount = widget.listing.grabPrice?.toInt() ?? (widget.listing.price * _defaultGrabMultiplier).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                        child: primaryImage != null
                            ? ImageService.base64ToImage(primaryImage, height: 380, width: double.infinity, fit: BoxFit.cover)
                            : Container(
                                height: 380,
                                color: AppColors.primaryLight,
                                child: Center(
                                  child: Icon(
                                    widget.listing.category == 'Books' ? Icons.menu_book : Icons.devices,
                                    size: 80,
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0, height: 120,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 48, left: 16,
                        child: _FloatingActionCircle(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
                      ),
                      Positioned(
                        top: 48, right: 16,
                        child: Row(
                          children: [
                            _FloatingActionCircle(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share coming soon'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)),
                              child: const Icon(Icons.share, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            if (currentUserId != null)
                              _FloatingActionCircle(
                                onTap: () {},
                                child: FavoriteButton(listingId: widget.listing.id, userId: currentUserId, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.listing.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111111), height: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(widget.listing.formattedPrice, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF8B0000))),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                              child: Text(widget.listing.condition, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7A7A7A))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Color(0xFF7A7A7A)),
                            const SizedBox(width: 6),
                            Text(widget.listing.location, style: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A))),
                            const SizedBox(width: 20),
                            const Icon(Icons.access_time, size: 16, color: Color(0xFF7A7A7A)),
                            const SizedBox(width: 6),
                            Text(widget.listing.timeAgo, style: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                        const SizedBox(height: 10),
                        Text(widget.listing.description, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF111111))),
                        const SizedBox(height: 16),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: Color(0xFF111111)),
                            children: [
                              TextSpan(text: 'Meetup preference: ', style: TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: 'On-campus, near the library', style: TextStyle(fontWeight: FontWeight.normal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(_getSafeFirstChar(widget.listing.sellerName), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.listing.sellerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                                const SizedBox(height: 2),
                                const Text('Member since 2023', style: TextStyle(fontSize: 13, color: Color(0xFF7A7A7A))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text('4.9', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(sellerId: widget.listing.sellerId, sellerUser: sellerUser)));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B0000),
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      ),
                      child: const Text('View Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<Map<String, bool>>(
                      stream: _lockStatusStream,
                      initialData: {'mine': false, 'steal': false, 'grab': false},
                      builder: (context, snapshot) {
                        final lockStatus = snapshot.data ?? {'mine': false, 'steal': false, 'grab': false};
                        return Row(
                          children: [
                            _buildOfferChip('Mine', mineAmount, locked: lockStatus['mine'] == true),
                            const SizedBox(width: 12),
                            _buildOfferChip('Steal', stealAmount, locked: lockStatus['steal'] == true),
                            const SizedBox(width: 12),
                            _buildOfferChip('Grab', grabAmount, locked: lockStatus['grab'] == true),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isSeller)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleEditListing(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            elevation: 2,
                            shadowColor: const Color(0xFF8B0000).withOpacity(0.3),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openChat(context),
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Chat Seller'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B0000),
                                side: const BorderSide(color: Color(0xFF8B0000)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showOfferModal(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B0000),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                elevation: 2,
                                shadowColor: const Color(0xFF8B0000).withOpacity(0.3),
                              ),
                              child: const Text('Make Offer', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditListing(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingPage(listing: widget.listing),
      ),
    );

    // Auto-refresh listing details if edit was successful
    if (result == true && mounted) {
      _refreshListingData();
    }
  }

  void _refreshListingData() {
    // Trigger a rebuild to fetch the latest listing data
    setState(() {
      // This will cause the page to rebuild and potentially fetch updated data
      // In a future enhancement, consider adding a Stream to auto-update from Firestore
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listing updated successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildOfferChip(String label, int amount, {required bool locked}) {
    return Expanded(
      child: GestureDetector(
        onTap: locked ? null : () => _handleAction(label.toLowerCase(), amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: locked ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: locked ? Colors.grey.shade300 : const Color(0xFF8B0000)),
            boxShadow: locked ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: locked ? Colors.grey.shade500 : const Color(0xFF8B0000), fontWeight: FontWeight.w600, fontSize: 12)),
                Text('₱$amount', style: TextStyle(color: locked ? Colors.grey.shade500 : const Color(0xFF8B0000), fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------- Reusable components -------------------------
class _FloatingActionCircle extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _FloatingActionCircle({required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _OfferListingSummary extends StatelessWidget {
  final ListingModel listing;
  const _OfferListingSummary({required this.listing});
  @override
  Widget build(BuildContext context) {
    final primaryImage = listing.imageBase64 ?? (listing.imageBase64List.isNotEmpty ? listing.imageBase64List.first : null);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F2EE), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: primaryImage != null
                ? ImageService.base64ToImage(primaryImage, width: 48, height: 48, fit: BoxFit.cover)
                : Container(width: 48, height: 48, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Seller: ${listing.sellerName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(listing.formattedPrice, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  const _OfferChip({required this.label, required this.selected, required this.onPressed});
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