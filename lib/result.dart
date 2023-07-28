///Used to return the result of an asynchronous function or an error if it was thrown.
class Result<T> {
  final T? _value;

  final Object? _error;

  final StackTrace? _stackTrace;

  /// Creates the Result object with [v] containing some value.
  Result.ok(T v)
      : _value = v,
        _error = null,
        _stackTrace = null;

  /// Creates the Result object with [e] and [s] containing error object and stackTrace object respectively.
  Result.error(Object e, StackTrace s)
      : _error = e,
        _value = null,
        _stackTrace = s;

  ///Returns true if the error is not null.
  bool get isError => _error != null;

  /// Getter for the error.
  /// Be sure to check [isError] before calling this getter.
  Object get requireError => _error!;

  /// Getter for the stackTrace.
  /// Be sure to check [isError] before calling this getter.
  StackTrace get requireStackTrace => _stackTrace!;

  /// Getter for the value property.
  /// Be sure to check [isError] before calling this getter.
  T get requireValue => _value!;
}
