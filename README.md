# flutter_future_progress_dialog

[![Pub Version](https://img.shields.io/pub/v/flutter_future_progress_dialog)](https://pub.dev/packages/flutter_future_progress_dialog)
![GitHub License](https://img.shields.io/github/license/nerdy-pro/flutter-progress-dialog)

A Flutter package that displays a progress dialog while an asynchronous task is running and returns the result when complete. Supports Material, Cupertino, and platform-adaptive dialog styles with built-in error handling.

Developed and maintained by [Nerdy Pro](https://nerdy.pro).

![Flutter progress dialog demo on iPhone](https://raw.githubusercontent.com/nerdy-pro/flutter-progress-dialog/main/img/flutter_progress_dialog.gif)

## Features

- Show a non-dismissible progress dialog while a Future is running
- Material and Cupertino dialog styles
- Adaptive dialog that automatically matches the host platform
- Custom dialog UI via a builder parameter
- Type-safe `ProgressDialogResult<T>` with `Success` and `Failure` variants
- Error handling with stack traces

## Installation

```shell
flutter pub add flutter_future_progress_dialog
```

```dart
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';
```

## Usage

### Basic example

Pass a `context` and a `future` callback to `showProgressDialog`. The dialog stays visible until the task completes, then returns a `ProgressDialogResult<T>`.

```dart
Future<String> fetchData() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Hello';
}

Future<void> onButtonPressed(BuildContext context) async {
  final result = await showProgressDialog(
    context: context,
    future: () => fetchData(),
  );

  switch (result) {
    case Success(:final value):
      print('Got: $value');
    case Failure(:final error):
      print('Error: $error');
  }
}
```

### Cupertino and adaptive dialogs

Use `showCupertinoProgressDialog` for an iOS-styled dialog, or `showAdaptiveProgressDialog` to automatically pick the right style for the current platform.

```dart
// iOS style
final result = await showCupertinoProgressDialog(
  context: context,
  future: () => fetchData(),
);

// Automatic: Cupertino on iOS/macOS, Material elsewhere
final result = await showAdaptiveProgressDialog(
  context: context,
  future: () => fetchData(),
);
```

### Custom dialog UI

Pass a `builder` to replace the default progress indicator with your own widget.

```dart
final result = await showProgressDialog(
  context: context,
  future: () => fetchData(),
  builder: (context) => const AlertDialog(
    content: Text('Loading, please wait...'),
  ),
);
```

### Handling results

`ProgressDialogResult<T>` is a sealed class with two variants:

- `Success<T>` — contains the `value` returned by the task
- `Failure<T>` — contains the `error` and optional `stackTrace`

```dart
switch (result) {
  case Success(:final value):
    // Use the value
    break;
  case Failure(:final error, :final stackTrace):
    // Handle the error
    break;
}
```

You can also use convenience methods:

```dart
result.isSuccess; // true if Success
result.isError;   // true if Failure
result.unwrap();  // returns value or throws error
result.map((v) => v.toString()); // transforms Success value
```

## API reference

| Function | Description |
|---|---|
| `showProgressDialog` | Material-styled progress dialog |
| `showCupertinoProgressDialog` | Cupertino-styled progress dialog |
| `showAdaptiveProgressDialog` | Platform-adaptive progress dialog |

A complete working example is available in the [example directory](https://github.com/nerdy-pro/flutter-progress-dialog/tree/main/example).

## License

MIT License. See [LICENSE](LICENSE) for details.
