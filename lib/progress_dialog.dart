library progress_dialog;

import 'dart:async';

import 'package:flutter/material.dart';

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
  Future<void> _getResult({
    required Future<T> Function() future,
  }) async {
    late Result<T> result;
    try {
      final futureResult = await future();
      result = Result.ok(futureResult);
    } catch (e, s) {
      result = Result.error(e, s);
    } finally {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    }
  }

  @override
  void initState() {
    _getResult(future: widget.future);
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
