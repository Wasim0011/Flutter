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
    required String displayName,
    required CommunicationPreference preference,
  }) async {
    state = const OnboardingSubmitting();

    final UserProfileRepository repo = ref.read(userProfileRepositoryProvider);

    final nameResult = await repo.saveDisplayName(userId: userId, displayName: displayName);
    if (nameResult.isFailure) {
      state = OnboardingFailed(
        nameResult.fold(onSuccess: (_) => '', onFailure: (f) => f.message),
      );
      return;
    }

    final preferenceResult =
    await repo.saveCommunicationPreference(userId: userId, preference: preference);

    if (preferenceResult.isSuccess) {
      // hasCompletedOnboardingProvider and displayNameProvider are
      // plain FutureProviders — they cache their resolved value and
      // never recompute on their own just because Firestore changed
      // underneath them. Without this invalidation, the router's
      // redirect (which reads hasCompletedOnboardingProvider) would
      // keep seeing a stale "not completed" result and could bounce a
      // freshly-onboarded user back to /onboarding indefinitely.
      ref.invalidate(hasCompletedOnboardingProvider(userId));
      ref.invalidate(displayNameProvider(userId));
    }

    state = preferenceResult.fold(
      onSuccess: (_) => const OnboardingComplete(),
      onFailure: (failure) => OnboardingFailed(failure.message),
    );
  }
}

@riverpod
Future<bool> hasCompletedOnboarding(Ref ref, String userId) async {
  final result = await ref.read(userProfileRepositoryProvider).getCommunicationPreference(userId);
  return result.fold(
    onSuccess: (preference) => preference != null,
    onFailure: (_) => false,
  );
}

/// The current [CommunicationPreference] for [userId], or null if not
/// yet set. Used by the chat feature to adapt message screen layout.
@riverpod
Future<CommunicationPreference?> communicationPreference(Ref ref, String userId) async {
  final result = await ref.read(userProfileRepositoryProvider).getCommunicationPreference(userId);
  return result.fold(onSuccess: (preference) => preference, onFailure: (_) => null);
}

/// The stored display name for [userId], or null if not set. Used by
/// chat's conversation list and conversation screen to show real
/// names instead of raw user ids.
@riverpod
Future<String?> displayName(Ref ref, String userId) async {
  final result = await ref.read(userProfileRepositoryProvider).getDisplayName(userId);
  return result.fold(onSuccess: (name) => name, onFailure: (_) => null);
}

/// The stored bio for [userId], or null if not set. Used by the
/// community feature's public profile screen (Milestone 5.2).
@riverpod
Future<String?> bio(Ref ref, String userId) async {
  final result = await ref.read(userProfileRepositoryProvider).getBio(userId);
  return result.fold(onSuccess: (bio) => bio, onFailure: (_) => null);
}