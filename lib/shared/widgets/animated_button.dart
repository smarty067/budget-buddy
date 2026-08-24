import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

/// A button with a subtle scale-down press animation (0.96x).
/// Respects Android's reduce-motion accessibility setting.
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleOnPress;
  final Duration animationDuration;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleOnPress = AppAnimation.buttonPressScale,
    this.animationDuration = AppAnimation.fast,
    this.decoration,
    this.padding,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations;

  void _onTapDown(TapDownDetails _) {
    if (!_reduceMotion) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (!_reduceMotion) {
      _controller.reverse();
    }
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (!_reduceMotion) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: _reduceMotion ? 1.0 : _scaleAnimation.value,
          child: Container(
            padding: widget.padding,
            decoration: widget.decoration,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A convenience widget that wraps ElevatedButton with scale-down animation.
class AnimatedElevatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const AnimatedElevatedButton({
    super.key,
    this.onPressed,
    required this.child,
    this.style,
  });

  @override
  State<AnimatedElevatedButton> createState() =>
      _AnimatedElevatedButtonState();
}

class _AnimatedElevatedButtonState extends State<AnimatedElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.fast,
    );
    _scale = Tween(begin: 1.0, end: AppAnimation.buttonPressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!_reduceMotion) _controller.forward();
      },
      onTapUp: (_) {
        if (!_reduceMotion) _controller.reverse();
      },
      onTapCancel: () {
        if (!_reduceMotion) _controller.reverse();
      },
      child: ScaleTransition(
        scale: _reduceMotion
            ? const AlwaysStoppedAnimation(1.0)
            : _scale,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: widget.style,
          child: widget.child,
        ),
      ),
    );
  }
}
