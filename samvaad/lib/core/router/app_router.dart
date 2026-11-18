import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/edit_profile_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_entry_page.dart';
import '../../features/auth/presentation/providers/app_session.dart';
import '../../features/calling/domain/entities/call.dart';
import '../../features/calling/presentation/pages/call_page.dart';
import '../../features/calling/presentation/pages/incoming_call_page.dart';
import '../../features/chat/presentation/pages/conversation_list_page.dart';
import '../../features/chat/presentation/pages/conversation_page.dart';
import '../../features/chat/presentation/pages/create_group_page.dart';
import '../../features/chat/presentation/pages/start_chat_page.dart';
import '../../features/community/domain/entities/community_group.dart';
import '../../features/community/presentation/pages/community_home_page.dart';
import '../../features/community/presentation/pages/group_detail_page.dart';
import '../../features/community/presentation/pages/public_profile_page.dart';
import '../../features/shell/presentation/pages/splash_page.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

/// Where should a user in [session] be when they are at [location]?
/// A pure function: no providers, no I/O, so it is trivially testable.
@visibleForTesting
String? appRedirect({required AppSession session, required String location}) {
  final bool onAuthRoute =
      location == AppRoutes.phoneEntry || location == AppRoutes.otpVerification;

  return switch (session) {
    AppSessionLoading() =>
      location == AppRoutes.splash ? null : AppRoutes.splash,
    AppSessionSignedOut() => onAuthRoute ? null : AppRoutes.phoneEntry,
    AppSessionNeedsOnboarding() =>
      location == AppRoutes.onboarding ? null : AppRoutes.onboarding,
    AppSessionReady() =>
      (onAuthRoute ||
              location == AppRoutes.onboarding ||
              location == AppRoutes.splash)
          ? AppRoutes.home
          : null,
  };
}

/// Samvaad's router, built exactly once for the life of the app.
///
/// It must NOT `ref.watch` anything: a rebuilt GoRouter resets navigation and
/// recreates the splash screen. Instead it listens to [appSessionProvider] and
/// pushes changes into a [ValueNotifier], which GoRouter's `refreshListenable`
/// uses to re-run `redirect` in place.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final ValueNotifier<AppSession> session = ValueNotifier<AppSession>(
    ref.read(appSessionProvider),
  );
  ref.listen<AppSession>(appSessionProvider, (previous, next) {
    session.value = next;
  });

  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        appRedirect(session: session.value, location: state.matchedLocation),
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
        builder: (context, state) {
          // Read the user at build time. The old code captured it when the
          // router was created, which is stale for a router built only once.
          final AppSession current = session.value;
          return current is AppSessionSignedIn
              ? OnboardingPage(userId: current.user.id)
              : const SplashPage();
        },
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
      GoRoute(
        path: AppRoutes.community,
        name: AppRoutes.communityName,
        builder: (context, state) => const CommunityHomePage(),
      ),
      GoRoute(
        path: AppRoutes.publicProfile,
        name: AppRoutes.publicProfileName,
        builder: (context, state) =>
            PublicProfilePage(userId: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.groupDetail,
        name: AppRoutes.groupDetailName,
        builder: (context, state) =>
            GroupDetailPage(group: state.extra! as CommunityGroup),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.editProfileName,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.incomingCall,
        name: AppRoutes.incomingCallName,
        builder: (context, state) =>
            IncomingCallPage(call: state.extra! as Call),
      ),
      GoRoute(
        path: AppRoutes.call,
        name: AppRoutes.callName,
        builder: (context, state) => CallPage(call: state.extra! as Call),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
}
