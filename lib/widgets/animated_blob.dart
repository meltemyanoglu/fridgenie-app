import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft, slowly-drifting gradient blob — used as a background flourish on
/// hero sections (onboarding, splash, generate-meals state).
class AnimatedBlob extends StatefulWidget {
  final double size;
  final List<Color> colors;
  final Duration duration;

  const AnimatedBlob({
    super.key,
    this.size = 220,
    required this.colors,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * 2 * math.pi;
        final dx = math.sin(t) * 8;
        final dy = math.cos(t) * 8;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: widget.colors),
            ),
          ),
        );
      },
    );
  }
}
