import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

/// ستارة عرض البنر التفاعلية
/// تنزل بحركة ناعمة من الأعلى حتى القائمة السفلية (المنيو)
/// تدعم عرض الصور والفيديو مع زر الروابط الخارجية وزر إغلاق (X)
class BannerCurtainModal extends StatefulWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onClose;

  const BannerCurtainModal({
    super.key,
    required this.banner,
    required this.onClose,
  });

  static Future<void> show(BuildContext context, Map<String, dynamic> banner) {
    SettingsService.instance.triggerHaptic(isHeavy: true);
    SoundService.instance.playClick();

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق الستارة',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim, secondaryAnim) {
        return BannerCurtainModal(
          banner: banner,
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: child,
        );
      },
    );
  }

  @override
  State<BannerCurtainModal> createState() => _BannerCurtainModalState();
}

class _BannerCurtainModalState extends State<BannerCurtainModal> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initVideoIfPresent();
  }

  void _initVideoIfPresent() {
    final videoUrl = widget.banner['video_url']?.toString();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(videoUrl);
        _videoController = VideoPlayerController.networkUrl(uri)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
                _isVideoPlaying = true;
              });
              _videoController?.setLooping(true);
              _videoController?.play();
            }
          }).catchError((err) {
            debugPrint('⚠️ Error initializing banner video: $err');
          });
      } catch (e) {
        debugPrint('⚠️ Invalid video url: $e');
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null || !_isVideoInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _openExternalUrl() async {
    final urlStr = widget.banner['external_url']?.toString();
    if (urlStr == null || urlStr.isEmpty) return;

    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ Error launching external banner url: $e');
    }
  }

  Widget _buildMediaContent() {
    final imageUrl = widget.banner['image_url']?.toString() ?? widget.banner['image']?.toString();
    final bool hasVideo = _isVideoInitialized && _videoController != null;

    if (hasVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // زر تشغيل/إيقاف مؤقت وكاتم الصوت
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // عرض الصورة الأساسية (شبكة أو Asset محلي مع تقييد الذاكرة)
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 800,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/crowd.webp',
            fit: BoxFit.cover,
            cacheWidth: 800,
          ),
        );
      } else {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 800,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/crowd.webp',
            fit: BoxFit.cover,
            cacheWidth: 800,
          ),
        );
      }
    }

    return Image.asset('assets/images/crowd.webp', fit: BoxFit.cover, cacheWidth: 800);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.banner['title']?.toString() ?? 'إعلان خاص من فرفشة 🎉';
    final externalUrl = widget.banner['external_url']?.toString();
    final bool hasExternalUrl = externalUrl != null && externalUrl.trim().isNotEmpty;
    final bool hasVideo = widget.banner['video_url'] != null && widget.banner['video_url'].toString().isNotEmpty;

    // تتوقف الستارة قبل شريط الملاحة السفلي (المنيو)
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 85.0;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 8,
            bottom: bottomPadding,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1052), Color(0xFF130628)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFFF8A4C),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A4C).withValues(alpha: 0.4),
                blurRadius: 35,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. وسائط العرض (صورة أو فيديو) تغطي الستارة
                _buildMediaContent(),

                // 2. طبقة تظليل سينمائية ناعمة لظهور النصوص والأزرار بوضوح تام
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.22, 0.55, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // 3. شارة نوع الوسائط (فيديو أو صورة) في الأعلى
                Positioned(
                  top: 18,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasVideo ? Icons.videocam_rounded : Icons.photo_library_rounded,
                          color: LammaColors.gold300,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasVideo ? 'عرض فيديو 🎥' : 'إعلان خاص 🌟',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. زر الإغلاق الدائري (X) في الركن العلوي
                Positioned(
                  top: 16,
                  right: 18,
                  child: GestureDetector(
                    onTap: () {
                      SettingsService.instance.triggerHaptic();
                      SoundService.instance.playClick();
                      widget.onClose();
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. المحتوى السفلي: العنوان، والزر الخارجي إن وجد
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 22,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اضغط على الزر أدناه لمعرفة التفاصيل أو اسحب للإغلاق',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE5D8FC),
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (hasExternalUrl) ...[
                        GameButton(
                          text: 'الانتقال للرابط وموقع الفعالية 🚀',
                          onPressed: _openExternalUrl,
                        ),
                      ] else ...[
                        GameButton(
                          text: 'حسناً، فهمت 👍',
                          onPressed: widget.onClose,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

