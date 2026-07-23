import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Domain-level representation of "what can go wrong" in Samvaad,
/// deliberately decoupled from any specific exception type (Firebase,
/// network, platform channel, etc).
///
/// Presentation and domain layers switch on this sealed type instead of
/// catching raw exceptions — the compiler enforces exhaustive handling,
/// so a new failure case can never silently fall through unhandled UI.
@freezed
sealed class Failure with _$Failure {
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

  /// Catch-all for anything not yet classified. Every occurrence of this
  /// case during development is a signal to add a more specific Failure
  /// case — it should shrink over time, not grow.
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}