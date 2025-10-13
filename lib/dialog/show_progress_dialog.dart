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

/// Function takes the `context`, the `useRootNavigator` and the `future` arguments.
/// Optionally you can provide a custom [builder] which will be used instead of the default [Dialog].
/// The result would hold the value of the future or the error if the future evaluation failed.
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
