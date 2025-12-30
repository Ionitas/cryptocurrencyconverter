import 'dart:async';
import 'package:flutter/material.dart';

enum CooldownButtonFinishType {
  text,
  icon,
  hidden,
}

enum CooldownButtonLoadingType {
  text,
  circular,
  linear,
}

/// A button that becomes enabled after a cooldown period
class CooldownButtonWidget extends StatefulWidget {
  const CooldownButtonWidget({
    super.key,
    required this.onTouch,
    this.cooldownSeconds = 5,
    this.finishType = CooldownButtonFinishType.text,
    this.loadingType = CooldownButtonLoadingType.text,
    this.closeIcon = Icons.close,
    this.size = 32,
    this.textOnCountdown,
    this.textAfterCountdown,
    this.iconAfterCountdown,
    this.textStyle,
  });

  final VoidCallback onTouch;
  final int cooldownSeconds;
  final CooldownButtonFinishType finishType;
  final CooldownButtonLoadingType loadingType;
  final IconData closeIcon;
  final double size;
  final String? textOnCountdown;
  final String? textAfterCountdown;
  final IconData? iconAfterCountdown;
  final TextStyle? textStyle;

  @override
  State<CooldownButtonWidget> createState() => _CooldownButtonWidgetState();
}

class _CooldownButtonWidgetState extends State<CooldownButtonWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.cooldownSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _isReady = true;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return _buildReadyButton();
    }
    return _buildLoadingButton();
  }

  Widget _buildReadyButton() {
    final icon = widget.iconAfterCountdown ?? widget.closeIcon;

    switch (widget.finishType) {
      case CooldownButtonFinishType.text:
        if (widget.textAfterCountdown != null) {
          return TextButton(
            onPressed: widget.onTouch,
            child: Text(
              widget.textAfterCountdown!,
              style: widget.textStyle,
            ),
          );
        }
        return IconButton(
          onPressed: widget.onTouch,
          icon: Icon(icon, size: widget.size),
        );
      case CooldownButtonFinishType.icon:
        return IconButton(
          onPressed: widget.onTouch,
          icon: Icon(icon, size: widget.size),
        );
      case CooldownButtonFinishType.hidden:
        return IconButton(
          onPressed: widget.onTouch,
          icon: Icon(icon, size: widget.size),
        );
    }
  }

  Widget _buildLoadingButton() {
    switch (widget.loadingType) {
      case CooldownButtonLoadingType.text:
        String displayText = '$_remainingSeconds';
        if (widget.textOnCountdown != null) {
          displayText = widget.textOnCountdown!.replaceAll('{s}', '$_remainingSeconds');
        }
        return Container(
          width: widget.size + 8,
          height: widget.size + 8,
          alignment: Alignment.center,
          child: Text(
            displayText,
            style: widget.textStyle ??
                TextStyle(
                  fontSize: widget.size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
          ),
        );
      case CooldownButtonLoadingType.circular:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            value: 1 - (_remainingSeconds / widget.cooldownSeconds),
            strokeWidth: 2,
          ),
        );
      case CooldownButtonLoadingType.linear:
        return SizedBox(
          width: widget.size * 2,
          child: LinearProgressIndicator(
            value: 1 - (_remainingSeconds / widget.cooldownSeconds),
          ),
        );
    }
  }
}
