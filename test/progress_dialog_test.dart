import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_dialog/progress_dialog.dart';

Future<Result<T>?> showProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() future,
  bool cancelOnTapOutside = true,
  bool useRootNavigator = true,
}) async {
  final result = await showDialog<Result<T>>(
    barrierDismissible: cancelOnTapOutside,
    useRootNavigator: useRootNavigator,
    context: context,
    builder: (context) => ProgressBarDialog<T>(future: future),
  );
  return result;
}

void main() {
  testWidgets('showProgressDialog completes with some value',
      (WidgetTester tester) async {
    final completer = Completer<Result<String>?>();
    dialogTest(BuildContext context) async {
      final result = await showProgressDialog(
        context: context,
        future: () async {
          await Future.delayed(
            const Duration(seconds: 1),
          );
          return 'ok';
        },
      );
      completer.complete(result);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                dialogTest(context).ignore();
              });
              return Container();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final result = await completer.future;
    expect(result?.isError, false);
    expect(result?.requireValue, 'ok');
  });

  testWidgets('showProgressDialog completes with some error',
      (WidgetTester tester) async {
    final completer = Completer<Result<String>?>();
    dialogTest(BuildContext context) async {
      final result = await showProgressDialog(
        context: context,
        future: () async {
          await Future.delayed(
            const Duration(seconds: 1),
          );
          throw 'error';
        },
      );
      completer.complete(result);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                dialogTest(context).ignore();
              });
              return Container();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final result = await completer.future;
    expect(result?.isError, true);
    expect(result?.requireError, 'error');
  });
}
