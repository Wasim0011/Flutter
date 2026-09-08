import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers_export.dart';

part 'phone_entry_controller.g.dart';

/// UI-facing state for the phone entry screen.
///
/// Kept separate from [AuthRepository]'s [Result] type deliberately —
/// the UI cares about "idle vs loading vs error vs sent," which is a
/// presentation concern, not a repository concern. Translating
/// Result/Failure into this shape happens once, here, so the widget
/// itself never touches Failure directly.
sealed class PhoneEntryState {
  const PhoneEntryState();
}

final class PhoneEntryIdle extends PhoneEntryState {
  const PhoneEntryIdle();
}

final class PhoneEntrySubmitting extends PhoneEntryState {
  const PhoneEntrySubmitting();
}

final class PhoneEntryFailed extends PhoneEntryState {
  const PhoneEntryFailed(this.message);
  final String message;
}

/// Emitted once, transiently, when an OTP has been sent successfully —
/// the widget listens for this to trigger navigation (wired in
/// Milestone 2.6) rather than holding it as persistent state.
final class PhoneEntrySent extends PhoneEntryState {
  const PhoneEntrySent(this.verificationId, this.phoneNumber);
  final String verificationId;
  final String phoneNumber;
}

@riverpod
class PhoneEntryController extends _$PhoneEntryController {
  @override
  PhoneEntryState build() => const PhoneEntryIdle();

  Future<void> submit(String phoneNumber) async {
    state = const PhoneEntrySubmitting();

    final AuthRepository repository = ref.read(authRepositoryProvider);
    final result = await repository.sendOtp(phoneNumber);

    state = result.fold(
      onSuccess: (sent) => PhoneEntrySent(sent.verificationId, phoneNumber),
      onFailure: (failure) => PhoneEntryFailed(_messageFor(failure)),
    );
  }

  /// Resets to idle — called by the widget after consuming a
  /// [PhoneEntryFailed] or [PhoneEntrySent] state (e.g. after showing
  /// an error, or right before navigating away), so a rebuild doesn't
  /// re-trigger the same one-time state.
  void reset() => state = const PhoneEntryIdle();

  String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    AuthenticationFailure(:final message) => message,
    PermissionFailure(:final message) => message,
    UnexpectedFailure(:final message) => message,
  };
}