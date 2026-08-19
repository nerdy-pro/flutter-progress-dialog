## Unreleased

**Breaking:** `ProgressDialogResult` is sealed and now has a third variant, so
exhaustive `switch` statements over it need a `Cancelled` case added.

* Fixed "Null check operator used on a null value" crash when the dialog was
  dismissed before the task completed — by the Android back button, or by a
  custom `builder` calling `Navigator.pop`
* Added `Cancelled<T>` result variant, `isCancelled`, and
  `ProgressDialogResult.cancelled()`
* `unwrap()` throws `ProgressDialogCancelledException` for a cancelled result;
  `map()` and `flatMap()` pass cancellation through
* Note: the task is not interrupted on cancellation — Dart futures cannot be
  cancelled, so it runs to completion and its result is discarded
* Fixed the returned future never completing when the hosting `Navigator` is
  disposed while the task is in flight — for example a nested navigator removed
  from the widget tree. The call now settles with `Cancelled` instead of leaving
  the caller awaiting forever
* Added Flutter Web support — `flutter_future_progress_dialog` no longer imports
  `dart:io`, so pub.dev now reports all six platforms
* **Behaviour change:** `showAdaptiveProgressDialog` now selects its style from
  `Theme.of(context).platform` instead of the host operating system, matching
  Flutter's own `showAdaptiveDialog`. An app that sets `ThemeData(platform: ...)`
  now gets the style it asked for rather than the style of the machine it runs on

## 1.5.0

* Fixed crash when dialog context unmounts before task completes
* Captured NavigatorState before async await to prevent null check errors
* Moved library sources to `lib/src/` following standard Dart package layout
* Replaced BSD-3 license with MIT
* Updated example with Material, Cupertino, custom, and failure variants
* Improved documentation and README
* Removed FVM configuration (not needed for a library)

## 1.4.2

* Avoid using `Navigator.pop()` when closing progress dialog

## 1.4.1

* Included examples in pub.dev
* Improved code documentation

## 1.4.0

* Changed signatures of classes to avoid interfering with other packages

## 1.3.2

* Fixed deprecation warnings
* Fixed image in readme file

## 1.3.1

* Updated docs

## 1.3.0

* Cupertino progress dialog
* Adaptive progress dialog
* Updated flutter version

## 1.2.0

* Updated flutter version

## 1.1.1

* Fixed nullable values in result.

## 1.1.0

* Migrated to `sealed class` usage for result handling.

## 1.0.0

* Initial library release.
