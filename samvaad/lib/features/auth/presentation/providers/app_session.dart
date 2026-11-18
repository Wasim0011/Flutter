import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/app_user.dart';
import '../controllers/onboarding_controller.dart';
import 'auth_providers.dart';

part 'app_session.g.dart';

/// Everything the router needs to know about "who is using the app right
/// now", collapsed into one plain value so `redirect` stays a pure function.
sealed class AppSession {
  const AppSession();
}

/// Auth (or the onboarding lookup) hasn't answered yet.
final class AppSessionLoading extends AppSession {
  const AppSessionLoading();
}

final class AppSessionSignedOut extends AppSession {
  const AppSessionSignedOut();
}

sealed class AppSessionSignedIn extends AppSession {
  const AppSessionSignedIn(this.user);
  final AppUser user;
}

final class AppSessionNeedsOnboarding extends AppSessionSignedIn {
  const AppSessionNeedsOnboarding(super.user);
}

final class AppSessionReady extends AppSessionSignedIn {
  const AppSessionReady(super.user);
}

@Riverpod(keepAlive: true)
AppSession appSession(Ref ref) {
  final AsyncValue<AppUser?> auth = ref.watch(authStateChangesProvider);

  return auth.when<AppSession>(
    loading: () => const AppSessionLoading(),
    error: (error, stackTrace) => const AppSessionSignedOut(),
    data: (user) {
      if (user == null) return const AppSessionSignedOut();

      // Legitimate ref.watch: it runs inside this provider's own build, so
      // Riverpod re-runs this provider (not the router) when it changes.
      final AsyncValue<bool> onboarding = ref.watch(
        hasCompletedOnboardingProvider(user.id),
      );

      return onboarding.when<AppSession>(
        loading: () => const AppSessionLoading(),
        error: (error, stackTrace) => AppSessionNeedsOnboarding(user),
        data: (completed) =>
            completed ? AppSessionReady(user) : AppSessionNeedsOnboarding(user),
      );
    },
  );
}
