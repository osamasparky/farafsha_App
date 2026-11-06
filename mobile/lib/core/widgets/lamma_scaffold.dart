import 'package:flutter/material.dart';
import '../theme/lamma_theme.dart';

/// الحاوية الأساسية لشاشات لمّة
/// توفر خلفية التدرج الشعاعي (Radial Gradient) مع كرات الضوء البوكيه (Bokeh Blobs)
class LammaScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showBokeh;
  final EdgeInsetsGeometry? padding;

  const LammaScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showBokeh = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LammaColors.bgDeep,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // 1. التدرج الشعاعي الكوني المعتمد في نظام التصميم
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.15,
                  colors: [
                    Color(0xFF5A2A9E), // توهج بنفسجي علوي
                    Color(0xFF2E1660), // بنفسجي غامق وسطي
                    Color(0xFF170B30), // بنفسجي داكن سفلي
                  ],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
          ),

          // 2. كرات الضوء والبوكيه الحيوية (Bokeh Glow Blobs)
          if (showBokeh) ...[
            Positioned(
              top: 40,
              right: 40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LammaColors.violet500.withValues(alpha: 0.35),
                  boxShadow: [
                    BoxShadow(
                      color: LammaColors.violet500.withValues(alpha: 0.45),
                      blurRadius: 70,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 300,
              left: 20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LammaColors.orange300.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: LammaColors.orange300.withValues(alpha: 0.35),
                      blurRadius: 50,
                      spreadRadius: 15,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 360,
              right: 10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LammaColors.pink500.withValues(alpha: 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: LammaColors.pink500.withValues(alpha: 0.3),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3. المحتوى الفعلي
          SafeArea(
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

