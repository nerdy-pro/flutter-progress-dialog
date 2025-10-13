import 'dart:io';

import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_future_progress_dialog/dialog/cupertino_progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/dialog/exactly_once.dart';
import 'package:flutter_future_progress_dialog/dialog/progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/dialog/result.dart';

typedef Task<T> = Future<T> Function();

Future<void> _callback<T>(w.BuildContext context, Task<T> task) async {
  final result = await task.result();
  if (!context.mounted) {
    return;
  }
  w.Navigator.of(context).pop(result);
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
/// * [traversalEdgeBehavior] - Determines dialog edge behavior when using keyboard traversal
/// * [barrierColor] - Color of the modal barrier, defaults to black54
/// * [useSafeArea] - Whether to respect system UI safe areas, defaults to true
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
/// ```
Future<ProgressDialogResult<T>> showProgressDialog<T>({
  required m.BuildContext context,
  required Task<T> future,
  m.WidgetBuilder? builder,
  bool? useRootNavigator,
  m.Offset? anchorPoint,
  String? barrierLabel,
  m.TraversalEdgeBehavior? traversalEdgeBehavior,
  m.Color? barrierColor = m.Colors.black54,
  bool useSafeArea = true,
}) async {
  final result = await m.showDialog<ProgressDialogResult<T>>(
    barrierDismissible: false,
    useRootNavigator: useRootNavigator ?? true,
    context: context,
    builder: (context) => ExactlyOnce(
      callback: () => _callback(context, future),
      child: builder?.call(context) ?? const ProgressBarDialog(),
    ),
    anchorPoint: anchorPoint,
    barrierLabel: barrierLabel,
    traversalEdgeBehavior: traversalEdgeBehavior,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
  );
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
///
/// Returns a [ProgressDialogResult] containing either the successful result value
/// or error details if the future fails.
Future<ProgressDialogResult<T>> showCupertinoProgressDialog<T>({
  required c.BuildContext context,
  required Task<T> future,
  c.WidgetBuilder? builder,
  bool? useRootNavigator,
  c.Offset? anchorPoint,
  String? barrierLabel,
}) async {
  final result = await c.showCupertinoDialog<ProgressDialogResult<T>>(
    barrierDismissible: false,
    context: context,
    builder: (context) => ExactlyOnce(
      callback: () => _callback(context, future),
      child: builder?.call(context) ?? const CupertinoProgressBarDialog(),
    ),
    useRootNavigator: useRootNavigator ?? true,
    anchorPoint: anchorPoint,
    barrierLabel: barrierLabel,
  );
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
///
/// Returns a [ProgressDialogResult] containing either the successful result value
/// or error details if the future fails.
Future<ProgressDialogResult<T>> showAdaptiveProgressDialog<T>({
  required w.BuildContext context,
  required Task<T> future,
  w.WidgetBuilder? builder,
  bool? useRootNavigator,
  w.Offset? anchorPoint,
  String? barrierLabel,
  m.TraversalEdgeBehavior? traversalEdgeBehavior,
  m.Color? barrierColor = m.Colors.black54,
  bool useSafeArea = true,
}) async {
  if (Platform.isMacOS || Platform.isIOS) {
    return await showCupertinoProgressDialog(
      context: context,
      future: future,
      builder: builder,
      useRootNavigator: useRootNavigator,
      anchorPoint: anchorPoint,
      barrierLabel: barrierLabel,
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
