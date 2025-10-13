import 'dart:async';

import 'package:flutter/widgets.dart';

class ExactlyOnce extends StatefulWidget {
  final Future<void> Function() callback;
  final Widget child;

  const ExactlyOnce({super.key, required this.callback, required this.child});

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
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_completer.isCompleted) {
        return;
      }
      _completer.complete(context);
    });
    return widget.child;
  }
}
