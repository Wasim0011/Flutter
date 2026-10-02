import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/sign_interpretation.dart';
import '../../domain/repositories/sign_interpretation_repository.dart';

/// Gemini-backed implementation of [SignInterpretationRepository], via
/// Firebase AI Logic (no separate API key management needed — this
/// authenticates through the existing Firebase project).
///
/// This is the one file that should import `firebase_ai` for sign
/// interpretation — the same discipline as every other data-layer
/// implementation in this codebase.
class GeminiSignInterpretationRepository implements SignInterpretationRepository {
  GeminiSignInterpretationRepository({GenerativeModel? model})
      : _model = model ??
      FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: Content.system(_systemPrompt),
      );

  final GenerativeModel _model;

  static const String _systemPrompt =
      'You are assisting a deaf or hard-of-hearing user during a video '
      'call by interpreting sign language gestures visible in a single '
      'photo frame. Respond with ONLY the most likely word or short '
      'phrase being signed, in plain text, no punctuation, no '
      'explanation. If no clear sign is visible, respond with exactly: '
      'NONE';

  @override
  Future<Result<SignInterpretation>> interpretFrame(List<int> imageBytes) async {
    try {
      final response = await _model.generateContent([
        Content.multi([
          InlineDataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]);

      final String raw = (response.text ?? '').trim();
      if (raw.isEmpty || raw.toUpperCase() == 'NONE') {
        return const Result.success(
          SignInterpretation(text: '', confidence: InterpretationConfidence.low),
        );
      }

      // Gemini doesn't return a calibrated confidence score for this
      // task — we approximate: a short, clean single-word/phrase
      // response is treated as higher confidence than a long or
      // hedging one (which usually signals the model wasn't sure).
      final InterpretationConfidence confidence = raw.split(' ').length <= 2
          ? InterpretationConfidence.medium
          : InterpretationConfidence.low;

      return Result.success(SignInterpretation(text: raw, confidence: confidence));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }
}