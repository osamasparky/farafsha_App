import 'package:flutter/material.dart';
import '../theme/lamma_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = LammaRadius.card,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? null : LammaColors.card.withValues(alpha: 0.8),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4C228A), Color(0xFF2E145B)],
                )
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isSelected ? LammaColors.violet400 : LammaColors.cardBorder,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LammaColors.violet500.withValues(alpha: 0.4),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}
