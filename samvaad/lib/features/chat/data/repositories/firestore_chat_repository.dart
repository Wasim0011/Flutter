import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Firestore implementation of [ChatRepository].
///
/// Data model:
/// - `conversations/{id}` — participantIds, type, title, lastMessage*,
///   and `directKey` (direct conversations only — see below).
/// - `conversations/{id}/messages/{id}` — subcollection, one doc per message.
///
/// `directKey` is the two participant ids sorted and joined
/// (e.g. "u1_u2"), stored only on direct conversations. This lets
/// `createOrGetDirectConversation` do a single exact-match query
/// instead of an array-contains query it would then have to filter
/// client-side — a deliberate modeling choice to keep that lookup
/// both correct and cheap.
class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  String _directKeyFor(String a, String b) {
    final List<String> sorted = [a, b]..sort();
    return sorted.join('_');
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_conversationFromDoc).toList());
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_messageFromDoc).toList());
  }

  @override
  Future<Result<Conversation>> createOrGetDirectConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final String key = _directKeyFor(currentUserId, otherUserId);
      final existing = await _conversations.where('directKey', isEqualTo: key).limit(1).get();

      if (existing.docs.isNotEmpty) {
        return Result.success(_conversationFromDoc(existing.docs.first));
      }

      final DateTime now = DateTime.now();
      final docRef = await _conversations.add({
        'type': ConversationType.direct.name,
        'participantIds': [currentUserId, otherUserId],
        'directKey': key,
        'createdAt': Timestamp.fromDate(now),
        'lastMessagePreview': null,
        'lastMessageAt': Timestamp.fromDate(now),
      });

      return Result.success(Conversation(
        id: docRef.id,
        type: ConversationType.direct,
        participantIds: [currentUserId, otherUserId],
        createdAt: now,
      ));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<Conversation>> createGroupConversation({
    required String currentUserId,
    required List<String> participantIds,
    required String title,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final Set<String> allParticipants = {currentUserId, ...participantIds};

      final docRef = await _conversations.add({
        'type': ConversationType.group.name,
        'participantIds': allParticipants.toList(),
        'title': title,
        'createdAt': Timestamp.fromDate(now),
        'lastMessagePreview': null,
        'lastMessageAt': Timestamp.fromDate(now),
      });

      return Result.success(Conversation(
        id: docRef.id,
        type: ConversationType.group,
        participantIds: allParticipants.toList(),
        createdAt: now,
        title: title,
      ));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final conversationRef = _conversations.doc(conversationId);

      // Two writes, not a transaction: the message write and the
      // preview-update are both idempotent-ish and eventually
      // consistent is acceptable here (a stale list preview for a
      // moment is a cosmetic issue, not a correctness one). A
      // transaction would be the right call if lastMessageAt were
      // ever used for something order-sensitive beyond display.
      await conversationRef.collection('messages').add({
        'senderId': senderId,
        'text': text,
        'sentAt': Timestamp.fromDate(now),
        'type': MessageType.text.name,
      });

      await conversationRef.set(
        {
          'lastMessagePreview': text,
          'lastMessageAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  Conversation _conversationFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Conversation(
      id: doc.id,
      type: ConversationType.values.firstWhere((t) => t.name == data['type']),
      participantIds: List<String>.from(data['participantIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      title: data['title'] as String?,
      lastMessagePreview: data['lastMessagePreview'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  Message _messageFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Message(
      id: doc.id,
      conversationId: doc.reference.parent.parent!.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      type: MessageType.values.firstWhere((t) => t.name == data['type']),
    );
  }
}