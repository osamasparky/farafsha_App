import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  List<Map<String, dynamic>> _dialects = [];
  bool _isLoadingDialects = false;

  @override
  void initState() {
    super.initState();
    _loadDialects();
  }

  Future<void> _loadDialects() async {
    setState(() => _isLoadingDialects = true);
    final list = await ApiService.instance.getDialects();
    if (mounted) {
      setState(() {
        _dialects = list;
        _isLoadingDialects = false;
      });
    }
  }

  void _showDialectSheet() {
    SoundService.instance.playClick();
    final isDark = _settings.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C0D38) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: isDark ? const Color(0xFFA35BFF) : const Color(0xFF8B42FC), width: 2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر لهجة المحتوى 🗣️',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF241050),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                ),
              ],
            ),
            Text(
              'يتم التحكم بجميع اللهجات من لوحة التحكم',
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 16),
            if (_isLoadingDialects)
              const Center(child: CircularProgressIndicator(color: LammaColors.violet500))
            else
              ..._dialects.map(
                (d) {
                  final name = d['name']?.toString() ?? '';
                  final icon = d['icon']?.toString() ?? '🌐';
                  final isSelected = _settings.dialect == name;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF4A1E9A) : const Color(0xFFE9DCFC))
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F5FA)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (isDark ? LammaColors.gold500 : const Color(0xFF8B42FC)) : (isDark ? Colors.white10 : const Color(0xFFE8E0F2)),
                      ),
                    ),
                    child: ListTile(
                      leading: Text(icon, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        name,
                        style: GoogleFonts.cairo(
                          color: isDark ? Colors.white : const Color(0xFF241050),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: LammaColors.gold500) : null,
                      onTap: () {
                        _settings.setDialect(name);
                        _settings.triggerHaptic();
                        SoundService.instance.playClick();
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPageContentModal(String slug, String defaultTitle) async {
    SoundService.instance.playClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: ApiService.instance.getPage(slug),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data;
            final title = data?['title']?.toString() ?? defaultTitle;
            final content = data?['content']?.toString() ?? 'جاري تحميل المحتوى من السيرفر...';

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF1A0C35),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: Color(0xFFA35BFF), width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: LammaColors.violet500))
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              content,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: const Color(0xFFE2D9F3),
                                height: 1.6,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showContactInfoModal() async {
    SoundService.instance.playClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: ApiService.instance.getContactInfo(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final meta = data?['meta'] as Map<String, dynamic>? ?? {};
            final email = meta['email']?.toString() ?? 'support@lammah.app';
            final whatsapp = meta['whatsapp']?.toString() ?? '+201000000000';
            final phone = meta['phone']?.toString() ?? '+201200000000';

            return Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF1A0C35),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: Color(0xFFA35BFF), width: 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'التواصل والدعم الفني 🎧',
                      style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  Center(
                    child: Text(
                      'يسعدنا الرد على استفساراتك ومقترحاتك مباشرة',
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // زر واتساب
                  _buildContactCard(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366),
                    title: 'واتساب الدعم المباشر',
                    subtitle: whatsapp,
                    onTap: () async {
                      final cleanPhone = whatsapp.replaceAll('+', '').replaceAll(' ', '');
                      final uri = Uri.parse('https://wa.me/$cleanPhone');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),

                  const SizedBox(height: 10),

                  // زر البريد الإلكتروني
                  _buildContactCard(
                    icon: Icons.mail_outline_rounded,
                    color: const Color(0xFF38B6FF),
                    title: 'البريد الإلكتروني',
                    subtitle: email,
                    onTap: () async {
                      final uri = Uri.parse('mailto:$email');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                  ),

                  const SizedBox(height: 10),

                  // زر الهاتف
                  _buildContactCard(
                    icon: Icons.phone_rounded,
                    color: LammaColors.orange500,
                    title: 'الاتصال الهاتفي',
                    subtitle: phone,
                    onTap: () async {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountDeletionDialog(BuildContext context) {
    SoundService.instance.playClick();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF241050),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            title: Text(
              'حذف الحساب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'هل أنت متأكد من رغبتك في حذف الحساب؟',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFFE0D4F7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final res = await AuthService.instance.requestAccountDeletion();

                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);

                        if (res['success'] == true) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تقديم طلب حذف الحساب بنجاح',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: const Color(0xFFE53935),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.go('/login');
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                res['message']?.toString() ?? 'حدث خطأ أثناء تقديم الطلب.',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: const Color(0xFFD2566A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'حذف الحساب',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E0E3E);
        final secondaryTextColor = isDark ? const Color(0xFFC7BAE3) : const Color(0xFF6B4AA8);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF150A2E) : const Color(0xFFF6F4FB),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const RadialGradient(
                      center: Alignment(0.0, -0.75),
                      radius: 1.0,
                      colors: [
                        Color(0xFF4A2290),
                        Color(0xFF241050),
                        Color(0xFF150A2E),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFEDE5FB),
                        Color(0xFFF7F4FD),
                        Colors.white,
                      ],
                    ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                children: [
                  // الشريط العلوي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios_rounded, color: primaryTextColor, size: 22),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'الإعدادات ⚙️',
                        style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: primaryTextColor),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 1. قسم التفضيلات (يظهر فقط إذا كانت اللهجات مفعلة ومتعددة في لوحة التحكم)
                  if (_dialects.length > 1) ...[
                    _buildSectionHeader('التفضيلات والمحتوى', secondaryTextColor),
                    _buildCardContainer([
                      _buildActionRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'لهجة المحتوى',
                        trailingText: _settings.dialect,
                        onTap: _showDialectSheet,
                        hasDivider: false,
                        isDark: isDark,
                      ),
                    ], isDark),
                    const SizedBox(height: 16),
                  ],

                  // 2. قسم الصوت والاهتزاز
                  _buildSectionHeader('الصوت والحركة', secondaryTextColor),
                  _buildCardContainer([
                    _buildSwitchRow(
                      icon: Icons.volume_up_outlined,
                      title: 'المؤثرات الصوتية',
                      value: _settings.soundEffects,
                      onChanged: (v) {
                        _settings.setSoundEffects(v);
                        if (v) SoundService.instance.playClick();
                      },
                      hasDivider: true,
                      isDark: isDark,
                    ),
                    _buildSwitchRow(
                      icon: Icons.vibration_rounded,
                      title: 'الاهتزاز مع المؤقت والأزرار',
                      value: _settings.vibration,
                      onChanged: (v) {
                        _settings.setVibration(v);
                        if (v) _settings.triggerHaptic(isHeavy: true);
                      },
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 16),

                  // 3. قسم المحتوى والعائلة
                  _buildSectionHeader('خيارات اللعب', secondaryTextColor),
                  _buildCardContainer([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: isDark ? const Color(0xFFC9A2FF) : const Color(0xFF7A3FE0), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الوضع العائلي',
                                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: primaryTextColor),
                                ),
                                Text(
                                  'يخفي المحتوى غير المناسب للقعدة العائلية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFFA99BC8) : const Color(0xFF6B4AA8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _settings.familyMode,
                            activeColor: LammaColors.gold500,
                            onChanged: (v) {
                              _settings.setFamilyMode(v);
                              _settings.triggerHaptic();
                            },
                          ),
                        ],
                      ),
                    ),
                  ], isDark),

                  const SizedBox(height: 16),

                  // 4. الدعم والصفحات والمعلومات
                  _buildSectionHeader('الدعم والخصوصية (من لوحة التحكم)', secondaryTextColor),
                  _buildCardContainer([
                    _buildActionRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'التنبيهات والإشعارات',
                      trailingText: '',
                      onTap: () => context.push('/notifications'),
                      hasDivider: true,
                      isDark: isDark,
                    ),
                    _buildActionRow(
                      icon: Icons.help_outline_rounded,
                      title: 'المساعدة والأسئلة الشائعة',
                      trailingText: '',
                      onTap: () => _showPageContentModal('faq-help', 'المساعدة والأسئلة الشائعة'),
                      hasDivider: true,
                      isDark: isDark,
                    ),
                    _buildActionRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'سياسة الخصوصية',
                      trailingText: '',
                      onTap: () => _showPageContentModal('privacy-policy', 'سياسة الخصوصية'),
                      hasDivider: true,
                      isDark: isDark,
                    ),
                    _buildActionRow(
                      icon: Icons.gavel_rounded,
                      title: 'الشروط والأحكام',
                      trailingText: '',
                      onTap: () => _showPageContentModal('terms-conditions', 'الشروط والأحكام'),
                      hasDivider: true,
                      isDark: isDark,
                    ),
                    _buildActionRow(
                      icon: Icons.support_agent_rounded,
                      title: 'تواصل معنا والدعم الفني',
                      trailingText: '',
                      onTap: _showContactInfoModal,
                      hasDivider: false,
                      isDark: isDark,
                    ),
                  ], isDark),

                  // 5. قسم إدارة الحساب (يظهر فقط إذا كان المستخدم مسجلاً وليس زائراً)
                  if (AuthService.instance.isLoggedIn && !AuthService.instance.isGuest) ...[
                    const SizedBox(height: 18),
                    _buildSectionHeader('إدارة الحساب', isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F)),
                    _buildCardContainer([
                      _buildActionRow(
                        icon: Icons.delete_outline_rounded,
                        title: 'حذف الحساب',
                        trailingText: '',
                        onTap: () => _showAccountDeletionDialog(context),
                        hasDivider: false,
                        isDark: isDark,
                      ),
                    ], isDark),
                  ],

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'تطبيق لمّـة v2.0 · إصدار الإنتاج',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241050) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? LammaColors.cardBorder : const Color(0xFFE5DBF5)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF5A2A9E).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
    required bool isDark,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1E0E3E);
    final iconColor = isDark ? const Color(0xFFC9A2FF) : const Color(0xFF7A3FE0);
    final dividerColor = isDark ? const Color(0xFF331B68) : const Color(0xFFF0EAFC);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor, size: 22),
          title: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText.isNotEmpty)
                Text(
                  trailingText,
                  style: GoogleFonts.cairo(fontSize: 13, color: LammaColors.gold500, fontWeight: FontWeight.w800),
                ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black26),
            ],
          ),
        ),
        if (hasDivider) Divider(color: dividerColor, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool hasDivider = false,
    required bool isDark,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1E0E3E);
    final iconColor = isDark ? const Color(0xFFC9A2FF) : const Color(0xFF7A3FE0);
    final dividerColor = isDark ? const Color(0xFF331B68) : const Color(0xFFF0EAFC);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor)),
              ),
              Switch(
                value: value,
                activeColor: LammaColors.gold500,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (hasDivider) Divider(color: dividerColor, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
