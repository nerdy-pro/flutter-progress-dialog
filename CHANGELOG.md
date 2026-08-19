## 2.0.0

### Breaking changes

* `ProgressDialogResult` gained a third variant, `Cancelled<T>`. The type is
  sealed, so exhaustive `switch` statements over a result need a `Cancelled`
  case added. See "Migrating from 1.x" in the README
* `showAdaptiveProgressDialog` now selects its style from
  `Theme.of(context).platform` instead of the host operating system, matching
  Flutter's own `showAdaptiveDialog`. An app that sets `ThemeData(platform: ...)`
  now gets the style it asked for rather than the style of the machine it runs on

### Added

* Flutter Web support — `flutter_future_progress_dialog` no longer imports
  `dart:io`, so pub.dev now reports all six platforms
* `Cancelled<T>` result variant, the `isCancelled` getter, and
  `ProgressDialogResult.cancelled()`
* `ProgressDialogCancelledException`, thrown by `unwrap()` on a cancelled result

### Fixed

* "Null check operator used on a null value" crash when the dialog was dismissed
  before the task completed — by the Android back button, or by a custom
  `builder` calling `Navigator.pop`
* The returned future never completing when the hosting `Navigator` was disposed
  while the task was in flight, which left the caller awaiting forever. The call
  now settles with `Cancelled`
* `map()` and `flatMap()` now pass cancellation through instead of failing to
  compile against the widened result type

### Notes

* Cancellation dismisses the dialog, not the task. Dart futures cannot be
  cancelled, so the work runs to completion in the background and its result is
  discarded

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
