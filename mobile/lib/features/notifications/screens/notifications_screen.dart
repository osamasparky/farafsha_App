import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final notifs = await ApiService.instance.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifs.isNotEmpty ? notifs : _fallbackNotifications();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _fallbackNotifications() {
    return [
      {
        'id': 1,
        'title': 'أهلاً بك في لمّـة! 🎉',
        'message': 'استمتع بألعاب القعدة والتحدي مع أصحابك وعائلتك محلياً وأونلاين وبطريقة اللمّة.',
        'type': 'info',
        'is_read': false,
        'created_at': 'منذ ساعة',
      },
      {
        'id': 2,
        'title': 'تحدي الأسبوع بدأ! 🏆',
        'message': 'العب الآن واحصد نقاطاً مضاعفة لتصعد إلى قمة لوحة الترتيب.',
        'type': 'reward',
        'is_read': false,
        'created_at': 'منذ يوم',
      },
    ];
  }

  void _markAllAsRead() {
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تمييز جميع الإشعارات كمقروءة ✅'),
        backgroundColor: Color(0xFF2A1050),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'reward':
        return Icons.emoji_events_rounded;
      case 'update':
        return Icons.auto_awesome_rounded;
      case 'game':
        return Icons.sports_esports_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'reward':
        return LammaColors.gold500;
      case 'update':
        return const Color(0xFF35B88E);
      case 'game':
        return const Color(0xFFFF8A4C);
      default:
        return const Color(0xFFA35BFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.75),
            radius: 1.0,
            colors: [
              Color(0xFF4A2290),
              Color(0xFF241050),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              children: [
                // الشريط العلوي
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'الإشعارات والتنبيهات 🔔',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _markAllAsRead,
                      child: Text(
                        'قراءة الكل',
                        style: GoogleFonts.cairo(color: LammaColors.gold500, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // قائمة الإشعارات
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: LammaColors.violet500))
                      : _notifications.isEmpty
                          ? Center(
                              child: Text(
                                'لا توجد إشعارات جديدة حالياً 📭',
                                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 15),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _notifications.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                final isRead = notif['is_read'] == true;
                                final type = notif['type']?.toString() ?? 'info';
                                final color = _getColorForType(type);
                                final icon = _getIconForType(type);

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isRead ? const Color(0xFF1E103B) : const Color(0xFF2C1555),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isRead ? Colors.white10 : color.withValues(alpha: 0.6),
                                      width: isRead ? 1.0 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.18),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(icon, color: color, size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif['title'] ?? '',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 15,
                                                      fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFFFF568A),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif['message'] ?? '',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: const Color(0xFFCFC6E4),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
