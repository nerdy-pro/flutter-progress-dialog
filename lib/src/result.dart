/// The result of an asynchronous operation shown in a progress dialog.
///
/// One of [Success] containing the value, [Failure] containing the error, or
/// [Cancelled] when the dialog was dismissed before the task delivered a result.
///
/// Example usage:
/// ```dart
/// ProgressDialogResult<String> result = await showProgressDialog(...);
/// switch (result) {
///   case Success<String>(value: var value):
///     print('Success: $value');
///   case Failure<String>(error: var error, stackTrace: var trace):
///     print('Error: $error');
///   case Cancelled<String>():
///     print('Dismissed before the task finished');
/// }
/// ```
sealed class ProgressDialogResult<T> {
  const ProgressDialogResult();

  /// Returns true if this result represents an error/failure case, false otherwise.
  /// This is equivalent to checking if the result is an instance of [Failure].
  bool get isError => this is Failure<T>;

  /// Returns true if this result represents a successful operation, false otherwise.
  /// This is equivalent to checking if the result is an instance of [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns true if the dialog was dismissed before the task delivered a result.
  /// This is equivalent to checking if the result is an instance of [Cancelled].
  bool get isCancelled => this is Cancelled<T>;

  /// Creates a success result with the given value
  static ProgressDialogResult<T> success<T>(T value) => Success(value);

  /// Creates a failure result with the given error and optional stack trace
  static ProgressDialogResult<T> failure<T>(Object error,
          [StackTrace? stackTrace]) =>
      Failure(error, stackTrace);

  /// Creates a cancelled result
  static ProgressDialogResult<T> cancelled<T>() => Cancelled<T>();

  /// Unwraps the result, returning the success value, throwing the error, or
  /// throwing a [ProgressDialogCancelledException] if the dialog was dismissed
  T unwrap() {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
      Cancelled() => throw const ProgressDialogCancelledException(),
    };
  }

  /// Maps the success value to a new value using the provided function
  ProgressDialogResult<R> map<R>(R Function(T value) fn) {
    return switch (this) {
      Success(:final value) => Success(fn(value)),
      Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
      Cancelled() => Cancelled<R>(),
    };
  }

  /// Chains results by applying the provided function to success values
  ProgressDialogResult<R> flatMap<R>(
      ProgressDialogResult<R> Function(T value) fn) {
    return switch (this) {
      Success(:final value) => fn(value),
      Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
      Cancelled() => Cancelled<R>(),
    };
  }
}

/// A successful result containing the [value] returned by the task.
class Success<T> extends ProgressDialogResult<T> {
  final T value;

  @override
  bool get isError => false;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A failed result containing the [error] and optional [stackTrace].
class Failure<T> extends ProgressDialogResult<T> {
  final Object error;
  final StackTrace? stackTrace;

  @override
  bool get isError => true;

  const Failure(this.error, [this.stackTrace]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;
}

/// A cancelled result: the dialog was dismissed before the task's result could
/// be delivered — for example by the Android back button, or by a custom
/// `builder` that calls `Navigator.pop`.
///
/// The task itself is **not** interrupted. Dart futures cannot be cancelled, so
/// the work keeps running to completion in the background and its result — value
/// or error — is discarded.
class Cancelled<T> extends ProgressDialogResult<T> {
  const Cancelled();

  @override
  bool get isError => false;

  @override
  bool get isCancelled => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cancelled && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Thrown by [ProgressDialogResult.unwrap] when the result is [Cancelled].
///
/// A cancelled result carries neither a value to return nor an error to rethrow,
/// so `unwrap` throws this instead.
class ProgressDialogCancelledException implements Exception {
  const ProgressDialogCancelledException();

  @override
  String toString() =>
      'ProgressDialogCancelledException: the progress dialog was dismissed before the task completed';
}
