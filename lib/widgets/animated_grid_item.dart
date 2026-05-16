import 'package:flutter/material.dart';

class AnimatedGridItem extends StatelessWidget {
  final int index;
  final AnimationController animationController;
  final Widget child;
  final double startDelay;
  final double interval;

  const AnimatedGridItem({
    super.key,
    required this.index,
    required this.animationController,
    required this.child,
    this.startDelay = 0.05,
    this.interval = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    final delay = startDelay + (index * interval);
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        delay.clamp(0.0, 1.0),
        (delay + interval).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade ONLY - no slide transition
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}