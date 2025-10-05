import 'dart:math' as math;

import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Full-page aurora backdrop: two slow-drifting radial-gradient blobs
/// (cyan + violet) painted at ~30% alpha over the app background. Places the
/// existing dark palette in a livelier context without introducing new colors.
///
/// Wrap the top-level Scaffold body (or the shell) in this widget once — it
/// is safe to nest; it will simply overlay another set of blobs.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 24),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(_controller.value),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bg,
    );

    final w = size.width;
    final h = size.height;

    // Two counter-drifting blobs on a Lissajous-style path.
    final phase = t * 2 * math.pi;

    final cyanCenter = Offset(
      w * (0.25 + 0.15 * math.sin(phase)),
      h * (0.20 + 0.10 * math.cos(phase * 0.7)),
    );
    final violetCenter = Offset(
      w * (0.80 + 0.10 * math.cos(phase * 0.9)),
      h * (0.75 + 0.12 * math.sin(phase * 1.1)),
    );

    final blobRadius = math.max(w, h) * 0.55;

    canvas.drawCircle(
      cyanCenter,
      blobRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: cyanCenter, radius: blobRadius))
        ..blendMode = BlendMode.plus,
    );

    canvas.drawCircle(
      violetCenter,
      blobRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accentPurple.withValues(alpha: 0.22),
            AppColors.accentPurple.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: violetCenter, radius: blobRadius),
        )
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.t != t;
}
