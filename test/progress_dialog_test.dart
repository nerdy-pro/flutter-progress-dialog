import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_dialog/progress_dialog.dart';

void main() {
  testWidgets('showProgressDialog', (WidgetTester tester) async {
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
}