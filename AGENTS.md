# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

`flutter_future_progress_dialog` — a published pub.dev package (Nerdy Pro) that shows a modal progress dialog while a `Future` runs and returns the result as a sealed `ProgressDialogResult<T>`. Pure Dart/Flutter library, no platform channels or native code.

## Commands

```shell
flutter pub get                                  # run in both root and example/ — analyze covers example/ and errors out without its deps
dart analyze --fatal-infos                       # CI gate — infos fail the build, not just warnings
flutter test                                     # full suite
flutter test test/progress_dialog_test.dart      # single file
flutter test --plain-name 'completes with some error'   # single test by name
flutter pub publish --dry-run                    # CI gate — checks package metadata/pubignore
cd example && flutter run                        # demo app (Material / Cupertino / custom / failure buttons)
```

Do not run `dart format .` — the codebase is formatted at ~120 columns while `dart format` defaults to 80, so it rewrites nearly every file. No format check runs in CI.

## Architecture

Everything lives in `lib/src/`; `lib/flutter_future_progress_dialog.dart` is the barrel and exports **only** `src/result.dart` and `src/show_progress_dialog.dart`. `ProgressBarDialog` and `CupertinoProgressBarDialog` are intentionally not part of the public API — a new file in `lib/src/` is invisible to consumers until added to the barrel.

### Dialog lifecycle (the non-obvious part)

`lib/src/show_progress_dialog.dart` does not call `showDialog`. It constructs the route itself so the route object can be captured in a `late final` and referenced from the builder:

1. `NavigatorState` is resolved **before** any `await` and passed into `_callback` — the dialog's `BuildContext` may be unmounted by the time the task finishes (fixed in 1.5.0, regression-tested).
2. A `DialogRoute` / `CupertinoDialogRoute` is pushed manually with `barrierDismissible: false`; Material also carries `InheritedTheme.capture(...)` so themes survive crossing into the root navigator.
3. The route's child is wrapped in `ExactlyOnce` (`lib/src/exactly_once.dart`), which fires the task from a post-frame callback guarded by a `Completer` — `build` runs many times during the dialog animation, so this guarantees the future starts exactly once.
4. On completion, `_callback` checks `route.isActive` and closes via `navigator.removeRoute(route, result)` — deliberately **not** `Navigator.pop()` (changed in 1.4.2), so a route someone else pushed on top is never popped by mistake.
5. `showProgressDialog` force-unwraps the push future (`result!`); it relies on `removeRoute` always supplying a result, so any change to step 4 must preserve that.

Errors never escape: the private `Task<T>.result()` extension wraps the call in try/catch and converts to `Success` / `Failure`.

`showAdaptiveProgressDialog` branches on `dart:io` `Platform.isMacOS || Platform.isIOS`, which means the adaptive entry point is **not web-safe**; the Material and Cupertino entry points are.

### Result type

`lib/src/result.dart` is a `sealed class ProgressDialogResult<T>` with `Success<T>` / `Failure<T>` subclasses, both with value equality. Exhaustive `switch` on it is the documented usage pattern, so adding a third variant is a breaking API change for every consumer.

### Testing

Widget tests drive the dialog through a `SchedulerBinding.addPostFrameCallback` + `Completer` pattern rather than tapping. `pumpAndSettle` hangs while a task is in flight (the dialog animates indefinitely), so tests that must observe the mid-flight state pump exactly two frames manually — one to build, one to fire `ExactlyOnce`.

## Release

Version lives in `pubspec.yaml` with a matching `CHANGELOG.md` entry. Publishing is the manual `workflow_dispatch` workflow in `.github/workflows/publish.yaml`, which runs tests then publishes via OIDC through the `pub_publish` GitHub environment (approval-gated). `example/` is shipped to pub.dev; `.pubignore` excludes `img/`, build output, and IDE files.
