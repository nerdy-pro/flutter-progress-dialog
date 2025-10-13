## flutter_future_progress_dialog

[![Pub Version](https://img.shields.io/pub/v/flutter_future_progress_dialog)](https://pub.dev/packages/flutter_future_progress_dialog)
![GitHub](https://img.shields.io/github/license/nerdy-pro/flutter-progress-dialog)

Show progress dialog with animation while waiting for Future completion and then return the result of that Future.

## Features

- Show progress dialog while Future is running
- Material and Cupertino style dialogs
- Adaptive dialog that matches platform style
- Custom dialog builder support
- Type-safe result handling
- Error handling with stack traces

![Iphone 15](https://raw.githubusercontent.com/nerdy-pro/flutter-progress-dialog/main/img/flutter_progress_dialog_1_4_0.gif)

## Getting started

- install the library

```shell
flutter pub add flutter_future_progress_dialog
```

- import the library

```dart
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';
```


## Usage

A complete working example can be found in
the [example directory](https://github.com/nerdy-pro/flutter-progress-dialog/tree/develop/example).

The dialog returns a `ProgressDialogResult<T>` type that can be either:

- `Success<T>` containing the successful result value
- `Failure` containing the error and stack trace

You can handle both cases using pattern matching:

Here is a short example of `showProgressDialog` usage.

Call the `showProgressDialog` inside your function. Pass `context` and `future` arguments. Then handle
result.

Alternatively you can use `showCupertinoProgressDialog` to show cupertino-styled dialog and `showAdaptiveProgressDialog` to show dialog matching host OS.

```dart

Future<String> myFuture() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'my string';
}

Future<void> yourFunction(BuildContext context) async {
  final result = await showProgressDialog(
    context: context,
    future: () => myFuture(),
  );
  if (!mounted) {
    return;
  }
  switch (result) {
    case Failure(:final error):
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(
              '$error',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );
    case Success<String>(:final value):
      // value variable would hold the 'my string' value here 
      break;
  } 
}
```

Optionally you can pass a `builder` to have a custom progress dialog

```dart
Future<ProgressDialogResult<LongRunningTaskResult>> buttonCallback({
  required BuildContext context,
}) async {
  return await showProgressDialog(
    future: () => myLongRunningTask(),
    context: context,
    builder: (context) => AlertDialog(
      content: Text('I am loading now'),
    ),
  );
}
```