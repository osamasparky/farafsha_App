import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/guest_locked_modal.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String _selectedMode = 'local'; // 'local', 'lammah', 'online'
  List<Map<String, dynamic>> _modes = [];

  static const List<Map<String, dynamic>> _defaultModes = [
    {
      'slug': 'local',
      'title': 'لعبة محلية',
      'subtitle': 'على جهاز واحد بالتناوب\nمع أصحابك جنبك (Pass & Play)',
      'badge': 'التناوب الكلاسيكي',
      'image': 'assets/images/local.webp',
      'image_url': null,
      'highlight_color': '#A35BFF',
    },
    {
      'slug': 'lammah',
      'title': 'طريقة اللمّة',
      'subtitle': 'واحد معاه الموبايل والميكروفون\nويقرأ الأسئلة للقعدة كلها',
      'badge': 'الأمتع للقعدة 🎉',
      'image': 'assets/images/crowd.webp',
      'image_url': null,
      'highlight_color': '#FF8A4C',
    },
    {
      'slug': 'online',
      'title': 'لعبة أونلاين',
      'subtitle': 'العب مع أصحابك\nعن بُعد بغرفة ورمز سري',
      'badge': 'غرف شبكية',
      'image': 'assets/images/online.webp',
      'image_url': null,
      'highlight_color': '#A35BFF',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (!AuthService.instance.isModeUnlocked(_selectedMode)) {
      _selectedMode = 'local';
    }
    _loadModes();
  }

  Future<void> _loadModes() async {
    try {
      final modes = await ApiService.instance.getGameplayModes();
      if (mounted && modes.isNotEmpty) {
        setState(() {
          _modes = modes;
        });
      }
    } catch (_) {}
  }

  String _fallbackAsset(String slug) {
    switch (slug) {
      case 'lammah':
        return 'assets/images/crowd.webp';
      case 'online':
        return 'assets/images/online.webp';
      case 'local':
      default:
        return 'assets/images/local.webp';
    }
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final activeModes = _modes.isNotEmpty ? _modes : _defaultModes;

    return LammaScaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // زر الرجوع
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
              ),

              // عنوان الشاشة
              Text(
                'اختر طريقة اللعب',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [Shadow(offset: Offset(0, 3), color: Color(0xFF6A24C9), blurRadius: 8)],
                ),
              ),

              const SizedBox(height: 14),

              // قائمة كروت الطرق الثلاثة قابلة للتمرير والتحكم من لوحة الإدارة
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: activeModes.map((mode) {
                    final slug = mode['slug']?.toString() ?? 'local';
                    final title = mode['title']?.toString() ?? '';
                    final subtitle = mode['subtitle']?.toString() ?? '';
                    final badge = mode['badge']?.toString() ?? '';
                    final imageUrl = mode['image_url']?.toString();
                    final fallbackAsset = _fallbackAsset(slug);
                    final isUnlocked = AuthService.instance.isModeUnlocked(slug);
                    final color = _parseColor(
                      mode['highlight_color']?.toString(),
                      slug == 'lammah' ? const Color(0xFFFF8A4C) : const Color(0xFFA35BFF),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _buildModeCard(
                        modeId: slug,
                        title: title,
                        subtitle: subtitle,
                        imageAsset: fallbackAsset,
                        imageUrl: imageUrl,
                        badge: badge,
                        highlightColor: color,
                        isUnlocked: isUnlocked,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // زر المتابعة
              GameButton(
                text: 'متابعة',
                onPressed: () {
                  if (!AuthService.instance.isModeUnlocked(_selectedMode)) {
                    final currentModeData = activeModes.firstWhere(
                      (m) => m['slug'] == _selectedMode,
                      orElse: () => {'title': 'طريقة اللعب'},
                    );
                    final title = currentModeData['title']?.toString() ?? 'طريقة اللعب';
                    GuestLockedModal.show(
                      context,
                      gameTitle: title,
                      customTitle: 'طريقة اللعب للمسجلين فقط! 🔒',
                      customMessage:
                          'طريقة "$title" متاحة فقط للأعضاء المسجلين في المنصة.\nسجّل دخولك الآن واستمتع بجميع طرق اللعب واللمّة والتحديات أونلاين واحفظ نقاطك!',
                    );
                    return;
                  }
                  if (_selectedMode == 'local') {
                    context.go('/home');
                  } else if (_selectedMode == 'lammah') {
                    _showLammahOptionsSheet(context);
                  } else {
                    _showOnlineOptionsSheet(context);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String modeId,
    required String title,
    required String subtitle,
    required String imageAsset,
    String? imageUrl,
    required String badge,
    Color highlightColor = const Color(0xFFA35BFF),
    required bool isUnlocked,
  }) {
    final bool isSelected = _selectedMode == modeId && isUnlocked;

    return GestureDetector(
      onTap: () {
        if (!isUnlocked) {
          HapticFeedback.lightImpact();
          GuestLockedModal.show(
            context,
            gameTitle: title,
            customTitle: 'طريقة اللعب للمسجلين فقط! 🔒',
            customMessage:
                'طريقة "$title" متاحة فقط للأعضاء المسجلين في المنصة.\nسجّل دخولك الآن واستمتع بجميع طرق اللعب واللمّة والتحديات أونلاين واحفظ نقاطك!',
          );
          return;
        }
        HapticFeedback.selectionClick();
        setState(() => _selectedMode = modeId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF3B1875),
                    highlightColor.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isUnlocked
                  ? const Color(0xFF1B0E38).withValues(alpha: 0.9)
                  : const Color(0xFF130926).withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? highlightColor
                : (isUnlocked
                    ? LammaColors.cardBorder
                    : const Color(0xFFFFD27A).withValues(alpha: 0.35)),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : (isUnlocked
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : []),
        ),
        child: Row(
          children: [
            // صورة الكارت
            SizedBox(
              width: 90,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (imageUrl != null && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')))
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        cacheWidth: 200,
                        errorBuilder: (_, __, ___) => Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          cacheWidth: 200,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.group_work_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      )
                    : Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        cacheWidth: 200,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.group_work_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // النصوص والبادج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (isUnlocked ? highlightColor : const Color(0xFFFFD27A)).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUnlocked ? badge : 'للمسجلين فقط 🔒',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isUnlocked ? highlightColor : const Color(0xFFFFD27A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isUnlocked ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? const Color(0xFFD6C8F5) : const Color(0xFFA99BC8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            // علامة الاختيار أو أيقونة القفل
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? highlightColor
                    : (isUnlocked ? Colors.transparent : Colors.black45),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (isUnlocked ? Colors.white38 : const Color(0xFFFFD27A)),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : (!isUnlocked
                      ? const Icon(Icons.lock_rounded, color: Color(0xFFFFD27A), size: 14)
                      : null),
            ),
          ],
        ),
      ),
    );
  }

  /// القائمة المنبثقة لاختيار نمط اللمّة (كلنا واحد VS فرق وتحدي)
  void _showLammahOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LammahSetupSheet(),
    );
  }

  /// القائمة المنبثقة لاختيار نمط اللعب أونلاين (إنشاء غرفة كمضيف VS انضمام لغرفة)
  void _showOnlineOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OnlineSetupSheet(),
    );
  }
}

/// شيت إعداد طريقة اللمّة مع إضافة الفرق ومسمياتها
class _LammahSetupSheet extends StatefulWidget {
  const _LammahSetupSheet();

  @override
  State<_LammahSetupSheet> createState() => _LammahSetupSheetState();
}

class _LammahSetupSheetState extends State<_LammahSetupSheet> {
  String _subMode = 'teams'; // 'all_in_one' or 'teams'
  String _selectedGameSlug = 'amthal-shaabiya';
  final TextEditingController _teamNameController = TextEditingController();

  final List<Map<String, dynamic>> _teams = [
    {'name': 'فرفوش', 'score': 0, 'color': const Color(0xFFA35BFF)},
    {'name': 'قفوش', 'score': 0, 'color': const Color(0xFFFF8A4C)},
  ];

  bool _isLoadingGames = true;
  List<Map<String, dynamic>> _availableGames = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await ApiService.instance.getGames();
      if (mounted) {
        setState(() {
          _availableGames = games.where((g) => g['is_active'] != false).toList();
          _isLoadingGames = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGames = false);
    }
  }

  List<Map<String, dynamic>> get _displayGames {
    if (_availableGames.isNotEmpty) return _availableGames;
    return const [
      {'name': 'أمثال شعبية', 'slug': 'amthal-shaabiya', 'category': 'أمثال'},
      {'name': 'جمل مشهورة', 'slug': 'famous-quotes', 'category': 'إفيهات'},
      {'name': 'سؤال على السريع', 'slug': 'speed-trivia', 'category': 'معلومات عامة'},
      {'name': 'مين أنا؟', 'slug': 'who-am-i', 'category': 'تخمين'},
      {'name': 'ممنوع تقول', 'slug': 'forbidden-words', 'category': 'ذكاء وسرعة'},
      {'name': 'حقيقتان وكذبة', 'slug': 'two-truths-and-lie', 'category': 'تواصل وضحك'},
      {'name': 'أتوبيس كومبليت', 'slug': 'autobus-complete', 'category': 'ذكاء وسرعة'},
    ];
  }

  IconData _getGameIcon(String slug) {
    switch (slug) {
      case 'amthal-shaabiya':
        return Icons.format_quote_rounded;
      case 'famous-quotes':
        return Icons.movie_filter_rounded;
      case 'who-am-i':
        return Icons.help_outline_rounded;
      case 'forbidden-words':
      case 'taboo':
        return Icons.block_rounded;
      case 'two-truths-and-lie':
        return Icons.psychology_rounded;
      case 'speed-trivia':
        return Icons.bolt_rounded;
      case 'autobus-complete':
        return Icons.directions_bus_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  final List<Color> _presetColors = const [
    Color(0xFFA35BFF),
    Color(0xFFFF8A4C),
    Color(0xFF35B88E),
    Color(0xFFF2569A),
    Color(0xFFFFD27A),
    Color(0xFF38B6FF),
  ];
  int _selectedColorIndex = 2;

  void _addTeam() {
    final name = _teamNameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _teams.add({
          'name': name,
          'score': 0,
          'color': _presetColors[_selectedColorIndex % _presetColors.length],
        });
        _selectedColorIndex++;
        _teamNameController.clear();
      });
      Navigator.pop(context); // إغلاق دايلوج الإضافة
    }
  }

  void _showAddTeamDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF241050),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'إضافة فرقة جديدة',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _teamNameController,
              autofocus: true,
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'اسم الفرقة (مثلاً: فريق البنات)',
                hintStyle: GoogleFonts.cairo(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LammaColors.orange500),
            onPressed: _addTeam,
            child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF170B30),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0xFFA35BFF), width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 14),

            // عنوان القائمة
            Center(
              child: Text(
                'إعداد طريقة اللمّة 🎤',
                style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                'أنت المذيع! اقرأ الأسئلة بصوتك للقعدة كلها',
                style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFFD6C8F5)),
              ),
            ),

            const SizedBox(height: 18),

            // اختيار النمطين (1. كلنا واحد  -  2. فرق وتحدي)
            Row(
              children: [
                Expanded(
                  child: _buildSubModePill(
                    id: 'all_in_one',
                    title: '1. كلنا واحد',
                    desc: 'بلا فرق أو نقاط (ضحك وتسلية)',
                    icon: Icons.favorite_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSubModePill(
                    id: 'teams',
                    title: '2. فرق وتحدي',
                    desc: 'تسجيل نقاط الفرق الفائزة',
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // قسم الفرق (يظهر فقط في نمط الفرق)
            if (_subMode == 'teams') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الفرق المشاركة:',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: _showAddTeamDialog,
                    icon: const Icon(Icons.add_circle_rounded, color: LammaColors.orange300, size: 20),
                    label: Text(
                      '+ إضافة فرقة',
                      style: GoogleFonts.cairo(
                        color: LammaColors.orange300,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // قائمة الفرق الحالية
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_teams.length, (i) {
                  final t = _teams[i];
                  final Color c = t['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          t['name'] as String,
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        if (_teams.length > 2) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _teams.removeAt(i)),
                            child: const Icon(Icons.close_rounded, color: Colors.white60, size: 16),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
            ],

            // اختيار اللعبة للعبها (محدثة ديناميكياً من الـ API)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر نوع الأسئلة واللعبة:',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                if (_isLoadingGames)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: LammaColors.gold500),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _displayGames.map((game) {
                final slug = game['slug']?.toString() ?? '';
                final name = game['name']?.toString() ?? slug;
                final category = game['category']?.toString();
                final isSelected = _selectedGameSlug == slug;
                final isUnlocked = AuthService.instance.isGameUnlocked(slug);
                final icon = _getGameIcon(slug);

                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 56) / 2,
                  child: GestureDetector(
                    onTap: () {
                      if (!isUnlocked) {
                        GuestLockedModal.show(context, gameTitle: name);
                        return;
                      }
                      setState(() => _selectedGameSlug = slug);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF451A8A)
                            : (isUnlocked ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? LammaColors.gold500
                              : (isUnlocked ? Colors.white24 : const Color(0xFFFFD27A).withValues(alpha: 0.35)),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: LammaColors.gold500.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LammaColors.gold500.withValues(alpha: 0.25)
                                  : (isUnlocked ? Colors.white.withValues(alpha: 0.08) : Colors.black38),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? LammaColors.gold500
                                  : (isUnlocked ? const Color(0xFFD9C2FF) : const Color(0xFFFFD27A)),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isUnlocked ? Colors.white : Colors.white70,
                                  ),
                                ),
                                if (category != null)
                                  Text(
                                    isUnlocked ? category : 'للمسجلين فقط 🔒',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? LammaColors.gold300
                                          : (isUnlocked ? const Color(0xFFA99BC8) : const Color(0xFFFFD27A)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: LammaColors.gold500, size: 16)
                          else if (!isUnlocked)
                            const Icon(Icons.lock_rounded, color: Color(0xFFFFD27A), size: 14),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // زر ابدأ اللمّة
            GameButton(
              text: 'ابدأ اللمّة الآن 🎤',
              onPressed: () {
                if (!AuthService.instance.isGameUnlocked(_selectedGameSlug)) {
                  GuestLockedModal.show(context, gameTitle: 'هذه اللعبة');
                  return;
                }
                Navigator.pop(context); // إغلاق الشيت
                context.push(
                  '/game/lammah-host',
                  extra: {
                    'gameSlug': _selectedGameSlug,
                    'subMode': _subMode,
                    'teams': _teams,
                    'totalQuestions': 50,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubModePill({
    required String id,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final bool isSelected = _subMode == id;
    return GestureDetector(
      onTap: () => setState(() => _subMode = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D1A7A) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? LammaColors.gold500 : LammaColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? LammaColors.gold500 : Colors.white60, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFCFC6E4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شيت إعداد اللعب أونلاين: الاختيار بين المضيف (إنشاء غرفة) أو الضيف (انضمام بكود)
class _OnlineSetupSheet extends StatefulWidget {
  const _OnlineSetupSheet();

  @override
  State<_OnlineSetupSheet> createState() => _OnlineSetupSheetState();
}

class _OnlineSetupSheetState extends State<_OnlineSetupSheet> {
  int _activeTab = 0; // 0: إنشاء غرفة (Host), 1: انضمام (Join)

  // Host state
  String _selectedGameSlug = 'amthal-shaabiya';
  int _totalRounds = 10;
  int _roundDuration = 20;
  bool _isLoadingHost = false;

  // Join state
  final TextEditingController _joinCodeController = TextEditingController();
  late TextEditingController _joinNameController;
  bool _isLoadingJoin = false;

  List<Map<String, dynamic>> _availableGames = [];

  @override
  void initState() {
    super.initState();
    final authName = AuthService.instance.userName.trim();
    final apiName = ApiService.instance.currentUser?['name']?.toString().trim() ?? '';
    final initialName = authName.isNotEmpty ? authName : (apiName.isNotEmpty ? apiName : '');
    _joinNameController = TextEditingController(text: initialName);
    _loadGames();
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    _joinNameController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    try {
      final games = await ApiService.instance.getGames();
      if (mounted) {
        setState(() {
          _availableGames = games.where((g) => g['is_active'] != false).toList();
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _displayGames {
    if (_availableGames.isNotEmpty) return _availableGames;
    return const [
      {'name': 'أمثال شعبية', 'slug': 'amthal-shaabiya', 'category': 'أمثال'},
      {'name': 'جمل مشهورة', 'slug': 'famous-quotes', 'category': 'إفيهات'},
      {'name': 'سؤال على السريع', 'slug': 'speed-trivia', 'category': 'معلومات عامة'},
      {'name': 'مين أنا؟', 'slug': 'who-am-i', 'category': 'تخمين'},
      {'name': 'ممنوع تقول', 'slug': 'forbidden-words', 'category': 'ذكاء وسرعة'},
      {'name': 'حقيقتان وكذبة', 'slug': 'two-truths-and-lie', 'category': 'تواصل وضحك'},
      {'name': 'أتوبيس كومبليت', 'slug': 'autobus-complete', 'category': 'ذكاء وسرعة'},
    ];
  }

  Future<void> _handleCreateRoom() async {
    if (!AuthService.instance.isGameUnlocked(_selectedGameSlug)) {
      GuestLockedModal.show(context, gameTitle: 'هذه اللعبة');
      return;
    }
    setState(() => _isLoadingHost = true);
    HapticFeedback.heavyImpact();

    try {
      final hostName = AuthService.instance.userName.trim().isNotEmpty
          ? AuthService.instance.userName.trim()
          : (ApiService.instance.currentUser?['name']?.toString().trim() ?? '');

      final res = await ApiService.instance.createRoom(
        gameSlug: _selectedGameSlug,
        hostName: hostName.isNotEmpty ? hostName : null,
        totalRounds: _totalRounds,
        roundDurationSeconds: _roundDuration,
      );

      final code = res['room']?['code']?.toString() ?? '';
      final token = res['token']?.toString();

      if (mounted) {
        Navigator.pop(context);
        context.push('/online-room', extra: {
          'code': code,
          'token': token,
          'isHost': true,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHost = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleJoinRoom() async {
    final code = _joinCodeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('رمز الغرفة يجب أن يتكون من 6 أرقام', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final name = _joinNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء كتابة اسمك للدخول', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoadingJoin = true);
    HapticFeedback.heavyImpact();

    try {
      final res = await ApiService.instance.joinRoom(
        code: code,
        playerName: name,
      );

      final token = res['token']?.toString();

      if (mounted) {
        Navigator.pop(context);
        context.push('/online-room', extra: {
          'code': code,
          'token': token,
          'isHost': false,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJoin = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B0E38),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0xFFA35BFF), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'اللعب أونلاين 🌐',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'اختر دورك في اللعبة للبدء مع أصحابك',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: const Color(0xFFCFC6E4),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // شريط التبديل بين المضيف والضيف
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activeTab = 0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _activeTab == 0
                            ? const LinearGradient(colors: [Color(0xFF6A24C9), Color(0xFFA35BFF)])
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: LammaColors.gold500, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'إنشاء غرفة (مضيف 👑)',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _activeTab == 0 ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activeTab = 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _activeTab == 1
                            ? const LinearGradient(colors: [Color(0xFF6A24C9), Color(0xFFA35BFF)])
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, color: Color(0xFF6FD9B5), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'انضمام بكود (لاعب 🚀)',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _activeTab == 1 ? Colors.white : Colors.white60,
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
          const SizedBox(height: 18),

          // المحتوى بناءً على التبويب النشط
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _activeTab == 0 ? _buildHostContent() : _buildJoinContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. اختر اللعبة للتحدي:',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: LammaColors.gold500),
        ),
        const SizedBox(height: 8),

        // قائمة الألعاب
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _displayGames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final game = _displayGames[index];
              final slug = game['slug'] as String;
              final isSel = _selectedGameSlug == slug;
              final isUnlocked = AuthService.instance.isGameUnlocked(slug);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (!isUnlocked) {
                    GuestLockedModal.show(context, gameTitle: game['name'] as String);
                    return;
                  }
                  setState(() => _selectedGameSlug = slug);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 110,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF4A2090)
                        : (isUnlocked ? const Color(0xFF26144D) : const Color(0xFF1B0E38)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel
                          ? LammaColors.gold500
                          : (isUnlocked
                              ? const Color(0xFFA35BFF).withValues(alpha: 0.3)
                              : const Color(0xFFFFD27A).withValues(alpha: 0.3)),
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUnlocked ? Icons.videogame_asset_rounded : Icons.lock_rounded,
                              color: isUnlocked ? LammaColors.gold500 : const Color(0xFFFFD27A),
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              game['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isUnlocked)
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: Icon(Icons.lock_rounded, size: 14, color: Color(0xFFFFD27A)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // عدد الجولات
        Text(
          '2. عدد الجولات:',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: LammaColors.gold500),
        ),
        const SizedBox(height: 6),
        Row(
          children: [5, 10, 15].map((rounds) {
            final isSel = _totalRounds == rounds;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _totalRounds = rounds),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFA35BFF) : const Color(0xFF26144D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? Colors.white : Colors.white24),
                  ),
                  child: Center(
                    child: Text(
                      '$rounds جولات',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // مدة السؤال
        Text(
          '3. وقت كل سؤال:',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: LammaColors.gold500),
        ),
        const SizedBox(height: 6),
        Row(
          children: [15, 20, 30].map((sec) {
            final isSel = _roundDuration == sec;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _roundDuration = sec),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFA35BFF) : const Color(0xFF26144D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? Colors.white : Colors.white24),
                  ),
                  child: Center(
                    child: Text(
                      '$sec ثانية',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        GameButton(
          text: _isLoadingHost ? 'جاري تجهيز الغرفة...' : 'إنشاء الغرفة واستلام الرمز 🚀',
          showArrow: false,
          height: 56,
          onPressed: _isLoadingHost ? () {} : _handleCreateRoom,
        ),
      ],
    );
  }

  Widget _buildJoinContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رمز الغرفة (6 أرقام):',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: LammaColors.gold500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF26144D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4), width: 1.5),
          ),
          child: TextField(
            controller: _joinCodeController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LammaColors.gold500,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              hintText: '784521',
              hintStyle: GoogleFonts.cairo(color: Colors.white24, letterSpacing: 6),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'اسمك في اللعبة:',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: LammaColors.gold500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF26144D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4), width: 1.5),
          ),
          child: TextField(
            controller: _joinNameController,
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'اكتب اسمك أو لقبك...',
              hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 24),

        GameButton(
          text: _isLoadingJoin ? 'جاري التحقق والدخول...' : 'دخول الغرفة والتحدي 🚀',
          showArrow: false,
          height: 56,
          onPressed: _isLoadingJoin ? () {} : _handleJoinRoom,
        ),
      ],
    );
  }
}

