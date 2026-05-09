import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../services/listing_service.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import 'chat_list_page.dart';
import 'home_page.dart';
import 'login_page.dart';

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

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = widget.sellerId == null;
    _profileUserId = widget.sellerId ?? '';
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
    // Only recreate stream if userId changed
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
    if (user == null) return 'U';
    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
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
    
    final displayName = user.displayName ?? user.email ?? 'User';
    final shareText = 'Check out $displayName\'s profile on UPamakal Campus Marketplace!';
    
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
              color: selected ? AppColors.primary : AppColors.primary,
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
                    child: listing.imageUrl != null
                        ? Image.network(
                            listing.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackThumb(listing),
                          )
                        : _buildFallbackThumb(listing),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
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
                    child: const Icon(Icons.edit, size: 14, color: Colors.black87),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.user;

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
                  icon: const Icon(Icons.settings_outlined, color: Colors.black),
                  onPressed: _openSettingsMenu,
                ),
              ]
            : [],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ListingModel>>(
          stream: _getListingsStream(_isOwnProfile ? (user?.uid ?? '') : _profileUserId),
          builder: (context, snapshot) {
            // Handle error state
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading listings: ${snapshot.error}'),
              );
            }
            
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final allListings = snapshot.data ?? const <ListingModel>[];
            final activeListings = _activeListings(allListings);
            final soldListings = _soldListings(allListings);
            
            UserModel? profileUser = _isOwnProfile ? user : widget.sellerUser;
            final displayName = profileUser?.displayName ?? profileUser?.email ?? 'User';
            final email = profileUser?.email ?? 'No email available';
            final photoUrl = profileUser?.photoURL;

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
                                          _getInitial(profileUser),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BS COMPUTER SCIENCE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Member since 2024',
                                  style: TextStyle(
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
                                          onPressed: () {
                                            final authVM = context.read<AuthViewModel>();
                                            if (authVM.user?.uid != _profileUserId) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => ChatListPage(),
                                                ),
                                              );
                                            }
                                          },
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
                                        onPressed: () => _openShareProfile(profileUser),
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