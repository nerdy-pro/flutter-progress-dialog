import 'dart:async';

import 'package:flutter/widgets.dart';

/// Runs [callback] exactly once, after [child]'s first frame, and reports the
/// teardown of its own subtree through [onDispose].
///
/// [onDispose] is the only reliable signal that a route was torn down without
/// being popped — for example when its [Navigator] is removed from the tree.
/// The framework abandons `Route.popped` in that case, so nothing else fires.
class ExactlyOnce extends StatefulWidget {
  final Future<void> Function() callback;
  final VoidCallback? onDispose;
  final Widget child;

  const ExactlyOnce({
    super.key,
    required this.callback,
    required this.child,
    this.onDispose,
  });

  @override
  State<ExactlyOnce> createState() => _ExactlyOnceState();
}

class _ExactlyOnceState extends State<ExactlyOnce> {
  final _completer = Completer<void>();

  @override
  void initState() {
    _completer.future.then((_) => widget.callback());
    super.initState();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_completer.isCompleted) {
        return;
      }
      _completer.complete();
    });
    return widget.child;
  }
}
