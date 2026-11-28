import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';
import '../../../core/widgets/player_avatar_widget.dart';

class CardTableScaffold extends StatefulWidget {
  final String title;
  final String scoreSummary;
  final String roundSummary;
  final bool isLandscape;
  final VoidCallback onToggleOrientation;
  final Widget tableContent;
  final Widget bottomHand;
  final Widget? actionHintBar;

  const CardTableScaffold({
    super.key,
    required this.title,
    required this.scoreSummary,
    required this.roundSummary,
    required this.isLandscape,
    required this.onToggleOrientation,
    required this.tableContent,
    required this.bottomHand,
    this.actionHintBar,
  });

  @override
  State<CardTableScaffold> createState() => _CardTableScaffoldState();
}

class _CardTableScaffoldState extends State<CardTableScaffold> {
  @override
  void initState() {
    super.initState();
    _applyOrientation(widget.isLandscape);
  }

  @override
  void didUpdateWidget(covariant CardTableScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLandscape != widget.isLandscape) {
      _applyOrientation(widget.isLandscape);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _applyOrientation(bool landscape) {
    if (landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF281254), Color(0xFF150A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // الشريط العلوي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.pause_rounded, color: Colors.white),
                      onPressed: () {
                        PauseDialog.show(
                          context,
                          currentRound: 1,
                          totalRounds: 1,
                          onResume: () {},
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: widget.onToggleOrientation,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.screen_rotation_rounded, color: LammaColors.gold500, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            widget.roundSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(color: LammaColors.gold300, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: LammaColors.gold500.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.scoreSummary,
                        style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // طاولة المخمل البنفسجي بإطار ذهبي
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFF4B2188), Color(0xFF2B1158)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFC24B).withOpacity(0.65), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA35BFF).withOpacity(0.25),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: widget.tableContent,
                ),
              ),

              if (widget.actionHintBar != null) ...[
                const SizedBox(height: 6),
                widget.actionHintBar!,
              ],

              const SizedBox(height: 6),
              widget.bottomHand,
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class CardSeatBadge extends StatelessWidget {
  final String name;
  final String avatarPath;
  final int cardsCount;
  final bool isTurn;
  final String? subText;
  final double progress;

  const CardSeatBadge({
    super.key,
    required this.name,
    required this.avatarPath,
    required this.cardsCount,
    required this.isTurn,
    this.subText,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTurn ? const Color(0xFF5A25B8) : Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTurn ? LammaColors.gold500 : Colors.white12, width: isTurn ? 1.8 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isTurn)
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 2.5,
                    color: LammaColors.gold500,
                  ),
                ),
              PlayerAvatarWidget(avatarPath: avatarPath, size: 28),
            ],
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
              ),
              Text(
                subText ?? '$cardsCount ورقة',
                style: GoogleFonts.cairo(
                  color: isTurn ? LammaColors.gold300 : Colors.white60,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
