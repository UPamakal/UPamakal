import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  String _currentUserId;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  NotificationViewModel({
    required NotificationService notificationService,
    required String currentUserId,
  })  : _notificationService = notificationService,
        _currentUserId = currentUserId {
    _configureForUser(currentUserId);
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  void updateCurrentUser(String userId) {
    if (userId == _currentUserId) return;
    _currentUserId = userId;
    _configureForUser(userId);
  }

  void _configureForUser(String userId) {
    _subscription?.cancel();
    if (userId.isEmpty) {
      _notifications = [];
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription =
        _notificationService.streamNotifications(_currentUserId).listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(_currentUserId, notificationId);
  }

  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead(_currentUserId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(_currentUserId, notificationId);
  }

  Future<void> clearAll() async {
    await _notificationService.clearAllNotifications(_currentUserId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
