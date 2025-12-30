import 'package:flutter/material.dart';

enum BackgroundType {
  expo,
  gradient,
  solid,
  image,
}

enum BackgroundExposureDarken {
  left,
  right,
  top,
  bottom,
}

/// Background widget for screens
class Background extends StatelessWidget {
  const Background({
    super.key,
    this.backgroundType = BackgroundType.expo,
    this.backgroundExposureDarken = const [],
    this.color,
    this.gradientColors,
  });

  final BackgroundType backgroundType;
  final List<BackgroundExposureDarken> backgroundExposureDarken;
  final Color? color;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    switch (backgroundType) {
      case BackgroundType.expo:
        return _buildExpoBackground(context);
      case BackgroundType.gradient:
        return _buildGradientBackground();
      case BackgroundType.solid:
        return Container(color: color ?? Theme.of(context).scaffoldBackgroundColor);
      case BackgroundType.image:
        return _buildImageBackground();
    }
  }

  Widget _buildExpoBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildImageBackground() {
    return Container(
      color: Colors.black,
    );
  }
}
