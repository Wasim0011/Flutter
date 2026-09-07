import 'package:go_router/go_router.dart';
import 'dart:async';
import 'deep_link_service.dart';

/// Notification Navigation Service
/// Singleton service that manages navigation from push notifications
class NotificationNavigationService {
  static final NotificationNavigationService _instance = NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  GoRouter? _router;
  final List<Map<String, dynamic>> _pendingNotifications = [];
  bool _isProcessing = false;

  /// Initialize with router instance
  void initialize(GoRouter router) {
    _router = router;
    _processPendingNotifications();
  }

  /// Queue a notification for navigation
  void queueNotification(Map<String, dynamic> data) {
    // Prevent duplicate notifications in queue
    final isDuplicate = _pendingNotifications.any((notification) =>
        notification['order_id'] == data['order_id'] &&
        notification['status'] == data['status']);
    
    if (isDuplicate) {
      return;
    }
    
    _pendingNotifications.add(data);
    _processPendingNotifications();
  }

  /// Process all pending notifications
  Future<void> _processPendingNotifications() async {
    if (_isProcessing || _router == null || _pendingNotifications.isEmpty) {
      return;
    }

    _isProcessing = true;

    // Wait a bit to ensure router is fully ready
    await Future.delayed(const Duration(milliseconds: 300));
    
    while (_pendingNotifications.isNotEmpty && _router != null) {
      final data = _pendingNotifications.removeAt(0);
      
      try {
        DeepLinkService.handleDeepLink(data, _router!);
        // Small delay between navigations
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Silently handle navigation errors
      }
    }

    _isProcessing = false;
  }

  /// Clear all pending notifications
  void clearPending() {
    _pendingNotifications.clear();
  }

  /// Check if router is ready
  bool get isReady => _router != null;
}
