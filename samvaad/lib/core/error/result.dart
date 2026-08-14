import 'failure.dart';

/// An Either-style wrapper: repository and use-case methods return
/// `Result<T>` instead of throwing. See `failure.dart` for why this is
/// hand-written rather than Freezed-generated.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  /// True when this Result represents success.
  bool get isSuccess => this is Success<T>;

  /// True when this Result represents failure.
  bool get isFailure => this is ResultFailure<T>;

  /// Exhaustively folds both cases down to a single value of type [R].
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

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.data == data);

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'Success($data)';
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is ResultFailure<T> && other.failure == failure);

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'ResultFailure($failure)';
}