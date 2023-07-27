## progress_dialog

![Pub Version](https://img.shields.io/pub/v/flutter_progress_dialog)
![GitHub](https://img.shields.io/github/license/nerdy-pro/flutter_progress_dialog)

Show progress dialog with animation while waiting for Future completion and then return the result of that Future.

## Features

![Iphone 14](https://github.com/nerdy-pro/flutter-progress-dialog/blob/develop/img/progress_dialog.gif)

## Getting started

- install the library

```shell
flutter pub add flutter_progress_dialog
```

- import the library

```dart
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
```


## Usage

Working example can be found in /example directory.
Use the showProgressDialog function. 

```dart
Future<Result<T>> showProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() future,
  bool useRootNavigator = true,
}) async {
  final result = await showDialog<Result<T>>(
    barrierDismissible: false,
    useRootNavigator: useRootNavigator,
    context: context,
    builder: (context) => ProgressBarDialog<T>(future: future),
  );
  return result!;
}
```
Here is some example of showProgressDialog usage.
Call the showProgressDialog inside your function. Pass 'context' and 'future' arguments. Then handle
result.
```dart
Future<void> someYourFunction(BuildContext context) async {
  final result = await showProgressDialog(
    context: context,
    future: () => myFuture(),
  );
  if (!mounted) {
    return;
  }
  if (result.isError) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            content: Text(
              '${result.requireError}',
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
              )
            ]);
      },
    );
  } 
}
```
