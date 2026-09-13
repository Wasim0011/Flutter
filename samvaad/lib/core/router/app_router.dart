import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_entry_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/shell/presentation/pages/splash_page.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

/// Samvaad's declarative route table.
///
/// Watches `authStateChangesProvider` directly (not just inside
/// `redirect`) so that Riverpod itself rebuilds this provider — and
/// therefore produces a fresh `GoRouter` whose `redirect` closes over
/// an already-resolved `authState` — whenever auth state changes.
///
/// An earlier version of this bridged the auth stream into GoRouter's
/// own `refreshListenable` mechanism instead. That works in principle,
/// but introduces two independent stream subscriptions racing each
/// other (the listenable's, and the provider's own), with no guarantee
/// `redirect` re-runs only after the provider has actually resolved.
/// Watching the provider directly removes that race: `redirect` always
/// sees the same already-computed `authState` the rest of this
/// function saw when it built.
@riverpod
GoRouter appRouter(Ref ref) {
  final AsyncValue<AppUser?> authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // While the very first auth-state event hasn't arrived yet,
      // stay on splash rather than guessing.
      if (authState.isLoading) {
        return state.matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final bool isSignedIn = authState.value != null;
      final bool onAuthRoute = state.matchedLocation == AppRoutes.phoneEntry ||
          state.matchedLocation == AppRoutes.otpVerification;
      final bool onSplash = state.matchedLocation == AppRoutes.splash;

      if (!isSignedIn && !onAuthRoute) {
        return AppRoutes.phoneEntry;
      }
      if (isSignedIn && (onAuthRoute || onSplash)) {
        // No home/dashboard feature exists yet (a future phase) —
        // land signed-in users back on splash, which shows a
        // "signed in" placeholder rather than redirect-looping.
        return null;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.phoneEntry,
        name: AppRoutes.phoneEntryName,
        builder: (context, state) => const PhoneEntryPage(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: AppRoutes.otpVerificationName,
        builder: (context, state) {
          final extra = state.extra! as Map<String, String>;
          return OtpVerificationPage(
            verificationId: extra['verificationId']!,
            phoneNumber: extra['phoneNumber']!,
          );
        },
      ),
    ],
  );
}