///Used in ProgressBarDialog widget to store result returned by the Future.
sealed class Result<T> {
  /// Left as a back compatibility with old versions of the library.
  /// @deprecated Use pattern matching of this class instead: its either [ResultOk] or [ResultError].
  bool get isError;

  static Result<T> runCatching<T>(T Function() f) {
    try {
      final result = f();
      return ResultOk(value: result);
    } catch (e, s) {
      return ResultError(error: e, stackTrace: s);
    }
  }

  static Future<Result<T>> runCatchingFuture<T>(Future<T> Function() f) async {
    try {
      final result = await f();
      return ResultOk(value: result);
    } catch (e, s) {
      return ResultError(error: e, stackTrace: s);
    }
  }
}

/// Creates the Result object with [value] containing some value.
class ResultOk<T> extends Result<T> {
  /// [value] property holds the value returned by the Future.
  final T value;

  @override
  bool get isError => false;

  ResultOk({required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ResultOk && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Creates the Result object with [error] and [stackTrace] containing error object and stackTrace object respectively.
class ResultError<T> extends Result<T> {
  /// [error] holds the error value
  final Object error;

  /// [stackTrace] holds the stackTrace
  final StackTrace? stackTrace;

  @override
  bool get isError => true;

  ResultError({required this.error, this.stackTrace});

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
