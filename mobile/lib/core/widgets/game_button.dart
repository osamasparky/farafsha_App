import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/lamma_theme.dart';

enum GameButtonVariant { primary, secondary }

/// زر اللعبة الثلاثي الأبعاد المعتمد في نظام التصميم (Primary & Secondary CTA)
class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final double height;
  final bool showArrow;
  final Widget? icon;
  final bool isFullWidth;
  final bool isLoading;

  const GameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = GameButtonVariant.primary,
    this.height = 62.0,
    this.showArrow = true,
    this.icon,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = widget.variant == GameButtonVariant.primary;
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    // ألوان التدرج والحدود السفلية المجسمة
    final Gradient bgGradient = isPrimary
        ? LammaGradients.ctaPrimary
        : LammaGradients.ctaSecondary;

    final Color bottomBorderColor = isPrimary
        ? LammaColors.pink700
        : LammaColors.violet900;

    final Color textColor = isPrimary
        ? LammaColors.onCta
        : Colors.white;

    final List<BoxShadow> shadows = _isPressed || !isEnabled
        ? []
        : [
            BoxShadow(
              color: isPrimary
                  ? LammaColors.pink500.withValues(alpha: 0.45)
                  : LammaColors.violet700.withValues(alpha: 0.45),
              offset: const Offset(0, 10),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ];

    final double bottomBorderWidth = _isPressed ? 2.0 : 5.0;
    final double translateY = _isPressed ? 3.0 : 0.0;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(0, translateY, 0),
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: isEnabled ? bgGradient : null,
          color: isEnabled ? null : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(999),
          border: Border(
            top: const BorderSide(color: Colors.white54, width: 1.2),
            left: const BorderSide(color: Colors.white24, width: 0.5),
            right: const BorderSide(color: Colors.white24, width: 0.5),
            bottom: BorderSide(
              color: isEnabled ? bottomBorderColor : Colors.grey.shade900,
              width: bottomBorderWidth,
            ),
          ),
          boxShadow: shadows,
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontFamily: 'Cairo',
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.showArrow) ...[
                      const SizedBox(width: 14),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPrimary
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
