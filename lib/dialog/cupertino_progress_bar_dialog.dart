import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_future_progress_dialog/dialog/result.dart';

const double _kDialogEdgePadding = 20.0;
const double _kCupertinoProgressSize = 60.0;

/// Widget displays the [Dialog] white the provided [future] is being evaluated.
/// Optionally you can provide a custom [builder] which will be used instead of the default [Dialog].
class CupertinoProgressBarDialog<T> extends StatefulWidget {
  final Future<T> Function() future;
  final WidgetBuilder? builder;
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;

  const CupertinoProgressBarDialog({
    super.key,
    required this.future,
    this.builder,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
  });

  @override
  State<StatefulWidget> createState() => _CupertinoProgressBarDialog<T>();
}

class _CupertinoProgressBarDialog<T> extends State<CupertinoProgressBarDialog<T>> {
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
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return CupertinoUserInterfaceLevel(
      data: CupertinoUserInterfaceLevelData.elevated,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          // iOS does not shrink dialog content below a 1.0 scale factor
          textScaleFactor: max(textScaleFactor, 1.0),
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
                    child: CupertinoPopupSurface(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: builder != null ? builder(context) : const CupertinoActivityIndicator(),
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
