import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String _selectedMode = 'local'; // 'local' or 'online'

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // زر الرجوع (يشير لليمين في الـ RTL)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                onPressed: () => context.pop(),
              ),
            ),

            const SizedBox(height: 6),

            // عنوان الشاشة
            const Text(
              'اختر طريقة اللعب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(offset: Offset(0, 3), color: Color(0xFF6A24C9))],
              ),
            ),

            const SizedBox(height: 24),

            // كارت اللعب المحلي
            _buildModeCard(
              modeId: 'local',
              title: 'لعبة محلية',
              subtitle: 'على جهاز واحد\nمع أصحابك جنبك',
              imageAsset: 'assets/images/local.png',
            ),

            const SizedBox(height: 18),

            // كارت اللعب أونلاين
            _buildModeCard(
              modeId: 'online',
              title: 'لعبة أونلاين',
              subtitle: 'العب مع أصحابك\nعن بُعد بغرفة ورمز',
              imageAsset: 'assets/images/online.png',
            ),

            const Spacer(),

            // مؤشر الصفحة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(width: 24, height: 8, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), shape: BoxShape.circle)),
              ],
            ),

            const SizedBox(height: 18),

            // زر المتابعة
            GameButton(
              text: 'متابعة',
              onPressed: () {
                if (_selectedMode == 'local') {
                  context.push('/home');
                } else {
                  context.push('/online-room');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String modeId,
    required String title,
    required String subtitle,
    required String imageAsset,
  }) {
    final bool isSelected = _selectedMode == modeId;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = modeId),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(minHeight: 170),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6A33C4), Color(0xFF3E1C82)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E1A5C), Color(0xFF1F1042)],
                    ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isSelected ? LammaColors.violet400 : LammaColors.cardBorder,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: LammaColors.violet500.withValues(alpha: 0.55),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFFEADFFF) : LammaColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  imageAsset,
                  width: 140,
                  height: 130,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // شارة التحديد الخضراء
          if (isSelected)
            Positioned(
              top: -8,
              left: -6,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LammaColors.success,
                  border: Border.all(color: LammaColors.bgDeep, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: LammaColors.success.withValues(alpha: 0.7),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
