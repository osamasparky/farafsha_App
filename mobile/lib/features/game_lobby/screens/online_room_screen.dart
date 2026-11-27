import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/voice_room_bar.dart';

class OnlineRoomScreen extends StatefulWidget {
  final String roomCode;
  final String? playerToken;
  final bool isHost;

  const OnlineRoomScreen({
    super.key,
    this.roomCode = '784521',
    this.playerToken,
    this.isHost = false,
  });

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> with WidgetsBindingObserver {
  late String _code;
  late String? _playerToken;
  late bool _isHost;

  Timer? _syncTimer;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _isAppActive = true;
  bool _isStarting = false;
  bool _hasNavigated = false;

  String _gameTitle = 'لعبة أونلاين';
  String _gameSlug = '';
  int _totalRounds = 10;
  int _roundDuration = 20;
  int _maxPlayers = 8;
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _code = widget.roomCode;
    _playerToken = widget.playerToken;
    _isHost = widget.isHost;

    _fetchRoomState();
    // بدء مزامنة حالة الغرفة كل 2.5 ثانية مع منع تداخل الطلبات
    _syncTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (_isAppActive) _fetchRoomState();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    if (_isAppActive) _fetchRoomState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRoomState() async {
    if (!mounted || _hasNavigated || _isFetching) return;
    _isFetching = true;

    try {
      final res = await ApiService.instance.getRoomState(_code, token: _playerToken);
      if (!mounted) return;

      final room = res['room'] as Map<String, dynamic>? ?? {};
      final status = room['status'] as String? ?? 'waiting';
      final game = room['game'] as Map<String, dynamic>?;
      final leaderboard = res['leaderboard'] as List<dynamic>? ?? [];

      setState(() {
        _isLoading = false;
        _gameTitle = game?['name']?.toString() ?? 'فرفشة أونلاين';
        _gameSlug = game?['slug']?.toString() ?? '';
        _totalRounds = (room['total_rounds'] as int?) ?? 10;
        _roundDuration = (room['round_duration_seconds'] as int?) ?? 20;
        _maxPlayers = (room['total_players'] as int?) ?? 8;

        _players = leaderboard.map((p) {
          final isH = p['is_host'] == true || p['is_host'] == 1;
          return {
            'name': p['player_name']?.toString() ?? 'لاعب',
            'avatar': p['avatar']?.toString() ?? 'assets/images/av-ahmed.webp',
            'isHost': isH,
            'score': p['score'] ?? 0,
            'status': 'متصل 🟢',
            'statusColor': const Color(0xFF6FD9B5),
          };
        }).toList();

        // تحديث صلاحية المضيف إذا تغيرت
        final myPlayer = res['my_player'] as Map<String, dynamic>?;
        if (myPlayer != null) {
          _isHost = myPlayer['is_host'] == true || myPlayer['is_host'] == 1;
        }
      });

      // إذا بدأت اللعبة، ننتقل فوراً لشاشة اللعب المناسبة
      if (status == 'playing' && !_hasNavigated) {
        _hasNavigated = true;
        _syncTimer?.cancel();
        final targetRoute = _gameSlug == 'domino' ? '/online-domino' : '/online-gameplay';
        context.pushReplacement(targetRoute, extra: {
          'code': _code,
          'token': _playerToken,
          'isHost': _isHost,
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _isFetching = false;
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رمز الغرفة ($_code)! شاركه مع أصحابك 🎉',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF6A24C9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInvite() {
    final joinUrl = 'https://farafsha.com/join/$_code';
    final text = 'يلا نلعب سوا في فرفشة! 🎉\nرمز الغرفة: $_code\nاضغط على الرابط للانضمام مباشرة أو تحميل التطبيق:\n$joinUrl';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رابط الدعوة مع الرمز بنجاح! شاركه على واتساب 📲',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF25D366),
      ),
    );
  }

  void _showExpandedQrDialog(BuildContext context) {
    final joinUrl = 'https://farafsha.com/join/$_code';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0E3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFA35BFF), width: 1.5),
        ),
        title: Column(
          children: [
            Text(
              'امسح الرمز للدخول 📱',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'وجّه كاميرا هاتفك نحو الرمز للانضمام فوراً',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: const Color(0xFFC7B8E8),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA35BFF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: joinUrl,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1656),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.6)),
              ),
              child: Text(
                _code.split('').join('  '),
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: LammaColors.gold500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: joinUrl));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF25D366),
                  content: Text('تم نسخ رابط الغرفة بنجاح 📋', style: GoogleFonts.cairo(color: Colors.white)),
                ),
              );
            },
            child: Text('نسخ الرابط 📋', style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _onStartGame() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    HapticFeedback.heavyImpact();

    try {
      await ApiService.instance.startRoom(_code, playerToken: _playerToken);
      _hasNavigated = true;
      _syncTimer?.cancel();
      if (mounted) {
        final targetRoute = _gameSlug == 'domino' ? '/online-domino' : '/online-gameplay';
        context.pushReplacement(targetRoute, extra: {
          'code': _code,
          'token': _playerToken,
          'isHost': _isHost,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
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

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241050),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'مغادرة الغرفة',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          _isHost
              ? 'أنت مضيف الغرفة، خروجك قد يسلّم القيادة للاعب آخر. هل أنت متأكد؟'
              : 'هل تريد الخروج من غرفة اللعب الحالية؟',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: const Color(0xFFD6C8F5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              _syncTimer?.cancel();
              await ApiService.instance.leaveRoom(_code, token: _playerToken);
              if (mounted) context.go('/home');
            },
            child: Text('مغادرة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                // الشريط العلوي (رجوع + عنوان + أيقونة المضيف)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                      onPressed: _confirmLeave,
                    ),
                    Column(
                      children: [
                        Text(
                          'غرفة اللعب أونلاين',
                          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          _gameTitle,
                          style: GoogleFonts.cairo(fontSize: 13, color: LammaColors.gold500, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHost ? LammaColors.gold500.withValues(alpha: 0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isHost ? LammaColors.gold500 : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isHost ? Icons.workspace_premium_rounded : Icons.person_rounded,
                            color: _isHost ? LammaColors.gold500 : Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHost ? 'مضيف' : 'لاعب',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _isHost ? LammaColors.gold500 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // شريط الدردشة الصوتية المباشرة عبر LiveKit WebRTC
                VoiceRoomBar(roomCode: _code, playerToken: _playerToken),

                const SizedBox(height: 10),

                // بطاقة رمز الغرفة الفعلي مع زر النسخ والمشاركة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1850),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA35BFF).withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رمز الغرفة للمشاركة',
                              style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFFCFC6E4), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _code,
                                  style: GoogleFonts.cairo(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: LammaColors.gold500,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _copyCode,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_totalRounds جولات • $_roundDuration ثانية لكل سؤال',
                              style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFB5A8D6)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showExpandedQrDialog(context),
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFA35BFF).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: 'https://farafsha.com/join/$_code',
                            version: QrVersions.auto,
                            size: 68.0,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // بطاقة قائمة اللاعبين المتصلين
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1850).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'اللاعبون المتصلون (${_players.length}/$_maxPlayers)',
                              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFE8DDFF)),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: LammaColors.gold500),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _players.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_outline_rounded, color: Colors.white38, size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        'في انتظار انضمام اللاعبين...',
                                        style: GoogleFonts.cairo(color: Colors.white60, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _players.length,
                                  separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.08), height: 14),
                                  itemBuilder: (context, index) {
                                    final p = _players[index];
                                    final isH = p['isHost'] == true;

                                    return Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isH ? LammaColors.gold500 : const Color(0xFFB98AFF),
                                              width: 2.2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              p['avatar'] as String,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                p['name'] as String,
                                                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                              if (isH) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: LammaColors.gold500.withValues(alpha: 0.25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'المضيف 👑',
                                                    style: GoogleFonts.cairo(fontSize: 11, color: LammaColors.gold500, fontWeight: FontWeight.w800),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: p['statusColor'] as Color? ?? const Color(0xFF6FD9B5),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              p['status'] as String? ?? 'متصل',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: p['statusColor'] as Color? ?? const Color(0xFF6FD9B5),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // زر مشاركة رابط الدعوة عبر واتساب
                GestureDetector(
                  onTap: _shareInvite,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'مشاركة الدعوة مع الأصدقاء (واتساب)',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // زر ابدأ اللعبة (للمضيف فقط) أو شريط الانتظار (للضيوف)
                if (_isHost)
                  GameButton(
                    text: _isStarting ? 'جاري بدء اللعبة...' : 'ابدأ اللعبة الآن 🚀',
                    showArrow: false,
                    height: 58,
                    onPressed: _isStarting ? () {} : _onStartGame,
                  )
                else
                  Container(
                    height: 58,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B0E38).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: LammaColors.gold500),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'في انتظار المضيف لبدء اللعبة... ⏳',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: LammaColors.gold500),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
