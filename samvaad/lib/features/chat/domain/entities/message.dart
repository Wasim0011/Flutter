/// A single message within a conversation.
///
/// Deliberately minimal for v1 — text only. `type` exists as an enum
/// (not a bool `isText`) specifically so adding image/voice-note
/// support later is a new enum case plus new handling, not a
/// structural rework of this entity.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.type = MessageType.text,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Message &&
              other.id == id &&
              other.conversationId == conversationId &&
              other.senderId == senderId &&
              other.text == text &&
              other.sentAt == sentAt &&
              other.type == type);

  @override
  int get hashCode => Object.hash(id, conversationId, senderId, text, sentAt, type);

  @override
  String toString() =>
      'Message(id: $id, senderId: $senderId, text: $text, sentAt: $sentAt)';
}

enum MessageType {
  text,
  // Future: image, voiceNote, signVideo — deliberately not built yet,
  // this enum is the extension point when they are.
}