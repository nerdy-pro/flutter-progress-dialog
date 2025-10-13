import 'package:flutter/cupertino.dart';

const double _kDialogEdgePadding = 20.0;
const double _kCupertinoProgressSize = 60.0;

/// Widget displays the [Dialog] white the provided [future] is being evaluated.
/// Optionally you can provide a custom [builder] which will be used instead of the default [Dialog].
class CupertinoProgressBarDialog extends StatefulWidget {
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;

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
