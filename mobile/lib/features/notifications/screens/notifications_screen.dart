import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _hasUnread = true;

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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              // الشريط العلوي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'الإشعارات',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _hasUnread = false);
                    },
                    child: const Text(
                      'قراءة الكل',
                      style: TextStyle(color: LammaColors.gold500, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // النهارده
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0, right: 4.0),
                child: Text('النهارده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFC9A2FF))),
              ),

              // كارت دعوة الغرفة النشطة
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8F3BD0).withValues(alpha: 0.5),
                      const Color(0xFF4A1E9A).withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB98AFF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA35BFF).withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: LammaColors.gold500, width: 2.5),
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/av-ahmed.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أحمد بيعزمك على غرفة «ممنوع تقول»',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'من دقيقتين · 3 لاعبين مستنيين',
                                style: TextStyle(fontSize: 12, color: Color(0xFFCFC6E4)),
                              ),
                            ],
                          ),
                        ),
                        if (_hasUnread)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF2569A),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/online-room'),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LammaGradients.ctaPrimary,
                                borderRadius: BorderRadius.circular(999),
                                border: const Border(bottom: BorderSide(color: Color(0xFFB83A72), width: 3)),
                              ),
                              child: const Center(
                                child: Text('انضم', style: TextStyle(color: Color(0xFF2A0E35), fontWeight: FontWeight.w900, fontSize: 15)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                              ),
                              child: const Center(
                                child: Text('بعدين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // كارت محتوى جديد
              _buildNotificationItem(
                title: '50 مثل جديد نزلوا في «أمثال شعبية»',
                time: 'من ساعة',
                iconAsset: 'assets/images/ic-quote.png',
                iconGradient: [const Color(0xFFD2566A), const Color(0xFF8E2A4E)],
                hasUnreadDot: _hasUnread,
              ),

              const SizedBox(height: 10),

              // كارت وسام مبروك
              _buildNotificationItem(
                title: 'مبروك! خدت وسام «ملك الأمثال»',
                time: 'من 3 ساعات · +100 نقطة خبرة',
                iconData: Icons.emoji_events_rounded,
                iconGradient: [const Color(0xFFE0A92E), const Color(0xFF9C6A10)],
                hasUnreadDot: false,
              ),

              const SizedBox(height: 16),

              // الأسبوع ده
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0, right: 4.0),
                child: Text('الأسبوع ده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFC9A2FF))),
              ),

              _buildSimpleItem(
                title: 'سارة عدّتك في الترتيب الأسبوعي',
                time: 'الثلاثاء',
                avatarAsset: 'assets/images/av-sara.png',
              ),

              const SizedBox(height: 10),

              _buildNotificationItem(
                title: 'تحدي الويك إند بدأ!',
                time: 'الخميس',
                iconAsset: 'assets/images/ic-dice.png',
                iconGradient: [const Color(0xFF8C3468), const Color(0xFF531B44)],
                hasUnreadDot: false,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String time,
    String? iconAsset,
    IconData? iconData,
    required List<Color> iconGradient,
    required bool hasUnreadDot,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: iconGradient),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: iconAsset != null
                  ? Image.asset(iconAsset, width: 34, height: 32, fit: BoxFit.contain)
                  : Icon(iconData, color: const Color(0xFFFFF1C7), size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFFCFC6E4))),
              ],
            ),
          ),
          if (hasUnreadDot)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF2569A),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleItem({
    required String title,
    required String time,
    required String avatarAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage(avatarAsset),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFFCFC6E4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
