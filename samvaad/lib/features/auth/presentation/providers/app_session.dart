import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shell/presentation/providers/splash_providers.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/onboarding_controller.dart';
import 'auth_providers.dart';

part 'app_session.g.dart';

/// Everything the router needs to know about "who is using the app right
/// now", collapsed into one plain value so `redirect` stays a pure function.
sealed class AppSession {
  const AppSession();
}

/// Auth, onboarding lookup, or the initial brand splash hold hasn't finished yet.
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
  final AsyncValue<void> hold = ref.watch(splashHoldProvider);
  final AsyncValue<AppUser?> auth = ref.watch(authStateChangesProvider);

  if (hold.isLoading) {
    return const AppSessionLoading();
  }

  return auth.when<AppSession>(
    loading: () => const AppSessionLoading(),
    error: (error, stackTrace) => const AppSessionSignedOut(),
    data: (user) {
      if (user == null) return const AppSessionSignedOut();

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
