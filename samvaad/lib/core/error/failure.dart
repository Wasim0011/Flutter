/// Domain-level representation of "what can go wrong" in Samvaad,
/// deliberately decoupled from any specific exception type (Firebase,
/// network, platform channel, etc).
///
/// Implemented as a plain Dart 3 sealed class hierarchy rather than a
/// Freezed-generated union. For a value type this simple (one message
/// per case), Dart's native `sealed class` + switch pattern matching
/// already gives us the same exhaustive-handling guarantee Freezed
/// would, with no codegen step and no exposure to Freezed's current
/// analyzer version constraint (see rrousselGit/freezed#1353 — Freezed
/// hasn't yet caught up to the analyzer version riverpod_generator
/// requires). Freezed remains the right tool for data-heavy models
/// later (e.g. Auth/Chat DTOs) — this is a deliberate, scoped choice
/// for this file, not a blanket rejection of Freezed.
sealed class Failure {
  const Failure(this.message);

  final String message;

  /// No network connectivity, or a request failed at the transport layer.
  const factory Failure.network(String message) = NetworkFailure;

  /// Authentication/authorization failed (invalid credentials, expired
  /// session, insufficient permissions to perform an action).
  const factory Failure.authentication(String message) = AuthenticationFailure;

  /// A device/platform permission was denied (camera, microphone,
  /// notifications) — relevant given calling and captioning depend on these.
  const factory Failure.permission(String message) = PermissionFailure;

  /// Input failed validation before ever reaching a data source.
  const factory Failure.validation(String message) = ValidationFailure;

  /// Catch-all for anything not yet classified. Every occurrence during
  /// development is a signal to add a more specific Failure case.
  const factory Failure.unexpected(String message) = UnexpectedFailure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other.runtimeType == runtimeType &&
              other is Failure &&
              other.message == message);

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType($message)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}