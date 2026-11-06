import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final List<String> _avatars = [
    'assets/images/av-sara.png',
    'assets/images/av-karim.png',
    'assets/images/av-ahmed.png',
    'assets/images/av-mena.png',
    'assets/images/av-mahmoud.png',
  ];

  int _selectedAvatarIndex = 2; // Default: Ahmed
  final TextEditingController _nameController = TextEditingController(text: 'أسامة');
  String _selectedDialect = 'مصري';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                  onPressed: () => context.pop(),
                ),
                const Text(
                  'خطوة أخيرة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFD9CCF2)),
                ),
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 6),

            const Text(
              'اعمل شخصيتك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // الصورة الكبيرة المختارة مع التاج والوهج الذهبي
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: LammaColors.gold500, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: LammaColors.gold500.withValues(alpha: 0.4),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(_avatars[_selectedAvatarIndex]),
                    ),
                  ),
                  Positioned(
                    top: -24,
                    child: Transform.rotate(
                      angle: -8 * 3.14159 / 180,
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFC24B),
                        size: 40,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // خيارات الأفاتار الخمسة للاختيار
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_avatars.length, (index) {
                final bool isSelected = _selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? LammaColors.gold500 : LammaColors.cardBorder,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.5), blurRadius: 12),
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(_avatars[index]),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            const Text(
              'اسمك في اللعب',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
            ),
            const SizedBox(height: 8),

            Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LammaColors.violet400, width: 2),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'لهجة المحتوى المفضلة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
            ),
            const SizedBox(height: 8),

            // خيارات اللهجة الثلاثية
            Row(
              children: [
                _buildDialectButton('مصري'),
                const SizedBox(width: 8),
                _buildDialectButton('خليجي'),
                const SizedBox(width: 8),
                _buildDialectButton('عربي عام'),
              ],
            ),

            const SizedBox(height: 36),

            GameButton(
              text: 'يلا نلعب',
              onPressed: () {
                context.push('/home');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDialectButton(String title) {
    final bool isSelected = _selectedDialect == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDialect = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isSelected ? null : Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? LammaColors.violet400 : LammaColors.cardBorder,
              width: isSelected ? 2 : 1.2,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFFEADFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
