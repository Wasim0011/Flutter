import '../../../auth/domain/entities/app_user.dart';

/// Maps a user's [CommunicationPreference] to concrete display
/// decisions for the conversation screen.
///
/// Kept as a small, explicit mapping rather than scattering
/// `if (preference == ...)` checks through the widget tree — every
/// layout decision tied to communication preference lives here, in
/// one place, so it's obvious what "adapting to preference" actually
/// means concretely.
class ChatDisplayStyle {
  const ChatDisplayStyle({
    required this.fontScale,
    required this.announceIncomingMessages,
    required this.showTimestamps,
  });

  /// Multiplier applied to message text size. Larger for
  /// captionsFirst, since captions/live text are the primary channel
  /// for that preference, not a secondary aid.
  final double fontScale;

  /// Whether incoming messages are wrapped in a `Semantics(liveRegion:
  /// true)` so screen readers announce them as they arrive — the
  /// direct, concrete meaning of "captions first" in a text chat
  /// context: new content should be announced, not just present.
  final bool announceIncomingMessages;

  /// Whether per-message timestamps are shown. Hidden for textFirst
  /// to keep the layout dense and scannable — a deliberate simplicity
  /// choice for users who primarily communicate via text and want
  /// less visual noise per message.
  final bool showTimestamps;

  factory ChatDisplayStyle.forPreference(CommunicationPreference? preference) {
    switch (preference) {
      case CommunicationPreference.captionsFirst:
        return const ChatDisplayStyle(
          fontScale: 1.2,
          announceIncomingMessages: true,
          showTimestamps: true,
        );
      case CommunicationPreference.textFirst:
        return const ChatDisplayStyle(
          fontScale: 1.0,
          announceIncomingMessages: false,
          showTimestamps: false,
        );
      case CommunicationPreference.signLanguage:
      // Sign language support in calling/video isn't built yet
      // (deferred per Phase 0's product decision) — for the text
      // chat surface specifically, this preference currently
      // behaves like noPreference. Kept as its own case rather than
      // falling through to `default`, so a future video-chat
      // feature has an obvious place to give it real behavior.
        return const ChatDisplayStyle(
          fontScale: 1.0,
          announceIncomingMessages: false,
          showTimestamps: true,
        );
      case CommunicationPreference.noPreference:
      case null:
        return const ChatDisplayStyle(
          fontScale: 1.0,
          announceIncomingMessages: false,
          showTimestamps: true,
        );
    }
  }
}