///Used in ProgressBarDialog widget to store result returned by the Future which is called
///inside the private [_getResult] function.
sealed class Result<T> {
  /// Left as a back compatibility with old versions of the library.
  /// @deprecated Use pattern matching of this class instead: its either [ResultOk] or [ResultError].
  bool get isError;
}

/// Creates the Result object with [value] containing some value.
class ResultOk<T> extends Result<T> {
  /// [value] property is used to store value of the type T?.
  final T? value;

  @override
  bool get isError => false;

  ResultOk({this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ResultOk && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Creates the Result object with [error] and [stackTrace] containing error object and stackTrace object respectively.
class ResultError<T> extends Result<T> {
  /// [error] property stores object of the Object? type.
  final Object? error;

  /// [stackTrace] property stores object of the StackTrace? type.
  final StackTrace? stackTrace;

  @override
  bool get isError => true;

  ResultError({this.error, this.stackTrace});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultError &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;
}
