/// This class is used to wrap the result of asynchronous operations shown in progress dialogs.
/// It can either be a [Success] containing the operation's result value, or a [Failure]
/// containing error details if the operation failed.
///
/// The type parameter [T] represents the type of value that will be returned in case of success.
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

/// Creates the Result object with [value] containing some value.
class Success<T> extends ProgressDialogResult<T> {
  /// [value] property holds the value returned by the Future.
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

/// Creates the Result object with [error] and [stackTrace] containing error object and stackTrace object respectively.
class Failure<T> extends ProgressDialogResult<T> {
  /// [error] holds the error value
  final Object error;

  /// [stackTrace] holds the stackTrace
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
