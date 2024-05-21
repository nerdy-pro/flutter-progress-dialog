## flutter_future_progress_dialog
![Pub Version](https://img.shields.io/pub/v/flutter_future_progress_dialog)
![GitHub](https://img.shields.io/github/license/nerdy-pro/flutter-progress-dialog)

Show progress dialog with animation while waiting for Future completion and then return the result of that Future.

## Features

![Iphone 15](https://github.com/nerdy-pro/flutter-progress-dialog/blob/develop/img/flutter_progress_dialog.gif)

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

Working example can be found in [/example](https://github.com/nerdy-pro/flutter-progress-dialog/tree/develop/example) directory.

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
    case ResultError(error: final error):
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
    case ResultOk<String>(value: final value):
      // value variable would hold the 'my string' value here 
      break;
  } 
}
```

Optionally you can pass a `builder` to have a custom progress dialog

```dart
Future<Result<LongRunningTaskResult>> buttonCallback({
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