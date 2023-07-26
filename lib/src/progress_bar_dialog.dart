import 'package:flutter/material.dart';
import 'package:progress_dialog/src/result.dart';

///Widget displays the [Dialog] with the [CircularProgressIndicator] while the [Future] '_getResult' is performs.

class ProgressBarDialog<T> extends StatefulWidget {
  final Future<T> Function() future;

  const ProgressBarDialog({
    super.key,
    required this.future,
  });

  @override
  State<StatefulWidget> createState() => _ProgressBarDialogState<T>();
}

class _ProgressBarDialogState<T> extends State<ProgressBarDialog<T>> {
  Future<void> _getResult() async {
    late Result<T> result;
    try {
      final futureResult = await widget.future();
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
    _getResult().ignore();
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
