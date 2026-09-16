import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A lightweight, celebratory badge widget with spring scale-up and
/// an animated radiant sparkle particle burst for settlements and confirmations.
class CelebrationBadge extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CelebrationBadge({
    super.key,
    this.icon = Icons.check_circle_rounded,
    this.color = AppColors.success,
    this.size = 76,
  });

  @override
  State<CelebrationBadge> createState() => _CelebrationBadgeState();
}

class _CelebrationBadgeState extends State<CelebrationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _burstAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutQuad),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInQuad),
      ),
    );

    _controller.forward();
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
        return CustomPaint(
          painter: _SparkleBurstPainter(
            progress: _burstAnimation.value,
            opacity: _fadeAnimation.value,
            color: widget.color,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.35),
                  width: 2.5,
                ),
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.62,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkleBurstPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Color color;

  static const int _particleCount = 10;

  _SparkleBurstPainter({
    required this.progress,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.55;
    final maxDistance = size.width * 0.38;

    final currentDistance = baseRadius + (maxDistance * progress);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < _particleCount; i++) {
      final angle = (i * (2 * math.pi / _particleCount)) + (progress * 0.2);
      final x = center.dx + math.cos(angle) * currentDistance;
      final y = center.dy + math.sin(angle) * currentDistance;

      final radius = (3.5 * (1.0 - progress)).clamp(0.5, 4.0);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.color != color;
  }
}
