import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class OnlineRoomScreen extends StatefulWidget {
  final String roomCode;
  const OnlineRoomScreen({super.key, this.roomCode = '784521'});

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> {
  late String _code;

  final List<Map<String, dynamic>> _players = [
    {
      'name': 'أنت',
      'role': '(المضيف)',
      'avatar': 'assets/images/av-karim.png',
      'isHost': true,
      'status': 'متصل',
      'statusColor': const Color(0xFF6FD9B5),
    },
    {
      'name': 'أحمد',
      'role': '',
      'avatar': 'assets/images/av-ahmed.png',
      'isHost': false,
      'status': 'متصل',
      'statusColor': const Color(0xFF6FD9B5),
    },
    {
      'name': 'سارة',
      'role': '',
      'avatar': 'assets/images/av-sara.png',
      'isHost': false,
      'status': 'متصل',
      'statusColor': const Color(0xFF6FD9B5),
    },
    {
      'name': 'محمود',
      'role': '',
      'avatar': 'assets/images/av-mahmoud.png',
      'isHost': false,
      'status': 'بيعيد الاتصال…',
      'statusColor': const Color(0xFFF2B661),
    },
  ];

  @override
  void initState() {
    super.initState();
    _code = widget.roomCode;
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رمز الغرفة! شاركه مع أصحابك'),
        backgroundColor: Color(0xFF6A24C9),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ رابط الغرفة: https://lammah.app/join/$_code'),
        backgroundColor: const Color(0xFF6A24C9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // الشريط العلوي (رجوع + عنوان + إعدادات الغرفة)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'غرفة اللعب',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // بطاقة الرمز مع كود QR
                Row(
                  children: [
                    // رمز الغرفة والنسخ
                    Expanded(
                      child: Container(
                        height: 112,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1850),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'رمز الغرفة',
                              style: TextStyle(fontSize: 13, color: Color(0xFFCFC6E4), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _code,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: LammaColors.gold500,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _copyCode,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // صندوق كود QR
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 92,
                          color: Color(0xFF21143F),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'شارك الرمز مع أصدقائك عشان ينضموا',
                    style: TextStyle(fontSize: 14, color: Color(0xFFCFC6E4)),
                  ),
                ),

                const SizedBox(height: 18),

                // قائمة اللاعبين المنضمين
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1850),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اللاعبون (4/8)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFD9C2FF)),
                      ),
                      const SizedBox(height: 6),
                      ..._players.map((p) {
                        final isHost = p['isHost'] == true;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isHost ? LammaColors.gold500 : const Color(0xFFB98AFF),
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    p['avatar'] as String,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      p['name'] as String,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                    if (isHost) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '(المضيف)',
                                        style: TextStyle(fontSize: 13, color: LammaColors.gold500, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isHost)
                                const Icon(Icons.workspace_premium_rounded, color: LammaColors.gold500, size: 22)
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: p['statusColor'] as Color,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      p['status'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: p['statusColor'] as Color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const Spacer(),

                // زر مشاركة رابط الدعوة
                GestureDetector(
                  onTap: _shareLink,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'مشاركة رابط الدعوة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // زر ابدأ اللعبة
                GameButton(
                  text: 'ابدأ اللعبة',
                  showArrow: false,
                  height: 60,
                  onPressed: () {
                    context.push('/game/amthal');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
