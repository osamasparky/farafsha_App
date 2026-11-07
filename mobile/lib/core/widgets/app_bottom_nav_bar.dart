import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';

/// الشريط السفلي الموحد للتطبيق بأربع أيقونات فقط:
/// 1. الرئيسية
/// 2. طريقة اللعب
/// 3. الترتيب
/// 4. الملف
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF130924),
        border: Border(top: BorderSide(color: Color(0xFF2E1C55), width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_filled,
                label: 'الرئيسية',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.sports_esports_rounded,
                label: 'طريقة اللعب',
                index: 1,
                route: '/mode-selection',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.leaderboard_rounded,
                label: 'الترتيب',
                index: 2,
                route: '/leaderboard',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_rounded,
                label: 'الملف',
                index: 3,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required String route,
  }) {
    final bool isSelected = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SettingsService.instance.triggerHaptic();
            SoundService.instance.playClick();
            context.go(route);
          },
          splashColor: const Color(0xFFB98AFF).withOpacity(0.2),
          highlightColor: const Color(0xFFB98AFF).withOpacity(0.1),
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2D1658) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFFB98AFF) : const Color(0xFF8B7AA8),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF8B7AA8),
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

