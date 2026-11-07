import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/livekit_voice_service.dart';
import '../theme/lamma_theme.dart';

class VoiceRoomBar extends StatelessWidget {
  final String roomCode;
  final String? playerToken;

  const VoiceRoomBar({
    super.key,
    required this.roomCode,
    this.playerToken,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveKitVoiceService.instance,
      builder: (context, _) {
        final voice = LiveKitVoiceService.instance;
        final isConnected = voice.isConnected;
        final isConnecting = voice.isConnecting;
        final isMuted = voice.isMuted;
        final speakers = voice.activeSpeakers;
        final count = voice.participantCount;

        if (!isConnected) {
          return GestureDetector(
            onTap: isConnecting
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    voice.joinVoiceRoom(roomCode: roomCode, playerToken: playerToken);
                  },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF26144D).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isConnecting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: LammaColors.gold500),
                    )
                  else
                    const Icon(Icons.mic_none_rounded, color: LammaColors.gold500, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isConnecting ? 'جاري الاتصال بالصوت...' : 'انضم للدردشة الصوتية 🎙️',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // حالة الاتصال الفعّال
        final hasActiveSpeaker = speakers.isNotEmpty;

        return Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0E3D),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasActiveSpeaker ? const Color(0xFF25D366) : const Color(0xFFA35BFF).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (hasActiveSpeaker ? const Color(0xFF25D366) : const Color(0xFFA35BFF)).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر كتم الميكروفون التفاعلي
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  voice.toggleMute();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMuted ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF25D366).withValues(alpha: 0.2),
                    border: Border.all(
                      color: isMuted ? Colors.redAccent : const Color(0xFF25D366),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: isMuted ? Colors.redAccent : const Color(0xFF25D366),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // حالة المتحدث الحالي
              if (hasActiveSpeaker) ...[
                const Icon(Icons.volume_up_rounded, color: Color(0xFF25D366), size: 18),
                const SizedBox(width: 6),
                Text(
                  '${speakers.first} يتكلم...',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF25D366),
                  ),
                ),
              ] else ...[
                const Icon(Icons.record_voice_over_rounded, color: Color(0xFFD6C8F5), size: 16),
                const SizedBox(width: 6),
                Text(
                  'دردشة صوتية ($count)',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD6C8F5),
                  ),
                ),
              ],

              const SizedBox(width: 8),

              // زر الخروج من الصوت
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  voice.leaveVoiceRoom();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
