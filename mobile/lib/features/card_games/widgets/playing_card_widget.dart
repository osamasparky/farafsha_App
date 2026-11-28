import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/playing_card.dart';

enum CardVisualState {
  normal,
  playable,
  selected,
  disabled,
  winning,
  captured,
}

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceDown;
  final double width;
  final CardVisualState state;
  final VoidCallback? onTap;
  final String? badgeText;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.faceDown = false,
    this.width = 64,
    this.state = CardVisualState.normal,
    this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final isDisabled = state == CardVisualState.disabled;

    Color borderColor = const Color(0xFFD8CCB4);
    double borderWidth = 1.4;
    double lift = 0;
    List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.32),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ];

    switch (state) {
      case CardVisualState.playable:
        borderColor = const Color(0xFF4FD1A5);
        borderWidth = 2.2;
        lift = -6;
        shadows = [
          BoxShadow(color: const Color(0xFF4FD1A5).withOpacity(0.45), blurRadius: 10),
        ];
        break;
      case CardVisualState.selected:
        borderColor = const Color(0xFFFFC24B);
        borderWidth = 2.6;
        lift = -12;
        shadows = [
          BoxShadow(color: const Color(0xFFFFC24B).withOpacity(0.55), blurRadius: 14),
        ];
        break;
      case CardVisualState.winning:
        borderColor = const Color(0xFFFFC24B);
        borderWidth = 2.6;
        shadows = [
          BoxShadow(color: const Color(0xFFFFC24B).withOpacity(0.6), blurRadius: 16),
        ];
        break;
      case CardVisualState.captured:
        borderColor = const Color(0xFF4FD1A5);
        borderWidth = 2.4;
        shadows = [
          BoxShadow(color: const Color(0xFF4FD1A5).withOpacity(0.5), blurRadius: 12),
        ];
        break;
      case CardVisualState.normal:
      case CardVisualState.disabled:
        break;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, lift, 0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.14),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.12),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: faceDown || card == null ? _buildBack(width, height) : _buildFront(card!, width, height),
          ),
        ),
      ),
    );
  }

  Widget _buildBack(double w, double h) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E1C7A), Color(0xFF21143F)],
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(w * 0.08),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.08),
          border: Border.all(color: const Color(0xFFFFC24B).withOpacity(0.75), width: 1.2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5D2BB0), Color(0xFF2A1458)],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFFFC24B).withOpacity(0.85),
            size: w * 0.34,
          ),
        ),
      ),
    );
  }

  Widget _buildFront(PlayingCard c, double w, double h) {
    final suitColor = c.isRed ? const Color(0xFFD6334F) : const Color(0xFF241B35);

    if (c.isFaceCard) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFFFFBF2)),
          SvgPicture.asset(
            c.faceAssetPath,
            fit: BoxFit.cover,
          ),
          // شارة الركن العلوي الأيسر (الرتبة + الرمز)
          Positioned(
            top: w * 0.06,
            left: w * 0.06,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(w * 0.07),
                border: Border.all(color: const Color(0xFFD8CCB4), width: 0.8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.rankLabel,
                    style: GoogleFonts.cairo(
                      fontSize: w * 0.21,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: suitColor,
                    ),
                  ),
                  Text(
                    c.suitSymbol,
                    style: TextStyle(fontSize: w * 0.18, height: 1.0, color: suitColor),
                  ),
                ],
              ),
            ),
          ),
          if (badgeText != null)
            Positioned(
              bottom: w * 0.06,
              left: w * 0.06,
              right: w * 0.06,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6334F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: w * 0.15, color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      color: const Color(0xFFFFFBF2),
      padding: EdgeInsets.all(w * 0.08),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.rankLabel,
                  style: GoogleFonts.cairo(
                    fontSize: w * 0.24,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: suitColor,
                  ),
                ),
                Text(
                  c.suitSymbol,
                  style: TextStyle(fontSize: w * 0.20, height: 1.0, color: suitColor),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              c.suitSymbol,
              style: TextStyle(fontSize: w * 0.44, height: 1.0, color: suitColor),
            ),
          ),
        ],
      ),
    );
  }
}
