import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../services/listing_service.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/chat_view_model.dart';
import 'chat_list_page.dart';
import 'chat_detail_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'create_listing_page.dart';
import 'edit_listing_page.dart';
import 'favorites_page.dart';
import '../repositories/user_repository.dart';

class ProfilePage extends StatefulWidget {
  final String? sellerId;
  final UserModel? sellerUser;

  const ProfilePage({super.key, this.sellerId, this.sellerUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ListingService _listingService = ListingService();
  late bool _isOwnProfile;
  late String _profileUserId;
  Stream<List<ListingModel>>? _cachedStream;
  String? _lastUserId;
  UserModel? _fetchedSellerUser;
  bool _isLoadingUser = false;
  
  // NEW: Track own profile data refresh
  UserModel? _refreshedOwnUser;
  bool _isLoadingOwnUser = false;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = widget.sellerId == null;
    _profileUserId = widget.sellerId ?? '';
    
    if (!_isOwnProfile && widget.sellerUser == null) {
      _fetchSellerUser();
    }
    
    // NEW: Refresh own user data from Firestore to get latest profile fields
    if (_isOwnProfile) {
      _refreshOwnUserData();
    }
  }

  // NEW: Fetch latest user data from Firestore for own profile
  Future<void> _refreshOwnUserData() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = authVM.user?.uid;
    
    if (currentUserId == null) return;
    
    setState(() {
      _isLoadingOwnUser = true;
    });
    
    try {
      final userRepo = UserRepository();
      final freshUser = await userRepo.getUserById(currentUserId);
      
      if (freshUser != null && mounted) {
        setState(() {
          _refreshedOwnUser = freshUser;
        });
        
        // OPTIONAL: Also update AuthViewModel if needed for other screens
        // await authVM.refreshUserFromFirestore();
      }
    } catch (e) {
      debugPrint('Error refreshing own user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOwnUser = false;
        });
      }
    }
  }

  Future<void> _fetchSellerUser() async {
    setState(() => _isLoadingUser = true);
    try {
      final userRepo = UserRepository();
      final userDoc = await userRepo.getUserById(_profileUserId);
      
      if (userDoc != null) {
        _fetchedSellerUser = userDoc;
      }
    } catch (e) {
      debugPrint('Error fetching seller: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _openSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _openEditProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_outlined),
                title: const Text('Refresh Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _refreshOwnUserData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing profile data...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _handleSignOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<List<ListingModel>> _getListingsStream(String userId) {
    if (userId.isEmpty) {
      _cachedStream = const Stream<List<ListingModel>>.empty();
      _lastUserId = '';
    } else if (_lastUserId != userId) {
      _lastUserId = userId;
      _cachedStream = _listingService.getListingsBySeller(userId);
    }
    return _cachedStream ?? const Stream<List<ListingModel>>.empty();
  }

  String _getInitial(UserModel? user) {
    if (user == null) return '?';
    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  List<ListingModel> _activeListings(List<ListingModel> listings) {
    return listings.where((listing) => !listing.isSold).toList();
  }

  List<ListingModel> _soldListings(List<ListingModel> listings) {
    return listings.where((listing) => listing.isSold).toList();
  }

  void _openEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile coming soon!')),
    );
  }

  void _openShareProfile(UserModel? user) {
    if (user == null) return;
    
    final displayName = user.getDisplayIdentifier();
    final userType = user.userType == UserTypes.student ? 'Student' : 'Community Member';
    final academicInfo = user.getAcademicInfo();
    final communityRoleDisplay = user.getCommunityRoleDisplay();
    final memberSince = user.getFormattedMemberSince();
    
    String shareText = 'Check out $displayName\'s profile on UPamakal Campus Marketplace!\n\n';
    shareText += '👤 $userType\n';
    if (academicInfo.isNotEmpty) shareText += '🎓 $academicInfo\n';
    if (communityRoleDisplay.isNotEmpty) shareText += '🏘️ $communityRoleDisplay\n';
    shareText += '📅 $memberSince';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shareText,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this text with friends:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile text copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final authVM = context.read<AuthViewModel>();
    try {
      await authVM.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return;

    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatListPage()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _startChatWithSeller() async {
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.user?.uid;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to message the seller'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (currentUserId == _profileUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself!'),
          behavior: SnackBarBehavior.floating,
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
        sellerId: _profileUserId,
        listingId: '',
        listingTitle: 'Chat with ${widget.sellerUser?.getDisplayIdentifier() ?? 'Seller'}',
      );
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(chatRoom: room)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  Future<void> _editListing(ListingModel listing) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditListingPage(listing: listing),
      ),
    );
    
    if (result == true && mounted) {
      _refreshListings();
    }
  }

  Future<void> _deleteListing(ListingModel listing) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "${listing.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _listingService.deleteListing(listing.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${listing.title}" has been deleted'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshListings();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _refreshListings() {
    setState(() {
      _lastUserId = null;
    });
  }

  Future<void> _toggleSoldStatus(ListingModel listing) async {
    final newStatus = !listing.isSold;
    final action = newStatus ? 'mark as sold' : 'mark as available';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Mark as Sold' : 'Mark as Available'),
        content: Text(
          'Do you want to ${action} "${listing.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newStatus ? Colors.orange : Colors.green,
            ),
            child: Text(newStatus ? 'Mark Sold' : 'Mark Available'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _listingService.markAsSold(listing.id, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${listing.title}" has been ${action}ed'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        _refreshListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showListingOptions(ListingModel listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Edit Listing'),
              onTap: () {
                Navigator.pop(context);
                _editListing(listing);
              },
            ),
            ListTile(
              leading: Icon(
                listing.isSold ? Icons.visibility_outlined : Icons.sell_outlined,
                color: listing.isSold ? Colors.green : Colors.orange,
              ),
              title: Text(listing.isSold ? 'Mark as Available' : 'Mark as Sold'),
              onTap: () {
                Navigator.pop(context);
                _toggleSoldStatus(listing);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Listing',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteListing(listing);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildListingImage(ListingModel listing) {
    if (listing.imageBase64 != null && listing.imageBase64!.isNotEmpty) {
      return ImageService.base64ToImage(
        listing.imageBase64!,
        fit: BoxFit.cover,
      );
    } 
    else if (listing.imageBase64List.isNotEmpty) {
      return ImageService.base64ToImage(
        listing.imageBase64List.first,
        fit: BoxFit.cover,
      );
    }
    else {
      return _buildFallbackThumb(listing);
    }
  }

  Widget _buildStatValue(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Container(
                    color: const Color(0xFFF2F2F2),
                    child: _buildListingImage(listing),
                  ),
                ),
                if (listing.isSold)
                  Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 32),
                          SizedBox(height: 4),
                          Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isOwnProfile)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showListingOptions(listing),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: listing.isSold ? Colors.grey[600] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.formattedPrice,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: listing.isSold ? Colors.grey[600] : AppColors.primary,
                    decoration: listing.isSold ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (listing.isSold)
                  const SizedBox(height: 2),
                if (listing.isSold)
                  Text(
                    'Sold',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumb(ListingModel listing) {
    return Center(
      child: Icon(
        listing.category == 'Books' ? Icons.menu_book : Icons.devices,
        size: 34,
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 52,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getUserMainInfo(UserModel user) {
    if (user.userType == UserTypes.student) {
      final academicInfo = user.getAcademicInfo();
      if (academicInfo.isNotEmpty) return academicInfo;
      return 'Student';
    } else {
      final roleDisplay = user.getCommunityRoleDisplay();
      if (roleDisplay.isNotEmpty) return roleDisplay;
      return 'Community Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.user;
    
    if (_isOwnProfile && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // NEW: Determine which user to display
    UserModel? displayUser;
    if (_isOwnProfile) {
      // Use refreshed data if available, otherwise fall back to authVM.user
      displayUser = _refreshedOwnUser ?? user;
    } else {
      displayUser = widget.sellerUser ?? _fetchedSellerUser;
    }

    // NEW: Show loading indicator while refreshing own data
    if (_isOwnProfile && _isLoadingOwnUser && _refreshedOwnUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isOwnProfile ? 'My Profile' : 'Profile',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: _isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    );
                  },
                  tooltip: 'My Favorites',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: _openSettingsMenu,
                  tooltip: 'Settings',
                ),
              ]
            : [],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateListingPage(),
            ),
          );
          if (result == true) {
            // Refresh listings if a new one was created
            setState(() {});
          }
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ListingModel>>(
          stream: _getListingsStream(
            _isOwnProfile ? (user?.uid ?? '') : _profileUserId,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading listings: ${snapshot.error}'),
              );
            }
            
            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final allListings = snapshot.data ?? const <ListingModel>[];
            final activeListings = _activeListings(allListings);
            final soldListings = _soldListings(allListings);
            
            final displayName = displayUser?.displayName ?? displayUser?.email?.split('@').first ?? 'User';
            final email = displayUser?.email ?? 'No email available';
            final photoUrl = displayUser?.photoURL;
            final userType = displayUser?.userType;
            
            // NEW: Use actual communitySince from Firestore
            final memberSince = displayUser?.getFormattedMemberSince() ?? 'Member since 2024';
            
            final selectedListings = switch (_selectedTabIndex) {
              0 => activeListings,
              1 => const <ListingModel>[],
              2 => soldListings,
              _ => activeListings,
            };

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.primaryLight,
                                  backgroundImage:
                                      photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null
                                      ? Text(
                                          _getInitial(displayUser),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  displayName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // User Type Badge
                                if (userType != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: userType == UserTypes.student
                                          ? AppColors.primaryLight
                                          : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          userType == UserTypes.student
                                              ? Icons.school
                                              : Icons.people,
                                          size: 14,
                                          color: userType == UserTypes.student
                                              ? AppColors.primary
                                              : Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          userType == UserTypes.student
                                              ? 'Student'
                                              : 'Community Member',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: userType == UserTypes.student
                                                ? AppColors.primary
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 6),
                                
                                // Academic Info or Community Role (NOW WORKS with refreshed data)
                                if (displayUser != null) ...[
                                  if (displayUser.userType == UserTypes.student && 
                                      displayUser.getAcademicInfo().isNotEmpty)
                                    Text(
                                      displayUser.getAcademicInfo()!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  if (displayUser.userType == UserTypes.nonStudent &&
                                      displayUser.getCommunityRoleDisplay().isNotEmpty)
                                    Text(
                                      displayUser.getCommunityRoleDisplay(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                ],
                                
                                // Member Since (NOW uses actual communitySince)
                                Text(
                                  memberSince,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatValue(
                                      '${activeListings.length + soldListings.length}',
                                      'Total',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: Colors.grey.shade300,
                                    ),
                                    _buildStatValue(
                                      '${activeListings.length}',
                                      'Active',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: Colors.grey.shade300,
                                    ),
                                    _buildStatValue(
                                      '${soldListings.length}',
                                      'Sold',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: Colors.grey.shade300,
                                    ),
                                    _buildStatValue('4.9', 'Rating'),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    if (_isOwnProfile)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _openEditProfile,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.black26,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            minimumSize: const Size(0, 42),
                                          ),
                                          child: const Text(
                                            'Edit Profile',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _startChatWithSeller,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.black26,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            minimumSize: const Size(0, 42),
                                          ),
                                          child: const Text(
                                            'Message',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => _openShareProfile(displayUser),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          minimumSize: const Size(0, 42),
                                        ),
                                        child: const Text(
                                          'Share Profile',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'My Listings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEFF2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                _buildTabChip(
                                  'Active (${activeListings.length})',
                                  _selectedTabIndex == 0,
                                  () => setState(() => _selectedTabIndex = 0),
                                ),
                                _buildTabChip(
                                  'Reserved (0)',
                                  _selectedTabIndex == 1,
                                  () => setState(() => _selectedTabIndex = 1),
                                ),
                                _buildTabChip(
                                  'Sold (${soldListings.length})',
                                  _selectedTabIndex == 2,
                                  () => setState(() => _selectedTabIndex = 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedTabIndex == 1)
                            _buildEmptyState(
                              'No reserved listings yet',
                              'Reserved items will show up here.',
                            )
                          else if (_selectedTabIndex == 2)
                            soldListings.isEmpty
                                ? _buildEmptyState(
                                    'No sold listings yet',
                                    'Items you mark as sold will appear here.',
                                  )
                                : _buildListingsGrid(selectedListings)
                          else if (activeListings.isEmpty)
                            _buildEmptyState(
                              'No active listings yet',
                              'Create a listing to populate this section.',
                            )
                          else
                            _buildListingsGrid(selectedListings),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isSelected: false,
                onTap: () => _handleBottomNavTap(0),
              ),
              _buildNavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Search',
                isSelected: false,
                onTap: () => _handleBottomNavTap(1),
              ),
              const SizedBox(width: 48),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                isSelected: false,
                onTap: () => _handleBottomNavTap(2),
                showBadge: true,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingsGrid(List<ListingModel> listings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => _buildListingCard(listings[index]),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
              if (showBadge)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}