///Used in ProgressBarDialog widget to store result returned by the Future which is called
///inside the private [_getResult] function.

class Result<T> {
  /// [value] property is used to store value of the type T?.
  final T? value;

  /// [error] property stores object of the Object? type.
  final Object? error;

  /// [stackTrace] property stores object of the StackTrace? type.
  final StackTrace? stackTrace;

  /// Creates the Result object with [value] containing some value.
  /// [error] and [stackTrace] properties are null.

  Result.ok(T v)
      : value = v,
        error = null,
        stackTrace = null;

  /// Creates the Result object with [error] and [stackTrace] containing error object and stackTrace object respectively.
  /// [value], in that case, is null.
  Result.error(Object e, StackTrace s)
      : error = e,
        value = null,
        stackTrace = s;

  ///Returns true if the error is not null.
  bool get isError => error != null;

  /// Getter for the error property.
  Object get requireError => error!;

  /// Getter for the value property.
  T get requireValue => value!;
}
