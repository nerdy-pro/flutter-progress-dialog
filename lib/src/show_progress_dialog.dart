import 'dart:async';

import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_future_progress_dialog/src/cupertino_progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/src/exactly_once.dart';
import 'package:flutter_future_progress_dialog/src/progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/src/result.dart';

typedef Task<T> = Future<T> Function();

Future<void> _callback<T>(
  w.NavigatorState navigator,
  Task<T> task,
  w.Route<ProgressDialogResult<T>> route,
  _Settle<T> settle,
) async {
  final result = await task.result();
  // Settle before removing the route: tearing the route down fires the dialog's
  // onDispose, and the real result must win that race.
  settle(result);
  if (!route.isActive) {
    return;
  }
  navigator.removeRoute(route, result);
}

typedef _Settle<T> = void Function(ProgressDialogResult<T> result);

/// Drives the returned future from whichever of three things happens first: the
/// task delivering a result, the route being popped, or the route's subtree
/// being torn down.
///
/// The last case is why this exists. When a [w.Navigator] is disposed it force-
/// disposes its routes without completing `Route.popped`, so a future derived
/// from `Navigator.push` alone would never complete and the caller would await
/// forever.
class _Outcome<T> {
  final _completer = Completer<ProgressDialogResult<T>>();

  Future<ProgressDialogResult<T>> get future => _completer.future;

  void settle(ProgressDialogResult<T> result) {
    if (!_completer.isCompleted) {
      _completer.complete(result);
    }
  }

  /// Wires up the route-popped and never-installed paths, and returns the
  /// future the caller should await.
  Future<ProgressDialogResult<T>> track(
    w.NavigatorState navigator,
    w.Route<ProgressDialogResult<T>> route,
  ) {
    navigator
        .push<ProgressDialogResult<T>>(route)
        .then((result) => settle(result ?? Cancelled<T>()))
        .ignore();

    // If the navigator is disposed before the route ever builds, the dialog's
    // onDispose never fires because its state was never created.
    w.WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.navigator == null) {
        settle(Cancelled<T>());
      }
    });

    return future;
  }
}

/// Shows a progress dialog while executing an asynchronous task.
///
/// Displays a modal progress dialog that remains visible until [future] completes.
/// The dialog UI can be customized using the [builder] parameter.
///
/// Parameters:
/// * [context] - The build context used to show the dialog
/// * [future] - The async task to execute while showing the progress dialog
/// * [builder] - Optional custom widget builder for the progress dialog UI
/// * [useRootNavigator] - Whether to show dialog above all screens, defaults to true
/// * [anchorPoint] - Optional anchor point for the dialog position
/// * [barrierLabel] - Semantic label used for the modal barrier
/// * [requestFocus] - Whether the dialog should request focus when opened
/// * [traversalEdgeBehavior] - Determines dialog edge behavior when using keyboard traversal
/// * [barrierColor] - Color of the modal barrier, defaults to black54
/// * [useSafeArea] - Whether to respect system UI safe areas, defaults to true
/// * [fullscreenDialog] - Whether this dialog is a fullscreen dialog
/// * [animationStyle] - Style of the dialog animation
///
/// Returns a [ProgressDialogResult]: [Success] with the value, [Failure] with the
/// error details if the future fails, or [Cancelled] if the dialog is dismissed
/// before the task delivers a result — for example by the Android back button, or
/// by a custom [builder] that calls `Navigator.pop`. The task itself is not
/// interrupted in that case; it runs to completion and its result is discarded.
///
/// Example:
/// ```dart
/// final result = await showProgressDialog(
///   context: context,
///   future: () => myAsyncTask(),
/// );
///
/// switch (result) {
///   case Success(value: final value):
///     print('Task completed successfully: $value');
///     break;
///   case Failure(error: final error):
///     print('Task failed: $error');
///     break;
///   case Cancelled():
///     print('Dialog dismissed before the task finished');
///     break;
/// }
/// ```
Future<ProgressDialogResult<T>> showProgressDialog<T>({
  required m.BuildContext context,
  required Task<T> future,
  m.WidgetBuilder? builder,
  bool useRootNavigator = true,
  m.Offset? anchorPoint,
  String? barrierLabel,
  bool? requestFocus,
  m.TraversalEdgeBehavior? traversalEdgeBehavior,
  m.Color? barrierColor,
  bool useSafeArea = true,
  bool fullscreenDialog = false,
  m.AnimationStyle? animationStyle,
}) async {
  final navigator = m.Navigator.of(context, rootNavigator: useRootNavigator);

  final themes = m.InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );

  late final m.Route<ProgressDialogResult<T>> route;
  final outcome = _Outcome<T>();

  route = m.DialogRoute<ProgressDialogResult<T>>(
    context: context,
    builder: (context) => ExactlyOnce(
      callback: () => _callback(navigator, future, route, outcome.settle),
      onDispose: () => outcome.settle(Cancelled<T>()),
      child: builder?.call(context) ?? const ProgressBarDialog(),
    ),
    barrierColor: barrierColor ??
        m.DialogTheme.of(context).barrierColor ??
        m.Theme.of(context).dialogTheme.barrierColor ??
        m.Colors.black54,
    barrierDismissible: false,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    themes: themes,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior:
        traversalEdgeBehavior ?? m.TraversalEdgeBehavior.closedLoop,
    requestFocus: requestFocus,
    animationStyle: animationStyle,
    fullscreenDialog: fullscreenDialog,
  );

  return outcome.track(navigator, route);
}

/// Shows a Cupertino-styled progress dialog while executing an asynchronous task.
///
/// Displays a modal progress dialog with iOS-style appearance that
/// remains visible until [future] completes.
///
/// Parameters:
/// * [context] - The build context used to show the dialog
/// * [future] - The async task to execute while showing the progress dialog
/// * [builder] - Optional custom widget builder for the progress dialog UI
/// * [useRootNavigator] - Whether to show dialog above all screens, defaults to true
/// * [anchorPoint] - Optional anchor point for the dialog position
/// * [barrierLabel] - Semantic label used for the modal barrier
/// * [barrierColor] - Color of the modal barrier behind the dialog
/// * [requestFocus] - Whether the dialog should request focus when opened
///
/// Returns a [ProgressDialogResult]: [Success] with the value, [Failure] with the
/// error details if the future fails, or [Cancelled] if the dialog is dismissed
/// before the task delivers a result — for example by the Android back button, or
/// by a custom [builder] that calls `Navigator.pop`. The task itself is not
/// interrupted in that case; it runs to completion and its result is discarded.
///
/// Example:
/// ```dart
/// final result = await showCupertinoProgressDialog(
///   context: context,
///   future: () => myAsyncTask(),
/// );
///
/// switch (result) {
///   case Success(value: final value):
///     print('Task completed successfully: $value');
///     break;
///   case Failure(error: final error):
///     print('Task failed: $error');
///     break;
///   case Cancelled():
///     print('Dialog dismissed before the task finished');
///     break;
/// }
/// ```
Future<ProgressDialogResult<T>> showCupertinoProgressDialog<T>({
  required c.BuildContext context,
  required Task<T> future,
  c.WidgetBuilder? builder,
  c.Offset? anchorPoint,
  String? barrierLabel,
  bool useRootNavigator = true,
  c.Color? barrierColor,
  bool? requestFocus,
}) async {
  final navigator = c.Navigator.of(context, rootNavigator: useRootNavigator);

  late final c.CupertinoDialogRoute<ProgressDialogResult<T>> route;
  final outcome = _Outcome<T>();

  route = c.CupertinoDialogRoute<ProgressDialogResult<T>>(
    builder: (context) => ExactlyOnce(
      callback: () => _callback(navigator, future, route, outcome.settle),
      onDispose: () => outcome.settle(Cancelled<T>()),
      child: builder?.call(context) ?? const CupertinoProgressBarDialog(),
    ),
    context: context,
    barrierDismissible: false,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
  );
  return outcome.track(navigator, route);
}

/// Shows a platform-adaptive progress dialog while executing an asynchronous task.
///
/// Displays a Cupertino-styled dialog on iOS and macOS, and a Material-styled
/// dialog on all other platforms.
///
/// The style is chosen from `Theme.of(context).platform`, matching Flutter's own
/// `showAdaptiveDialog`. An app that overrides `ThemeData.platform` therefore
/// gets the dialog style it asked for, and the choice works on Flutter Web.
///
/// Parameters:
/// * [context] - The build context used to show the dialog
/// * [future] - The async task to execute while showing the progress dialog
/// * [builder] - Optional custom widget builder for the progress dialog UI
/// * [useRootNavigator] - Whether to show dialog above all screens, defaults to true
/// * [anchorPoint] - Optional anchor point for the dialog position
/// * [barrierLabel] - Semantic label used for the modal barrier
/// * [traversalEdgeBehavior] - Determines dialog edge behavior when using keyboard traversal
/// * [barrierColor] - Color of the modal barrier, defaults to black54
/// * [useSafeArea] - Whether to respect system UI safe areas, defaults to true
/// * [requestFocus] - Whether the dialog should request focus when opened
///
/// Returns a [ProgressDialogResult]: [Success] with the value, [Failure] with the
/// error details if the future fails, or [Cancelled] if the dialog is dismissed
/// before the task delivers a result — for example by the Android back button, or
/// by a custom [builder] that calls `Navigator.pop`. The task itself is not
/// interrupted in that case; it runs to completion and its result is discarded.
///
/// Example:
/// ```dart
/// final result = await showAdaptiveProgressDialog(
///   context: context,
///   future: () => myAsyncTask(),
/// );
///
/// switch (result) {
///   case Success(value: final value):
///     print('Task completed successfully: $value');
///     break;
///   case Failure(error: final error):
///     print('Task failed: $error');
///     break;
///   case Cancelled():
///     print('Dialog dismissed before the task finished');
///     break;
/// }
/// ```
Future<ProgressDialogResult<T>> showAdaptiveProgressDialog<T>({
  required w.BuildContext context,
  required Task<T> future,
  w.WidgetBuilder? builder,
  bool useRootNavigator = true,
  w.Offset? anchorPoint,
  String? barrierLabel,
  m.TraversalEdgeBehavior? traversalEdgeBehavior,
  w.Color? barrierColor,
  bool useSafeArea = true,
  bool? requestFocus,
}) async {
  final platform = m.Theme.of(context).platform;
  if (platform == m.TargetPlatform.iOS || platform == m.TargetPlatform.macOS) {
    return await showCupertinoProgressDialog(
      context: context,
      future: future,
      builder: builder,
      useRootNavigator: useRootNavigator,
      anchorPoint: anchorPoint,
      barrierLabel: barrierLabel,
      requestFocus: requestFocus,
    );
  }
  return await showProgressDialog(
    context: context,
    future: future,
    builder: builder,
    useRootNavigator: useRootNavigator,
    anchorPoint: anchorPoint,
    barrierLabel: barrierLabel,
    traversalEdgeBehavior: traversalEdgeBehavior,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
    requestFocus: requestFocus,
  );
}

extension<T> on Task<T> {
  Future<ProgressDialogResult<T>> result() async {
    try {
      final value = await this.call();
      return ProgressDialogResult.success(value);
    } catch (e, s) {
      return ProgressDialogResult.failure(e, s);
    }
  }
}
