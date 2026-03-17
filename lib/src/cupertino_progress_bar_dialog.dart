import 'package:flutter/cupertino.dart';

const double _kDialogEdgePadding = 20.0;
const double _kCupertinoProgressSize = 60.0;

/// A widget that displays a Cupertino-style progress indicator dialog with iOS-like appearance.
///
/// This dialog presents a centered activity indicator with a translucent background,
/// following iOS design guidelines. The dialog animates its position based on view insets
/// and can be customized with animation duration and curve parameters.
///
/// Example usage:
/// ```dart
/// CupertinoProgressBarDialog(
///   insetAnimationDuration: Duration(milliseconds: 100),
///   insetAnimationCurve: Curves.decelerate,
/// )
/// ```
class CupertinoProgressBarDialog extends StatefulWidget {
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;

  /// Creates a Cupertino-style progress indicator dialog.
  ///
  /// The [insetAnimationDuration] parameter controls how long the animation of dialog
  /// position takes when keyboard appears/disappears. Defaults to 100ms.
  ///
  /// The [insetAnimationCurve] parameter defines the animation curve used for
  /// the dialog position animation. Defaults to [Curves.decelerate].
  const CupertinoProgressBarDialog({
    super.key,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
  });

  @override
  State<StatefulWidget> createState() => _CupertinoProgressBarDialog();
}

class _CupertinoProgressBarDialog extends State<CupertinoProgressBarDialog> {
  @override
  Widget build(BuildContext context) {
    return CupertinoUserInterfaceLevel(
      data: CupertinoUserInterfaceLevelData.elevated,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedPadding(
              padding: MediaQuery.viewInsetsOf(context) + const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              duration: widget.insetAnimationDuration,
              curve: widget.insetAnimationCurve,
              child: MediaQuery.removeViewInsets(
                removeLeft: true,
                removeTop: true,
                removeRight: true,
                removeBottom: true,
                context: context,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: _kDialogEdgePadding),
                    width: _kCupertinoProgressSize,
                    height: _kCupertinoProgressSize,
                    child: const CupertinoPopupSurface(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
