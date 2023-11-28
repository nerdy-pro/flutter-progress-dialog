import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(result.runtimeType, ResultOk<String>);
    result as ResultOk<String>;
    expect(result.value, 'ok');
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
          final error = await Future<String>.error('error');
          return error;
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
    expect(result.runtimeType, ResultError<String>);
    result as ResultError<String>;
    expect(result.error, 'error');
  });
}
