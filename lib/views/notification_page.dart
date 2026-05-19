import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../view_models/notification_view_model.dart';
import '../services/listing_service.dart';
import '../services/chat_service.dart';
import '../widgets/notification_tile.dart';
import 'chat_detail_page.dart';
import 'listing_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (vm.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () => vm.markAllAsRead(),
            ),
          if (vm.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all notifications?'),
                    content: const Text(
                        'This will permanently delete all notifications.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await vm.clearAll();
                }
              },
            ),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, NotificationViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone mines, steals, or grabs\nyour listing, you\'ll see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        itemCount: vm.notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notif = vm.notifications[index];
          return NotificationTile(
            notification: notif,
            onTap: () => _handleTap(context, notif),
            onDelete: () => _handleDelete(context, notif, vm),
          );
        },
      ),
    );
  }

  void _handleDelete(BuildContext context, NotificationModel notif, NotificationViewModel vm) {
    vm.deleteNotification(notif.id);
  }

  void _handleTap(BuildContext context, NotificationModel notif) async {
    final vm = context.read<NotificationViewModel>();

    if (!notif.isRead) {
      vm.markAsRead(notif.id);
    }

    if (notif.type == 'chat_message' && notif.chatRoomId != null) {
      final chatService = context.read<ChatService>();
      final room = await chatService.getChatRoom(notif.chatRoomId!);
      if (!context.mounted) return;
      if (room != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(chatRoom: room),
          ),
        );
      }
    } else if (notif.listingId != null) {
      final listingService = context.read<ListingService>();
      final listing = await listingService.getListingById(notif.listingId!);
      if (!context.mounted) return;
      if (listing != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      }
    }
  }
}
