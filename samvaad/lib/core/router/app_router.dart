import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/onboarding_controller.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
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
/// Milestone 2.7 adds a second reactive dependency the same way:
/// `redirect` also watches `hasCompletedOnboardingProvider` for the
/// current user, so a signed-in user who hasn't set a communication
/// preference yet is routed to onboarding before reaching anywhere else.
@riverpod
GoRouter appRouter(Ref ref) {
  final AsyncValue<AppUser?> authState = ref.watch(authStateChangesProvider);
  final AppUser? currentUser = authState.value;

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // While the very first auth-state event hasn't arrived yet,
      // stay on splash rather than guessing.
      if (authState.isLoading) {
        return state.matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final bool isSignedIn = currentUser != null;
      final bool onAuthRoute = state.matchedLocation == AppRoutes.phoneEntry ||
          state.matchedLocation == AppRoutes.otpVerification;
      final bool onOnboarding = state.matchedLocation == AppRoutes.onboarding;
      // final bool onSplash = state.matchedLocation == AppRoutes.splash;

      if (!isSignedIn && !onAuthRoute) {
        return AppRoutes.phoneEntry;
      }

      if (isSignedIn && onAuthRoute) {
        return AppRoutes.splash;
      }

      if (isSignedIn) {
        final AsyncValue<bool> onboardingDone =
        ref.watch(hasCompletedOnboardingProvider(currentUser.id));

        // While checking Firestore, stay put rather than guessing.
        if (onboardingDone.isLoading) return null;

        final bool completed = onboardingDone.value ?? false;

        if (!completed && !onOnboarding) {
          return AppRoutes.onboarding;
        }
        if (completed && onOnboarding) {
          // No home/dashboard feature exists yet (a future phase) —
          // land back on splash, which shows a "signed in" placeholder
          // rather than redirect-looping.
          return AppRoutes.splash;
        }
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
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (context, state) => OnboardingPage(userId: currentUser!.id),
      ),
    ],
  );
}