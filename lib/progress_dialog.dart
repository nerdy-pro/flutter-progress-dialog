library progress_dialog;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:progress_dialog/src/progress_bar_dialog.dart';
import 'package:progress_dialog/src/result.dart';

/// Function takes the 'context', the 'useRootNavigator' and the Future<t>Function() arguments.
/// First two it passes to the [showDialog] function which is used internally. Also [showDialog]'s argument 'barrierDismissible'
/// set to false to avoid canceling of the [Future] performance.
/// For more information about above-mentioned arguments see the [showDialog].
/// The builder of the [showDialog] returns the [ProgressBarDialog] widget which requires the named
/// parameter 'future' of the Future<T>Function() type to be passed to its constructor.
/// The result of the [showDialog] is assigned to the variable 'result' which is then returned by the function.

Future<Result<T>> showProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() future,
  bool useRootNavigator = true,
}) async {
  final result = await showDialog<Result<T>>(
    barrierDismissible: false,
    useRootNavigator: useRootNavigator,
    context: context,
    builder: (context) => ProgressBarDialog<T>(future: future),
  );
  return result!;
}
