import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/asset_sync_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _showActions = false;
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    AssetSyncService.instance.addListener(_onSyncStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSyncAndSession();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    AssetSyncService.instance.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkInitialSyncAndSession() async {
    final alreadySynced = await AssetSyncService.instance.hasCompletedInitialSync();
    if (!alreadySynced) {
      final success = await AssetSyncService.instance.startInitialSync();
      if (!success) {
        // يبقى في حالة offlineBlocked ليطلب المستخدم إعادة المحاولة
        return;
      }
    }

    _proceedAfterSync();
  }

  Future<void> _proceedAfterSync() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (AuthService.instance.isLoggedIn || AuthService.instance.isGuest) {
      context.go('/home');
      return;
    }

    setState(() {
      _showActions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncService = AssetSyncService.instance;
    final isSyncing = syncService.status == AssetSyncStatus.syncing || syncService.status == AssetSyncStatus.checking;
    final isOfflineBlocked = syncService.status == AssetSyncStatus.offlineBlocked || syncService.status == AssetSyncStatus.error;

    return Scaffold(
      backgroundColor: const Color(0xFF150A2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية الشاشة الكاملة من الصورة الرسمية
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // تدرج لوني سفلي ناعم لإبراز الأزرار التفاعلية فقط عند عدم وجود جلسة
          if (_showActions && !isSyncing && !isOfflineBlocked)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF150A2E).withValues(alpha: 0.95),
                      const Color(0xFF150A2E).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // بطاقة الحظر في حال عدم توفر إنترنت في أول تشغيل
          if (isOfflineBlocked)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E103B),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFFF8A4C), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8A4C).withValues(alpha: 0.35),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8A4C).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                color: Color(0xFFFF8A4C),
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'يلزم الاتصال بالإنترنت لأول مرة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'أهلاً بك في فرفشة! لتحميل ألعاب وبطاقات وتصاميم اللعبة بأعلى دقة وتجهيزها للعب بدون إنترنت لاحقاً، يرجى التأكد من تشغيل الواي فاي أو بيانات الهاتف.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD6C8F5),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GameButton(
                            text: 'إعادة المحاولة 🔄',
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _checkInitialSyncAndSession();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // بطاقة شريط التقدم أثناء تحميل وتجهيز الأصول لأول مرة
          if (isSyncing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E103B),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFA35BFF), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA35BFF).withValues(alpha: 0.35),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA35BFF).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_download_rounded,
                                color: Color(0xFFFFD27A),
                                size: 44,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'تجهيز ألعاب وبطاقات فرفشة 🚀',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            syncService.currentStepMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE4D9FA),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: syncService.progress,
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD27A)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(syncService.progress * 100).toInt()}%',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFD27A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // أزرار البداية والانتقال للتعريف تظهر فقط إذا لم يكن مسجلاً واكتملت المزامنة
          if (_showActions && !isSyncing && !isOfflineBlocked)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameButton(
                        text: 'ابدأ الآن 🚀',
                        onPressed: () => context.push('/onboarding'),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.cairo(fontSize: 15, color: const Color(0xFFE4D9FA)),
                              children: const [
                                TextSpan(text: 'لديك حساب بالفعل؟ '),
                                TextSpan(
                                  text: 'تسجيل الدخول',
                                  style: TextStyle(fontWeight: FontWeight.w900, color: LammaColors.gold300),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
