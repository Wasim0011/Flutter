import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'onboarding_controller.dart';

part 'edit_profile_controller.g.dart';

sealed class EditProfileState {
  const EditProfileState();
}

final class EditProfileIdle extends EditProfileState {
  const EditProfileIdle();
}

final class EditProfileSubmitting extends EditProfileState {
  const EditProfileSubmitting();
}

final class EditProfileFailed extends EditProfileState {
  const EditProfileFailed(this.message);
  final String message;
}

final class EditProfileSuccess extends EditProfileState {
  const EditProfileSuccess();
}

@riverpod
class EditProfileController extends _$EditProfileController {
  @override
  EditProfileState build() => const EditProfileIdle();

  Future<void> submit({
    required String userId,
    required String displayName,
    required String bio,
  }) async {
    if (displayName.trim().isEmpty) {
      state = const EditProfileFailed('Display name can\'t be empty.');
      return;
    }

    state = const EditProfileSubmitting();

    final repo = ref.read(userProfileRepositoryProvider);

    final nameResult = await repo.saveDisplayName(
      userId: userId,
      displayName: displayName.trim(),
    );
    if (nameResult.isFailure) {
      state = EditProfileFailed(
        nameResult.fold(onSuccess: (_) => '', onFailure: (f) => f.message),
      );
      return;
    }

    final bioResult = await repo.saveBio(userId: userId, bio: bio.trim());

    if (bioResult.isSuccess) {
      // Same FutureProvider-caching lesson from onboarding: without
      // invalidation, the directory/profile screens would keep
      // showing the old name/bio until something else happens to
      // invalidate them.
      ref.invalidate(displayNameProvider(userId));
      ref.invalidate(bioProvider(userId));
    }

    state = bioResult.fold(
      onSuccess: (_) => const EditProfileSuccess(),
      onFailure: (failure) => EditProfileFailed(failure.message),
    );
  }
}
