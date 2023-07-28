import 'package:flutter/material.dart';
import 'package:flutter_progress_dialog/progress_bar_dialog.dart';
import 'package:flutter_progress_dialog/result.dart';

/// Function takes the `context`, the `useRootNavigator` and the `future` arguments.
/// Optionally you can provide a custom [builder] which will be used instead of the default [Dialog].
/// The result would hold the value of the future or the error if the future evaluation failed.
Future<Result<T>> showProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() future,
  WidgetBuilder? builder,
  bool? useRootNavigator,
}) async {
  final result = await showDialog<Result<T>>(
    barrierDismissible: false,
    useRootNavigator: useRootNavigator ?? true,
    context: context,
    builder: (context) => ProgressBarDialog<T>(
      future: future,
      builder: builder,
    ),
  );
  return result!;
}
