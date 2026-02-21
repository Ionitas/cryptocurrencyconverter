import 'dart:ui';
import 'package:flutter/material.dart';

/// A container with a blur effect
class BlurContainer extends StatelessWidget {
  const BlurContainer({
    super.key,
    required this.child,
    this.sigmaBlur = 10.0,
    this.circularBoder = 0.0,
    this.color,
  });

  final Widget child;
  final double sigmaBlur;
  final double circularBoder;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(circularBoder),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaBlur, sigmaY: sigmaBlur),
        child: Container(
          color: color ?? Colors.black.withValues(alpha: 0.1),
          child: child,
        ),
      ),
    );
  }
}
