import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String _selectedMode = 'local'; // 'local', 'lammah', 'online'

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => context.pop(),
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

              // قائمة كروت الطرق الثلاثة قابلة للتمرير
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. كارت اللعب المحلي (تمرير الهاتف)
                    _buildModeCard(
                      modeId: 'local',
                      title: 'لعبة محلية',
                      subtitle: 'على جهاز واحد بالتناوب\nمع أصحابك جنبك (Pass & Play)',
                      imageAsset: 'assets/images/local.png',
                      badge: 'التناوب الكلاسيكي',
                    ),

                    const SizedBox(height: 14),

                    // 2. كارت طريقة اللمّة (المذيع)
                    _buildModeCard(
                      modeId: 'lammah',
                      title: 'طريقة اللمّة',
                      subtitle: 'واحد معاه الموبايل والميكروفون\nويقرأ الأسئلة للقعدة كلها',
                      imageAsset: 'assets/images/crowd.png',
                      badge: 'الأمتع للقعدة 🎉',
                      highlightColor: const Color(0xFFFF8A4C),
                    ),

                    const SizedBox(height: 14),

                    // 3. كارت اللعب أونلاين
                    _buildModeCard(
                      modeId: 'online',
                      title: 'لعبة أونلاين',
                      subtitle: 'العب مع أصحابك\nعن بُعد بغرفة ورمز سري',
                      imageAsset: 'assets/images/online.png',
                      badge: 'غرف شبكية',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // زر المتابعة
              GameButton(
                text: 'متابعة',
                onPressed: () {
                  if (_selectedMode == 'local') {
                    context.push('/home');
                  } else if (_selectedMode == 'lammah') {
                    _showLammahOptionsSheet(context);
                  } else {
                    context.push('/online-room');
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
    required String badge,
    Color highlightColor = const Color(0xFFA35BFF),
  }) {
    final bool isSelected = _selectedMode == modeId;

    return GestureDetector(
      onTap: () {
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
          color: isSelected ? null : const Color(0xFF1B0E38).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? highlightColor : LammaColors.cardBorder,
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
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // صورة الكارت
            Image.asset(
              imageAsset,
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.group_work_rounded, color: Colors.white, size: 48),
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
                      color: highlightColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: highlightColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD6C8F5),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            // علامة الاختيار
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? highlightColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
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
    {'name': 'فريق البنفسج', 'score': 0, 'color': const Color(0xFFA35BFF)},
    {'name': 'فريق البرتقان', 'score': 0, 'color': const Color(0xFFFF8A4C)},
  ];

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

            // اختيار اللعبة للعبها
            Text(
              'اختر نوع الأسئلة:',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildGameOption('أمثال شعبية', 'amthal-shaabiya', Icons.format_quote_rounded),
                const SizedBox(width: 8),
                _buildGameOption('جمل مشهورة', 'famous-quotes', Icons.movie_filter_rounded),
                const SizedBox(width: 8),
                _buildGameOption('معلومات عامة', 'speed-trivia', Icons.bolt_rounded),
              ],
            ),

            const SizedBox(height: 24),

            // زر ابدأ اللمّة
            GameButton(
              text: 'ابدأ اللمّة الآن 🎤',
              onPressed: () {
                Navigator.pop(context); // إغلاق الشيت
                context.push(
                  '/game/lammah-host',
                  extra: {
                    'gameSlug': _selectedGameSlug,
                    'subMode': _subMode,
                    'teams': _teams,
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

  Widget _buildGameOption(String name, String slug, IconData icon) {
    final bool isSelected = _selectedGameSlug == slug;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGameSlug = slug),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? LammaColors.violet700 : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFFD9C2FF), size: 20),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
