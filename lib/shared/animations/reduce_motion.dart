import 'package:flutter/material.dart';

/// Utility extensions for respecting reduce-motion accessibility settings.
extension ReduceMotionContext on BuildContext {
  /// Whether the user has requested reduced motion (accessibility setting).
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  /// Returns [duration] if animations are enabled, or [Duration.zero] if not.
  Duration animationDuration(Duration duration) =>
      reduceMotion ? Duration.zero : duration;

  /// Returns the given [curve] or [Curves.linear] if reduce-motion is active.
  Curve animationCurve([Curve curve = Curves.easeOutCubic]) =>
      reduceMotion ? Curves.linear : curve;
}

/// Extension on Duration for reduce-motion handling.
extension ReduceMotionDuration on Duration {
  /// Returns this duration if animations are enabled, zero if reduce-motion.
  Duration respectReduceMotion(BuildContext context) =>
      context.reduceMotion ? Duration.zero : this;
}
