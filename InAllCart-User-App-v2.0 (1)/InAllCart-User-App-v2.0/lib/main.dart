import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';

import 'core/constants/app_constants.dart';
import 'core/services/video_cache_service.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/firebase_chat_service.dart';
import 'core/services/cache_sync_service.dart';
import 'core/services/notification_navigation_service.dart';
import 'core/widgets/deep_link_handler.dart';
import 'features/app_config/presentation/bloc/app_config_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'plugins/plugin_manifest.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      MediaKit.ensureInitialized();
    } catch (e) {
      debugPrint('MediaKit initialization note: $e');
    }

    try {
      VideoCacheService().clearAll();
    } catch (_) {}

    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

    try {
      await AppConstants.initPackageInfo();
    } catch (e) {
      debugPrint('initPackageInfo error: $e');
    }

    registerAllPlugins();
    await configureDependencies();
    getIt<AppConfigBloc>().add(LoadAppConfig());
    getIt<AuthBloc>().add(CheckAuthStatusEvent());
    runApp(const InAllCartApp());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initRuntimeServices());
    });
  }, (error, stackTrace) {
    debugPrint('Unhandled error in app: $error\n$stackTrace');
  });
}

Future<void> _initRuntimeServices() async {
  final notificationNav = NotificationNavigationService();
  notificationNav.initialize(AppRouter.router);

  await getIt<PushNotificationService>().initialize();

  final initialNotification = getIt<PushNotificationService>()
      .getAndClearLastNotification();
  if (initialNotification != null) {
    notificationNav.queueNotification(initialNotification);
  }

  await FirebaseChatService.instance.initialize();
  getIt<CacheSyncService>().initialize();
  // Load cart once after a short delay to let auth state settle first.
  // The cart page also dispatches LoadCart in initState, so this only
  // pre-warms the BLoC for badge counts on the bottom nav.
  Future.delayed(const Duration(seconds: 2), () {
    getIt<CartBloc>().add(LoadCart());
  });
}

class InAllCartApp extends StatefulWidget {
  const InAllCartApp({super.key});

  @override
  State<InAllCartApp> createState() => _InAllCartAppState();
}

class _InAllCartAppState extends State<InAllCartApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: () => VideoCacheService().clearAll(),
    );
  }

  @override
  void dispose() {
    VideoCacheService().clearAll();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AppConfigBloc>()),
        BlocProvider.value(value: getIt<AuthBloc>()),
        BlocProvider.value(value: getIt<CartBloc>()),
        BlocProvider(create: (_) => getIt<WishlistBloc>()..add(LoadWishlist())),
      ],
      child: DeepLinkHandler(
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
