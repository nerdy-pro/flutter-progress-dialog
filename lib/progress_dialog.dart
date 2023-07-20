library progress_dialog;

import 'dart:async';

import 'package:flutter/material.dart';

Future<Result<T>?> showProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() future,
}) async {
  final result = await showDialog<Result<T>>(
    context: context,
    builder: (context) => ProgressBarDialog<T>(future: future),
  );
  return result;
}

class ProgressBarDialog<T> extends StatefulWidget {
  final Future<T> Function() future;

  const ProgressBarDialog({
    super.key,
    required this.future,
  });

  @override
  State<StatefulWidget> createState() => _ProgressBarDialogState<T>();
}

class Result<T> {
  final T? value;
  final Object? error;
  final StackTrace? stackTrace;

  Result.ok(T v)
      : value = v,
        error = null,
        stackTrace = null;

  Result.error(Object e, StackTrace s)
      : error = e,
        value = null,
        stackTrace = s;

  bool get isError => error != null;

  Object get requireError => error!;

  T get requireValue => value!;
}

class _ProgressBarDialogState<T> extends State<ProgressBarDialog<T>> {
  @override
  void initState() {
    Future<void>(() async {
      Result? result;
      try {
        final futureResult = await widget.future();
        result = Result.ok(futureResult);
      } catch (e, s) {
        result = Result.error(e, s);
      } finally {
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    }); //then((value) => Navigator.of(context).pop(value));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          height: 40,
          width: 40,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}