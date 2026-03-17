import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showProgressDialog completes with some value', (WidgetTester tester) async {
    final completer = Completer<ProgressDialogResult<String>?>();
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
    expect(result.runtimeType, Success<String>);
    expect((result as Success<String>).value, 'ok');
  });

  // Regression test: when the dialog is on a nested navigator and that
  // navigator is removed from the tree while the task is in-flight,
  // the dialog's context becomes unmounted. The original _callback would
  // check context.mounted, return early, and never call removeRoute —
  // causing push() to resolve with null and result! to throw.
  testWidgets(
    'showProgressDialog does not crash when context unmounts before task completes',
    (WidgetTester tester) async {
      final taskCompleter = Completer<void>();
      final showNestedNav = ValueNotifier(true);
      late BuildContext nestedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showNestedNav,
            builder: (_, show, __) {
              if (!show) return const SizedBox();
              return Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (ctx) {
                    nestedContext = ctx;
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Launch the dialog on the nested navigator.
      showProgressDialog<String>(
        context: nestedContext,
        future: () async {
          await taskCompleter.future;
          return 'ok';
        },
        useRootNavigator: false,
      ).ignore();

      // Let the dialog build and ExactlyOnce fire _callback.
      // Can't use pumpAndSettle here — the pending task keeps the dialog
      // animating indefinitely, so we pump two frames manually: one to
      // build the widget tree and one to fire the post-frame callback.
      await tester.pump();
      await tester.pump();

      // Remove the nested navigator from the tree — this disposes all its
      // routes and unmounts the dialog's context while the task is running.
      showNestedNav.value = false;
      await tester.pumpAndSettle();

      // Complete the task after context has been unmounted.
      taskCompleter.complete();
      await tester.pumpAndSettle();

      // With the old code, _callback returns early (context.mounted == false),
      // removeRoute is never called, and push() resolves with null causing
      // result! to throw.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('showProgressDialog completes with some error', (WidgetTester tester) async {
    final completer = Completer<ProgressDialogResult<String>?>();
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
    expect(result.runtimeType, Failure<String>);
    expect((result as Failure<String>).error, 'error');
  });
}
