import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../services/storage_service.dart';
import 'routes.dart';

/// Route guard utilities for protecting routes
class RouteGuards {
  static final _storage = getIt<StorageService>();

  /// Check if user is authenticated
  static bool get isAuthenticated => _storage.isLoggedIn;

  /// Check if onboarding is completed
  static bool get isOnboardingCompleted => _storage.isOnboardingCompleted();

  /// Redirect to login with return URL
  static String loginRedirect(String returnUrl) {
    return '${Routes.login}?redirect=${Uri.encodeComponent(returnUrl)}';
  }

  /// Handle post-login redirect
  static void handlePostLogin(BuildContext context) {
    final state = GoRouterState.of(context);
    final redirect = state.uri.queryParameters['redirect'];
    
    if (redirect != null && redirect.isNotEmpty) {
      context.go(Uri.decodeComponent(redirect));
    } else {
      context.go(Routes.home);
    }
  }

  /// Protected route wrapper
  static Widget protectedRoute({
    required Widget child,
    required BuildContext context,
  }) {
    if (!isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentPath = GoRouterState.of(context).matchedLocation;
        context.go(loginRedirect(currentPath));
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}

/// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  void goToProduct(String id) => go(Routes.product(id));
  void goToCategory(String id) => go(Routes.category(id));
  void goToOrder(String id) => go(Routes.order(id));
  void goToTrackOrder(String id) => go(Routes.order(id));
  
  void pushProduct(String id) => push(Routes.product(id));
  void pushCategory(String id) => push(Routes.category(id));
  void pushOrder(String id) => push(Routes.order(id));
}
