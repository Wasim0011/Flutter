import 'package:freezed_annotation/freezed_annotation.dart';
import 'failure.dart';

part 'result.freezed.dart';

/// An Either-style wrapper: repository and use-case methods return
/// `Result<T>` instead of throwing. This forces every call site to
/// explicitly handle both the success and failure paths — there is no
/// way to "forget" to catch an error, because there's nothing to catch;
/// the failure is just data.
@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  /// True when this Result represents success.
  bool get isSuccess => this is Success<T>;

  /// True when this Result represents failure.
  bool get isFailure => this is ResultFailure<T>;

  /// Exhaustively folds both cases down to a single value of type [R].
  ///
  /// Named `fold` (not `when`) deliberately — Freezed already generates
  /// a `when()` method for this union matching constructor names
  /// (`success`/`failure` as positional callbacks with different
  /// signatures), so reusing that name would collide. `fold` is the
  /// conventional name for this operation in Result/Either types anyway.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      ResultFailure<T>(failure: final f) => onFailure(f),
    };
  }
}