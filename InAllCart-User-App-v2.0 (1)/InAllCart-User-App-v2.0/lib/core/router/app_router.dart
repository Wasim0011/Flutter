import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../di/injection.dart';
import '../services/storage_service.dart';
import '../utils/bottom_nav_scroll_controller.dart';
import 'routes.dart';
import 'route_names.dart';
import 'page_transitions.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/products/domain/entities/product.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_detail_page.dart';
import '../../features/stores/presentation/pages/store_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/app_content/domain/entities/app_content.dart';
import '../../features/app_content/data/models/app_content_model.dart';
import '../../features/address/presentation/bloc/address_bloc.dart'
    as address_bloc;
import '../../features/address/presentation/pages/address_list_page.dart';
import '../../features/address/presentation/pages/address_form_page.dart';
import '../../features/location/presentation/pages/location_picker_page.dart';
import '../../features/orders/presentation/pages/order_success_page.dart';
import '../../features/orders/presentation/pages/order_chat_page.dart';
import '../../features/orders/presentation/pages/orders_list_page.dart';
import '../../features/orders/presentation/pages/order_detail_wrapper.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/orders/presentation/bloc/orders_event.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/data/models/order_model.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/top_up_page.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/loyalty/presentation/pages/cashback_page.dart';
import '../../features/loyalty/presentation/bloc/points_bloc.dart';
import '../../features/wallet/presentation/bloc/wallet_event.dart';
import '../../features/cart/presentation/widgets/floating_cart_summary.dart';
import '../../features/ai/presentation/pages/ai_chat_page.dart';
import '../../features/ai/presentation/bloc/ai_chat_bloc.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';
import '../../features/referral/presentation/bloc/referral_event.dart';
import '../../features/referral/presentation/pages/referral_page.dart';
import '../../features/orders/presentation/pages/order_review_page.dart';
import '../theme/app_colors.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';
import '../../core/plugins/plugin_registry.dart';
import '../../features/membership/presentation/pages/vip_membership_page.dart';

Map<String, dynamic> _normalizeJsonMap(dynamic value) {
  final decoded = jsonDecode(jsonEncode(value));
  return Map<String, dynamic>.from(decoded as Map);
}

Map<String, dynamic> _fixProductJsonShape(Map<String, dynamic> json) {
  final fixed = Map<String, dynamic>.from(json);

  fixed['name'] ??= fixed['title'] ?? '';
  fixed['slug'] ??= '';

  final price = fixed['price'];
  if (price is num) {
    final compare = fixed['compare_price'] ?? fixed['comparePrice'];
    fixed['price'] = <String, dynamic>{
      'amount': price.toDouble(),
      'formatted': price.toString(),
      'compare_price': compare is num ? compare.toDouble() : null,
    };
  } else if (price is Map) {
    fixed['price'] = _normalizeJsonMap(price);
  } else {
    fixed['price'] = <String, dynamic>{};
  }

  final inventory = fixed['inventory'];
  if (inventory is Map) {
    fixed['inventory'] = _normalizeJsonMap(inventory);
  } else {
    fixed['inventory'] = <String, dynamic>{
      'quantity': fixed['quantity'] ?? 0,
      'in_stock': fixed['in_stock'] ?? fixed['inStock'] ?? true,
      'is_low_stock': fixed['is_low_stock'] ?? false,
    };
  }

  final description = fixed['description'];
  if (description is String) {
    fixed['description'] = <String, dynamic>{
      'short': description,
      'full': description,
    };
  } else if (description is Map) {
    fixed['description'] = _normalizeJsonMap(description);
  } else {
    fixed['description'] = <String, dynamic>{};
  }

  final flags = fixed['flags'];
  if (flags is Map) {
    fixed['flags'] = _normalizeJsonMap(flags);
  } else {
    fixed['flags'] = <String, dynamic>{
      'is_active': fixed['is_active'] ?? true,
      'is_featured': fixed['is_featured'] ?? false,
    };
  }

  return fixed;
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // Maintenance
      GoRoute(
        path: '/maintenance',
        name: 'maintenance',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaintenancePage(
            title: extra?['title'] ?? "We'll be back soon!",
            message: extra?['message'] ?? 'Scheduled maintenance in progress.',
            imageUrl: extra?['imageUrl'],
          );
        },
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth Routes
      GoRoute(
        path: Routes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.register,
        name: RouteNames.register,
        builder: (context, state) {
          final referralCode = state.uri.queryParameters['ref'];
          return RegisterPage(referralCode: referralCode);
        },
      ),
      GoRoute(
        path: Routes.verifyOtp,
        name: RouteNames.verifyOtp,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return OtpVerificationPage(
            identifier: extras?['identifier'] ?? '',
            type: extras?['type'] ?? 'phone',
            name: extras?['name'],
            phone: extras?['phone'],
            password: extras?['password'],
            isFirebase: extras?['isFirebase'] ?? false,
            verificationId: extras?['verificationId'],
            referralCode: extras?['referralCode'],
            otpLength: extras?['otpLength'] ?? 6,
            resendCooldown: extras?['resendCooldown'] ?? 60,
          );
        },
      ),
      GoRoute(
        path: Routes.completeProfile,
        name: RouteNames.completeProfile,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return CompleteProfilePage(
            phone: extras?['phone'],
          );
        },
      ),

      // Main App Shell with Bottom Navigation (Stateful for caching)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: RouteNames.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),

          // Branch 1: Categories
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.categories,
                name: RouteNames.categories,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CategoriesPage()),
              ),
            ],
          ),

          // Branch 2: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.orders,
                name: RouteNames.orders,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BlocProvider(
                    create: (_) => getIt<OrdersBloc>()..add(const LoadOrders()),
                    child: const OrdersListPage(),
                  ),
                ),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                name: RouteNames.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfilePage()),
              ),
            ],
          ),
        ],
      ),

      // Cart (outside shell - no bottom nav)
      GoRoute(
        path: Routes.cart,
        name: RouteNames.cart,
        pageBuilder: (context, state) =>
            SlideTransitionPage(key: state.pageKey, child: const CartPage()),
      ),

      // Product Details (outside shell)
      GoRoute(
        path: Routes.productDetails,
        name: RouteNames.productDetails,
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id']!;
          final extra = state.extra;
          Product? product;
          if (extra is Product) {
            product = extra;
          } else if (extra is ContentProduct) {
            product = ProductModel.fromJson(<String, dynamic>{
              'id': extra.id,
              'name': extra.name,
              'slug': '',
              'price': <String, dynamic>{
                'amount': extra.price,
                'formatted': extra.price.toString(),
                'compare_price': extra.comparePrice,
              },
              'description': <String, dynamic>{},
              'inventory': <String, dynamic>{
                'quantity': extra.inStock ? 999 : 0,
                'in_stock': extra.inStock,
                'is_low_stock': false,
              },
              'unit': extra.unit,
              'brand': null,
              'images': extra.image != null
                  ? <Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': 0,
                        'url': extra.image,
                        'is_primary': true,
                        'sort_order': 0,
                      },
                    ]
                  : <Map<String, dynamic>>[],
              'primary_image': extra.image != null
                  ? <String, dynamic>{
                      'id': 0,
                      'url': extra.image,
                      'is_primary': true,
                      'sort_order': 0,
                    }
                  : null,
              'flags': <String, dynamic>{
                'is_active': true,
                'is_featured': false,
              },
              'rating': extra.rating,
              'review_count': extra.reviewCount,
            });
          } else if (extra is Map) {
            try {
              final normalized = _normalizeJsonMap(extra);
              product = ProductModel.fromJson(_fixProductJsonShape(normalized));
            } catch (_) {
              product = null;
            }
          }
          return ZoomTransitionPage(
            key: state.pageKey,
            child: ProductDetailsPage(
              productId: productId,
              initialProduct: product,
            ),
          );
        },
      ),

      // Products List
      GoRoute(
        path: Routes.products,
        name: RouteNames.products,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return SlideTransitionPage(
            key: state.pageKey,
            child: ProductsPage(searchQuery: query),
          );
        },
      ),

      // Search
      GoRoute(
        path: Routes.search,
        name: RouteNames.search,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return NoTransitionPage(
            key: state.pageKey,
            child: SearchPage(initialQuery: query),
          );
        },
      ),

      // Category Products
      GoRoute(
        path: Routes.categoryProducts,
        name: RouteNames.categoryProducts,
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['id']!;
          final categoryName = state.uri.queryParameters['name'];
          return SlideTransitionPage(
            key: state.pageKey,
            child: CategoryDetailPage(
              categoryId: int.parse(categoryId),
              categoryName: categoryName,
            ),
          );
        },
      ),

      // Store Details
      GoRoute(
        path: Routes.storeDetails,
        name: 'store',
        pageBuilder: (context, state) {
          final storeId = state.pathParameters['id']!;
          final extra = state.extra;
          final ContentStore? store = extra is ContentStore
              ? extra
              : extra is Map<String, dynamic>
              ? ContentStoreModel.fromJson(extra)
              : null;
          return SlideTransitionPage(
            key: state.pageKey,
            child: StorePage(storeId: int.parse(storeId), store: store),
          );
        },
      ),

      // Order Success
      GoRoute(
        path: Routes.orderSuccess,
        name: RouteNames.orderSuccess,
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null) {
            // No order data — show orders list
            return BlocProvider(
              create: (_) => getIt<OrdersBloc>()..add(const LoadOrders()),
              child: const OrdersListPage(),
            );
          }

          final Order? order = extra is Order
              ? extra
              : extra is Map<String, dynamic>
              ? OrderModel.fromJson(extra)
              : null;

          return OrderSuccessPage(order: order!);
        },
      ),

      // Order Details
      GoRoute(
        path: Routes.orderDetails,
        name: RouteNames.orderDetails,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          final extra = state.extra;

          final Order? order = extra is Order
              ? extra
              : extra is Map<String, dynamic>
              ? OrderModel.fromJson(extra)
              : null;

          return OrderDetailWrapper(orderId: orderId, order: order);
        },
      ),

      // Order Chat
      GoRoute(
        path: '/orders/:orderId/chat/:chatType',
        name: 'orderChat',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          final chatType = state.pathParameters['chatType']!;
          return OrderChatPage(orderId: orderId, chatType: chatType);
        },
      ),

      // Settings (same as profile)
      GoRoute(
        path: Routes.settings,
        name: RouteNames.settings,
        builder: (context, state) => const ProfilePage(),
      ),

      // Edit Profile
      GoRoute(
        path: Routes.editProfile,
        name: RouteNames.editProfile,
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: const EditProfilePage(),
        ),
      ),

      // Wishlist
      GoRoute(
        path: Routes.wishlist,
        name: RouteNames.wishlist,
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: const WishlistPage(),
        ),
      ),

      // Notifications
      GoRoute(
        path: Routes.notifications,
        name: RouteNames.notifications,
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: const NotificationsPage(),
        ),
      ),

      // Wallet
      GoRoute(
        path: Routes.wallet,
        name: RouteNames.wallet,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<WalletBloc>(),
            child: const WalletPage(),
          );
        },
      ),
      GoRoute(
        path: Routes.topUp,
        name: RouteNames.topUp,
        builder: (context, state) {
          final prefilledAmount = state.uri.queryParameters['amount'];
          return BlocProvider(
            create: (_) => getIt<WalletBloc>()..add(const LoadWallet()),
            child: TopUpPage(
              prefilledAmount: prefilledAmount != null
                  ? double.tryParse(prefilledAmount)
                  : null,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.cashback,
        name: 'cashback',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<PointsBloc>(),
            child: const CashbackPage(),
          );
        },
      ),

      // Address Management
      GoRoute(
        path: Routes.addresses,
        name: RouteNames.addresses,
        builder: (context, state) {
          return BlocProvider(
            create: (_) =>
                getIt<address_bloc.AddressBloc>()
                  ..add(address_bloc.LoadAddresses()),
            child: const AddressListPage(),
          );
        },
      ),
      GoRoute(
        path: Routes.addAddress,
        name: RouteNames.addAddress,
        builder: (context, state) {
          // AddressFormPage will auto-push AddressMapPage in initState if no mapResult
          return BlocProvider(
            create: (_) => getIt<address_bloc.AddressBloc>(),
            child: const AddressFormPage(),
          );
        },
      ),
      GoRoute(
        path: '${Routes.addresses}/edit/:id',
        name: 'editAddress',
        builder: (context, state) {
          final addressId = int.parse(state.pathParameters['id']!);
          return BlocProvider(
            create: (_) =>
                getIt<address_bloc.AddressBloc>()
                  ..add(address_bloc.LoadAddresses()),
            child: AddressFormPage(addressId: addressId),
          );
        },
      ),

      // Location Picker
      GoRoute(
        path: Routes.selectLocation,
        name: RouteNames.selectLocation,
        builder: (context, state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
          return LocationPickerPage(initialLat: lat, initialLng: lng);
        },
      ),

      // AI Chat
      GoRoute(
        path: Routes.aiChat,
        name: 'aiChat',
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<AiChatBloc>(),
            child: const AiChatPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.referral,
        name: 'referral',
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<ReferralBloc>()..add(LoadReferralStats()),
            child: const ReferralPage(),
          ),
        ),
      ),

      // Order Review
      GoRoute(
        path: Routes.orderReview,
        name: 'orderReview',
        pageBuilder: (context, state) {
          final order = state.extra is Order ? state.extra as Order : null;
          final orderIdStr = state.pathParameters['id'];
          final orderId = int.tryParse(orderIdStr ?? '');
          return SlideTransitionPage(
            key: state.pageKey,
            child: OrderReviewPage(order: order, orderId: orderId),
          );
        },
      ),

      // VIP Membership
      GoRoute(
        path: Routes.vipMembership,
        name: 'vipMembership',
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: const VipMembershipPage(),
        ),
      ),

      // Plugin Routes (auto-registered from PluginRegistry)
      ...PluginRegistry.instance.allRoutes,
    ],
    redirect: _handleRedirect,
    refreshListenable: _CombinedNotifier(
      getIt<AuthBloc>(),
      getIt<AppConfigBloc>(),
    ),
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );

  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authState = getIt<AuthBloc>().state;
    final isLoggedIn = authState is Authenticated;
    final currentPath = state.matchedLocation;

    // Allow splash to load
    if (currentPath == Routes.splash) return null;

    // --- Maintenance Mode check ---
    final configState = getIt<AppConfigBloc>().state;
    if (configState is AppConfigLoaded && configState.config.maintenanceMode) {
      // Only redirect if not already on maintenance page
      if (currentPath != '/maintenance') {
        return '/maintenance';
      }
      return null;
    }
    // If we were on maintenance but it's now off, go to splash to re-evaluate
    if (currentPath == '/maintenance') {
      return Routes.splash;
    }
    // --- End Maintenance Mode check ---

    // Wait for auth to be checked initially
    if (authState is AuthInitial || authState is AuthLoading) {
      return null;
    }

    // Auth routes - redirect to home if already logged in
    final isAuthRoute =
        currentPath == Routes.login || currentPath == Routes.register;
    if (isAuthRoute && isLoggedIn) {
      return Routes.home;
    }

    // Protected routes - redirect to login if not logged in
    final protectedRoutes = [
      Routes.orders,
      Routes.profile,
      Routes.addresses,
      Routes.wallet,
      Routes.wishlist,
      Routes.cashback,
      Routes.referral,
      Routes.notifications,
      Routes.aiChat,
    ];
    if (protectedRoutes.any((r) => currentPath.startsWith(r)) && !isLoggedIn) {
      return '${Routes.login}?redirect=$currentPath';
    }

    return null;
  }
}

/// Listens to both Auth and AppConfig blocs so the router re-runs redirect
/// whenever maintenance mode is toggled OR auth state changes.
class _CombinedNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  final AppConfigBloc _configBloc;
  late final dynamic _authSub;
  late final dynamic _configSub;

  _CombinedNotifier(this._authBloc, this._configBloc) {
    _authSub = _authBloc.stream.listen((_) => notifyListeners());
    _configSub = _configBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _authSub.cancel();
    _configSub.cancel();
    super.dispose();
  }
}

// Main Shell with Bottom Navigation
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final _navController = BottomNavScrollController();
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1), // Slide down to hide
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Listen to scroll controller changes
    _navController.addListener(_onVisibilityChange);
  }

  void _onVisibilityChange() {
    if (_navController.isVisible) {
      _animationController.reverse(); // Show
    } else {
      _animationController.forward(); // Hide
    }
  }

  @override
  void dispose() {
    _navController.removeListener(_onVisibilityChange);
    _animationController.dispose();
    super.dispose();
  }

  // Map NavigationBar index to Router Branch index
  // Nav: 0(Home), 1(Cat), 2(Cart), 3(Orders), 4(Profile)
  // Branch: 0(Home), 1(Cat), -(Cart), 2(Orders), 3(Profile)
  int _getBranchIndex(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Categories
      case 2:
        return -1; // Cart (Special)
      case 3:
        return 2; // Orders
      case 4:
        return 3; // Profile
      default:
        return 0;
    }
  }

  // Map Branch index to NavigationBar index
  int _getNavIndex(int branchIndex) {
    switch (branchIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Categories
      case 2:
        return 3; // Orders
      case 3:
        return 4; // Profile
      default:
        return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    // Show navbar when tapping tabs
    _navController.show();

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    final storage = getIt<StorageService>();

    // Determine if we should treat user as logged in
    final isLoggedIn =
        authState is Authenticated ||
        ((authState is AuthInitial || authState is AuthLoading) &&
            storage.isLoggedIn);

    // Cart (Index 2) is special - pushes route
    if (index == 2) {
      context.pushNamed(RouteNames.cart);
      return;
    }

    // Protected tabs
    if ((index == 3 || index == 4) && !isLoggedIn) {
      _showLoginRequiredSnackbar(context, index == 3 ? 'orders' : 'profile');
      return;
    }

    final branchIndex = _getBranchIndex(index);
    if (branchIndex != -1) {
      // Always trigger scroll-to-top when tapping home tab
      if (index == 0) {
        BottomNavScrollController().triggerScrollToTop();
      }
      widget.navigationShell.goBranch(
        branchIndex,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  void _showLoginRequiredSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please login to view your $feature'),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'LOGIN',
          textColor: Colors.white,
          onPressed: () => context.push(Routes.login),
        ),
      ),
    );
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;

    // If not on Home tab (Branch 0), go to Home tab first
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    // On Home tab: double back press to exit app
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current Nav Index based on Branch
    final navIndex = _getNavIndex(widget.navigationShell.currentIndex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop),
      child: Scaffold(
        resizeToAvoidBottomInset:
            false, // Prevent nav bar from moving up with keyboard
        extendBody:
            true, // Allow body to extend behind bottom nav when it hides
        body: Stack(
          children: [
            widget.navigationShell,

            // Premium-style Floating Cart Summary
            // Moves up/down depending on nav bar visibility
            // Positioned MUST be a direct child of Stack
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, // Base at the very bottom
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final bottomPadding = Tween<double>(
                    begin: 75.0, // Above nav bar (visible state)
                    end: 16.0, // Near bottom (hidden state)
                  ).evaluate(_animationController);

                  return Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: child,
                  );
                },
                child: const FloatingCartSummary(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: navIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.1),
              elevation: 0,
              height: 65,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/home_outline.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icons/home_filled.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/categories_outline.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icons/categories_filled.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Categories',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/cart_outline.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icons/cart_filled.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/orders_outline.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icons/orders_filled.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/profile_outline.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icons/profile_filled.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Error Page
class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
