import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Default preset from design (7 8 4 5)
    _controllers[0].text = '7';
    _controllers[1].text = '8';
    _controllers[2].text = '4';
    _controllers[3].text = '5';
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _roomCode => _controllers.map((c) => c.text).join();

  void _onJoin() {
    final code = _roomCode;
    if (code.length == 6) {
      context.push('/online-room');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة رمز الغرفة المكون من 6 أرقام')),
      );
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
            center: Alignment(0.0, -0.6),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
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
                      'انضم لغرفة',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 10),

                // صورة أونلاين الجذابة
                Image.asset(
                  'assets/images/online.png',
                  width: 240,
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.wifi_tethering_rounded, size: 100, color: Colors.white),
                ),

                const SizedBox(height: 8),

                const Text(
                  'اكتب الرمز اللي صاحبك بعته',
                  style: TextStyle(fontSize: 16, color: Color(0xFFE4D9FA), fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 20),

                // مربعات الرمز الستة (اتجاه LTR)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final hasValue = _controllers[index].text.isNotEmpty;
                      return Container(
                        width: 48,
                        height: 62,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: hasValue
                              ? const Color(0xFFA35BFF).withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasValue ? const Color(0xFFB98AFF) : const Color(0xFFA35BFF).withValues(alpha: 0.4),
                            width: hasValue ? 2 : 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: LammaColors.gold500,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (val.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            setState(() {});
                          },
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),

                // فاصل "أو"
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('أو', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  ],
                ),

                const SizedBox(height: 20),

                // زر مسح كود QR
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فتح الكاميرا لمسح كود QR...')),
                    );
                  },
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA35BFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.45), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: LammaColors.gold500, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'امسح كود QR',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // زر ادخل الغرفة
                GameButton(
                  text: 'ادخل الغرفة',
                  showArrow: false,
                  height: 62,
                  onPressed: _onJoin,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

