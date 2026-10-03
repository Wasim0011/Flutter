import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/translation/domain/entities/sign_interpretation.dart';

void main() {
  group('SignInterpretation', () {
    test('two instances with identical fields are equal', () {
      const a = SignInterpretation(
        text: 'hello',
        confidence: InterpretationConfidence.medium,
      );
      const b = SignInterpretation(
        text: 'hello',
        confidence: InterpretationConfidence.medium,
      );

      expect(a, equals(b));
    });

    test('differing confidence makes instances unequal', () {
      const a = SignInterpretation(
        text: 'hello',
        confidence: InterpretationConfidence.medium,
      );
      const b = SignInterpretation(
        text: 'hello',
        confidence: InterpretationConfidence.low,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
