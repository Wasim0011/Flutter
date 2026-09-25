import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/firestore_call_repository.dart';
import '../../domain/repositories/call_repository.dart';

part 'call_providers.g.dart';

@riverpod
CallRepository callRepository(Ref ref) {
  return FirestoreCallRepository();
}