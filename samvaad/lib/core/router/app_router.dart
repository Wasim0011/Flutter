import 'package:go_router/go_router.dart';
import '../../features/shell/presentation/pages/splash_page.dart';
import 'app_routes.dart';

/// Samvaad's declarative route table.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splashName,
      builder: (context, state) => const SplashPage(),
    ),
  ],
);