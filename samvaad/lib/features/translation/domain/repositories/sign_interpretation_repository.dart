import '../../../../core/error/result.dart';
import '../entities/sign_interpretation.dart';

/// Contract for turning a single image frame into a best-effort text
/// interpretation of sign language content in it.
///
/// Deliberately scoped to a single frame, not a video stream — this
/// is the swappable interface point anticipated back in Phase 0: today
/// it's implemented against Gemini's multimodal image understanding;
/// if a purpose-built sign-language model (on-device TFLite, or a
/// specialized cloud API) ever replaces this, only the implementation
/// changes, nothing above this interface does.
abstract interface class SignInterpretationRepository {
  /// [imageBytes] is a single JPEG-encoded frame. Returns a
  /// [SignInterpretation] with the model's best-effort reading of any
  /// sign-language gesture visible in it, or a [Failure] if the
  /// request itself fails (network, quota, malformed image).
  ///
  /// Note this can succeed with an empty or low-confidence [text] even
  /// when no clear sign is present — callers should treat that as "no
  /// useful interpretation this frame," not surface it as an error.
  Future<Result<SignInterpretation>> interpretFrame(List<int> imageBytes);
}