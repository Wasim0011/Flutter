import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/gemini_sign_interpretation_repository.dart';
import '../../domain/repositories/sign_interpretation_repository.dart';

part 'translation_providers.g.dart';

@riverpod
SignInterpretationRepository signInterpretationRepository(Ref ref) {
  return GeminiSignInterpretationRepository();
}