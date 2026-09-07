import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../network/api_interceptor.dart';
import '../network/network_info.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/cache_sync_service.dart';
import '../services/data_sync_service.dart';
import '../../features/app_config/data/datasources/app_config_remote_datasource.dart';
import '../../features/app_config/data/repositories/app_config_repository_impl.dart';
import '../../features/app_config/domain/repositories/app_config_repository.dart';
import '../../features/app_config/domain/usecases/get_app_config.dart';
import '../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/get_onboarding_screens.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/popups/data/datasources/popup_remote_datasource.dart';
import '../../features/popups/domain/services/popup_manager.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/datasources/product_local_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_products.dart';
import '../../features/products/domain/usecases/get_products_by_ids.dart';
import '../../features/products/domain/usecases/suggest_products.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/categories/data/datasources/category_remote_datasource.dart';
import '../../features/categories/data/datasources/category_local_datasource.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/get_categories.dart';
import '../../features/categories/presentation/bloc/category_bloc.dart';
import '../../features/cart/data/datasources/cart_remote_datasource.dart';
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/cart_usecases.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home_header/data/datasources/home_header_remote_datasource.dart';
import '../../features/home_header/data/datasources/home_header_local_datasource.dart';
import '../../features/home_header/data/repositories/home_header_repository_impl.dart';
import '../../features/home_header/domain/repositories/home_header_repository.dart';
import '../../features/home_header/domain/usecases/get_home_header_config.dart';
import '../../features/home_header/presentation/bloc/home_header_bloc.dart';
import '../../features/app_content/data/datasources/app_content_remote_datasource.dart';
import '../../features/app_content/data/datasources/app_content_local_datasource.dart';
import '../../features/app_content/data/repositories/app_content_repository_impl.dart';
import '../../features/app_content/domain/repositories/app_content_repository.dart';
import '../../features/app_content/domain/usecases/get_app_content.dart';
import '../../features/app_content/domain/usecases/get_category_screen_content.dart';
import '../../features/app_content/presentation/bloc/app_content_bloc.dart';
import '../../features/checkout/presentation/bloc/checkout_bloc.dart';
import '../../features/orders/data/datasources/order_remote_datasource.dart';
import '../../features/orders/data/datasources/order_local_datasource.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/usecases/place_order.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/orders/data/datasources/delivery_tracking_remote_datasource.dart';
import '../../features/orders/data/datasources/delivery_tracking_local_datasource.dart';
import '../../features/orders/data/repositories/delivery_tracking_repository_impl.dart';
import '../../features/orders/domain/repositories/delivery_tracking_repository.dart';
import '../../features/orders/domain/usecases/get_delivery_tracking.dart';
import '../../features/orders/presentation/bloc/delivery_tracking_bloc.dart';
import '../../features/address/data/datasources/address_remote_datasource.dart';
import '../../features/address/data/repositories/address_repository_impl.dart';
import '../../features/address/domain/repositories/address_repository.dart';
import '../../features/address/presentation/bloc/address_bloc.dart' as address_bloc;
import '../services/payment_gateway_service.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_balance.dart';
import '../../features/wallet/domain/usecases/get_wallet_transactions.dart';
import '../../features/wallet/domain/usecases/initiate_wallet_top_up.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/wishlist/data/datasources/wishlist_local_datasource.dart';
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/repositories/wishlist_repository.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../features/ai/data/datasources/ai_remote_datasource.dart';
import '../../features/ai/data/datasources/ai_local_datasource.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../features/ai/presentation/bloc/ai_chat_bloc.dart';
import '../../features/loyalty/data/datasources/points_remote_datasource.dart';
import '../../features/loyalty/data/repositories/points_repository_impl.dart';
import '../../features/loyalty/domain/repositories/points_repository.dart';
import '../../features/loyalty/presentation/bloc/points_bloc.dart';
import '../../features/referral/data/datasources/referral_remote_datasource.dart';
import '../../features/referral/data/repositories/referral_repository_impl.dart';
import '../../features/referral/domain/repositories/referral_repository.dart';
import '../../features/referral/domain/usecases/get_referral_stats.dart';
import '../../features/referral/domain/usecases/get_invite_link.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';
import '../../core/plugins/plugin_registry.dart';
import '../../features/support/data/support_repository.dart';
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ============== INITIALIZE HIVE FIRST (BEFORE ANYTHING ELSE) ==============
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive.initFlutter error: $e');
  }
  
  // Helper to open box safely with corruption fallback
  Future<Box<T>> openBoxSafely<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return await Hive.openBox<T>(name);
    }
  }

  final categoriesBox = await openBoxSafely<Map>('categories');
  final productsBox = await openBoxSafely<Map>('products');
  final deliveryTrackingBox = await openBoxSafely<Map>('delivery_tracking');
  final wishlistBox = await openBoxSafely<List>('wishlist');
  final aiChatBox = await openBoxSafely<String>('ai_chat');
  
  // Register Hive boxes in GetIt so datasources can access them directly
  getIt.registerSingleton<Box<Map>>(categoriesBox, instanceName: 'categoriesBox');
  getIt.registerSingleton<Box<Map>>(productsBox, instanceName: 'productsBox');
  getIt.registerSingleton<Box<Map>>(deliveryTrackingBox, instanceName: 'deliveryTrackingBox');
  getIt.registerSingleton<Box<List>>(wishlistBox, instanceName: 'wishlistBox');
  getIt.registerSingleton<Box<String>>(aiChatBox, instanceName: 'aiChatBox');

  // ============== EXTERNAL ==============
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // ============== CORE SERVICES ==============
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt()),
  );

  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt()),
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    dio.interceptors.add(ApiInterceptor(getIt()));
    return dio;
  });

  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));
  getIt.registerLazySingleton<PushNotificationService>(() => PushNotificationService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  
  // DataSyncService - singleton for reactive data synchronization
  // Uses RxDart BehaviorSubject streams for real-time UI updates
  getIt.registerLazySingleton<DataSyncService>(() => DataSyncService());

  // ============== APP CONFIG FEATURE ==============
  getIt.registerLazySingleton<AppConfigRemoteDataSource>(
    () => AppConfigRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AppConfigRepository>(
    () => AppConfigRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetAppConfig(getIt()));
  getIt.registerLazySingleton(() => AppConfigBloc(getIt()));

  // ============== ONBOARDING FEATURE ==============
  getIt.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetOnboardingScreens(getIt()));
  getIt.registerLazySingleton(() => CompleteOnboarding(getIt()));
  getIt.registerFactory(() => OnboardingBloc(getIt(), getIt()));

  // ============== PRODUCTS FEATURE ==============
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(getIt(), getIt<Box<Map>>(instanceName: 'productsBox')),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetProducts(getIt()));
  getIt.registerLazySingleton(() => GetFeaturedProducts(getIt()));
  getIt.registerLazySingleton(() => GetProductById(getIt()));
  getIt.registerLazySingleton(() => GetProductsByCategory(getIt()));
  getIt.registerLazySingleton(() => SearchProducts(getIt()));
  getIt.registerLazySingleton(() => GetRelatedProducts(getIt()));
  getIt.registerLazySingleton(() => GetProductsByIds(getIt()));
  getIt.registerLazySingleton(() => SuggestProducts(getIt()));
  getIt.registerFactory(() => ProductBloc(getIt(), getIt(), getIt(), getIt(), getIt()));
  getIt.registerFactory(() => FeaturedProductsBloc(getIt()));

  // ============== SEARCH FEATURE ==============
  getIt.registerFactory(() => SearchBloc(getIt(), getIt()));

  // ============== CATEGORIES FEATURE ==============
  getIt.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(getIt(), getIt<Box<Map>>(instanceName: 'categoriesBox')),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetCategories(getIt()));
  getIt.registerLazySingleton(() => GetFeaturedCategories(getIt()));
  getIt.registerLazySingleton(() => GetCategoryById(getIt()));
  getIt.registerFactory(() => CategoryBloc(getIt(), getIt()));

  // ============== CART FEATURE ==============
  getIt.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(),
  );
  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetCart(getIt()));
  getIt.registerLazySingleton(() => AddToCart(getIt()));
  getIt.registerLazySingleton(() => UpdateCartItem(getIt()));
  getIt.registerLazySingleton(() => LocalUpdateCartItem(getIt()));
  getIt.registerLazySingleton(() => RemoveFromCart(getIt()));
  getIt.registerLazySingleton(() => ClearCart(getIt()));
  getIt.registerLazySingleton(() => ApplyCoupon(getIt()));
  getIt.registerLazySingleton(() => RemoveCoupon(getIt()));
  getIt.registerLazySingleton(() => SyncCart(getIt()));
  getIt.registerLazySingleton(() => ValidateCart(getIt()));
  getIt.registerLazySingleton(() => CartBloc(
    getIt(),  // GetCart
    getIt(),  // AddToCart
    getIt(),  // UpdateCartItem
    getIt(),  // LocalUpdateCartItem
    getIt(),  // RemoveFromCart
    getIt(),  // ClearCart
    getIt(),  // ApplyCoupon
    getIt(),  // RemoveCoupon
    getIt(),  // SyncCart
    getIt(),  // ValidateCart
  ));

  // ============== CACHE SYNC SERVICE ==============
  getIt.registerLazySingleton<CacheSyncService>(
    () => CacheSyncService(getIt(), getIt(), getIt(), getIt()),
  );

  // ============== POPUPS FEATURE ==============
  getIt.registerLazySingleton<PopupRemoteDataSource>(
    () => PopupRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<PopupManager>(
    () => PopupManager(getIt(), getIt()),
  );

  // ============== AUTH FEATURE ==============
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt(), getIt<CartLocalDataSource>(), getIt<CartRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => Login(getIt()));
  getIt.registerLazySingleton(() => Register(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUser(getIt()));
  getIt.registerLazySingleton(() => UpdateProfile(getIt()));
  getIt.registerLazySingleton(() => Logout(getIt()));
  getIt.registerLazySingleton(() => LogoutAll(getIt()));
  getIt.registerLazySingleton(() => CheckAuthStatus(getIt()));
  getIt.registerLazySingleton(() => GetAuthConfig(getIt()));
  getIt.registerLazySingleton(() => SendPhoneOtp(getIt()));
  getIt.registerLazySingleton(() => VerifyPhoneOtp(getIt()));
  getIt.registerLazySingleton(() => SendEmailOtp(getIt()));
  getIt.registerLazySingleton(() => VerifyEmailOtp(getIt()));
  getIt.registerLazySingleton(() => VerifyFirebaseToken(getIt()));
  getIt.registerLazySingleton(() => DeleteAccount(getIt()));
  getIt.registerLazySingleton(() => AuthBloc(
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
    getIt(),
  ));

  // ============== HOME HEADER FEATURE ==============
  getIt.registerLazySingleton<HomeHeaderRemoteDataSource>(
    () => HomeHeaderRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<HomeHeaderLocalDataSource>(
    () => HomeHeaderLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<HomeHeaderRepository>(
    () => HomeHeaderRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetHomeHeaderConfig(getIt()));
  getIt.registerFactory(() => HomeHeaderBloc(getIt()));

  // ============== APP CONTENT FEATURE ==============
  getIt.registerLazySingleton<AppContentRemoteDataSource>(
    () => AppContentRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AppContentLocalDataSource>(
    () => AppContentLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AppContentRepository>(
    () => AppContentRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );
  getIt.registerLazySingleton(() => GetAppContent(getIt()));
  getIt.registerLazySingleton(() => GetCategoryScreenContent(getIt()));
  getIt.registerFactory(() => AppContentBloc(
    getAppContent: getIt(),
    getCategoryScreenContent: getIt(),
  ));

  // ============== ORDERS FEATURE ==============
  getIt.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<OrderLocalDataSource>(
    () => OrderLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => PlaceOrder(getIt()));
  getIt.registerFactory(() => OrdersBloc(
    getIt(),
    pushNotificationService: getIt(),
  ));

  // ============== DELIVERY TRACKING FEATURE ==============
  getIt.registerLazySingleton<DeliveryTrackingRemoteDataSource>(
    () => DeliveryTrackingRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<DeliveryTrackingLocalDataSource>(
    () => DeliveryTrackingLocalDataSourceImpl(
      getIt(),
      getIt<Box<Map>>(instanceName: 'deliveryTrackingBox'),
    ),
  );
  getIt.registerLazySingleton<DeliveryTrackingRepository>(
    () => DeliveryTrackingRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetDeliveryTracking(getIt()));
  getIt.registerLazySingleton(() => GetTrackingHistory(getIt()));
  getIt.registerFactory(() => DeliveryTrackingBloc(
    getDeliveryTracking: getIt(),
    getTrackingHistory: getIt(),
    dataSyncService: getIt(),
  ));

  // ============== ADDRESS FEATURE ==============
  getIt.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSourceImpl(apiClient: getIt()),
  );
  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => address_bloc.AddressBloc(getIt()));

  // ============== PAYMENT GATEWAY SERVICE ==============
  getIt.registerLazySingleton<PaymentGatewayService>(
    () => PaymentGatewayService(getIt()),
  );


  // ============== WALLET FEATURE ==============
  getIt.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetWalletBalance(getIt()));
  getIt.registerLazySingleton(() => GetWalletTransactions(getIt()));
  getIt.registerLazySingleton(() => InitiateWalletTopUp(getIt()));
  getIt.registerFactory(() => WalletBloc(
    getWalletBalance: getIt(),
    getWalletTransactions: getIt(),
    initiateWalletTopUp: getIt(),
  ));

  // ============== LOYALTY / POINTS FEATURE ==============
  getIt.registerLazySingleton<PointsRemoteDataSource>(
    () => PointsRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<PointsRepository>(
    () => PointsRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => PointsBloc(getIt()));

  // ============== CHECKOUT FEATURE ==============
  getIt.registerFactory(() {
    // Resolve the authenticated user's email and phone at construction time
    // so payment gateways (Razorpay, Stripe, etc.) receive real contact info
    // instead of empty strings.
    final authRepo = getIt<AuthRepository>();
    final user = authRepo.currentUser;
    return CheckoutBloc(
      getIt<PaymentGatewayService>(),
      getIt<PlaceOrder>(),
      userEmail: user?.email ?? '',
      userPhone: user?.phone ?? '',
    );
  });

  // ============== WISHLIST FEATURE ==============
  getIt.registerLazySingleton<WishlistLocalDataSource>(
    () => WishlistLocalDataSourceImpl(getIt<Box<List>>(instanceName: 'wishlistBox')),
  );
  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => WishlistBloc(getIt()));

  // ============== AI FEATURE ==============
  getIt.registerLazySingleton<AiRemoteDataSource>(
    () => AiRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AiLocalDataSource>(
    () => AiLocalDataSourceImpl(getIt<Box<String>>(instanceName: 'aiChatBox')),
  );
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );
  getIt.registerFactory(() => AiChatBloc(getIt(), getIt()));

  // ============== REFERRAL FEATURE ==============
  getIt.registerLazySingleton<ReferralRemoteDataSource>(
    () => ReferralRemoteDataSourceImpl(apiClient: getIt()),
  );
  getIt.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => GetReferralStats(getIt()));
  getIt.registerLazySingleton(() => GetInviteLink(getIt()));
  getIt.registerFactory(() => ReferralBloc(
    getReferralStats: getIt(),
    getInviteLink: getIt(),
  ));

  // ============== PLUGINS ==============
  PluginRegistry.instance.registerAllDependencies(getIt);

  // ============== SUPPORT FEATURE ==============
  getIt.registerLazySingleton<SupportRepository>(
    () => SupportRepository(getIt()),
  );
}
