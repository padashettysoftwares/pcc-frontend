import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Clean bordered card — replaces old GlowCard
class GlowCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? borderGradient;
  final List<BoxShadow>? glowShadow;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlowCard({
    super.key,
    required this.child,
    this.borderGradient,
    this.glowShadow,
    this.padding,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppShadows.subtleShadow,
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }
}
