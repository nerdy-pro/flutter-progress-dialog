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

  // Regression test: when the dialog is on a nested navigator and that navigator
  // is removed from the tree while the task is in-flight, the navigator force-
  // disposes its routes without completing `Route.popped`. A result derived from
  // `Navigator.push` alone would therefore never arrive and the caller would
  // await forever. The dialog's own dispose signal settles it as Cancelled.
  //
  // Note this asserts on a captured value rather than awaiting the call: a
  // regression here hangs rather than throws, so awaiting would stall the suite
  // instead of failing it.
  testWidgets(
    'showProgressDialog returns Cancelled when its navigator is disposed mid-task',
    (WidgetTester tester) async {
      final taskCompleter = Completer<void>();
      final showNestedNav = ValueNotifier(true);
      late BuildContext nestedContext;
      ProgressDialogResult<String>? outcome;

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
      ).then((result) => outcome = result);

      // Let the dialog build and ExactlyOnce fire _callback.
      // Can't use pumpAndSettle here — the pending task keeps the dialog
      // animating indefinitely, so we pump two frames manually: one to
      // build the widget tree and one to fire the post-frame callback.
      await tester.pump();
      await tester.pump();

      // Remove the nested navigator from the tree — this disposes all its
      // routes and unmounts the dialog's subtree while the task is running.
      showNestedNav.value = false;
      await tester.pumpAndSettle();

      expect(
        outcome,
        isA<Cancelled<String>>(),
        reason: 'the caller must be released when the navigator goes away',
      );

      // The task is not interrupted; completing it later changes nothing.
      taskCompleter.complete();
      await tester.pumpAndSettle();
      expect(outcome, isA<Cancelled<String>>());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'showCupertinoProgressDialog returns Cancelled when its navigator is disposed mid-task',
    (WidgetTester tester) async {
      final taskCompleter = Completer<void>();
      final showNestedNav = ValueNotifier(true);
      late BuildContext nestedContext;
      ProgressDialogResult<String>? outcome;

      await tester.pumpWidget(
        CupertinoApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showNestedNav,
            builder: (_, show, __) {
              if (!show) return const SizedBox();
              return Navigator(
                onGenerateRoute: (_) => CupertinoPageRoute(
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

      showCupertinoProgressDialog<String>(
        context: nestedContext,
        future: () async {
          await taskCompleter.future;
          return 'ok';
        },
        useRootNavigator: false,
      ).then((result) => outcome = result);

      await tester.pump();
      await tester.pump();

      showNestedNav.value = false;
      await tester.pumpAndSettle();

      expect(outcome, isA<Cancelled<String>>());

      taskCompleter.complete();
      await tester.pumpAndSettle();
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

  // showAdaptiveProgressDialog must follow the target platform reported by the
  // theme, the way Flutter's own showAdaptiveDialog does — not the host OS the
  // process happens to be running on.
  group('adaptive platform selection', () {
    Future<Completer<void>> pumpAdaptive(WidgetTester tester, TargetPlatform platform) async {
      final task = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showAdaptiveProgressDialog<void>(
                    context: context,
                    future: () => task.future,
                  ).ignore();
                });
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      return task;
    }

    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      testWidgets('uses a Cupertino dialog on $platform', (WidgetTester tester) async {
        final task = await pumpAdaptive(tester, platform);

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        task.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.fuchsia,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      testWidgets('uses a Material dialog on $platform', (WidgetTester tester) async {
        final task = await pumpAdaptive(tester, platform);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(CupertinoActivityIndicator), findsNothing);

        task.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('returns a result like the non-adaptive variants', (WidgetTester tester) async {
      final completer = Completer<ProgressDialogResult<String>>();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Material(
            child: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showAdaptiveProgressDialog<String>(
                    context: context,
                    future: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 100));
                      return 'ok';
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

      expect(await completer.future, const Success<String>('ok'));
      expect(tester.takeException(), isNull);
    });
  });
}
