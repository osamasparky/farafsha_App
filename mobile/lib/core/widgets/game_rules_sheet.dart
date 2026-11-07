import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/lamma_theme.dart';
import 'game_button.dart';

class GameRuleStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  const GameRuleStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

class GameRulesSheet extends StatelessWidget {
  final String gameTitle;
  final String? gameSlug;
  final VoidCallback? onResume;

  const GameRulesSheet({
    super.key,
    required this.gameTitle,
    this.gameSlug,
    this.onResume,
  });

  static Future<void> show(
    BuildContext context, {
    required String gameTitle,
    String? gameSlug,
    VoidCallback? onResume,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0A0418).withValues(alpha: 0.8),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: GameRulesSheet(
          gameTitle: gameTitle,
          gameSlug: gameSlug,
          onResume: onResume,
        ),
      ),
    );
  }

  List<GameRuleStep> _getSteps() {
    final slug = (gameSlug ?? '').toLowerCase();
    final title = gameTitle.toLowerCase();

    if (slug.contains('amthal') || title.contains('أمثال')) {
      return const [
        GameRuleStep(
          number: 1,
          title: 'أول المثل بيظهر',
          description: 'اللاعب صاحب الدور يقرأ بداية المثل الشعبي بصوت واضح للقعدة كلها.',
          icon: Icons.format_quote_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFD2566A), Color(0xFF8E2A4E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        GameRuleStep(
          number: 2,
          title: 'كمّلوه في 20 ثانية',
          description: 'اختاروا التكملة الشعبية الصحيحة من الخيارات قبل انتهاء العداد التنازلي.',
          icon: Icons.timer_outlined,
          gradient: LinearGradient(
            colors: [Color(0xFF4846BE), Color(0xFF2B2580)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        GameRuleStep(
          number: 3,
          title: 'اجمعوا النقط',
          description: 'كل مثل صح يمنح 3 نقاط لفريقك، وصاحب أعلى رصيد في الآخر يتوج بالكأس!',
          icon: Icons.emoji_events_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF8B42FC), Color(0xFF5523A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ];
    } else if (slug.contains('quote') || title.contains('جمل')) {
      return const [
        GameRuleStep(
          number: 1,
          title: 'الإيفيه بيظهر',
          description: 'اقرأ بداية الجملة من الفيلم أو المسرحية الشهيرة بصوت واضح للجميع.',
          icon: Icons.movie_filter_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFD2566A), Color(0xFF8E2A4E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        GameRuleStep(
          number: 2,
          title: 'كمّل الإيفيه في 15 ثانية',
          description: 'خمن التكملة الأيقونية الأصلية من الخيارات المتاحة قبل نفاد الوقت.',
          icon: Icons.timer_outlined,
          gradient: LinearGradient(
            colors: [Color(0xFF4846BE), Color(0xFF2B2580)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        GameRuleStep(
          number: 3,
          title: 'احصد نقاط الفيلم',
          description: 'كل إيفيه صح يضيف 3 نقاط، والفريق الأعلى يتصدر لوحة الشرف!',
          icon: Icons.emoji_events_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF8B42FC), Color(0xFF5523A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ];
    } else if (slug.contains('taboo') || title.contains('ممنوع')) {
      return const [
        GameRuleStep(
          number: 1,
          title: 'الكلمة والممنوعات',
          description: 'اشرح الكلمة المطلوبة لفريقك بدون نطق أي كلمة من الكلمات المحظورة بالكارت!',
          icon: Icons.block_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        GameRuleStep(
          number: 2,
          title: 'السرعة والذكاء في 60 ثانية',
          description: 'فريقك يحاول تخمين أكبر عدد من الكلمات قبل انتهاء جرس الوقت.',
          icon: Icons.timer_outlined,
          gradient: LinearGradient(
            colors: [Color(0xFF4846BE), Color(0xFF2B2580)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        GameRuleStep(
          number: 3,
          title: 'حساب النقاط',
          description: 'نقطة لكل تخمين صحيح، وخصم نقطة فوري إذا نُطقت كلمة محظورة.',
          icon: Icons.emoji_events_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF8B42FC), Color(0xFF5523A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ];
    }

    // Generic fallback
    return const [
      GameRuleStep(
        number: 1,
        title: 'التحدي بيظهر',
        description: 'اللاعب صاحب الدور يقرأ التحدي أو السؤال بوضوح لجميع الحضور.',
        icon: Icons.lightbulb_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFFD2566A), Color(0xFF8E2A4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      GameRuleStep(
        number: 2,
        title: 'السرعة والتفكير',
        description: 'جاوب أو نفّذ التحدي المطلوب مع فريقك قبل انتهاء العداد التنازلي.',
        icon: Icons.timer_outlined,
        gradient: LinearGradient(
          colors: [Color(0xFF4846BE), Color(0xFF2B2580)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      GameRuleStep(
        number: 3,
        title: 'اجمعوا النقط وتصدروا',
        description: 'كل إجابة صحيحة تمنح فريقك نقاطاً إضافية للتتويج بالمركز الأول!',
        icon: Icons.emoji_events_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF8B42FC), Color(0xFF5523A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1866), Color(0xFF1B0D3C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(
          top: BorderSide(color: Color(0xFFB98AFF), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA35BFF).withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب العلوي
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),

              // العنوان وزر الإغلاق
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إزاي نلعب $gameTitle؟',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // خطوات اللعب
                      ...steps.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFA35BFF).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // أيقونة الخطوة ورقمها
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: step.gradient,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(step.icon, color: Colors.white, size: 26),
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: LammaColors.gold500,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${step.number}',
                                            style: const TextStyle(
                                              color: Color(0xFF2A0E35),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  // النصوص
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          step.description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFCFC6E4),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                      const SizedBox(height: 8),

                      // قسم حساب النقط
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'حساب النقط',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC9A2FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF35B88E).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF35B88E).withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    '+3',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF6FD9B5),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'إجابة صحيحة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC24B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFC24B).withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    '+2',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFFD27A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'بعد التلميح',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFCFC6E4),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'خطأ أو وقت',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),

              // زر فهمت اللعبة / كمّل اللعب
              GameButton(
                text: 'فهمت، كمّل اللعب!',
                icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2A0E35), size: 22),
                showArrow: false,
                height: 56,
                onPressed: () {
                  Navigator.pop(context);
                  onResume?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
