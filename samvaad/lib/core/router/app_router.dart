import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/chat/presentation/pages/conversation_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/onboarding_controller.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_entry_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/chat/presentation/pages/conversation_list_page.dart';
import '../../features/chat/presentation/pages/create_group_page.dart';
import '../../features/chat/presentation/pages/start_chat_page.dart';
import '../../features/shell/presentation/pages/splash_page.dart';
import 'app_routes.dart';

part 'app_router.g.dart';


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
      final bool onSplash = state.matchedLocation == AppRoutes.splash;

      if (!isSignedIn && !onAuthRoute) {
        return AppRoutes.phoneEntry;
      }

      if (isSignedIn && onAuthRoute) {
        return AppRoutes.home;
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
          return AppRoutes.home;
        }
        if (completed && onSplash) {
          return AppRoutes.home;
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
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const ConversationListPage(),
      ),
      GoRoute(
        path: AppRoutes.startChat,
        name: AppRoutes.startChatName,
        builder: (context, state) => const StartChatPage(),
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        name: AppRoutes.createGroupName,
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        path: AppRoutes.conversation,
        name: AppRoutes.conversationName,
        builder: (context, state) {
          final extra = state.extra! as Map<String, String>;
          return ConversationPage(
            conversationId: extra['conversationId']!,
            title: extra['title']!,
          );
        },
      ),
    ],
  );
}