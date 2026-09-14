import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/firestore_chat_repository.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_providers.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) {
  return FirestoreChatRepository();
}