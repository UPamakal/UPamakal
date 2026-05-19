import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../views/profile_page.dart';

class UserSearchCard extends StatelessWidget {
  final UserModel user;

  const UserSearchCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(sellerUser: user, sellerId: user.uid),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF800000).withValues(alpha: 0.1),
              child: user.photoURL != null && user.photoURL!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                      ),
                    )
                  : _buildInitialsAvatar(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.getDisplayIdentifier(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (user.userType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF800000).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            UserTypes.getDisplayName(user.userType!),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF800000),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (user.averageRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Color(0xFFFFB800)),
                            const SizedBox(width: 2),
                            Text(
                              user.averageRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final name = user.getDisplayIdentifier();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Text(
      initials,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF800000),
      ),
    );
  }
}
