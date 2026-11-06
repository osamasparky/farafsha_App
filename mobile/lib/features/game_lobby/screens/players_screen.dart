import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class PlayersScreen extends StatefulWidget {
  final String targetRoute;
  const PlayersScreen({super.key, this.targetRoute = '/game/amthal'});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  bool _isTeamsMode = true;
  final TextEditingController _newPlayerController = TextEditingController();

  final List<Map<String, String>> _teamViolet = [
    {'name': 'أحمد', 'avatar': 'assets/images/av-ahmed.png'},
    {'name': 'سارة', 'avatar': 'assets/images/av-sara.png'},
    {'name': 'كريم', 'avatar': 'assets/images/av-karim.png'},
  ];

  final List<Map<String, String>> _teamOrange = [
    {'name': 'منة', 'avatar': 'assets/images/av-mena.png'},
    {'name': 'محمود', 'avatar': 'assets/images/av-mahmoud.png'},
  ];

  @override
  void dispose() {
    _newPlayerController.dispose();
    super.dispose();
  }

  void _shuffleTeams() {
    setState(() {
      final all = [..._teamViolet, ..._teamOrange]..shuffle();
      final half = (all.length / 2).ceil();
      _teamViolet.clear();
      _teamOrange.clear();
      _teamViolet.addAll(all.sublist(0, half));
      _teamOrange.addAll(all.sublist(half));
    });
  }

  void _addNewPlayer() {
    final text = _newPlayerController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final newP = {'name': text, 'avatar': 'assets/images/av-ahmed.png'};
      if (_teamViolet.length <= _teamOrange.length) {
        _teamViolet.add(newP);
      } else {
        _teamOrange.add(newP);
      }
      _newPlayerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  'مين بيلعب؟',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded, color: LammaColors.gold500, size: 24),
                  onPressed: _shuffleTeams,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // زر التبديل بين نمط الفرق والفردي
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LammaColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isTeamsMode = true),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: _isTeamsMode ? LammaGradients.ctaSecondary : null,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: _isTeamsMode
                              ? [BoxShadow(color: LammaColors.violet500.withValues(alpha: 0.55), blurRadius: 16)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'فرق',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _isTeamsMode ? FontWeight.w900 : FontWeight.w700,
                              color: _isTeamsMode ? Colors.white : const Color(0xFFCFC6E4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isTeamsMode = false),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: !_isTeamsMode ? LammaGradients.ctaSecondary : null,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text(
                            'فردي بالتناوب',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: !_isTeamsMode ? FontWeight.w900 : FontWeight.w700,
                              color: !_isTeamsMode ? Colors.white : const Color(0xFFCFC6E4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // كارت فريق البنفسج
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8F3BD0).withValues(alpha: 0.45),
                    const Color(0xFF4A1E9A).withValues(alpha: 0.35),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LammaColors.violet400, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(color: LammaColors.violet400, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 8),
                          const Text('فريق البنفسج', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                      Text('${_teamViolet.length} لاعبين', style: const TextStyle(fontSize: 13, color: Color(0xFFEADFFF), fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _teamViolet.map((p) => _buildPlayerChip(p, () => setState(() => _teamViolet.remove(p)))).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // كارت فريق البرتقان
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LammaColors.orange500.withValues(alpha: 0.35),
                    LammaColors.pink500.withValues(alpha: 0.25),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF9E6A), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFFFF9E6A), borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 8),
                          const Text('فريق البرتقان', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                      Text('${_teamOrange.length} لاعبين', style: const TextStyle(fontSize: 13, color: Color(0xFFFFE3D2), fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _teamOrange.map((p) => _buildPlayerChip(p, () => setState(() => _teamOrange.remove(p)))).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // حقل إضافة لاعب جديد
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LammaColors.cardBorder, width: 1.5),
                    ),
                    child: TextField(
                      controller: _newPlayerController,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'اسم لاعب جديد',
                        hintStyle: TextStyle(color: Color(0xFFA99BC8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addNewPlayer,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: LammaGradients.ctaSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(bottom: BorderSide(color: Color(0xFF4A1690), width: 4)),
                    ),
                    child: const Center(
                      child: Text('+ إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('من 4 لـ 12 لاعب. الاسم بيتحفظ على الجهاز بس.', style: TextStyle(fontSize: 12, color: Color(0xFFA99BC8))),

            const Spacer(),

            // زر ابدأ الجولة (ينتقل لشاشة تسليم الهاتف 19-Handoff)
            GameButton(
              text: 'ابدأ الجولة',
              onPressed: () {
                context.push('/handoff', extra: widget.targetRoute);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerChip(Map<String, String> player, VoidCallback onRemove) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundImage: AssetImage(player['avatar']!),
          ),
          const SizedBox(width: 8),
          Text(player['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFCFC6E4)),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
