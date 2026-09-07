import 'package:flutter/material.dart';
import '../di/injection.dart';
import '../services/push_notification_service.dart';
import '../services/notification_navigation_service.dart';

/// Deep Link Handler Widget
/// Processes pending notification deep links when app is ready
class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({
    super.key,
    required this.child,
  });

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> with WidgetsBindingObserver {
  bool _hasProcessedInitial = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Process any pending notification after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingNotification();
      _hasProcessedInitial = true;
    });

    // Listen for foreground messages — do NOT auto-navigate on foreground
    // notifications; navigation only happens when the user taps the notification
    // (handled via _handleNotificationTap / _onNotificationTap in PushNotificationService).
    getIt<PushNotificationService>().onMessage.listen((_) {
      // Intentionally no navigation here to prevent duplicate pages
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only process on resume if we've already processed initial
    // This prevents double-processing during app startup
    if (state == AppLifecycleState.resumed && _hasProcessedInitial) {
      _processPendingNotification();
    }
  }

  void _processPendingNotification() {
    try {
      final pushService = getIt<PushNotificationService>();
      final notificationData = pushService.getAndClearLastNotification();
      
      if (notificationData != null) {
        // Queue the notification for processing
        NotificationNavigationService().queueNotification(notificationData);
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
