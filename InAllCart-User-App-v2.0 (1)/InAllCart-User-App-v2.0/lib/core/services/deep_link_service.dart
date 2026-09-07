import 'package:go_router/go_router.dart';
import 'dart:convert';

import '../constants/app_constants.dart';

/// Deep Link Service
/// Handles navigation from push notifications and deep links
class DeepLinkService {
  /// Process deep link data from notification
  static void handleDeepLink(Map<String, dynamic> data, GoRouter router) {
    final screen = data['screen'] as String?;
    final deepLink = data['deep_link'] as String?;
    final paramsJson = data['params'] as String?;
    
    Map<String, dynamic>? params;
    if (paramsJson != null) {
      try {
        params = jsonDecode(paramsJson) as Map<String, dynamic>;
      } catch (e) {
        // Failed to parse params
      }
    }
    
    final directOrderId = data['order_id'] ?? data['orderId'] ?? params?['orderId'] ?? params?['order_id'];
    if (directOrderId != null) {
      final targetPath = '/orders/$directOrderId';
      router.push(targetPath);
      return;
    }

    final type = data['type'] as String? ?? '';
    if (type == 'new_order' || type == 'order_status' || type == 'order_update' || type.contains('order')) {
      router.go('/orders');
      return;
    }
    
    // Handle different screen types
    switch (screen) {
      case 'order_detail':
        _navigateToOrderDetail(params, router);
        break;
      case 'order_list':
        _navigateToOrderList(router);
        break;
      case 'product_detail':
        _navigateToProductDetail(params, router);
        break;
      case 'category':
        _navigateToCategory(params, router);
        break;
      case 'store':
        _navigateToStore(params, router);
        break;
      case 'brand':
        _navigateToBrand(params, router);
        break;
      case 'cart':
        _navigateToCart(router);
        break;
      case 'home':
        _navigateToHome(router);
        break;
      case 'custom':
        _navigateToCustom(params, router);
        break;
      default:
        // Try parsing deep link URL
        if (deepLink != null) {
          _parseDeepLinkUrl(deepLink, router);
        } else {
          _navigateToHome(router);
        }
    }
  }
  
  /// Navigate to order detail screen
  static void _navigateToOrderDetail(Map<String, dynamic>? params, GoRouter router) {
    if (params == null) return;
    
    final orderId = params['orderId'];
    final orderNumber = params['orderNumber'];
    
    if (orderId != null) {
      final targetPath = '/orders/$orderId';
      // If already on this order's detail page, don't push a duplicate
      final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();
      if (currentLocation == targetPath) return;
      router.push(targetPath);
    } else if (orderNumber != null) {
      // orderNumber-based deep links go to orders list; user can tap to see details
      router.go('/orders');
    }
  }
  
  /// Navigate to order list screen
  static void _navigateToOrderList(GoRouter router) {
    router.go('/orders');
  }
  
  /// Navigate to product detail screen
  static void _navigateToProductDetail(Map<String, dynamic>? params, GoRouter router) {
    if (params == null) return;
    
    final productId = params['productId'];
    if (productId != null) {
      router.push('/product/$productId');
    }
  }
  
  /// Navigate to category screen
  static void _navigateToCategory(Map<String, dynamic>? params, GoRouter router) {
    if (params == null) return;
    
    final categoryId = params['categoryId'];
    final categoryName = params['categoryName'];
    if (categoryId != null) {
      // Navigate to products filtered by category
      router.push('/category/$categoryId/products${categoryName != null ? '?name=$categoryName' : ''}');
    }
  }
  
  /// Navigate to store screen
  static void _navigateToStore(Map<String, dynamic>? params, GoRouter router) {
    if (params == null) return;
    
    final storeId = params['storeId'];
    if (storeId != null) {
      // Navigate to the store's product listing page.
      router.push('/store/$storeId');
    }
  }
  
  /// Navigate to brand screen
  static void _navigateToBrand(Map<String, dynamic>? params, GoRouter router) {
    if (params == null) return;
    
    final brandId = params['brandId'];
    if (brandId != null) {
      // Navigate to the brand's product listing page.
      router.push('/products?brand=$brandId');
    }
  }
  
  /// Navigate to custom URL
  static void _navigateToCustom(Map<String, dynamic>? params, GoRouter router) {
    if (params == null) return;
    
    final url = params['url'] as String?;
    if (url != null) {
      // Try to parse as deep link first
      if (url.startsWith('${AppConstants.appScheme}://')) {
        _parseDeepLinkUrl(url, router);
      } else {
        // External URL: navigate to home as a safe fallback.
        // To open in a browser, add url_launcher to pubspec.yaml and use launchUrl().
        router.go('/');
      }
    }
  }

  /// Navigate to registration screen with referral code
  static void _navigateToRegister(String? referralCode, GoRouter router) {
    if (referralCode != null) {
      router.push('/register?ref=$referralCode');
    } else {
      router.push('/register');
    }
  }
  
  /// Navigate to cart screen
  static void _navigateToCart(GoRouter router) {
    router.push('/cart');
  }
  
  /// Navigate to home screen
  static void _navigateToHome(GoRouter router) {
    router.go('/');
  }
  
  /// Parse deep link URL (appScheme://... or https://your-domain.com/...)
  static void _parseDeepLinkUrl(String deepLink, GoRouter router) {
    try {
      final uri = Uri.parse(deepLink);
      
      // Handle Web Links (https://your-domain.com/product/123)
      // The host is derived from AppConstants.apiBaseUrl so buyers only need
      // to change the URL in one place and deep links work automatically.
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final baseUri = Uri.tryParse(AppConstants.apiBaseUrl);
        final configuredHost = baseUri?.host ?? '';
        final host = uri.host;

        if (configuredHost.isNotEmpty &&
            (host == configuredHost || host == 'www.$configuredHost')) {
          if (uri.pathSegments.isNotEmpty) {
            final type = uri.pathSegments[0];
            final id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

            switch (type) {
              case 'product':
                if (id != null) router.push('/product/$id');
                return;
              case 'category':
                if (id != null) router.push('/category/$id/products');
                return;
              case 'invite':
                if (id != null) _navigateToRegister(id, router);
                return;
              case 'orders':
                if (id != null) {
                  router.push('/orders/$id');
                } else {
                  router.go('/orders');
                }
                return;
              case 'cart':
                router.push('/cart');
                return;
            }
          }
        }
        return;
      }

      // Custom scheme deep links: appScheme://order/123
      // The scheme must match AppConstants.appScheme and the value registered
      // in AndroidManifest.xml (android:scheme) and Info.plist (CFBundleURLSchemes).
      if (uri.scheme != AppConstants.appScheme) {
        router.go('/');
        return;
      }

      // appScheme://order/123
      if (uri.host == 'order' && uri.pathSegments.isNotEmpty) {
        router.push('/orders/${uri.pathSegments.first}');
        return;
      }
      
      // appScheme://product/456
      if (uri.host == 'product' && uri.pathSegments.isNotEmpty) {
        router.push('/product/${uri.pathSegments.first}');
        return;
      }
      
      // appScheme://category/789
      if (uri.host == 'category' && uri.pathSegments.isNotEmpty) {
        router.push('/category/${uri.pathSegments.first}/products');
        return;
      }
      
      // appScheme://invite/XYZ
      if (uri.host == 'invite' && uri.pathSegments.isNotEmpty) {
        _navigateToRegister(uri.pathSegments.first, router);
        return;
      }
      
      // appScheme://store/123
      if (uri.host == 'store' && uri.pathSegments.isNotEmpty) {
        router.push('/store/${uri.pathSegments.first}');
        return;
      }
      
      // appScheme://brand/456
      if (uri.host == 'brand' && uri.pathSegments.isNotEmpty) {
        router.push('/products?brand=${uri.pathSegments.first}');
        return;
      }
      
      // appScheme://cart
      if (uri.host == 'cart') {
        router.push('/cart');
        return;
      }
      
      // appScheme://orders
      if (uri.host == 'orders') {
        router.go('/orders');
        return;
      }
      
      // appScheme://home
      if (uri.host == 'home') {
        router.go('/');
        return;
      }
      
      // Default to home
      router.go('/');
    } catch (e) {
      // Invalid URL, go to home
      router.go('/');
    }
  }
  
  /// Get router instance from context
  static GoRouter getRouter(dynamic context) {
    return GoRouter.of(context);
  }
}
