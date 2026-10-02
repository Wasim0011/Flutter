/// The result of asking a translation provider (Gemini, in the current
/// implementation) to interpret a single video frame as sign language.
///
/// `confidence` is intentionally a coarse three-level signal, not a
/// numeric score — Gemini doesn't return a calibrated probability for
/// this kind of task, and presenting a fake-precise number (e.g.
/// "87% confident") would overstate what the model actually knows.
/// This entity is honest about being a best-effort interpretation,
/// not a certified translation.
class SignInterpretation {
  const SignInterpretation({
    required this.text,
    required this.confidence,
  });

  final String text;
  final InterpretationConfidence confidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is SignInterpretation && other.text == text && other.confidence == confidence);

  @override
  int get hashCode => Object.hash(text, confidence);

  @override
  String toString() => 'SignInterpretation(text: $text, confidence: $confidence)';
}

enum InterpretationConfidence { low, medium, high }