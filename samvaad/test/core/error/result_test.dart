import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/core/error/failure.dart';
import 'package:samvaad/core/error/result.dart';

void main() {
  group('Result', () {
    test('success wraps data and reports isSuccess correctly', () {
      const Result<int> result = Result.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('failure wraps a Failure and reports isFailure correctly', () {
      const Result<int> result = Result.failure(Failure.network('offline'));

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('fold() invokes the onSuccess branch for Success', () {
      const Result<int> result = Result.success(10);

      final String output = result.fold(
        onSuccess: (data) => 'got $data',
        onFailure: (failure) => 'failed',
      );

      expect(output, 'got 10');
    });

    test('fold() invokes the onFailure branch for ResultFailure', () {
      const Result<String> result =
      Result.failure(Failure.validation('empty field'));

      final String output = result.fold(
        onSuccess: (data) => 'got $data',
        onFailure: (failure) => failure.when(
          network: (m) => 'network: $m',
          authentication: (m) => 'auth: $m',
          permission: (m) => 'permission: $m',
          validation: (m) => 'validation: $m',
          unexpected: (m) => 'unexpected: $m',
        ),
      );

      expect(output, 'validation: empty field');
    });

    test('Failure equality works via Freezed value equality', () {
      const Failure a = Failure.network('offline');
      const Failure b = Failure.network('offline');

      expect(a, equals(b));
    });
  });
}