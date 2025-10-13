import 'dart:io';

import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_future_progress_dialog/dialog/cupertino_progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/dialog/exactly_once.dart';
import 'package:flutter_future_progress_dialog/dialog/progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/dialog/result.dart';

typedef Task<T> = Future<T> Function();

Future<void> _callback<T>(
  w.BuildContext context,
  Task<T> task,
  w.Route<ProgressDialogResult<T>> route,
) async {
  final result = await task.result();
  if (!context.mounted) {
    return;
  }
  w.Navigator.of(context).removeRoute(route, result);
}

/// Shows a progress dialog while executing a Future task.
///
/// This function displays a modal progress dialog that remains visible until the provided
/// [future] completes. The dialog can be customized using the [builder] parameter.
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
/// Returns a [ProgressDialogResult] containing either the successful result value
/// or error details if the future fails.
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
  final themes = m.InheritedTheme.capture(
    from: context,
    to: m.Navigator.of(context, rootNavigator: useRootNavigator).context,
  );

  late final m.Route<ProgressDialogResult<T>> route;

  route = m.DialogRoute<ProgressDialogResult<T>>(
    context: context,
    builder: (context) => ExactlyOnce(
      callback: () => _callback(context, future, route),
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

  final result = await m.Navigator.of(context, rootNavigator: useRootNavigator)
      .push<ProgressDialogResult<T>>(route);

  return result!;
}

/// Shows a Cupertino-styled progress dialog while executing a Future task.
///
/// This function displays a modal progress dialog with iOS-style appearance that
/// remains visible until the provided [future] completes.
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
/// Returns a [ProgressDialogResult] containing either the successful result value
/// or error details if the future fails.
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
  late final c.CupertinoDialogRoute<ProgressDialogResult<T>> route;

  route = c.CupertinoDialogRoute<ProgressDialogResult<T>>(
    builder: (context) => ExactlyOnce(
      callback: () => _callback(context, future, route),
      child: builder?.call(context) ?? const CupertinoProgressBarDialog(),
    ),
    context: context,
    barrierDismissible: false,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
  );
  final result = await c.Navigator.of(context, rootNavigator: useRootNavigator)
      .push<ProgressDialogResult<T>>(route);
  return result!;
}

/// Shows a platform-adaptive progress dialog while executing a Future task.
///
/// This function displays a modal progress dialog that matches the host platform's style.
/// On iOS and macOS it shows a Cupertino-styled dialog, while on other platforms it
/// shows the Material-styled dialog.
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
/// Returns a [ProgressDialogResult] containing either the successful result value
/// or error details if the future fails.
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
  if (Platform.isMacOS || Platform.isIOS) {
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
