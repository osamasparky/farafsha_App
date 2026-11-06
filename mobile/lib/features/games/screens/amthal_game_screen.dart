import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';

class AmthalGameScreen extends StatefulWidget {
  const AmthalGameScreen({super.key});

  @override
  State<AmthalGameScreen> createState() => _AmthalGameScreenState();
}

class _AmthalGameScreenState extends State<AmthalGameScreen> {
  final int _currentRound = 3;
  final int _totalRounds = 10;
  int _secondsLeft = 20;
  Timer? _timer;
  int? _selectedOptionIndex;
  bool _isAnswered = false;

  final List<Map<String, dynamic>> _players = [
    {'name': 'أحمد', 'score': 20, 'avatar': 'assets/images/av-ahmed.png', 'isLeader': true},
    {'name': 'سارة', 'score': 15, 'avatar': 'assets/images/av-sara.png', 'isLeader': false},
    {'name': 'محمود', 'score': 10, 'avatar': 'assets/images/av-mahmoud.png', 'isLeader': false},
    {'name': 'منة', 'score': 10, 'avatar': 'assets/images/av-mena.png', 'isLeader': false},
  ];

  final String _prompt = 'اللي اختشوا …';
  final List<String> _options = ['ماتوا', 'هربوا', 'سكتوا'];
  final int _correctOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        setState(() => _isAnswered = true);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    if (_secondsLeft > 0 && !_isAnswered) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onSelectOption(int index) {
    if (_isAnswered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
      if (index == _correctOptionIndex) {
        _players[0]['score'] += 3;
      }
    });
  }

  void _openPauseModal() {
    _pauseTimer();
    PauseDialog.show(
      context,
      currentRound: _currentRound,
      totalRounds: _totalRounds,
      violetScore: 14,
      orangeScore: 11,
      onResume: _resumeTimer,
      onRestartRound: () {
        setState(() {
          _secondsLeft = 20;
          _selectedOptionIndex = null;
          _isAnswered = false;
        });
        _startTimer();
      },
    );
  }

  void _onNext() {
    if (_currentRound < _totalRounds) {
      context.push('/handoff');
    } else {
      context.push('/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
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
                // الشريط العلوي (زر الإيقاف، رقم الجولة، المؤقت)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _openPauseModal,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'الجولة $_currentRound من $_totalRounds',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8138E8), Color(0xFFA35BFF)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA35BFF).withValues(alpha: 0.5),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: LammaColors.gold500, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '00:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // شريط اللاعبين الأربعة والنقاط
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _players.map((p) {
                    final bool isLeader = p['isLeader'] == true;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLeader)
                          const Icon(Icons.workspace_premium_rounded, color: LammaColors.gold500, size: 20)
                        else
                          const SizedBox(height: 20),
                        Container(
                          width: isLeader ? 56 : 52,
                          height: isLeader ? 56 : 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLeader ? LammaColors.gold500 : const Color(0xFFB98AFF),
                              width: 3,
                            ),
                            boxShadow: isLeader
                                ? [
                                    BoxShadow(
                                      color: LammaColors.gold500.withValues(alpha: 0.55),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              p['avatar'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['name'] as String,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          '${p['score']}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isLeader ? LammaColors.gold500 : const Color(0xFFD9C2FF),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // بطاقة المثل الشعبي التراثية البردية
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1850),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'كمّل المثل الشعبي',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF6E3B8), Color(0xFFE8C98A)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFB88746), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8C5A1E).withValues(alpha: 0.35),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _prompt,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E2410),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // خيارات الإجابة
                Expanded(
                  child: ListView.separated(
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedOptionIndex == index;
                      return GestureDetector(
                        onTap: () => _onSelectOption(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xFF6A24C9), Color(0xFF8138E8)])
                                : null,
                            color: isSelected ? null : const Color(0xFF2A1850),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC9A2FF)
                                  : const Color(0xFFA35BFF).withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFA35BFF).withValues(alpha: 0.55),
                                      blurRadius: 18,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _options[index],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF2E9D7B),
                                  ),
                                  child: const Icon(Icons.check, size: 18, color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // زر التالي (ينتقل للجولة التالية أو شاشة النتائج)
                GestureDetector(
                  onTap: _onNext,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFB98AFF), Color(0xFF7A2FE0)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF4A1690), width: 5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA35BFF).withValues(alpha: 0.55),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'التالي',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
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
