import 'package:flutter/material.dart';
import '../theme/lamma_theme.dart';

class TimerPill extends StatelessWidget {
  final int secondsRemaining;

  const TimerPill({
    super.key,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = secondsRemaining <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLow
              ? [LammaColors.error, const Color(0xFF9E1F35)]
              : [LammaColors.orange300, LammaColors.orange500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: (isLow ? LammaColors.error : LammaColors.orange500).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.timer_outlined : Icons.timer_rounded,
            color: isLow ? Colors.white : LammaColors.onCta,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '00:${secondsRemaining.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isLow ? Colors.white : LammaColors.onCta,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
