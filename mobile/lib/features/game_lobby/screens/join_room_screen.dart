import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class JoinRoomScreen extends StatefulWidget {
  final String? initialCode;

  const JoinRoomScreen({super.key, this.initialCode});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late TextEditingController _nameController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authName = AuthService.instance.userName.trim();
    final currentUserName = authName.isNotEmpty ? authName : (ApiService.instance.currentUser?['name']?.toString().trim() ?? '');
    _nameController = TextEditingController(text: currentUserName);

    // ملء رمز الغرفة تلقائياً في حال الدخول عبر ديب لينك (Deep Link) أو مسح QR كود
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      final clean = widget.initialCode!.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < clean.length; i++) {
        _controllers[i].text = clean[i];
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _nameController.dispose();
    super.dispose();
  }

  String get _roomCode => _controllers.map((c) => c.text).join();

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (text.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = text[i];
      }
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  Future<void> _onJoin() async {
    final code = _roomCode.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال رمز الغرفة كاملاً (6 أرقام)', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء كتابة اسمك أو لقبك لدخول التحدي', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      final res = await ApiService.instance.joinRoom(
        code: code,
        playerName: name,
      );

      if (mounted) {
        context.pushReplacement('/online-room', extra: {
          'code': code,
          'token': res['token']?.toString(),
          'isHost': false,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                    Text(
                      'انضم لغرفة لعب',
                      style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 10),

                // صورة أونلاين الجذابة
                Image.asset(
                  'assets/images/online.webp',
                  width: 200,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.wifi_tethering_rounded, size: 100, color: Colors.white),
                ),

                const SizedBox(height: 6),

                Text(
                  'اكتب الرمز المكون من 6 أرقام للدخول',
                  style: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFFE4D9FA), fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 18),

                // مربعات الرمز الستة
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final hasValue = _controllers[index].text.isNotEmpty;
                      return Container(
                        width: 46,
                        height: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: hasValue
                              ? const Color(0xFFA35BFF).withValues(alpha: 0.22)
                              : Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasValue ? LammaColors.gold500 : const Color(0xFFA35BFF).withValues(alpha: 0.4),
                            width: hasValue ? 2 : 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: LammaColors.gold500,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
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

                const SizedBox(height: 10),

                // زر لصق الرمز من الحافظة
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded, color: Color(0xFFC0A4FF), size: 18),
                  label: Text(
                    'لصق الرمز من الحافظة',
                    style: GoogleFonts.cairo(color: const Color(0xFFC0A4FF), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 16),

                // حقل اسم اللاعب
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241050),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'اسمك في اللعبة',
                      labelStyle: GoogleFonts.cairo(color: const Color(0xFFB5A8D6), fontSize: 13),
                      hintText: 'اكتب اسمك الذي سيظهر للاعبين...',
                      hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.badge_rounded, color: LammaColors.gold500),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // زر الدخول
                GameButton(
                  text: _isLoading ? 'جاري التحقق والدخول...' : 'دخول الغرفة والتحدي 🚀',
                  showArrow: false,
                  height: 60,
                  onPressed: _isLoading ? () {} : _onJoin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
