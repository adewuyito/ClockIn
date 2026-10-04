import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Pixel-perfect vector rendering of the official Solana Mobile / Seeker emblem.
///
/// Features the 3 iconic stacked speed bars.
/// When [isActive] is true (running on a Solana Seeker device or simulated),
/// the logo illuminates with the signature Solana purple-to-mint gradient
/// (#9945FF -> #14F195) and an emerald halo glow.
class SeekerLogo extends StatelessWidget {
  final double size;
  final bool isActive;
  final bool withGlow;

  const SeekerLogo({
    super.key,
    this.size = 18.0,
    this.isActive = false,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = size;
    final height = size * (19.0 / 24.0);

    Widget mark = CustomPaint(
      size: Size(width, height),
      painter: _SolanaSeekerMarkPainter(isActive: isActive),
    );

    if (isActive && withGlow) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF14F195).withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14F195).withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: mark,
      );
    }

    return mark;
  }
}

class _SolanaSeekerMarkPainter extends CustomPainter {
  final bool isActive;

  _SolanaSeekerMarkPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 19.0;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (isActive) {
      paint.shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF9945FF), // Solana Electric Purple
          Color(0xFF00D18C), // Solana Mint Green
          Color(0xFF14F195), // Solana Bright Emerald
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = AppColors.onSurfaceVariant.withValues(alpha: 0.45);
    }

    // Top Bar (slanting up-right)
    final p1 = Path()
      ..moveTo(3.9 * sx, 0.23 * sy)
      ..cubicTo(4.05 * sx, 0.08 * sy, 4.25 * sx, 0.0 * sy, 4.454 * sx, 0.0 * sy)
      ..lineTo(23.607 * sx, 0.0 * sy)
      ..cubicTo(23.957 * sx, 0.0 * sy, 24.132 * sx, 0.422 * sy, 23.884 * sx, 0.67 * sy)
      ..lineTo(20.101 * sx, 4.453 * sy)
      ..cubicTo(19.956 * sx, 4.598 * sy, 19.757 * sx, 4.683 * sy, 19.546 * sx, 4.683 * sy)
      ..lineTo(0.393 * sx, 4.683 * sy)
      ..cubicTo(0.043 * sx, 4.683 * sy, -0.132 * sx, 4.261 * sy, 0.116 * sx, 4.013 * sy)
      ..close();
    canvas.drawPath(p1, paint);

    // Middle Bar (inverted slant)
    final p2 = Path()
      ..moveTo(20.1 * sx, 7.017 * sy)
      ..cubicTo(19.946 * sx, 6.872 * sy, 19.747 * sx, 6.787 * sy, 19.546 * sx, 6.787 * sy)
      ..lineTo(0.393 * sx, 6.787 * sy)
      ..cubicTo(0.043 * sx, 6.787 * sy, -0.132 * sx, 7.209 * sy, 0.116 * sx, 7.457 * sy)
      ..lineTo(3.899 * sx, 11.241 * sy)
      ..cubicTo(4.044 * sx, 11.386 * sy, 4.243 * sx, 11.471 * sy, 4.454 * sx, 11.471 * sy)
      ..lineTo(23.607 * sx, 11.471 * sy)
      ..cubicTo(23.957 * sx, 11.471 * sy, 24.132 * sx, 11.048 * sy, 23.884 * sx, 10.801 * sy)
      ..close();
    canvas.drawPath(p2, paint);

    // Bottom Bar (same slant as top)
    final p3 = Path()
      ..moveTo(3.9 * sx, 14.125 * sy)
      ..cubicTo(4.05 * sx, 13.975 * sy, 4.25 * sx, 13.895 * sy, 4.454 * sx, 13.895 * sy)
      ..lineTo(23.607 * sx, 13.895 * sy)
      ..cubicTo(23.957 * sx, 13.895 * sy, 24.132 * sx, 14.318 * sy, 23.884 * sx, 14.565 * sy)
      ..lineTo(20.101 * sx, 18.349 * sy)
      ..cubicTo(19.956 * sx, 18.494 * sy, 19.757 * sx, 18.579 * sy, 19.546 * sx, 18.579 * sy)
      ..lineTo(0.393 * sx, 18.579 * sy)
      ..cubicTo(0.043 * sx, 18.579 * sy, -0.132 * sx, 18.156 * sy, 0.116 * sx, 17.909 * sy)
      ..close();
    canvas.drawPath(p3, paint);
  }

  @override
  bool shouldRepaint(covariant _SolanaSeekerMarkPainter oldDelegate) {
    return oldDelegate.isActive != isActive;
  }
}

/// A compact illuminated chip indicating Seeker hardware detection status.
class SeekerHardwareChip extends StatelessWidget {
  final bool isSeeker;
  final VoidCallback? onTap;

  const SeekerHardwareChip({
    super.key,
    required this.isSeeker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSeeker
              ? const Color(0xFF14F195).withValues(alpha: 0.16)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSeeker
                ? const Color(0xFF00D18C).withValues(alpha: 0.5)
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SeekerLogo(size: 11, isActive: isSeeker),
            const SizedBox(width: 4.5),
            Text(
              isSeeker ? 'SEEKER' : 'MOBILE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isSeeker ? const Color(0xFF0B5E36) : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
