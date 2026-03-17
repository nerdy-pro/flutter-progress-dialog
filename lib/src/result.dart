/// The result of an asynchronous operation shown in a progress dialog.
///
/// Either a [Success] containing the value, or a [Failure] containing the error.
///
/// Example usage:
/// ```dart
/// ProgressDialogResult<String> result = await showProgressDialog(...);
/// switch (result) {
///   case Success<String>(value: var value):
///     print('Success: $value');
///   case Failure<String>(error: var error, stackTrace: var trace):
///     print('Error: $error');
/// }
/// ```
sealed class ProgressDialogResult<T> {
  /// Returns true if this result represents an error/failure case, false otherwise.
  /// This is equivalent to checking if the result is an instance of [Failure].
  bool get isError => this is Failure<T>;

  /// Returns true if this result represents a successful operation, false otherwise.
  /// This is equivalent to checking if the result is an instance of [Success].
  bool get isSuccess => this is Success<T>;

  /// Creates a success result with the given value
  static ProgressDialogResult<T> success<T>(T value) => Success(value);

  /// Creates a failure result with the given error and optional stack trace
  static ProgressDialogResult<T> failure<T>(Object error, [StackTrace? stackTrace]) => Failure(error, stackTrace);

  /// Unwraps the result, returning the success value or throwing the error
  T unwrap() {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
    };
  }

  /// Maps the success value to a new value using the provided function
  ProgressDialogResult<R> map<R>(R Function(T value) fn) {
    return switch (this) {
      Success(:final value) => Success(fn(value)),
      Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
    };
  }

  /// Chains results by applying the provided function to success values
  ProgressDialogResult<R> flatMap<R>(ProgressDialogResult<R> Function(T value) fn) {
    return switch (this) {
      Success(:final value) => fn(value),
      Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
    };
  }
}

/// A successful result containing the [value] returned by the task.
class Success<T> extends ProgressDialogResult<T> {
  final T value;

  @override
  bool get isError => false;

  Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A failed result containing the [error] and optional [stackTrace].
class Failure<T> extends ProgressDialogResult<T> {
  final Object error;
  final StackTrace? stackTrace;

  @override
  bool get isError => true;

  Failure(this.error, [this.stackTrace]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure && runtimeType == other.runtimeType && error == other.error && stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;
}
