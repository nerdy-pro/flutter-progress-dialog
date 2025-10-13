import 'package:flutter/material.dart';

/// A widget that displays a circular progress indicator inside a [Dialog].
///
/// This widget is used internally by [showProgressDialog], [showCupertinoProgressDialog],
/// and [showAdaptiveProgressDialog] to show a loading state while a future task is being executed.
///
/// The dialog contains a centered [CircularProgressIndicator] with fixed dimensions
/// and padding. The generic type [T] corresponds to the type of data being processed.
class ProgressBarDialog extends StatefulWidget {
  /// Creates a progress bar dialog.
  ///
  /// The [key] parameter is optional and is used to control how one widget replaces
  /// another widget in the tree.
  const ProgressBarDialog({super.key});

  @override
  State<StatefulWidget> createState() => _ProgressBarDialogState();
}

/// State class for [ProgressBarDialog] that manages the dialog's visual representation.
///
/// This class builds a simple dialog containing a centered circular progress indicator
/// with fixed dimensions and padding.
class _ProgressBarDialogState extends State<ProgressBarDialog> {
  /// Builds the dialog widget with a centered circular progress indicator.
  ///
  /// @param context The build context for this widget.
  /// @return A [Dialog] widget containing a padded circular progress indicator.
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
