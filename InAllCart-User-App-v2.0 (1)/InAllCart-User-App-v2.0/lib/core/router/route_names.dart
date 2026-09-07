/// Named routes for type-safe navigation
/// Use with context.goNamed() or context.pushNamed()
abstract class RouteNames {
  // Initial
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';

  // Auth
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';
  static const String verifyOtp = 'verifyOtp';

  // Main Tabs
  static const String home = 'home';
  static const String categories = 'categories';
  static const String cart = 'cart';
  static const String orders = 'orders';
  static const String profile = 'profile';

  // Products
  static const String products = 'products';
  static const String productDetails = 'productDetails';
  static const String search = 'search';
  static const String categoryProducts = 'categoryProducts';

  // Checkout
  static const String checkout = 'checkout';
  static const String paymentMethods = 'paymentMethods';
  static const String orderSuccess = 'orderSuccess';

  // Orders
  static const String orderDetails = 'orderDetails';

  // Profile
  static const String editProfile = 'editProfile';
  static const String settings = 'settings';
  static const String addresses = 'addresses';
  static const String addAddress = 'addAddress';
  static const String editAddress = 'editAddress';
  static const String wishlist = 'wishlist';
  static const String notifications = 'notifications';

  // Wallet
  static const String wallet = 'wallet';
  static const String topUp = 'topUp';

  // Location
  static const String selectLocation = 'selectLocation';

  // Profile completion (new users after OTP)
  static const String completeProfile = 'completeProfile';
}
