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
        final isSpeakerMuted = voice.isSpeakerMuted;
        final speakers = voice.activeSpeakers;
        final count = voice.participantCount;

        // ==========================================
        // الحالة الأولى: الصوت غير متصل (زر تشغيل الصوت)
        // ==========================================
        if (!isConnected) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: isConnecting
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        voice.joinVoiceRoom(roomCode: roomCode, playerToken: playerToken);
                      },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF321768), Color(0xFF1E0C40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF25D366).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnecting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: LammaColors.gold500),
                        )
                      else ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.mic_none_rounded, color: Color(0xFF25D366), size: 20),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        isConnecting ? 'جاري الاتصال بالسيرفر...' : 'تشغيل الصوت والدردشة 🎙️',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // ==========================================
        // الحالة الثانية: الصوت شغال (تحكم كامل في المايك، السماعة، وإيقاف الصوت)
        // ==========================================
        final hasActiveSpeaker = speakers.isNotEmpty;

        return Center(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B0B38),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: hasActiveSpeaker ? const Color(0xFF25D366) : const Color(0xFFA35BFF).withValues(alpha: 0.6),
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
                // 1. زر كتم / تشغيل المايك الخاص باللاعب
                Tooltip(
                  message: isMuted ? 'تشغيل المايك' : 'كتم المايك',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      voice.toggleMute();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMuted
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : const Color(0xFF25D366).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isMuted ? Colors.redAccent : const Color(0xFF25D366),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: isMuted ? Colors.redAccent : const Color(0xFF25D366),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMuted ? 'مكتوم' : 'مايك',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isMuted ? Colors.redAccent : const Color(0xFF25D366),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // 2. زر كتم / تشغيل سماعة الصوت (Deafen)
                Tooltip(
                  message: isSpeakerMuted ? 'تشغيل السماعة' : 'كتم سماعة الصوت',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      voice.toggleSpeakerMute();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSpeakerMuted
                            ? Colors.orangeAccent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: isSpeakerMuted ? Colors.orangeAccent : Colors.white24,
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        isSpeakerMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: isSpeakerMuted ? Colors.orangeAccent : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 3. حالة المتحدث الحالي أو عدد المتصلين
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasActiveSpeaker) ...[
                        const Icon(Icons.graphic_eq_rounded, color: Color(0xFF25D366), size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            speakers.first,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF25D366),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$count بالصوت',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD6C8F5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 4. زر إيقاف الصوت والخروج التام من المكالمة
                Tooltip(
                  message: 'إيقاف الصوت تماماً',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      voice.leaveVoiceRoom();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            'إيقاف',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
