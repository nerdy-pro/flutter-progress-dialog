# flutter_future_progress_dialog

**Show a progress dialog in Flutter while a `Future` runs, then get the result back — Material, Cupertino, and platform-adaptive styles with type-safe results.**

[![Pub Version](https://img.shields.io/pub/v/flutter_future_progress_dialog)](https://pub.dev/packages/flutter_future_progress_dialog)
[![Pub Points](https://img.shields.io/pub/points/flutter_future_progress_dialog)](https://pub.dev/packages/flutter_future_progress_dialog/score)
![GitHub License](https://img.shields.io/github/license/nerdy-pro/flutter-progress-dialog)

![Animated demo of a Flutter progress dialog showing a loading spinner while an async task runs on iPhone](https://raw.githubusercontent.com/nerdy-pro/flutter-progress-dialog/main/img/flutter_progress_dialog.gif)

`flutter_future_progress_dialog` is a Flutter package that displays a modal loading dialog for the lifetime of an asynchronous task and returns a type-safe `ProgressDialogResult<T>` describing the outcome: `Success`, `Failure`, or `Cancelled`. A single `await` replaces the usual show-dialog, try-catch, pop-dialog boilerplate.

Developed and maintained by [Nerdy Pro](https://nerdy.pro).

## Contents

- [Quick start](#quick-start)
- [Why use flutter_future_progress_dialog](#why-use-flutter_future_progress_dialog)
- [Features](#features)
- [Requirements and platform support](#requirements-and-platform-support)
- [Installation](#installation)
- [Usage](#usage)
- [API reference](#api-reference)
- [FAQ](#faq)
- [Known limitations](#known-limitations)
- [License](#license)

## Quick start

Install the package, then wrap any `Future` in `showProgressDialog`:

```dart
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';

Future<String> fetchData() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Hello';
}

Future<void> onButtonPressed(BuildContext context) async {
  final result = await showProgressDialog(
    context: context,
    future: fetchData,
  );

  switch (result) {
    case Success(:final value):
      print('Got: $value');
    case Failure(:final error):
      print('Error: $error');
    case Cancelled():
      print('Dismissed before the task finished');
  }
}
```

The dialog appears immediately, stays on screen until `fetchData` completes, and closes itself. The `await` resolves with the result.

## Why use flutter_future_progress_dialog

Showing a loading dialog around an async call in plain Flutter means opening a route, remembering to close it on every exit path, and guarding the `BuildContext` across the `await`:

```dart
// Without the package
Future<void> onButtonPressed(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final value = await fetchData();
    if (context.mounted) Navigator.of(context).pop();
    print('Got: $value');
  } catch (error) {
    if (context.mounted) Navigator.of(context).pop();
    print('Error: $error');
  }
}
```

```dart
// With flutter_future_progress_dialog
Future<void> onButtonPressed(BuildContext context) async {
  final result = await showProgressDialog(context: context, future: fetchData);
  // result is Success, Failure, or Cancelled — the dialog is already closed
}
```

The dialog is closed for you on every path, errors are captured instead of escaping, and the compiler forces you to handle each outcome because `ProgressDialogResult<T>` is a sealed class.

**Use `flutter_future_progress_dialog` when** you have a discrete async task — a network call, a file write, a sign-in — that should block interaction until it finishes.

**Use something else when** you need determinate progress (a percentage bar), inline loading state inside a page rather than a modal, or a task the user can genuinely abort mid-flight. See [Known limitations](#known-limitations).

## Features

- Show a modal progress dialog while a `Future` is running, and get its result back
- Material, Cupertino, and platform-adaptive dialog styles
- Custom dialog UI through a `builder` parameter
- Type-safe `ProgressDialogResult<T>` with `Success`, `Failure`, and `Cancelled` variants
- Errors captured with stack traces instead of thrown across the dialog boundary
- Dismissal — Android back button, or a custom cancel button — reported as `Cancelled` rather than crashing
- Nullable and `void` task types fully supported: a task returning `null` yields `Success(null)`, never `Cancelled`

## Requirements and platform support

| | |
|---|---|
| **Dart SDK** | `^3.0.0` — Dart 3 is required for sealed classes and pattern matching |
| **Dependencies** | None beyond the Flutter SDK |
| **License** | MIT |

Supported platforms, as reported on [pub.dev](https://pub.dev/packages/flutter_future_progress_dialog):

| Platform | Supported |
|---|---|
| Android | Yes |
| iOS | Yes |
| macOS | Yes |
| Windows | Yes |
| Linux | Yes |
| Web | Yes |

## Installation

```shell
flutter pub add flutter_future_progress_dialog
```

Or add it to `pubspec.yaml` manually:

```yaml
dependencies:
  flutter_future_progress_dialog: ^1.5.0
```

Then import it:

```dart
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';
```

## Usage

### How do I show a loading dialog while a Future runs in Flutter?

Call `showProgressDialog` with a `context` and a `future` callback. `showProgressDialog` displays a Material dialog containing a `CircularProgressIndicator`, keeps it on screen until the task completes, closes it, and resolves with a `ProgressDialogResult<T>`.

```dart
final result = await showProgressDialog(
  context: context,
  future: () => fetchData(),
);
```

Note that `future` takes a *callback* returning a `Future`, not a `Future` itself. The task starts when the dialog is on screen.

### How do I show an iOS-style progress dialog?

Call `showCupertinoProgressDialog` for an iOS-styled dialog built around `CupertinoActivityIndicator`, or `showAdaptiveProgressDialog` to select the style automatically — Cupertino on iOS and macOS, Material everywhere else.

`showAdaptiveProgressDialog` reads `Theme.of(context).platform`, the same signal Flutter's own `showAdaptiveDialog` uses. An app that overrides `ThemeData.platform` gets the style it asked for, and the selection works on Flutter Web.

```dart
// Always iOS style
final result = await showCupertinoProgressDialog(
  context: context,
  future: () => fetchData(),
);

// Cupertino on iOS/macOS, Material elsewhere
final result = await showAdaptiveProgressDialog(
  context: context,
  future: () => fetchData(),
);
```

### How do I use a custom progress dialog widget?

Pass a `builder` to replace the default indicator with any widget. The dialog is still driven by the same task lifecycle.

```dart
final result = await showProgressDialog(
  context: context,
  future: () => fetchData(),
  builder: (context) => const AlertDialog(
    content: Text('Loading, please wait...'),
  ),
);
```

### How do I handle the result?

`ProgressDialogResult<T>` is a sealed class with three variants, so a `switch` over it is checked for exhaustiveness at compile time:

| Variant | Meaning | Carries |
|---|---|---|
| `Success<T>` | The task completed | `value` |
| `Failure<T>` | The task threw | `error`, `stackTrace` |
| `Cancelled<T>` | The dialog was dismissed before the task delivered a result | nothing |

```dart
switch (result) {
  case Success(:final value):
    // Use the value
    break;
  case Failure(:final error, :final stackTrace):
    // Handle the error
    break;
  case Cancelled():
    // The user dismissed the dialog
    break;
}
```

Convenience members are available when a full `switch` is more than you need:

```dart
result.isSuccess;   // true if Success
result.isError;     // true if Failure
result.isCancelled; // true if Cancelled
result.unwrap();    // returns the value, throws the error, or throws
                    // ProgressDialogCancelledException if cancelled
result.map((v) => v.toString());     // transforms a Success value, passes the rest through
result.flatMap((v) => otherResult);  // chains results
```

### Can the user cancel the progress dialog?

The dialog ignores taps on the modal barrier, but it is still a route. The Android back button pops it, and a custom `builder` can render its own cancel button that calls `Navigator.pop`. Either way, the `await` resolves with `Cancelled<T>` instead of crashing.

```dart
final result = await showProgressDialog(
  context: context,
  future: () => slowUpload(),
  builder: (dialogContext) => Dialog(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  ),
);
```

**The task itself is not interrupted.** Dart futures cannot be cancelled, so the work runs to completion in the background and its result — value or error — is discarded. If the work must actually stop, give the task its own cancellation mechanism, such as a `CancelToken` on your HTTP client.

## API reference

### Functions

| Function | Dialog style | Returns |
|---|---|---|
| `showProgressDialog<T>` | Material — `Dialog` with a `CircularProgressIndicator` | `Future<ProgressDialogResult<T>>` |
| `showCupertinoProgressDialog<T>` | Cupertino — `CupertinoPopupSurface` with a `CupertinoActivityIndicator` | `Future<ProgressDialogResult<T>>` |
| `showAdaptiveProgressDialog<T>` | Cupertino on iOS and macOS, Material elsewhere, per `Theme.of(context).platform` | `Future<ProgressDialogResult<T>>` |

### Parameters

| Parameter | Type | Default | Available on |
|---|---|---|---|
| `context` | `BuildContext` | required | all |
| `future` | `Future<T> Function()` | required | all |
| `builder` | `WidgetBuilder?` | `null` | all |
| `useRootNavigator` | `bool` | `true` | all |
| `anchorPoint` | `Offset?` | `null` | all |
| `barrierLabel` | `String?` | `null` | all |
| `barrierColor` | `Color?` | Material: dialog theme, then `Colors.black54`. Cupertino: the Cupertino default | all |
| `requestFocus` | `bool?` | `null` | all |
| `useSafeArea` | `bool` | `true` | Material, adaptive |
| `traversalEdgeBehavior` | `TraversalEdgeBehavior?` | `closedLoop` | Material, adaptive |
| `fullscreenDialog` | `bool` | `false` | Material |
| `animationStyle` | `AnimationStyle?` | `null` | Material |

### Types

| Type | Description |
|---|---|
| `ProgressDialogResult<T>` | Sealed result type; one of `Success<T>`, `Failure<T>`, `Cancelled<T>` |
| `Task<T>` | Typedef for `Future<T> Function()`, the shape of the `future` parameter |
| `ProgressDialogCancelledException` | Thrown by `unwrap()` when the result is `Cancelled` |

A complete working app covering the Material, Cupertino, custom, cancellable, and failure cases is in the [example directory](https://github.com/nerdy-pro/flutter-progress-dialog/tree/main/example).

## FAQ

### Does dismissing the dialog cancel the Future?

No. Dismissing the dialog resolves the `await` with `Cancelled<T>`, but the underlying task keeps running to completion in the background and its result is discarded. Dart futures have no built-in cancellation, so `flutter_future_progress_dialog` cannot interrupt work already in flight.

### Can the user dismiss the progress dialog by tapping outside it?

No. `flutter_future_progress_dialog` sets `barrierDismissible: false`, so taps on the modal barrier are ignored. The Android back button still pops the dialog, which yields `Cancelled<T>`.

### How do I handle errors thrown by the task?

Errors are caught for you. If the task throws, the dialog closes and the call resolves with `Failure<T>`, carrying the `error` and its `stackTrace`. Nothing is rethrown across the `await`, so a `try`/`catch` around `showProgressDialog` is unnecessary.

### Does it work with `Future<void>` or a nullable type?

Yes. A `Future<void>` task yields `Success<void>`, and a task returning `null` yields `Success<T>(null)` — a `null` value is never confused with cancellation, because `Cancelled` is a distinct type rather than an absent value.

### Does flutter_future_progress_dialog support Flutter Web?

Yes. `flutter_future_progress_dialog` supports all six Flutter platforms — Android, iOS, macOS, Windows, Linux, and Web. Platform detection in `showAdaptiveProgressDialog` goes through `Theme.of(context).platform` rather than `dart:io`, so nothing is host-specific.

### What is the difference between the three functions?

`showProgressDialog` always renders a Material dialog, `showCupertinoProgressDialog` always renders an iOS-style dialog, and `showAdaptiveProgressDialog` picks between them based on `Theme.of(context).platform`. All three take the same task callback and return the same `ProgressDialogResult<T>`.

### Do I need to check `context.mounted` after awaiting?

Yes, if you use the `BuildContext` afterwards. `showProgressDialog` closes its own dialog, but your `context` may still have been unmounted while the task was running, so guard any subsequent use of it as you would after any `await`.

## Known limitations

- **The task cannot be aborted.** Cancellation dismisses the dialog, not the work. See [Can the user cancel the progress dialog?](#can-the-user-cancel-the-progress-dialog)
- **No determinate progress.** The dialog shows an indeterminate spinner; there is no percentage or step reporting.
- **If the hosting `Navigator` is disposed while the task is in flight** — for example a nested navigator removed from the widget tree — the dialog is torn down without error, but the returned future never completes, so the `await` waits forever.

## Contributing

Issues and pull requests are welcome at [github.com/nerdy-pro/flutter-progress-dialog](https://github.com/nerdy-pro/flutter-progress-dialog).

## License

MIT License. See [LICENSE](LICENSE) for details.
