import 'package:flutter/material.dart';
import '../theme/lamma_theme.dart';

class AvatarCircle extends StatelessWidget {
  final String? assetName; // e.g. "av-ahmed", "av-sara", etc.
  final double radius;
  final bool isLeader;
  final bool isSelected;
  final bool? isOnline;
  final VoidCallback? onTap;

  const AvatarCircle({
    super.key,
    this.assetName,
    this.radius = 24.0,
    this.isLeader = false,
    this.isSelected = false,
    this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String imagePath = assetName != null
        ? (assetName!.contains('/') ? assetName! : 'assets/images/$assetName.webp')
        : 'assets/images/av-ahmed.webp';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // إطار الصورة الخارجي
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? LammaColors.gold500
                    : (isLeader ? LammaColors.gold500 : LammaColors.violet400.withValues(alpha: 0.6)),
                width: isSelected || isLeader ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: LammaColors.gold500.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: LammaColors.bgRaised,
              backgroundImage: AssetImage(imagePath),
            ),
          ),

          // تاج الفائز / المتصدر الملكي
          if (isLeader)
            Positioned(
              top: -radius * 0.45,
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFC24B),
                size: 22,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),

          // نقطة حالة الاتصال (متصل / غير متصل)
          if (isOnline != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline! ? LammaColors.success : LammaColors.error,
                  border: Border.all(color: LammaColors.bgDeep, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

