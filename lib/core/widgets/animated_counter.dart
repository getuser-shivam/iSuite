import 'package:flutter/material.dart';

/// Animated Counter Widget for smooth number transitions
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.prefix,
    this.suffix,
    this.decimals = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _startValue;

  @override
  void initState() {
    super.initState();
    _startValue = widget.value;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _startValue.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _startValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _startValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final formattedValue = widget.decimals > 0
            ? currentValue.toStringAsFixed(widget.decimals)
            : currentValue.toInt().toString();

        return Text(
          '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}',
          style: widget.style ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}

/// Gradient Card Widget with customizable gradients and effects
class GradientCard extends StatefulWidget {
  final Widget child;
  final LinearGradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final Duration animationDuration;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHover;
  final bool enableFeedback;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation = 4.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onTap,
    this.onLongPress,
    this.enableHover = true,
    this.enableFeedback = true,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (!mounted) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHover || !mounted) return;
    setState(() => _isHovered = isHovered);
  }

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      colors: [
        Theme.of(context).colorScheme.surface,
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ],
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: Card(
              margin: widget.margin,
              elevation: _isHovered || _isPressed
                  ? _elevationAnimation.value
                  : widget.elevation,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: widget.enableFeedback ? _handleTapDown : null,
                onTapUp: widget.enableFeedback ? _handleTapUp : null,
                onTapCancel: widget.enableFeedback ? _handleTapCancel : null,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: widget.gradient ?? defaultGradient,
                  ),
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Slide In Animation Widget for smooth entrance effects
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final SlideDirection direction;
  final double offset;
  final Curve curve;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.direction = SlideDirection.fromBottom,
    this.offset = 50.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final startOffset = _getOffset(widget.direction, widget.offset);

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  Offset _getOffset(SlideDirection direction, double offset) {
    switch (direction) {
      case SlideDirection.fromTop:
        return Offset(0, -offset);
      case SlideDirection.fromBottom:
        return Offset(0, offset);
      case SlideDirection.fromLeft:
        return Offset(-offset, 0);
      case SlideDirection.fromRight:
        return Offset(offset, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Slide Direction Enum
enum SlideDirection {
  fromTop,
  fromBottom,
  fromLeft,
  fromRight,
}

/// Scale Animation Widget for zoom effects
class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double beginScale;
  final double endScale;
  final Curve curve;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.beginScale = 0.8,
    this.endScale = 1.0,
    this.curve = Curves.elasticOut,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse Animation Widget for breathing effects
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginScale;
  final double endScale;
  final bool repeat;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.beginScale = 0.95,
    this.endScale = 1.05,
    this.repeat = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Staggered Animation Widget for sequential animations
class StaggeredAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration delayBetweenItems;
  final Duration itemAnimationDuration;
  final SlideDirection direction;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.delayBetweenItems = const Duration(milliseconds: 100),
    this.itemAnimationDuration = const Duration(milliseconds: 600),
    this.direction = SlideDirection.fromBottom,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.children.length,
        (index) => SlideInAnimation(
          delay: Duration(
            milliseconds: index * widget.delayBetweenItems.inMilliseconds,
          ),
          duration: widget.itemAnimationDuration,
          direction: widget.direction,
          child: widget.children[index],
        ),
      ),
    );
  }
}

/// Bounce Animation Widget for playful effects
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double bounceHeight;

  const BounceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.bounceHeight = 20.0,
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -widget.bounceHeight)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -widget.bounceHeight, end: 0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: widget.child,
        );
      },
    );
  }
}

/// Fade In Animation Widget for smooth opacity transitions
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeIn,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Rotation Animation Widget for spinning effects
class RotationAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double rotations;
  final Curve curve;
  final bool repeat;

  const RotationAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1000),
    this.rotations = 1.0,
    this.curve = Curves.linear,
    this.repeat = false,
  });

  @override
  State<RotationAnimation> createState() => _RotationAnimationState();
}

class _RotationAnimationState extends State<RotationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotations * 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.repeat) {
      _controller.repeat();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
