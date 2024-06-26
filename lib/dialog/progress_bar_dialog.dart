import 'package:flutter/material.dart';
import 'package:flutter_future_progress_dialog/dialog/result.dart';

/// Widget displays the [Dialog] white the provided [future] is being evaluated.
/// Optionally you can provide a custom [builder] which will be used instead of the default [Dialog].
class ProgressBarDialog<T> extends StatefulWidget {
  final Future<T> Function() future;
  final WidgetBuilder? builder;

  const ProgressBarDialog({super.key, required this.future, this.builder});

  @override
  State<StatefulWidget> createState() => _ProgressBarDialogState<T>();
}

class _ProgressBarDialogState<T> extends State<ProgressBarDialog<T>> {
  Future<void> _evaluateFuture() async {
    final result = await Result.runCatchingFuture(() async {
      return await widget.future();
    });
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  void initState() {
    _evaluateFuture().ignore();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;
    if (builder != null) {
      return builder(context);
    } else {
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
}
