import 'dart:math' as math;
import 'package:flutter/material.dart';

class LammaWordmark extends StatelessWidget {
  final double fontSize;
  final bool showConfetti;

  const LammaWordmark({
    super.key,
    this.fontSize = 110.0,
    this.showConfetti = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fontSize * 2.3,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // كنز البهارج والقصاصات المتناثرة (Confetti)
          if (showConfetti) ...[
            Positioned(
              top: 25,
              right: 18,
              child: Transform.rotate(
                angle: 30 * math.pi / 180,
                child: Container(
                  width: 9,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2569A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 25,
              right: 6,
              child: Transform.rotate(
                angle: 45 * math.pi / 180,
                child: Container(
                  width: 13,
                  height: 13,
                  color: const Color(0xFFFFC24B),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Transform.rotate(
                angle: 45 * math.pi / 180,
                child: Container(
                  width: 11,
                  height: 11,
                  color: const Color(0xFFFF8A4C),
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 10,
              child: Transform.rotate(
                angle: -25 * math.pi / 180,
                child: Container(
                  width: 8,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB98AFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],

          // التاج الملكي المائل
          Positioned(
            top: -fontSize * 0.28,
            left: fontSize * 0.65,
            child: Transform.rotate(
              angle: -12 * math.pi / 180,
              child: CustomPaint(
                size: Size(fontSize * 0.62, fontSize * 0.44),
                painter: _CrownPainter(),
              ),
            ),
          ),

          // كلمة "لمّة" مع تأثيرات التجسيم والظلال
          Text(
            'لمّة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: Colors.white,
              height: 1.15,
              shadows: const [
                // تحديد وردي بارز
                Shadow(offset: Offset(3, 0), color: Color(0xFFF2569A)),
                Shadow(offset: Offset(-3, 0), color: Color(0xFFF2569A)),
                Shadow(offset: Offset(0, 3), color: Color(0xFFF2569A)),
                Shadow(offset: Offset(0, -3), color: Color(0xFFF2569A)),
                Shadow(offset: Offset(2.5, 2.5), color: Color(0xFFF2569A)),
                Shadow(offset: Offset(-2.5, 2.5), color: Color(0xFFF2569A)),
                // عمق ثلاثي الأبعاد بنفسجي
                Shadow(offset: Offset(0, 8), color: Color(0xFF6A24C9)),
                Shadow(offset: Offset(0, 14), color: Color(0xFF3E1585)),
                Shadow(offset: Offset(0, 22), color: Color(0x66000000)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFFC24B)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFC98A12)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.35)
      ..lineTo(size.width * 0.28, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.1)
      ..lineTo(size.width * 0.72, size.height * 0.6)
      ..lineTo(size.width * 0.92, size.height * 0.35)
      ..lineTo(size.width * 0.82, size.height * 0.92)
      ..lineTo(size.width * 0.18, size.height * 0.92)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // كرات التاج الثلاثة
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.3), 4.5, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.3), 4.5, strokePaint);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.07), 4.5, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.07), 4.5, strokePaint);

    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.3), 4.5, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.3), 4.5, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
