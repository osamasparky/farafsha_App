import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/widgets/game_button.dart';

class ForceUpdateScreen extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const ForceUpdateScreen({
    super.key,
    required this.updateInfo,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _isCheckingAgain = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // توجيه تلقائي مباشر للمتجر بعد 1.2 ثانية ليرى المستخدم الشاشة ثم يُفتح المتجر تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          AppUpdateService.instance.launchStoreOrUpdate();
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _recheckUpdate() async {
    setState(() => _isCheckingAgain = true);
    HapticFeedback.lightImpact();

    final newInfo = await AppUpdateService.instance.checkUpdate();
    if (!mounted) return;

    setState(() => _isCheckingAgain = false);

    if (newInfo == null || !newInfo.isForceUpdate) {
      // تم التحديث بنجاح أو رفع الإلزام، نوجه المستخدم لبداية التطبيق
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ما زال تطبيقك بالإصدار القديم (${widget.updateInfo.currentBuildNumber})، يرجى استكمال التحديث للمتابعة.',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // إغلاق التطبيق إذا حاول المستخدم الضغط على زر الرجوع لتجاوز التحديث
          AppUpdateService.instance.exitApp();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF150A2E),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية التطبيق الرسمية
            Image.asset(
              'assets/images/splash_bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 1080,
            ),

            // طبقة تعتيم غامقة لإبراز بطاقة التحديث الإجباري
            Container(
              color: Colors.black.withOpacity(0.78),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E103B).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFFFF8A4C),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A4C).withOpacity(0.35),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // أيقونة صاروخ / تحديث نابضة بالحيوية
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8A4C), Color(0xFFFF3E85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3E85).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // شارة تنبيه
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3E85).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFF3E85)),
                          ),
                          child: Text(
                            'تحديث إجباري مطلوب ⚠️',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFFFF6584),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // العنوان الرئيسي
                        Text(
                          info.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // نص الرسالة
                        Text(
                          info.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD6C8F5),
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // مقارنة الإصدارات في كبسولة أنيقة
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'إصدارك الحالي',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: const Color(0xFFA594D1),
                                    ),
                                  ),
                                  Text(
                                    'v${info.currentVersion} (${info.currentBuildNumber})',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF8A4C),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFFA594D1),
                                size: 18,
                              ),
                              Column(
                                children: [
                                  Text(
                                    'الإصدار الأحدث',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: const Color(0xFFA594D1),
                                    ),
                                  ),
                                  Text(
                                    info.latestVersion,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4EFA8B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),

                        // زر التحديث الأساسي
                        GameButton(
                          text: isAndroid ? 'تحديث عبر Google Play 📲' : 'تحديث عبر App Store 📲',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            AppUpdateService.instance.launchStoreOrUpdate();
                          },
                        ),
                        const SizedBox(height: 12),

                        // زر التحميل المباشر البديل إذا وُجد
                        if (isAndroid && info.directDownloadUrl.isNotEmpty) ...[
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AppUpdateService.instance.launchStoreOrUpdate(preferDirectDownload: true);
                            },
                            icon: const Icon(Icons.download_rounded, color: Color(0xFFFFD27A), size: 18),
                            label: Text(
                              'أو تنزيل التحديث مباشرة (AAB / APK)',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFFFD27A),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // أزرار التحقق مرة أخرى والخروج
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _isCheckingAgain ? null : _recheckUpdate,
                              icon: _isCheckingAgain
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                    )
                                  : const Icon(Icons.refresh_rounded, color: Color(0xFFD6C8F5), size: 16),
                              label: Text(
                                _isCheckingAgain ? 'جاري الفحص...' : 'فحص بعد التحديث 🔄',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFFD6C8F5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                AppUpdateService.instance.exitApp();
                              },
                              child: Text(
                                'إغلاق التطبيق',
                                style: GoogleFonts.cairo(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
