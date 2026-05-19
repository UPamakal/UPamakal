import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// --------------------------------------------------------------------------
/// FCMService
/// --------------------------------------------------------------------------
/// Handles push notification registration, token management, and listeners.
/// --------------------------------------------------------------------------
class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _listenersInitialized = false;
  String? _currentUserId;
  Future<void> Function(String chatRoomId)? _onChatOpened;

  void setChatOpenHandler(Future<void> Function(String chatRoomId) handler) {
    _onChatOpened = handler;
  }

  /// Initialize FCM and local notifications
  Future<void> initialize(String userId) async {
    if (userId.isEmpty) return;
    _currentUserId = userId;
    if (_initialized) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _updateUserToken(userId, token);
      }
      return;
    }

    _initialized = true;

    // Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateUserToken(userId, token);
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        final currentUserId = _currentUserId;
        if (currentUserId != null) {
          _updateUserToken(currentUserId, newToken);
        }
      });

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final chatRoomId = response.payload;
          if (chatRoomId != null && chatRoomId.isNotEmpty) {
            final handler = _onChatOpened;
            if (handler != null) {
              unawaited(handler(chatRoomId));
            }
          }
        },
      );

      // Listen for foreground messages
      if (!_listenersInitialized) {
        _listenersInitialized = true;
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpen(initialMessage);
        }
      }
    }
  }

  /// Update user's FCM token in Firestore
  Future<void> _updateUserToken(String userId, String token) async {
    if (userId.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  /// Show a local notification when the app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data['chatRoomId'] as String?,
      );
    }
  }

  Future<void> _handleMessageOpen(RemoteMessage message) async {
    if (message.data['type'] != 'chat_message') return;

    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId is! String || chatRoomId.isEmpty) return;

    await _onChatOpened?.call(chatRoomId);
  }
}
