import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _dialect = 'مصري';
  bool _darkMode = true;
  bool _soundEffects = true;
  bool _vibration = true;
  bool _reduceMotion = false;
  bool _familyMode = false;

  void _showDialectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LammaColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: LammaColors.cardBorder, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'اختر لهجة المحتوى',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ...['مصري', 'خليجي', 'شامي', 'مغاربي'].map(
              (d) => ListTile(
                title: Text(d, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                trailing: _dialect == d ? const Icon(Icons.check_circle_rounded, color: LammaColors.gold500) : null,
                onTap: () {
                  setState(() => _dialect = d);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
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
                    'الإعدادات',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 16),

              // قسم التفضيلات
              _buildSectionHeader('التفضيلات'),
              _buildCardContainer([
                _buildActionRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'لهجة المحتوى',
                  trailingText: _dialect,
                  onTap: _showDialectSheet,
                  hasDivider: true,
                ),
                _buildSwitchRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'الوضع الليلي',
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
              ]),

              const SizedBox(height: 16),

              // قسم الصوت والحركة
              _buildSectionHeader('الصوت والحركة'),
              _buildCardContainer([
                _buildSwitchRow(
                  icon: Icons.volume_up_outlined,
                  title: 'المؤثرات الصوتية',
                  value: _soundEffects,
                  onChanged: (v) => setState(() => _soundEffects = v),
                  hasDivider: true,
                ),
                _buildSwitchRow(
                  icon: Icons.vibration_rounded,
                  title: 'الاهتزاز مع المؤقت',
                  value: _vibration,
                  onChanged: (v) => setState(() => _vibration = v),
                  hasDivider: true,
                ),
                _buildSwitchRow(
                  icon: Icons.motion_photos_off_outlined,
                  title: 'تقليل الحركة',
                  value: _reduceMotion,
                  onChanged: (v) => setState(() => _reduceMotion = v),
                ),
              ]),

              const SizedBox(height: 16),

              // قسم المحتوى
              _buildSectionHeader('المحتوى'),
              _buildCardContainer([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFFC9A2FF), size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الوضع العائلي',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              'يخفي المحتوى غير المناسب للعيلة',
                              style: TextStyle(fontSize: 12, color: Color(0xFFA99BC8), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _familyMode,
                        activeThumbColor: LammaColors.gold500,
                        onChanged: (v) => setState(() => _familyMode = v),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // قسم الحساب
              _buildSectionHeader('الحساب'),
              _buildCardContainer([
                _buildActionRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'الإشعارات',
                  trailingText: '',
                  onTap: () => context.push('/notifications'),
                  hasDivider: true,
                ),
                _buildActionRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'الخصوصية والبيانات',
                  trailingText: '',
                  onTap: () {},
                  hasDivider: true,
                ),
                _buildActionRow(
                  icon: Icons.help_outline_rounded,
                  title: 'المساعدة والتواصل',
                  trailingText: '',
                  onTap: () {},
                  hasDivider: true,
                ),
                InkWell(
                  onTap: () => context.go('/login'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFFF8FA0), size: 22),
                        SizedBox(width: 12),
                        Text(
                          'تسجيل الخروج',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFFF8FA0)),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'لمّة — الإصدار 1.0.0',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA99BC8)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFC9A2FF)),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String trailingText,
    required VoidCallback onTap,
    bool hasDivider = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFC9A2FF), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                if (trailingText.isNotEmpty) ...[
                  Text(trailingText, style: const TextStyle(color: LammaColors.gold500, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCFC6E4), size: 14),
              ],
            ),
          ),
        ),
        if (hasDivider) Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool hasDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFC9A2FF), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              Switch(
                value: value,
                activeThumbColor: LammaColors.gold500,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (hasDivider) Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }
}
