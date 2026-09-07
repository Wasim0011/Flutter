/// All route paths in the application
/// Centralized for easy maintenance and refactoring
abstract class Routes {
  // Initial
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';

  // Main Tabs (Shell Routes)
  static const String home = '/home';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // Products
  static const String products = '/products';
  static const String productDetails = '/product/:id';
  static const String search = '/search';
  static const String categoryProducts = '/category/:id/products';
  static const String storeDetails = '/store/:id';

  // Order Success
  static const String orderSuccess = '/order-success/:id';

  // Orders
  static const String orderDetails = '/orders/:id';

  // Profile
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String addresses = '/addresses';
  static const String addAddress = '/addresses/add';
  static const String editAddress = '/addresses/:id/edit';
  static const String wishlist = '/wishlist';
  static const String notifications = '/notifications';

  // Wallet
  static const String wallet = '/wallet';
  static const String topUp = '/wallet/top-up';
  static const String cashback = '/cashback';
  static const String referral = '/referral';

  // AI
  static const String aiChat = '/ai-chat';

  // Plugin Modules (conditionally enabled by backend plugins)
  // Note: Plugin routes are registered via PluginRegistry, not here.
  // This constant is kept for reference only.

  // Reviews
  static const String orderReview = '/orders/:id/review';

  // Location
  static const String selectLocation = '/select-location';

  // VIP Membership
  static const String vipMembership = '/vip-membership';

  // Profile completion (new users after OTP)
  static const String completeProfile = '/complete-profile';

  // Helpers for dynamic routes
  static String product(String id) => '/product/$id';
  static String category(String id) => '/category/$id/products';
  static String store(String id) => '/store/$id';
  static String order(String id) => '/orders/$id';
  static String address(String id) => '/addresses/$id/edit';
}
