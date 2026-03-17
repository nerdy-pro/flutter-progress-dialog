import 'package:flutter/material.dart';

/// A Material-styled dialog that displays a centered [CircularProgressIndicator].
///
/// Used as the default UI for [showProgressDialog] and [showAdaptiveProgressDialog]
/// on non-Apple platforms.
class ProgressBarDialog extends StatefulWidget {
  const ProgressBarDialog({super.key});

  @override
  State<StatefulWidget> createState() => _ProgressBarDialogState();
}

class _ProgressBarDialogState extends State<ProgressBarDialog> {
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
