import 'package:flutter/material.dart';

/// Finish display type
enum CooldownButtonFinishType { icon, text }

/// Loading display type
enum CooldownButtonLoadingType { indicator, text }

/// External controller for CooldownButtonWidget
class CooldownButtonController extends ChangeNotifier {
  _CooldownButtonWidgetState? _state;

  void _attach(_CooldownButtonWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Restart the countdown (reset + start)
  void restart() => _state?._restart();

  /// Reset without starting countdown
  void reset() => _state?._reset();

  /// Start the cooldown countdown
  void start() => _state?._start();
}

class CooldownButtonWidget extends StatefulWidget {
  final VoidCallback onTouch;
  final VoidCallback? onFinish;
  final int cooldownSeconds;
  final CooldownButtonFinishType finishType;
  final CooldownButtonLoadingType loadingType;
  final String textOnCountdown;
  final String textAfterCountdown;
  final IconData iconAfterCountdown;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double indicatorStrokeWidth;
  final CooldownButtonController? controller;
  final Color? color;

  const CooldownButtonWidget({
    super.key,
    required this.onTouch,
    this.onFinish,
    this.cooldownSeconds = 5,
    this.finishType = CooldownButtonFinishType.text,
    this.loadingType = CooldownButtonLoadingType.text,
    this.textOnCountdown = "Wait {s}s",
    this.textAfterCountdown = "Close",
    this.iconAfterCountdown = Icons.close,
    this.textStyle,
    this.padding = const EdgeInsets.all(12),
    this.indicatorStrokeWidth = 2.0,
    this.controller,
    this.color,
  });

  @override
  State<CooldownButtonWidget> createState() => _CooldownButtonWidgetState();
}

class _CooldownButtonWidgetState extends State<CooldownButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        seconds: widget.cooldownSeconds > 0 ? widget.cooldownSeconds : 1,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_finishedNotified) {
        _finishedNotified = true;
        widget.onFinish?.call();
      }
    });

    widget.controller?._attach(this);

    // Start countdown immediately
    _start();
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.cooldownSeconds > 0) {
      _finishedNotified = false;
      _controller.forward(from: 0.0);
    } else {
      _markFinished();
    }
  }

  void _restart() {
    _reset();
    _start();
  }

  void _reset() {
    _finishedNotified = false;
    _controller.reset();
  }

  void _markFinished() {
    _controller.value = 1.0;
    if (!_finishedNotified) {
      _finishedNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFinish?.call();
      });
    }
  }

  int _remainingSeconds() {
    if (widget.cooldownSeconds == 0) return 0;
    final remaining = (widget.cooldownSeconds * (1 - _controller.value)).ceil();
    return remaining < 0 ? 0 : remaining;
  }

  Widget _buildIndicator(Color color) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        value: 1.0 - _controller.value,
        strokeWidth: widget.indicatorStrokeWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black87;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final complete = widget.cooldownSeconds == 0 || _controller.isCompleted;
        final seconds = _remainingSeconds();

        // What to show during countdown
        Widget loadingChild;
        if (widget.loadingType == CooldownButtonLoadingType.text) {
          loadingChild = Text(
            widget.textOnCountdown.replaceAll("{s}", "$seconds"),
            style: widget.textStyle ??
                TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: color.withOpacity(0.5),
                ),
          );
        } else {
          loadingChild = _buildIndicator(color);
        }

        // What to show after countdown
        Widget finishedChild;
        if (widget.finishType == CooldownButtonFinishType.text) {
          finishedChild = Text(
            widget.textAfterCountdown,
            style: widget.textStyle ??
                TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: color,
                ),
          );
        } else {
          finishedChild =
              Icon(widget.iconAfterCountdown, size: 20, color: color);
        }

        return GestureDetector(
          onTap: complete ? widget.onTouch : null,
          child: Padding(
            padding: widget.padding,
            child: complete ? finishedChild : loadingChild,
          ),
        );
      },
    );
  }
}
