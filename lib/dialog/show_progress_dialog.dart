import 'dart:io';

import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_future_progress_dialog/dialog/cupertino_progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/dialog/progress_bar_dialog.dart';
import 'package:flutter_future_progress_dialog/dialog/result.dart';

typedef ProgressDialogResult<T> = Future<Result<T>>;
typedef ProgressDialogFuture<T> = Future<T> Function();

/// Function takes the `context`, the `useRootNavigator` and the `future` arguments.
/// Optionally you can provide a custom [builder] which will be used instead of the default [Dialog].
/// The result would hold the value of the future or the error if the future evaluation failed.
ProgressDialogResult<T> showProgressDialog<T>({
  required m.BuildContext context,
  required ProgressDialogFuture<T> future,
  m.WidgetBuilder? builder,
  bool? useRootNavigator,
  m.Offset? anchorPoint,
  String? barrierLabel,
  m.TraversalEdgeBehavior? traversalEdgeBehavior,
  m.Color? barrierColor = m.Colors.black54,
  bool useSafeArea = true,
}) async {
  final result = await m.showDialog<Result<T>>(
    barrierDismissible: false,
    useRootNavigator: useRootNavigator ?? true,
    context: context,
    builder: (context) => ProgressBarDialog<T>(future: future, builder: builder),
    anchorPoint: anchorPoint,
    barrierLabel: barrierLabel,
    traversalEdgeBehavior: traversalEdgeBehavior,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
  );
  return result!;
}

ProgressDialogResult<T> showCupertinoProgressDialog<T>({
  required c.BuildContext context,
  required ProgressDialogFuture<T> future,
  c.WidgetBuilder? builder,
  bool? useRootNavigator,
  c.Offset? anchorPoint,
  String? barrierLabel,
}) async {
  final result = await c.showCupertinoDialog<Result<T>>(
    barrierDismissible: false,
    context: context,
    builder: (context) => CupertinoProgressBarDialog<T>(future: future, builder: builder),
    useRootNavigator: useRootNavigator ?? true,
    anchorPoint: anchorPoint,
    barrierLabel: barrierLabel,
  );
  return result!;
}

ProgressDialogResult<T> showAdaptiveProgressDialog<T>({
  required w.BuildContext context,
  required ProgressDialogFuture<T> future,
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
