import 'package:package_info_plus/package_info_plus.dart';

/// App-level constants and configuration
/// Change these values to configure the entire app
abstract class AppConstants {
  // ============== APP INFO ==============
  static const String appName = 'InAllCart';
  static const String appTagline = 'Shop Smart, Live Better';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  /// Android applicationId / iOS bundle identifier.
  ///
  /// Resolved from the platform at startup via [package_info_plus], so it
  /// always reflects the real build identifier with nothing to edit on rename.
  /// Initialized once by [initPackageInfo] in main() before runApp().
  static String packageName = 'com.inallcart.customer.demo3';

  /// Resolves [packageName] from the running platform.
  static Future<void> initPackageInfo() async {
    try {
      packageName = (await PackageInfo.fromPlatform()).packageName;
    } catch (_) {}
  }

  /// Custom URL scheme for deep links (e.g. myapp://product/123).
  /// Must match the scheme registered in AndroidManifest.xml and Info.plist.
  static const String appScheme = 'inallcart';

  // TODO: Replace with your server URL before building.
  // Example: 'https://yourdomain.com'
  static const String apiBaseUrl = 'https://demo3.inallcart.com';
  static String get mediaBaseUrl => apiBaseUrl;

  /// Convert a relative storage URL to a full URL.
  ///
  /// Root cause fix (Sub-task 6): this backend (Laravel) serves uploaded
  /// media through the public "storage" symlink (storage/app/public ->
  /// public/storage). Category/banner image paths already include that
  /// "storage/" segment, but several product image fields come back as the
  /// raw DB path (e.g. "products/xyz.jpg") without it. The previous version
  /// of this method had an `if (path.startsWith('storage/'))` check but
  /// BOTH branches returned the identical `'$mediaBaseUrl/$path'` string -
  /// so the check never actually added the missing prefix, and any product
  /// image path lacking "storage/" resolved to a 404 while category images
  /// (which already had it) loaded fine. This is why products displayed
  /// correctly (the JSON/API layer was never the problem) but their images
  /// did not. We now actually insert the "storage/" segment when missing.
  static String getFullMediaUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty || relativeUrl == 'null') return '';
    if (relativeUrl.startsWith('http')) return relativeUrl;

    // Remove leading slash if present
    String path = relativeUrl.startsWith('/') ? relativeUrl.substring(1) : relativeUrl;

    // Only add the "storage/" segment when it's genuinely missing - leave
    // bundled assets and already-correct paths untouched.
    if (!path.startsWith('storage/') && !path.startsWith('assets/')) {
      path = 'storage/$path';
    }

    return '$mediaBaseUrl/$path';
  }

  // ============== API TIMEOUTS ==============
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============== PAGINATION ==============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============== CACHE ==============
  static const Duration cacheMaxAge = Duration(hours: 24);
  static const Duration configCacheMaxAge = Duration(hours: 1);

  // ============== STORAGE KEYS ==============
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String appConfigKey = 'app_config';
  static const String fcmTokenKey = 'fcm_token';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String cartKey = 'cart_data';
  static const String latitudeKey = 'selected_lat';
  static const String longitudeKey = 'selected_lng';
  static const String cachedAddressLabelKey = 'cached_address_label';
  static const String searchHistoryKey = 'search_history';
  static const String aiHistoryKey = 'ai_history';

  // ============== VALIDATION ==============
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int otpLength =
  6; // fallback — actual length comes from auth config API
  static const Duration otpResendDelay = Duration(seconds: 60);
  static const int maxLoginAttempts = 5;

  // ============== UI CONFIGURATION ==============
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonHeight = 52.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // ============== MAP DEFAULTS ==============
  static const double defaultMapZoom = 14.0;
  static const double defaultLat = 28.6139; // Delhi (fallback)
  static const double defaultLng = 77.2090;
  static const int locationUpdateDistance = 10; // meters

  // ============== SERVICE AREA ==============
  static const double serviceLat = 28.6139;
  static const double serviceLng = 77.2090;
  static const double serviceRadius = 5000.0; // meters (5km)

  // ============== MAP TILE PROVIDERS ==============
  // OSM tile URL — no API key required.
  // The app uses OpenStreetMap by default; switch to Google Maps via admin settings.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // ============== IMAGE CONFIGURATION ==============
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const double thumbnailSize = 150.0;
  static const double productImageSize = 400.0;

  // ============== NOTIFICATION CHANNELS ==============
  static const String notificationChannelId = 'inallcart_high_importance';
  static const String notificationChannelName = 'App Notifications';
  static const String notificationChannelDesc =
      'Important updates and notifications';

  // ============== SOCIAL LINKS ==============
  // Update these to match your business details.
  static const String websiteUrl = 'https://your-domain.com';
  static const String privacyPolicyUrl = 'https://your-domain.com/privacy';
  static const String termsUrl = 'https://your-domain.com/terms';
  static const String supportEmail = 'support@your-domain.com';
  static const String supportPhone = '+1234567890';

  // ============== FEATURE FLAGS ==============
  static const bool enableGoogleSignIn = true;
  static const bool enableAppleSignIn = true;
  static const bool enableBiometricAuth = true;
  static const bool enableDarkMode = true;
  static const bool enableMultiLanguage = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
}

/// App environment
enum Environment { development, staging, production }

/// API Endpoints - centralized for easy maintenance
abstract class ApiEndpoints {
  // Base API version
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';

  // Auth
  static const String login = '$apiPrefix/auth/login';
  static const String register = '$apiPrefix/auth/register';
  static const String logout = '$apiPrefix/auth/logout';
  static const String logoutAll = '$apiPrefix/auth/logout-all';
  static const String refreshToken = '$apiPrefix/auth/refresh';
  static const String forgotPassword = '$apiPrefix/auth/forgot-password';
  static const String resetPassword = '$apiPrefix/auth/reset-password';
  static const String verifyOtp = '$apiPrefix/auth/verify-otp';
  static const String user = '$apiPrefix/auth/user';
  static const String updateProfile = '$apiPrefix/auth/profile';
  static const String deleteAccount = '$apiPrefix/auth/profile';
  static const String changePassword = '$apiPrefix/auth/password';
  static const String authConfig = '$apiPrefix/auth/config';
  static const String sendPhoneOtp = '$apiPrefix/auth/otp/send-phone';
  static const String verifyPhoneOtp = '$apiPrefix/auth/otp/verify-phone';
  static const String sendEmailOtp = '$apiPrefix/auth/otp/send-email';
  static const String verifyEmailOtp = '$apiPrefix/auth/otp/verify-email';

  // Config
  static const String appConfig = '$apiPrefix/config/app';
  static const String onboarding = '$apiPrefix/config/onboarding';
  static const String popups = '$apiPrefix/config/popups';

  // Products
  static const String products = '$apiPrefix/products';
  static const String featuredProducts = '$apiPrefix/products/featured';
  static const String searchProducts = '$apiPrefix/products/search';
  static String productDetails(String id) => '$apiPrefix/products/$id';
  static String productsByCategory(String categoryId) =>
      '$apiPrefix/products/category/$categoryId';
  static String storeProducts(String storeId) =>
      '$apiPrefix/products/store/$storeId';
  static String relatedProducts(String id) => '$apiPrefix/products/$id/related';

  // Categories
  static const String categories = '$apiPrefix/categories';
  static const String featuredCategories = '$apiPrefix/categories/featured';
  static String categoryDetails(String id) => '$apiPrefix/categories/$id';

  // Cart
  static const String cart = '$apiPrefix/cart';
  static const String cartItems = '$apiPrefix/cart/items';
  static String cartItem(String id) => '$apiPrefix/cart/items/$id';
  static const String applyCoupon = '$apiPrefix/cart/coupon';
  static const String removeCoupon = '$apiPrefix/cart/coupon';
  // Batch sync (guest → authenticated migration)
  static const String cartSync = '$apiPrefix/cart/sync';
  // Pre-checkout validation
  static const String cartValidate = '$apiPrefix/cart/validate';
  static const String coupons = '$apiPrefix/coupons';

  // Orders
  static const String orders = '$apiPrefix/orders';
  static String orderDetails(String id) => '$apiPrefix/orders/$id';
  static String trackOrder(String orderNumber) =>
      '$apiPrefix/orders/track/$orderNumber';
  static String cancelOrder(String id) => '$apiPrefix/orders/$id/cancel';

  // Delivery Tracking
  static String deliveryTracking(String orderId) =>
      '$apiPrefix/orders/$orderId/tracking';
  static String deliveryTrackingHistory(String orderId) =>
      '$apiPrefix/orders/$orderId/tracking/history';

  // Addresses
  static const String addresses = '$apiPrefix/addresses';
  static String addressDetails(String id) => '$apiPrefix/addresses/$id';
  static String setDefaultAddress(String id) =>
      '$apiPrefix/addresses/$id/set-default';

  // Wishlist
  static const String wishlist = '$apiPrefix/wishlist';
  static String wishlistItem(String productId) =>
      '$apiPrefix/wishlist/$productId';

  // Reviews
  static String productReviews(String productId) =>
      '$apiPrefix/products/$productId/reviews';
  static const String myReviews = '$apiPrefix/reviews/my';

  // Notifications
  static const String notifications = '$apiPrefix/notifications';
  static const String registerDevice = '$apiPrefix/notifications/register';
  static const String unregisterDevice = '$apiPrefix/notifications/unregister';

  // Referral
  static const String referralStats = '$apiPrefix/referral';
  static const String inviteLink = '$apiPrefix/referral/invite-link';

  // Points / Loyalty
  static const String points = '$apiPrefix/points';
  static const String pointsHistory = '$apiPrefix/points/history';
  static const String pointsRedeem = '$apiPrefix/points/redeem';

  // Config
  static const String configPages = '$apiPrefix/config/pages';

  // FCM
  static const String fcmToken = '$apiPrefix/fcm/token';

  // Wallet
  static const String wallet = '$apiPrefix/wallet';
  static const String walletTransactions = '$apiPrefix/wallet/transactions';
  static const String walletTopUp = '$apiPrefix/wallet/top-up';

  // AI
  static const String aiChat = '$apiPrefix/ai/chat';

  // Payment
  static const String paymentMethods = '$apiPrefix/payment/methods';
  static const String paymentInitialize = '$apiPrefix/payment/initialize';
  static const String paymentVerify = '$apiPrefix/payment/verify';

  // VIP User Membership
  static const String membershipPlans = '$apiPrefix/user/membership/plans';
  static const String membershipPage = '$apiPrefix/user/membership/page';
  static const String membershipStatus = '$apiPrefix/user/membership/my-status';
  static const String membershipSubscribe = '$apiPrefix/user/membership/subscribe';
  static const String membershipCancelAutoRenew = '$apiPrefix/user/membership/cancel-auto-renew';
}

/// Asset paths
abstract class AppAssets {
  // Images
  static const String imagesPath = 'assets/images';
  static const String logo = '$imagesPath/logo.png';
  static const String logoWhite = '$imagesPath/logo_white.png';
  static const String placeholder = '$imagesPath/placeholder.png';
  static const String emptyCart = '$imagesPath/empty_cart.png';
  static const String emptyOrders = '$imagesPath/empty_orders.png';
  static const String noInternet = '$imagesPath/no_internet.png';
  static const String error = '$imagesPath/error.png';

  // Onboarding
  static const String onboarding1 = '$imagesPath/onboarding_1.png';
  static const String onboarding2 = '$imagesPath/onboarding_2.png';
  static const String onboarding3 = '$imagesPath/onboarding_3.png';

  // Icons
  static const String iconsPath = 'assets/icons';

  // Animations (Lottie)
  static const String animationsPath = 'assets/animations';
  static const String loadingAnimation = '$animationsPath/loading.json';
  static const String successAnimation = '$animationsPath/success.json';
  static const String emptyAnimation = '$animationsPath/empty.json';
}