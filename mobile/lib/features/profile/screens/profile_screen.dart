import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _avatar = 'assets/images/farfasha_logo.png';
  int _totalPoints = 0;
  int _wins = 0;
  int _gamesPlayed = 0;

  // تفاصيل المستوى
  int _levelNumber = 1;
  String _levelTitle = 'مبتدئ الفرفشة';
  Color _levelColor = const Color(0xFFE879F9);
  int _pointsInLevel = 0;
  int _neededForNext = 100;
  double _progressPercent = 0.0;

  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final auth = AuthService.instance;
    _userName = auth.userName;
    _avatar = auth.userAvatar;
    _totalPoints = auth.totalPoints;
    _wins = auth.wins;
    _gamesPlayed = auth.gamesPlayed;

    if (auth.isGuest) {
      if (mounted) {
        setState(() {
          _userName = 'زائر فرفشة';
          _avatar = 'assets/images/farfasha_logo.png';
          _totalPoints = 0;
          _wins = 0;
          _gamesPlayed = 0;
          _badges = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final data = await ApiService.instance.getProfile(
        isGuest: false,
        token: auth.authToken,
      );
      if (data != null && mounted) {
        setState(() {
          _userName = data['name'] ?? _userName;
          _avatar = data['avatar'] ?? _avatar;
          _totalPoints = (data['total_points'] as num?)?.toInt() ?? _totalPoints;
          _wins = (data['wins'] as num?)?.toInt() ?? _wins;
          _gamesPlayed = (data['games_played'] as num?)?.toInt() ?? _gamesPlayed;

          if (data['level'] is Map) {
            final lvl = data['level'] as Map<String, dynamic>;
            _levelNumber = lvl['level_number'] ?? _levelNumber;
            _levelTitle = lvl['title'] ?? _levelTitle;
            _pointsInLevel = lvl['points_in_level'] ?? _pointsInLevel;
            _neededForNext = lvl['needed_for_next'] ?? _neededForNext;
            _progressPercent = (lvl['progress_percent'] as num?)?.toDouble() ?? _progressPercent;
            if (lvl['color'] != null) {
              _levelColor = _parseColor(lvl['color'].toString(), const Color(0xFFE879F9));
            }
          }

          if (data['badges'] is List) {
            _badges = List<Map<String, dynamic>>.from(data['badges']);
          }
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // في حال عدم توفر اتصال بالشبكة
    final fallbackBadges = await ApiService.instance.getBadges(userPoints: _totalPoints);
    if (mounted) {
      setState(() {
        _badges = fallbackBadges;
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String hexString, Color fallback) {
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  IconData _getBadgeIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'quote':
        return Icons.format_quote_rounded;
      case 'bulb':
        return Icons.lightbulb_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'film':
        return Icons.movie_filter_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'mask':
        return Icons.theater_comedy_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  void _showBadgeDetail(Map<String, dynamic> badge) {
    SoundService.instance.playClick();
    final color = _parseColor(badge['color']?.toString() ?? '', const Color(0xFFFFC24B));
    final isUnlocked = badge['is_unlocked'] == true;
    final game = badge['game'] is Map ? badge['game']['name']?.toString() : null;
    final reqPoints = badge['required_points'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C0D38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFFB98AFF), width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 18),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 24),
                ],
              ),
              child: Icon(_getBadgeIcon(badge['icon']?.toString()), color: color, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              badge['title']?.toString() ?? 'وسام',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            if (game != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFA35BFF).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFB98AFF).withValues(alpha: 0.5)),
                ),
                child: Text(
                  'خاص بلعبة: $game',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              badge['description']?.toString() ?? 'وسام تميز وتحدٍّ في اللمّة.',
              style: const TextStyle(fontSize: 14, color: Color(0xFFCFC6E4), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('النقاط المطلوبة للفتح:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '$reqPoints نقطة',
                    style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF35B88E).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnlocked ? const Color(0xFF35B88E) : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                    color: isUnlocked ? const Color(0xFF35B88E) : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked ? 'تم الحصول عليه وتتويجه في البروفايل 🎉' : 'متبقي نقاط لفتح هذا الوسام 🔒',
                    style: TextStyle(
                      color: isUnlocked ? const Color(0xFF35B88E) : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAllBadgesSheet() {
    SoundService.instance.playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF1C0D38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFFB98AFF), width: 2)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 16),
            const Text(
              'جميع الأوسمة والإنجازات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'يتم التحكم بجميع الأوسمة وشروطها من لوحة التحكم',
              style: TextStyle(fontSize: 12, color: Color(0xFFCFC6E4)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _badges.length,
                itemBuilder: (context, index) {
                  final badge = _badges[index];
                  final color = _parseColor(badge['color']?.toString() ?? '', const Color(0xFFFFC24B));
                  final isUnlocked = badge['is_unlocked'] == true;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showBadgeDetail(badge);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: isUnlocked ? 0.6 : 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.2),
                              border: Border.all(color: color, width: 2),
                            ),
                            child: Icon(_getBadgeIcon(badge['icon']?.toString()), color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  badge['title']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  badge['description']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFCFC6E4)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF35B88E), size: 22)
                          else
                            const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(String path, {double size = 110}) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.5, color: Colors.white),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.5, color: Colors.white),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.5, color: Colors.white),
        );
      }
      return Image.asset(
        'assets/images/farfasha_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
  }

  void _showEditProfileSheet(BuildContext context) {
    final List<String> availableAvatars = [
      'assets/images/av-ahmed.png',
      'assets/images/av-karim.png',
      'assets/images/av-mahmoud.png',
      'assets/images/av-sara.png',
      'assets/images/av-mena.png',
    ];

    String selectedAvatar = _avatar;
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: AuthService.instance.userPhone);
    final emailCtrl = TextEditingController(text: AuthService.instance.userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isCustomImage = !selectedAvatar.startsWith('assets/');

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1D0E38),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(color: Color(0xFFB98AFF), width: 2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تعديل الملف الشخصي ✏️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'اختر صورتك من الكاميرا أو المعرض، أو اختر شخصية رمزية وعدّل بياناتك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCFC6E4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // أزرار الكاميرا والمعرض
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 800,
                                maxHeight: 800,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                setModalState(() => selectedAvatar = picked.path);
                              }
                            },
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8F4BF0).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFB98AFF), width: 1.4),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, color: Color(0xFFFFD27A), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'التقاط بالكاميرا',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 800,
                                maxHeight: 800,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                setModalState(() => selectedAvatar = picked.path);
                              }
                            },
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8F4BF0).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFB98AFF), width: 1.4),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded, color: Color(0xFFFFD27A), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'اختيار من المعرض',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isCustomImage) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF35B88E).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF35B88E)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF35B88E), size: 16),
                              SizedBox(width: 6),
                              Text('تم اختيار صورة مخصصة من جهازك 👍', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // اختيار الأفاتار (بنين وبنات)
                    const Text(
                      'أو اختر شخصية رمزية:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: availableAvatars.map((av) {
                          final isSelected = selectedAvatar == av;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => selectedAvatar = av);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFFD27A) : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFFD27A).withValues(alpha: 0.5),
                                          blurRadius: 14,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(av),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // تعديل الاسم
                    const Text(
                      'الاسم أو اللقب في اللعب',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: TextField(
                        controller: nameCtrl,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: 'اكتب اسمك هنا...',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // البريد الإلكتروني
                    const Text(
                      'البريد الإلكتروني',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFB98AFF), size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: 'user@example.com',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // رقم الهاتف
                    const Text(
                      'رقم الهاتف',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.phone_android_rounded, color: Color(0xFFB98AFF), size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: '01X XXXX XXXX',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // خيار تغيير كلمة المرور داخل صفحة تعديل الملف الشخصي
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(modalContext); // إغلاق شيت التعديل
                        _showChangePasswordSheet(context); // فتح شيت تغيير كلمة المرور فوراً
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFB98AFF).withOpacity(0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8F4BF0).withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: Color(0xFFFFD27A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تغيير كلمة المرور 🔒',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'تحديث كلمة المرور لحماية حسابك وبياناتك',
                                    style: TextStyle(
                                      color: Color(0xFFCFC6E4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white38,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // زر حفظ التعديلات
                    GestureDetector(
                      onTap: () async {
                        final newName = nameCtrl.text.trim();
                        if (newName.isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        await AuthService.instance.updateProfile(
                          name: newName,
                          avatar: selectedAvatar,
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        );
                        setState(() {
                          _userName = newName;
                          _avatar = selectedAvatar;
                        });
                        if (modalContext.mounted) {
                          Navigator.pop(modalContext);
                        }
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ بياناتك بنجاح! 🎉'),
                            backgroundColor: Color(0xFF35B88E),
                          ),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8F4BF0).withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'حفظ التعديلات 🎉',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1D0E38),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(color: Color(0xFFB98AFF), width: 2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset_rounded, color: Color(0xFFFFD27A), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'تغيير كلمة المرور',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أدخل كلمة المرور الحالية ثم عيّن كلمة المرور الجديدة وتأكيدها.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFFCFC6E4)),
                    ),
                    const SizedBox(height: 16),

                    if (errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2566A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD2566A), width: 1.2),
                        ),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(color: Color(0xFFFF9AA2), fontSize: 13, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    // كلمة المرور الحالية
                    const Text(
                      'كلمة المرور الحالية',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA35BFF).withOpacity(0.6), width: 1.5),
                      ),
                      child: TextField(
                        controller: currentPassCtrl,
                        obscureText: obscureCurrent,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '•••••••• (اتركها فارغة إذا لم تعين كلمة مرور مسبقاً)',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFB98AFF), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                            onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // كلمة المرور الجديدة
                    const Text(
                      'كلمة المرور الجديدة (6 خانات كحد أدنى)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA35BFF).withOpacity(0.6), width: 1.5),
                      ),
                      child: TextField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'أدخل كلمة المرور الجديدة',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFFB98AFF), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // تأكيد كلمة المرور الجديدة
                    const Text(
                      'تأكيد كلمة المرور الجديدة',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA35BFF).withOpacity(0.6), width: 1.5),
                      ),
                      child: TextField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'أعد كتابة كلمة المرور الجديدة',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFB98AFF), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // زر الحفظ
                    GestureDetector(
                      onTap: isSaving
                          ? null
                          : () async {
                              final newPass = newPassCtrl.text;
                              final confirmPass = confirmPassCtrl.text;

                              if (newPass.isEmpty) {
                                setModalState(() => errorMsg = 'يرجى إدخال كلمة المرور الجديدة.');
                                return;
                              }
                              if (newPass.length < 6) {
                                setModalState(() => errorMsg = 'كلمة المرور يجب ألا تقل عن 6 خانات.');
                                return;
                              }
                              if (newPass != confirmPass) {
                                setModalState(() => errorMsg = 'كلمتا المرور غير متطابقتين.');
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                                errorMsg = null;
                              });

                              final res = await ApiService.instance.changePassword(
                                currentPassword: currentPassCtrl.text.isNotEmpty ? currentPassCtrl.text : null,
                                newPassword: newPass,
                                newPasswordConfirmation: confirmPass,
                                token: AuthService.instance.authToken,
                              );

                              if (!modalContext.mounted) return;
                              setModalState(() => isSaving = false);

                              if (res['success'] == true) {
                                Navigator.pop(modalContext);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تحديث كلمة المرور بنجاح 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                setModalState(() {
                                  errorMsg = res['message']?.toString() ?? 'فشل تغيير كلمة المرور.';
                                });
                              }
                            },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8F4BF0).withOpacity(0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text(
                                  'حفظ كلمة المرور الجديدة 🔒',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF150A2E),
        body: Center(
          child: CircularProgressIndicator(color: LammaColors.gold500),
        ),
      );
    }

    final progressFactor = (_pointsInLevel / (_neededForNext > 0 ? _neededForNext : 1)).clamp(0.0, 1.0);

    final auth = AuthService.instance;
    final isGuest = auth.isGuest;

    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.76),
            radius: 1.0,
            colors: [
              Color(0xFF5A2A9E),
              Color(0xFF2A1458),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Column(
              children: [
                // الشريط العلوي (رجوع + الإعدادات)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    const Text(
                      'الملف الشخصي',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // كارت البروفايل الأفقي الفاخر المدمج (صورة على اليمين والبيانات على اليسار توفر مساحة كبرى)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D0E38).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isGuest ? const Color(0xFFFFD27A).withValues(alpha: 0.5) : const Color(0xFFB98AFF).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isGuest ? const Color(0xFFFFD27A) : const Color(0xFF8F4BF0)).withValues(alpha: 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // صورة الملف الشخصي ومؤشر التعديل (على اليمين)
                      Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          GestureDetector(
                            onTap: () => isGuest ? context.push('/login') : _showEditProfileSheet(context),
                            child: Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isGuest ? const Color(0xFFFFD27A) : const Color(0xFFB98AFF),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isGuest ? const Color(0xFFFFD27A) : const Color(0xFFA35BFF)).withValues(alpha: 0.45),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _buildAvatarWidget(_avatar, size: 74),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => isGuest ? context.push('/login') : _showEditProfileSheet(context),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: LammaColors.gold500,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF2A1458), width: 2),
                              ),
                              child: Icon(
                                isGuest ? Icons.login_rounded : Icons.edit_rounded,
                                color: const Color(0xFF2A0E35),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // البيانات على اليسار (الاسم، البريد، شارة المستوى، زر التعديل)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                                if (!isGuest)
                                  GestureDetector(
                                    onTap: () => _showEditProfileSheet(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8F4BF0).withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFB98AFF).withValues(alpha: 0.5)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFFFD27A)),
                                          SizedBox(width: 3),
                                          Text('تعديل', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (!isGuest && (auth.userEmail.isNotEmpty || auth.userPhone.isNotEmpty)) ...[
                              Text(
                                auth.userEmail.isNotEmpty ? auth.userEmail : auth.userPhone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCFC6E4)),
                              ),
                              const SizedBox(height: 6),
                            ],
                            // الشارة المدمجة
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isGuest ? const Color(0xFFFFD27A) : _levelColor).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isGuest ? const Color(0xFFFFD27A) : _levelColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isGuest ? Icons.theater_comedy_rounded : Icons.star_rounded,
                                    color: isGuest ? const Color(0xFFFFD27A) : _levelColor,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isGuest ? 'حساب زائر فرفشة' : 'المستوى $_levelNumber • $_levelTitle',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isGuest ? const Color(0xFFFFD27A) : _levelColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // شارة المستوى أو تنبيه الزائر
                if (isGuest) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF381566), Color(0xFF220B44)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD27A), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD27A).withValues(alpha: 0.2),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.theater_comedy_rounded, color: Color(0xFFFFD27A), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'أنت تلعب الآن كـ زائر 🎭',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'سجّل دخول عشان تفرفش وتفتح كل الألعاب وتعدل اسمك وصورتك وتحفظ أوسمتك ونقاطك!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFFD9CCF2), height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/login'),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8A4C), Color(0xFFE94560)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'تسجيل الدخول / إنشاء حساب 🚀',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // شريط خبرة التقدم للمستوى التالي
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _levelColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'التقدم نحو المستوى التالي',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _levelColor),
                            ),
                            Text(
                              '$_pointsInLevel / $_neededForNext نقطة للترقية',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: progressFactor,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [_levelColor, const Color(0xFFFF8A4C)]),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (!isGuest) ...[
                  const SizedBox(height: 18),

                  // كروت الإحصائيات الثلاثة
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: LammaColors.gold500,
                          value: '$_wins',
                          label: 'فوز',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.sports_esports_rounded,
                          iconColor: const Color(0xFFC9A2FF),
                          value: '$_gamesPlayed',
                          label: 'لعبة',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFF8A4C),
                          value: '$_totalPoints',
                          label: 'نقطة',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // الأوسمة والإنجازات (مرتبة من لوحة التحكم)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الأوسمة والإنجازات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: _showAllBadgesSheet,
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LammaColors.gold500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // صف عرض أفضل 4 أوسمة
                  if (_badges.isEmpty)
                    Container(
                      height: 72,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(color: LammaColors.gold500),
                    )
                  else
                    Row(
                      children: [
                        // الوسام الأول
                        if (_badges.isNotEmpty)
                          Expanded(child: _buildDynamicBadgeWidget(_badges[0])),
                        const SizedBox(width: 8),
                        // الوسام الثاني
                        if (_badges.length > 1)
                          Expanded(child: _buildDynamicBadgeWidget(_badges[1])),
                        const SizedBox(width: 8),
                        // الوسام الثالث
                        if (_badges.length > 2)
                          Expanded(child: _buildDynamicBadgeWidget(_badges[2])),
                        const SizedBox(width: 8),
                        // زر استعراض باقي الأوسمة
                        Expanded(
                          child: GestureDetector(
                            onTap: _showAllBadgesSheet,
                            child: Container(
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.military_tech_rounded, color: LammaColors.gold500, size: 24),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+${_badges.length > 3 ? _badges.length - 3 : _badges.length}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 18),

                // روابط الحساب وإدارته
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildNavigationRow(
                        icon: Icons.leaderboard_rounded,
                        title: 'لوحة الترتيب والمتصدرين',
                        count: '',
                        onTap: () => context.push('/leaderboard'),
                        hasDivider: true,
                      ),
                      _buildNavigationRow(
                        icon: Icons.history_rounded,
                        title: 'سجل الألعاب السابقة',
                        count: '',
                        onTap: () => context.push('/results'),
                        hasDivider: true,
                      ),
                      if (isGuest)
                        _buildNavigationRow(
                          icon: Icons.login_rounded,
                          title: 'تسجيل الدخول إلى حسابك',
                          count: 'دخول 🚀',
                          onTap: () => context.push('/login'),
                          hasDivider: false,
                        )
                      else
                        _buildNavigationRow(
                          icon: Icons.logout_rounded,
                          title: 'تسجيل الخروج',
                          count: '',
                          onTap: () async {
                            await auth.logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          hasDivider: false,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBadgeWidget(Map<String, dynamic> badge) {
    final color = _parseColor(badge['color']?.toString() ?? '', const Color(0xFFFFC24B));
    final isUnlocked = badge['is_unlocked'] == true;

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUnlocked
                ? [color.withValues(alpha: 0.85), color.withValues(alpha: 0.5)]
                : [Colors.white12, Colors.white10],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: isUnlocked ? 0.9 : 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getBadgeIcon(badge['icon']?.toString()),
              size: 26,
              color: isUnlocked ? Colors.white : Colors.white54,
            ),
            const SizedBox(height: 2),
            Text(
              badge['title']?.toString() ?? '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isUnlocked ? Colors.white : Colors.white60,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1F74), Color(0xFF241050)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCFC6E4))),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    required String count,
    required VoidCallback onTap,
    required bool hasDivider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFC9A2FF), size: 22),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const Spacer(),
                if (count.isNotEmpty)
                  Text(
                    count,
                    style: const TextStyle(color: LammaColors.gold500, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFCFC6E4), size: 14),
              ],
            ),
          ),
          if (hasDivider)
            const Divider(color: Color(0xFF331B68), height: 1, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}
