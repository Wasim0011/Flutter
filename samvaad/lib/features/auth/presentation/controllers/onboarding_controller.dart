import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firestore_user_profile_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_profile_repository.dart';

part 'onboarding_controller.g.dart';

@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  return FirestoreUserProfileRepository();
}

sealed class OnboardingState {
  const OnboardingState();
}

final class OnboardingIdle extends OnboardingState {
  const OnboardingIdle();
}

final class OnboardingSubmitting extends OnboardingState {
  const OnboardingSubmitting();
}

final class OnboardingFailed extends OnboardingState {
  const OnboardingFailed(this.message);
  final String message;
}

final class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingIdle();

  Future<void> submit({
    required String userId,
    required CommunicationPreference preference,
  }) async {
    state = const OnboardingSubmitting();

    final result = await ref
        .read(userProfileRepositoryProvider)
        .saveCommunicationPreference(userId: userId, preference: preference);

    state = result.fold(
      onSuccess: (_) => const OnboardingComplete(),
      onFailure: (failure) => OnboardingFailed(failure.message),
    );
  }
}

/// Whether the current signed-in user has already completed
/// onboarding — the router guard (below) uses this to decide whether
/// to show OnboardingPage or let the user through.
///
/// FutureProvider rather than a controller method: this is a one-shot
/// read tied to the current user id, re-fetched whenever that id
/// changes (family-like behavior via ref.watch on authStateChanges).
@riverpod
Future<bool> hasCompletedOnboarding(Ref ref, String userId) async {
  final result = await ref.read(userProfileRepositoryProvider).getCommunicationPreference(userId);
  return result.fold(
    onSuccess: (preference) => preference != null,
    onFailure: (_) => false, // fail open to onboarding on error, not through it
  );
}