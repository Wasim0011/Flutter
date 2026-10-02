import 'package:samvaad/core/error/failure.dart';
import 'package:samvaad/core/error/result.dart';
import 'package:samvaad/features/translation/domain/entities/sign_interpretation.dart';
import 'package:samvaad/features/translation/domain/repositories/sign_interpretation_repository.dart';

class FakeSignInterpretationRepository implements SignInterpretationRepository {
  SignInterpretation? nextResult;
  Failure? nextFailure;

  @override
  Future<Result<SignInterpretation>> interpretFrame(List<int> imageBytes) async {
    if (nextFailure != null) return Result.failure(nextFailure!);
    return Result.success(
      nextResult ?? const SignInterpretation(text: '', confidence: InterpretationConfidence.low),
    );
  }
}