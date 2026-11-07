import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';

class TabooGameScreen extends StatefulWidget {
  const TabooGameScreen({super.key});

  @override
  State<TabooGameScreen> createState() => _TabooGameScreenState();
}

class _TabooGameScreenState extends State<TabooGameScreen> {
  int _secondsLeft = 32;
  final int _totalSeconds = 60;
  Timer? _timer;
  int _correctCount = 4;
  int _foulCount = 1;
  int _skipsLeft = 2;

  final String _mainWord = 'مكرونة بشاميل';
  final List<String> _forbiddenWords = [
    'فرن',
    'جبنة',
    'صينية',
    'لحمة مفرومة',
    'مكرونة',
  ];

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
        context.push('/results');
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    if (_secondsLeft > 0) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCorrect() {
    HapticFeedback.heavyImpact();
    setState(() {
      _correctCount++;
    });
  }

  void _onFoul() {
    HapticFeedback.vibrate();
    setState(() {
      _foulCount++;
    });
  }

  void _onSkip() {
    if (_skipsLeft > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _skipsLeft--;
      });
    }
  }

  void _openPauseModal() {
    _pauseTimer();
    PauseDialog.show(
      context,
      currentRound: 4,
      totalRounds: 10,
      gameTitle: 'ممنوع تقول',
      gameSlug: 'taboo',
      violetScore: 18,
      orangeScore: 14,
      onResume: _resumeTimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _secondsLeft / _totalSeconds;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [
              Color(0xFF3A2CA0),
              Color(0xFF201460),
              Color(0xFF120A30),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // الشريط العلوي (زر الإيقاف + من يشرح)
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
                      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA35BFF).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFB98AFF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: AssetImage('assets/images/av-ahmed.png'),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'أحمد بيشرح · البنفسج',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 16),

                // صف العداد والإحصائيات
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // عداد الصح
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_correctCount',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF6FD9B5)),
                        ),
                        const Text(
                          'صح',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCFC6E4)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // الدائرة التنازلية
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFF1A0F40),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9E4C)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_secondsLeft',
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const Text(
                                'ثانية',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCFC6E4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // عداد المخالفات
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_foulCount',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFFF8FA0)),
                        ),
                        const Text(
                          'مخالفة',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCFC6E4)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // كارت التابو المائل (تصميم الكارت الحقيقي)
                Transform.rotate(
                  angle: -0.02,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA35BFF).withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // رأس الكارت البنفسجي مع الكلمة الرئيسية
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6A5AF0), Color(0xFF3B2CB0)],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'اشرح الكلمة دي',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDCD6FF)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _mainWord,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // قائمة الكلمات الممنوعة باللون الوردي
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.block_rounded, color: Color(0xFFA3264F), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'ممنوع تقول:',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFA3264F),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ..._forbiddenWords.map(
                                (word) => Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE3EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      word,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8E1F4E),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // صف أزرار التحكم (تخطي، قال ممنوعة، صح!)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // زر تخطي
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _skipsLeft > 0 ? _onSkip : null,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                              const SizedBox(height: 2),
                              Text(
                                'تخطي ($_skipsLeft)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر قال ممنوعة (مخالفة)
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _onFoul,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFE0566B), Color(0xFFB23A50)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF7A2236), width: 5),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, color: Colors.white, size: 24),
                              SizedBox(height: 2),
                              Text(
                                'قال ممنوعة',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر صح! (الكبير والأخضر)
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _onCorrect,
                        child: Container(
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF4FD1A5), Color(0xFF2E9D7B)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF1A6B52), width: 6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4FD1A5).withValues(alpha: 0.45),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, color: Color(0xFF0E2A22), size: 30),
                              SizedBox(height: 2),
                              Text(
                                'صح!',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0E2A22)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
