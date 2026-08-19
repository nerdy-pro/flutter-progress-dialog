import 'dart:async';

import 'package:flutter/cupertino.dart';
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

  // Regression test: the dialog is modal but not un-poppable. The Android
  // system back button pops the DialogRoute, push() resolves with null, and
  // the old `result!` threw "Null check operator used on a null value".
  testWidgets(
    'showProgressDialog returns Cancelled when the back button dismisses the dialog',
    (WidgetTester tester) async {
      final taskCompleter = Completer<String>();
      final completer = Completer<ProgressDialogResult<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<String>(
                    context: context,
                    future: () => taskCompleter.future,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await completer.future, isA<Cancelled<String>>());
      expect(tester.takeException(), isNull);

      // The task is not interrupted — it finishes and its value is discarded.
      taskCompleter.complete('ok');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  // A custom `builder` can render its own cancel affordance, which pops the
  // route out from under the in-flight task.
  testWidgets(
    'showProgressDialog returns Cancelled when a custom builder pops the route',
    (WidgetTester tester) async {
      final taskCompleter = Completer<String>();
      final completer = Completer<ProgressDialogResult<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<String>(
                    context: context,
                    future: () => taskCompleter.future,
                    builder: (dialogContext) => Dialog(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await completer.future, isA<Cancelled<String>>());
      expect(tester.takeException(), isNull);

      taskCompleter.complete('ok');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'showCupertinoProgressDialog returns Cancelled when the back button dismisses the dialog',
    (WidgetTester tester) async {
      final taskCompleter = Completer<String>();
      final completer = Completer<ProgressDialogResult<String>>();

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                showCupertinoProgressDialog<String>(
                  context: context,
                  future: () => taskCompleter.future,
                ).then(completer.complete);
              });
              return Container();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await completer.future, isA<Cancelled<String>>());
      expect(tester.takeException(), isNull);

      taskCompleter.complete('ok');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  // The narrow window where the route is mid-dismiss but not yet gone: the
  // callback must not try to remove a route the navigator is already popping.
  testWidgets(
    'showProgressDialog returns Cancelled when the task completes during the dismiss animation',
    (WidgetTester tester) async {
      final taskCompleter = Completer<String>();
      final completer = Completer<ProgressDialogResult<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<String>(
                    context: context,
                    future: () => taskCompleter.future,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Let the navigator process the pop, then resolve the task while the
      // dismiss animation is still running.
      await tester.binding.handlePopRoute();
      await tester.pump();
      taskCompleter.complete('ok');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(await completer.future, isA<Cancelled<String>>());
      expect(tester.takeException(), isNull);
    },
  );

  // The opposite side of that race: a back press that has been requested but
  // not yet delivered does not invalidate a task that finishes first. The
  // dialog closes with the value it actually produced.
  testWidgets(
    'showProgressDialog returns Success when the task wins the race against a pending pop',
    (WidgetTester tester) async {
      final taskCompleter = Completer<String>();
      final completer = Completer<ProgressDialogResult<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<String>(
                    context: context,
                    future: () => taskCompleter.future,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      tester.binding.handlePopRoute().ignore();
      taskCompleter.complete('ok');
      await tester.pumpAndSettle();

      expect(await completer.future, const Success<String>('ok'));
      expect(tester.takeException(), isNull);
    },
  );

  group('Cancelled', () {
    test('reports itself as neither success nor error', () {
      const result = Cancelled<String>();
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
    });

    test('Success and Failure are not cancelled', () {
      expect(const Success<String>('ok').isCancelled, isFalse);
      expect(const Failure<String>('boom').isCancelled, isFalse);
    });

    test('unwrap throws ProgressDialogCancelledException', () {
      expect(
        () => const Cancelled<String>().unwrap(),
        throwsA(isA<ProgressDialogCancelledException>()),
      );
    });

    test('map and flatMap pass cancellation through', () {
      const result = Cancelled<String>();
      expect(result.map((v) => v.length), isA<Cancelled<int>>());
      expect(
        result.flatMap((v) => Success<int>(v.length)),
        isA<Cancelled<int>>(),
      );
    });

    test('instances of the same type are equal', () {
      expect(const Cancelled<String>(), equals(const Cancelled<String>()));
      expect(
        const Cancelled<String>().hashCode,
        equals(const Cancelled<String>().hashCode),
      );
      expect(const Cancelled<String>(), isNot(equals(const Cancelled<int>())));
    });

    test('ProgressDialogResult.cancelled builds a Cancelled', () {
      expect(ProgressDialogResult.cancelled<String>(), isA<Cancelled<String>>());
    });
  });

  // A task whose value is legitimately null must not be confused with the
  // absence of a result. `push` resolves with the ProgressDialogResult wrapper,
  // which is never null when the task delivers, so Success(null) survives the
  // `result ?? Cancelled<T>()` fallback intact.
  group('nullable task results', () {
    testWidgets('showProgressDialog returns Success for a Future<Null> task', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<Null>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<Null>(
                    context: context,
                    future: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 100));
                      return null;
                    },
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<Success<Null>>());
      expect((result as Success<Null>).value, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.unwrap(), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showProgressDialog reports a null value as Success, not Cancelled', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<String?>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<String?>(
                    context: context,
                    future: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 100));
                      return null;
                    },
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, const Success<String?>(null));
      expect(result.isCancelled, isFalse);
      expect(result.unwrap(), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showCupertinoProgressDialog returns Success for a Future<Null> task', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<Null>>();

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                showCupertinoProgressDialog<Null>(
                  context: context,
                  future: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 100));
                    return null;
                  },
                ).then(completer.complete);
              });
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<Success<Null>>());
      expect((result as Success<Null>).value, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showProgressDialog returns Cancelled when a nullable task is dismissed', (WidgetTester tester) async {
      final taskCompleter = Completer<String?>();
      final completer = Completer<ProgressDialogResult<String?>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<String?>(
                    context: context,
                    future: () => taskCompleter.future,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<Cancelled<String?>>());
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(tester.takeException(), isNull);

      taskCompleter.complete(null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('showProgressDialog surfaces errors from a Future<Null> task', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<Null>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog<Null>(
                    context: context,
                    future: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 100));
                      throw 'boom';
                    },
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<Failure<Null>>());
      expect((result as Failure<Null>).error, 'boom');
      expect(tester.takeException(), isNull);
    });

    // Realistic usage: no explicit type argument, T comes from the task's own
    // Future<String?> signature. runtimeType is checked exactly because
    // Success<Null> would satisfy isA<Success<String?>>() by covariance.
    testWidgets('showProgressDialog infers String? from the task signature', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<String?>>();

      Future<String?> nullableTask() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog(
                    context: context,
                    future: nullableTask,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.runtimeType, Success<String?>);
      expect((result as Success<String?>).value, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.unwrap(), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showProgressDialog carries a non-null value on a String? task', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<String?>>();

      Future<String?> nullableTask() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return 'ok';
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog(
                    context: context,
                    future: nullableTask,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.runtimeType, Success<String?>);
      expect(result, const Success<String?>('ok'));
      expect(result.unwrap(), 'ok');
      expect(tester.takeException(), isNull);
    });

    testWidgets('showProgressDialog infers String? when a nullable task is dismissed', (WidgetTester tester) async {
      final taskCompleter = Completer<String?>();
      final completer = Completer<ProgressDialogResult<String?>>();

      Future<String?> nullableTask() => taskCompleter.future;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showProgressDialog(
                    context: context,
                    future: nullableTask,
                  ).then(completer.complete);
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result.runtimeType, Cancelled<String?>);
      expect(result.isCancelled, isTrue);
      expect(tester.takeException(), isNull);

      taskCompleter.complete(null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('a null Success is distinguishable from Cancelled', () {
      const success = Success<String?>(null);
      const cancelled = Cancelled<String?>();

      expect(success, isNot(equals(cancelled)));
      expect(success.isSuccess, isTrue);
      expect(success.isCancelled, isFalse);
      expect(cancelled.isSuccess, isFalse);
      expect(cancelled.isCancelled, isTrue);
    });

    test('map and flatMap carry a null value through', () {
      const success = Success<String?>(null);

      expect(success.map((v) => v?.length), const Success<int?>(null));
      expect(
        success.flatMap((v) => Success<int?>(v?.length)),
        const Success<int?>(null),
      );
    });
  });
}
