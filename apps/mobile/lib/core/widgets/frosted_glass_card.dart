import 'dart:ui';

import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A frosted glass card. `BackdropFilter` blurs whatever's behind it, on top of
/// which we paint a translucent gradient and a hairline border.
///
/// Pair with [AnimatedGradientBackground] for the aurora-through-glass look.
/// Falls back gracefully on light mode (which we don't ship, but leaving the
/// hook open costs nothing).
class FrostedGlassCard extends StatelessWidget {
  const FrostedGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 20,
    this.blur = 22,
    this.hoverLift = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final double blur;
  final bool hoverLift;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.70),
                AppColors.surfaceElevated.withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          hoverColor: AppColors.accent.withValues(alpha: 0.05),
          splashColor: AppColors.accent.withValues(alpha: 0.10),
          child: content,
        ),
      );
    }

    if (!hoverLift) return content;
    return _HoverLift(child: content);
  }
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child});
  final Widget child;
  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: _hover
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
