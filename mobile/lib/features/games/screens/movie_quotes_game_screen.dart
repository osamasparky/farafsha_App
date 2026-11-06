import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';

class MovieQuotesGameScreen extends StatefulWidget {
  const MovieQuotesGameScreen({super.key});

  @override
  State<MovieQuotesGameScreen> createState() => _MovieQuotesGameScreenState();
}

class _MovieQuotesGameScreenState extends State<MovieQuotesGameScreen> {
  final int _currentRound = 5;
  final int _totalRounds = 10;
  int _secondsLeft = 15;
  Timer? _timer;
  int? _selectedChoiceIndex;
  bool _isAnswered = false;

  final String _categoryTag = 'فيلم كوميدي · التسعينات';
  final String _quote = '«إنت فاكرني مين؟\nأنا …»';
  final List<String> _options = [
    'اللي ما بيتنسيش',
    'ابن البلد الجدع',
    'صاحب الحق',
  ];
  final int _correctIndex = 0;

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

  void _onSelectChoice(int index) {
    if (_isAnswered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedChoiceIndex = index;
      _isAnswered = true;
      if (index == _correctIndex) {
        // إجابة صحيحة
      }
    });
  }

  void _openPauseModal() {
    _pauseTimer();
    PauseDialog.show(
      context,
      currentRound: _currentRound,
      totalRounds: _totalRounds,
      violetScore: 16,
      orangeScore: 12,
      onResume: _resumeTimer,
      onRestartRound: () {
        setState(() {
          _secondsLeft = 15;
          _selectedChoiceIndex = null;
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
            center: Alignment(0.0, -0.44),
            radius: 1.0,
            colors: [
              Color(0xFF5E1F7A),
              Color(0xFF2A0F4A),
              Color(0xFF12071F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    // الشريط العلوي (زر الإيقاف، الجولة، العداد)
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // عنوان اللعبة
                    const Text(
                      'كمّل الجملة المشهورة',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // كارت إطار السينما والفيلم الذهبي
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0B2C),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: LammaColors.gold500, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: LammaColors.gold500.withValues(alpha: 0.35),
                            blurRadius: 30,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            center: Alignment(0.0, -1.0),
                            radius: 1.2,
                            colors: [Color(0xFF3E2380), Color(0xFF1F0F42)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: LammaColors.gold500,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _categoryTag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2A0E35),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _quote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // خيارات الإجابة
                    Expanded(
                      child: ListView.separated(
                        itemCount: _options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedChoiceIndex == index;
                          return GestureDetector(
                            onTap: () => _onSelectChoice(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(colors: [Color(0xFF6A24C9), Color(0xFF8138E8)])
                                    : null,
                                color: isSelected ? null : const Color(0xFF2A1850),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFC9A2FF)
                                      : const Color(0xFFA35BFF).withValues(alpha: 0.35),
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
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
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
                                        color: Color(0xFF35B88E),
                                      ),
                                      child: const Icon(Icons.check, size: 16, color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // زر التالي
                    GestureDetector(
                      onTap: _onNext,
                      child: Container(
                        height: 60,
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

                // صورة الفشار العائمة أسفل اليسار
                Positioned(
                  left: -12,
                  bottom: 74,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/popcorn.png',
                      width: 125,
                      height: 105,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
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
