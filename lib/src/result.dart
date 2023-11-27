///Used in ProgressBarDialog widget to store result returned by the Future which is called
///inside the private [_getResult] function.
sealed class Result<T> {}

/// Creates the Result object with [value] containing some value.
class ResultOk<T> extends Result<T> {
  /// [value] property is used to store value of the type T?.
  final T? value;

  ResultOk({this.value});
}

/// Creates the Result object with [error] and [stackTrace] containing error object and stackTrace object respectively.
class ResultError<T> extends Result<T> {
  /// [error] property stores object of the Object? type.
  final Object? error;

  /// [stackTrace] property stores object of the StackTrace? type.
  final StackTrace? stackTrace;

  ResultError({this.error, this.stackTrace});
}
