/// Domain representation of an authenticated Samvaad user.
///
/// Deliberately minimal and Firebase-agnostic — this is what the rest
/// of the app (UI, other features) is allowed to know about "who is
/// logged in." Firebase-specific concepts (UID format, provider data,
/// ID tokens) stay entirely inside the auth feature's data layer and
/// never leak into this entity or beyond it.
///
/// `communicationPreference` is nullable because it's collected during
/// onboarding (Milestone 2.7), not at the moment a phone number is
/// verified — a user can exist, briefly, before they've stated one.
class AppUser {
  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.communicationPreference,
  });

  /// Stable unique identifier for this user. Sourced from Firebase Auth's
  /// UID in the data layer, but treated here as an opaque string — the
  /// domain layer has no business knowing it's a Firebase UID specifically.
  final String id;

  /// E.164-formatted phone number (e.g. "+919876543210") used to sign in.
  final String phoneNumber;

  /// Optional display name, set during onboarding. Null until then.
  final String? displayName;

  /// How this user prefers to communicate — captions, sign language,
  /// text-first, or some combination. Null until onboarding (Milestone
  /// 2.7) sets it; UI elsewhere in the app should treat null as
  /// "not yet specified," not as a default preference.
  final CommunicationPreference? communicationPreference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is AppUser &&
              other.id == id &&
              other.phoneNumber == phoneNumber &&
              other.displayName == displayName &&
              other.communicationPreference == communicationPreference);

  @override
  int get hashCode =>
      Object.hash(id, phoneNumber, displayName, communicationPreference);

  @override
  String toString() =>
      'AppUser(id: $id, phoneNumber: $phoneNumber, displayName: $displayName, '
          'communicationPreference: $communicationPreference)';
}

/// How a user prefers to communicate within Samvaad.
///
/// Collected during onboarding (Milestone 2.7) and used across future
/// features (chat, calling) to decide default UI — e.g. captions-on by
/// default for `captionsFirst`, or surfacing sign-language-friendly
/// call layouts for `signLanguage`.
enum CommunicationPreference {
  /// Prefers spoken/typed text with live captions.
  captionsFirst,

  /// Prefers or uses sign language as a primary mode.
  signLanguage,

  /// Prefers text-based communication (chat) over voice/video where possible.
  textFirst,

  /// No strong preference — the app should not assume anything and
  /// should surface all modes equally.
  noPreference,
}