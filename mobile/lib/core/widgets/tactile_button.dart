import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// زر ثلاثي الأبعاد تفاعلي (Tactile 3D Button) مع تأثير ضغط واقعي
class TactileButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color shadowColor;
  final TextStyle? textStyle;
  final double height;
  final double depth;
  final BorderRadius? borderRadius;
  final bool isFullWidth;
  final bool isLoading;

  const TactileButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.brandViolet,
    this.shadowColor = const Color(0xFF5E1FB5),
    this.textStyle,
    this.height = 54,
    this.depth = 4.0,
    this.borderRadius,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              SettingsService.instance.triggerHaptic();
              SoundService.instance.playClick();
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
        duration: const Duration(milliseconds: 90),
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? widget.depth : 0,
          bottom: _isPressed ? 0 : widget.depth,
        ),
        decoration: BoxDecoration(
          color: isEnabled ? widget.backgroundColor : Colors.grey.shade700,
          borderRadius: effectiveRadius,
          boxShadow: _isPressed || !isEnabled
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, widget.depth),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: widget.textStyle ?? AppTypography.button,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

