import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../di/injection.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // DON'T show notification here - Firebase already shows it automatically
  // when app is in background/terminated state
  
  // Handle cache invalidation in background
  PushNotificationService._handleBackgroundCacheInvalidation(message);
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'inallcart_high_importance',
    'InAllCart Notifications',
    description: 'Important notifications from InAllCart',
    importance: Importance.high,
  );

  // Stream controller for push messages (for cache sync)
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  // Static stream for background messages
  static final _backgroundMessageController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onBackgroundMessage => _backgroundMessageController.stream;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase not configured yet - skip initialization
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await _initializeLocalNotifications();

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _processNotificationData(initialMessage.data);
      }

      await _saveFcmToken();
      messaging.onTokenRefresh.listen(_onTokenRefresh);
    } catch (e) {
      // Firebase messaging not properly configured - continue without push notifications
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  Future<void> _saveFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await getIt<StorageService>().setFcmToken(token);
      // Send token to backend
      await uploadTokenToServer();
    }
  }

  void _onTokenRefresh(String token) async {
    await getIt<StorageService>().setFcmToken(token);
    // Send updated token to backend
    await uploadTokenToServer();
  }

  Future<void> uploadTokenToServer() async {
    try {
      final token = await getIt<StorageService>().getFcmToken();
      if (token == null) return;
      final apiClient = getIt<ApiClient>();
      await apiClient.post(ApiEndpoints.fcmToken, data: {'token': token});
    } catch (e) {
      // Token will be sent on next app launch or login
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      getIt<StorageService>().saveNotification(
        title: message.notification!.title ?? AppConstants.appName,
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }

    // Emit to stream for cache sync
    _messageController.add({
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
      'data': message.data,
    });

    // Only show notification when app is in foreground
    // When app is in background/terminated, Firebase shows it automatically
    if (message.notification != null) {
      _showNotification(message);
    }
    
    // Process notification data for deep linking
    if (message.data.isNotEmpty) {
      _processNotificationData(message.data);
    }
  }

  static void _handleBackgroundCacheInvalidation(RemoteMessage message) {
    // Emit to background stream
    _backgroundMessageController.add({
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
      'data': message.data,
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (message.notification != null) {
      getIt<StorageService>().saveNotification(
        title: message.notification!.title ?? AppConstants.appName,
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
    _processNotificationData(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _processNotificationData(data);
    }
  }

  void _processNotificationData(Map<String, dynamic> data) {
    // Prevent duplicate processing of same notification
    if (_lastNotificationData != null && 
        _lastNotificationData!['order_id'] == data['order_id'] &&
        _lastNotificationData!['status'] == data['status']) {
      return;
    }
    
    _lastNotificationData = data;
  }
  
  // Store last notification data
  Map<String, dynamic>? _lastNotificationData;
  
  /// Get and clear last notification data
  Map<String, dynamic>? getAndClearLastNotification() {
    final data = _lastNotificationData;
    _lastNotificationData = null;
    return data;
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> subscribeToTopic(String topic) =>
      FirebaseMessaging.instance.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      FirebaseMessaging.instance.unsubscribeFromTopic(topic);

  Future<void> deleteToken() async {
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.delete(ApiEndpoints.fcmToken);
      await FirebaseMessaging.instance.deleteToken();
      await getIt<StorageService>().removeFcmToken();
    } catch (e) {
      // Ignore errors on logout
    }
  }

  void dispose() {
    _messageController.close();
  }
}
