import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_entry_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/shell/presentation/pages/splash_page.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

/// Samvaad's declarative route table, now provided via Riverpod so
/// `redirect` can react to live auth state (Milestone 2.3's
/// `authStateChangesProvider`) — this is exactly the mechanical
/// upgrade anticipated back in Milestone 4 of Phase 1, not a redesign.
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // GoRouter needs to re-evaluate `redirect` whenever auth state
    // changes (e.g. sign-out from a future settings screen) — this
    // Listenable bridges the auth stream into something GoRouter can
    // subscribe to directly. We go straight to the repository's raw
    // Stream<AppUser?> here rather than a `.stream` provider modifier,
    // since the raw stream is unambiguous regardless of how the
    // generated provider class exposes (or doesn't expose) that
    // modifier across Riverpod versions.
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final AsyncValue<AppUser?> authState = ref.read(authStateChangesProvider);

      // While the very first auth-state event hasn't arrived yet,
      // stay on splash rather than guessing — this is the "loading"
      // window between app start and Firebase reporting whether
      // anyone is signed in.
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
        // No home/dashboard feature exists yet (that's a future
        // phase) — land signed-in users back on splash, which will
        // simply show a "signed in" placeholder for now rather than
        // redirect-looping. See SplashPage.
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

/// Adapts a raw [Stream] into a [Listenable], which is what GoRouter's
/// `refreshListenable` requires. This is the standard, documented
/// bridge pattern for combining GoRouter with any stream-based state
/// (Riverpod, Bloc, plain Streams) — GoRouter itself has no Riverpod
/// awareness, so this small adapter is necessary glue, not a workaround.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}