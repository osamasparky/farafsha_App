import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class DrawingGameScreen extends StatefulWidget {
  const DrawingGameScreen({super.key});

  @override
  State<DrawingGameScreen> createState() => _DrawingGameScreenState();
}

class _DrawingGameScreenState extends State<DrawingGameScreen> {
  int _secondsLeft = 48;
  Timer? _timer;
  bool _isWordHidden = false;
  final String _secretWord = 'قطة';

  Color _selectedColor = const Color(0xFF241B35);
  final double _strokeWidth = 5.0;
  bool _isEraser = false;

  final List<List<DrawingPoint>> _strokes = [];
  List<DrawingPoint> _currentStroke = [];

  final List<Color> _palette = const [
    Color(0xFF241B35), // أسود
    Color(0xFFFF8A4C), // برتقاني
    Color(0xFFF2569A), // وردي
    Color(0xFF4FC3F7), // أزرق
    Color(0xFF35B88E), // أخضر
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

  void _openPauseModal() {
    _pauseTimer();
    PauseDialog.show(
      context,
      currentRound: 6,
      totalRounds: 10,
      gameTitle: 'خمن الرسمة',
      gameSlug: 'draw',
      violetScore: 21,
      orangeScore: 17,
      onResume: _resumeTimer,
    );
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [
              Color(0xFF2E4DA8),
              Color(0xFF1C2468),
              Color(0xFF0F1236),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              children: [
                // الشريط العلوي (زر الإيقاف، الكلمة السرية، المؤقت)
                Row(
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
                    const SizedBox(width: 8),

                    // شريط الكلمة المطلوب رسمها
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC24B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFC24B).withValues(alpha: 0.6), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ارسم: ',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFE3A8)),
                            ),
                            Text(
                              _isWordHidden ? '••••' : _secretWord,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFFD27A)),
                            ),
                            IconButton(
                              icon: Icon(
                                _isWordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 18,
                                color: const Color(0xFFFFE3A8),
                              ),
                              onPressed: () {
                                setState(() => _isWordHidden = !_isWordHidden);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // المؤقت
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8138E8), Color(0xFFA35BFF)]),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: LammaColors.gold500, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '0:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // لوحة الرسم التفاعلية
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.4), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Stack(
                        children: [
                          // مساحة الرسم باللمس
                          GestureDetector(
                            onPanStart: (details) {
                              final renderBox = context.findRenderObject() as RenderBox?;
                              if (renderBox != null) {
                                final localPos = details.localPosition;
                                final paint = Paint()
                                  ..color = _isEraser ? const Color(0xFFFFFDF7) : _selectedColor
                                  ..strokeWidth = _isEraser ? 24.0 : _strokeWidth
                                  ..strokeCap = StrokeCap.round;

                                setState(() {
                                  _currentStroke = [DrawingPoint(offset: localPos, paint: paint)];
                                  _strokes.add(_currentStroke);
                                });
                              }
                            },
                            onPanUpdate: (details) {
                              final localPos = details.localPosition;
                              final paint = Paint()
                                ..color = _isEraser ? const Color(0xFFFFFDF7) : _selectedColor
                                ..strokeWidth = _isEraser ? 24.0 : _strokeWidth
                                ..strokeCap = StrokeCap.round;

                              setState(() {
                                _currentStroke.add(DrawingPoint(offset: localPos, paint: paint));
                              });
                            },
                            child: CustomPaint(
                              painter: CanvasPainter(strokes: _strokes),
                              size: Size.infinite,
                            ),
                          ),

                          // بالونات التخمين العائمة أعلى اليسار
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGuessBubble('سارة: كلب؟', Colors.black87, const Color(0xFFEEEAF3)),
                                const SizedBox(height: 4),
                                _buildGuessBubble('منة: أسد؟', Colors.black87, const Color(0xFFEEEAF3)),
                                const SizedBox(height: 4),
                                _buildGuessBubble('كريم قرّب جدًا! 🔥', const Color(0xFF0E2A22), const Color(0xFF6FD9B5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // شريط أدوات الرسم (الألوان + الممحاة والتراجع)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      // الألوان
                      Row(
                        children: _palette.map((color) {
                          final isSelected = !_isEraser && _selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                                _isEraser = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        const BoxShadow(
                                          color: Color(0xFF4FC3F7),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),

                      // زر الممحاة
                      GestureDetector(
                        onTap: () {
                          setState(() => _isEraser = !_isEraser);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isEraser ? const Color(0xFF4FC3F7) : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.cleaning_services_rounded,
                            color: _isEraser ? const Color(0xFF0F1236) : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // زر التراجع
                      GestureDetector(
                        onTap: _undo,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.undo_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // أزرار مسح الكل وخمنوها صح
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _clearCanvas,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Center(
                            child: Text(
                              'مسح الكل',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => context.push('/results'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF4FD1A5), Color(0xFF2E9D7B)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF1A6B52), width: 5),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'خمّنوها صح! ✨',
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0E2A22)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessBubble(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<List<DrawingPoint>> strokes;
  CanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i].offset, stroke[i + 1].offset, stroke[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}
