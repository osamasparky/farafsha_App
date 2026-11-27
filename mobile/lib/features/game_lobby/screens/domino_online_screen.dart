import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

/// شاشة لعبة الدومينو الأونلاين (2 أو 3 أو 4 لاعبين — فردي أو 2 ضد 2 حتى 100 نقطة)
class DominoOnlineScreen extends StatefulWidget {
  final String roomCode;
  final String? playerToken;
  final bool isHost;

  const DominoOnlineScreen({
    super.key,
    required this.roomCode,
    this.playerToken,
    this.isHost = false,
  });

  @override
  State<DominoOnlineScreen> createState() => _DominoOnlineScreenState();
}

class _DominoOnlineScreenState extends State<DominoOnlineScreen> with WidgetsBindingObserver {
  Timer? _syncTimer;
  Timer? _countdownTimer;

  bool _isLoading = true;
  bool _isFetching = false;
  bool _isSubmitting = false;
  bool _isAppActive = true;

  Map<String, dynamic> _domino = {};
  List<Map<String, dynamic>> _players = [];
  int _myPlayerId = 0;
  int _remainingSeconds = 25;
  int _turnDuration = 25;
  List<int>? _pendingDualChoiceTile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchState();

    _syncTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (_isAppActive) _fetchState();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final roundEnded = _domino['round_ended'] == true;
      final matchOver = _domino['match_over'] == true;
      if (_remainingSeconds > 0 && !roundEnded && !matchOver) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 0) {
          _triggerTimeout();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    if (_isAppActive) _fetchState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchState() async {
    if (!mounted || _isFetching) return;
    _isFetching = true;

    try {
      final res = await ApiService.instance.getRoomState(widget.roomCode, token: widget.playerToken);
      if (!mounted) return;

      final domino = res['domino_state'] as Map<String, dynamic>? ?? {};
      final leaderboard = List<Map<String, dynamic>>.from(res['leaderboard'] ?? []);
      final myPlayer = res['my_player'] as Map<String, dynamic>?;

      setState(() {
        _isLoading = false;
        _domino = domino;
        _players = leaderboard;
        _myPlayerId = (myPlayer?['id'] as int?) ?? _myPlayerId;
        _turnDuration = (domino['turn_duration_seconds'] as int?) ?? 25;
        _remainingSeconds = (domino['remaining_seconds'] as int?) ?? 25;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _isFetching = false;
    }
  }

  void _applyActionResponse(Map<String, dynamic> res) {
    final domino = res['domino_state'] as Map<String, dynamic>?;
    if (domino != null && mounted) {
      setState(() {
        _domino = domino;
        _pendingDualChoiceTile = null;
        _remainingSeconds = (domino['remaining_seconds'] as int?) ?? _turnDuration;
      });
    }
    _fetchState();
  }

  bool get _isMyTurn => (_domino['current_turn_player_id'] as int?) == _myPlayerId && _domino['round_ended'] != true;

  int? get _leftEnd => _domino['left_end'] as int?;
  int? get _rightEnd => _domino['right_end'] as int?;

  List<List<int>> get _myHand {
    final raw = _domino['my_hand'] as List<dynamic>? ?? [];
    return raw.map((e) => List<int>.from((e as List).map((n) => (n as num).toInt()))).toList();
  }

  List<List<int>> get _board {
    final raw = _domino['board'] as List<dynamic>? ?? [];
    return raw.map((e) => List<int>.from((e as List).map((n) => (n as num).toInt()))).toList();
  }

  bool _canPlayOn(List<int> tile, String side) {
    if (_leftEnd == null || _rightEnd == null) return true;
    final target = side == 'left' ? _leftEnd! : _rightEnd!;
    return tile[0] == target || tile[1] == target;
  }

  bool get _hasAnyValidMove {
    for (final t in _myHand) {
      if (_canPlayOn(t, 'left') || _canPlayOn(t, 'right')) return true;
    }
    return false;
  }

  Future<void> _onTapHandTile(List<int> tile) async {
    if (!_isMyTurn || _isSubmitting) return;

    final fitsLeft = _canPlayOn(tile, 'left');
    final fitsRight = _canPlayOn(tile, 'right');

    if (!fitsLeft && !fitsRight) {
      HapticFeedback.vibrate();
      return;
    }

    if (_board.isEmpty || (fitsLeft && !fitsRight) || (_leftEnd == _rightEnd)) {
      await _playTile(tile, fitsRight ? 'right' : 'left');
      return;
    }

    if (!fitsLeft && fitsRight) {
      await _playTile(tile, 'right');
      return;
    }

    // البلاطة تركب على الطرفين: إظهار اختيار سريع يسار/يمين
    HapticFeedback.selectionClick();
    setState(() => _pendingDualChoiceTile = tile);
  }

  Future<void> _playTile(List<int> tile, String side) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    SoundService.instance.playClick();

    try {
      final res = await ApiService.instance.playDominoTile(
        widget.roomCode,
        tile,
        side,
        playerToken: widget.playerToken,
      );
      _applyActionResponse(res);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _drawTile() async {
    if (!_isMyTurn || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final res = await ApiService.instance.drawDominoTile(widget.roomCode, playerToken: widget.playerToken);
      _applyActionResponse(res);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _passTurn() async {
    if (!_isMyTurn || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.instance.passDominoTurn(widget.roomCode, playerToken: widget.playerToken);
      _applyActionResponse(res);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _triggerTimeout() async {
    try {
      final res = await ApiService.instance.timeoutDominoTurn(widget.roomCode, playerToken: widget.playerToken);
      _applyActionResponse(res);
    } catch (_) {}
  }

  Future<void> _nextRound() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.instance.nextDominoRound(widget.roomCode, playerToken: widget.playerToken);
      _applyActionResponse(res);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', ''), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  String _playerNameById(int pid) {
    for (final p in _players) {
      if ((p['id'] as int?) == pid) return p['player_name']?.toString() ?? 'لاعب';
    }
    return 'لاعب';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF150A2E),
        body: Center(child: CircularProgressIndicator(color: LammaColors.gold500)),
      );
    }

    if (_domino['match_over'] == true) {
      return _buildMatchOverView();
    }

    final teamMode = _domino['team_mode'] == true;
    final targetScore = (_domino['target_score'] as int?) ?? 100;
    final roundNumber = (_domino['round_number'] as int?) ?? 1;
    final boneyardCount = (_domino['boneyard_count'] as int?) ?? 0;
    final matchScores = _domino['match_scores'] as Map<String, dynamic>? ?? {};
    final handCounts = _domino['hand_counts'] as Map<String, dynamic>? ?? {};
    final turnPid = (_domino['current_turn_player_id'] as int?) ?? 0;
    final roundEnded = _domino['round_ended'] == true;

    final opponents = _players.where((p) => (p['id'] as int?) != _myPlayerId).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.2),
            radius: 1.1,
            colors: [Color(0xFF3E1C78), Color(0xFF200F45), Color(0xFF120829)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. الشريط العلوي (الجولة + الهدف + لوحة النقاط + خروج)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => context.go('/home'),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  'جولة $roundNumber',
                                  style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                if (teamMode) ...[
                                  Text(
                                    'فريقنا: ${matchScores['team_a'] ?? 0}',
                                    style: GoogleFonts.cairo(color: const Color(0xFF6FD9B5), fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                  Text(
                                    'المنافس: ${matchScores['team_b'] ?? 0}',
                                    style: GoogleFonts.cairo(color: const Color(0xFFFF8A4C), fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                ] else
                                  Text(
                                    'نقاطك: ${matchScores['$_myPlayerId'] ?? 0} / $targetScore',
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _remainingSeconds <= 5 ? Colors.redAccent : const Color(0xFF6A24C9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_remainingSecondsث',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. مقاعد الخصوم في الأعلى
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: opponents.map((op) {
                        final pid = (op['id'] as int?) ?? 0;
                        final isTurn = pid == turnPid && !roundEnded;
                        final count = handCounts['$pid'] ?? 0;
                        final score = teamMode ? '' : ' • ${matchScores['$pid'] ?? 0}ن';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isTurn ? const Color(0xFF5A25B8) : Colors.black26,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isTurn ? LammaColors.gold500 : Colors.white12,
                              width: isTurn ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                op['player_name']?.toString() ?? 'لاعب',
                                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              Text(
                                '🁣 $count$score',
                                style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. الطاولة (Board)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15382B).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.35), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: _board.isEmpty
                          ? Center(
                              child: Text(
                                _isMyTurn ? 'دورك! اختر بلاطة للبدء 🎯' : 'في انتظار ${_playerNameById(turnPid)}...',
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            )
                          : Center(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 8,
                                  children: _board.map((tile) {
                                    final isDouble = tile[0] == tile[1];
                                    return _DominoTileWidget(
                                      a: tile[0],
                                      b: tile[1],
                                      isVertical: isDouble,
                                      scale: 0.76,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                  ),

                  // اختيار الطرف عند إمكانية اللعب على اليمين واليسار
                  if (_pendingDualChoiceTile != null && _isMyTurn)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A24C9)),
                              onPressed: () => _playTile(_pendingDualChoiceTile!, 'left'),
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              label: Text('العب يسار (${_leftEnd ?? ""})', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A4C)),
                              onPressed: () => _playTile(_pendingDualChoiceTile!, 'right'),
                              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                              label: Text('العب يمين (${_rightEnd ?? ""})', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. شريط الدور + السحب من السوق / التخطي
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isMyTurn ? LammaColors.gold500 : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isMyTurn ? 'دورك الآن! ✨' : 'دور ${_playerNameById(turnPid)}',
                            style: GoogleFonts.cairo(
                              color: _isMyTurn ? const Color(0xFF1B0E38) : Colors.white70,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_isMyTurn && !_hasAnyValidMove)
                          boneyardCount > 0
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A4C)),
                                  onPressed: _isSubmitting ? null : _drawTile,
                                  icon: const Icon(Icons.add_box_rounded, color: Colors.white, size: 18),
                                  label: Text('اسحب من السوق ($boneyardCount)', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: _isSubmitting ? null : _passTurn,
                                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 18),
                                  label: Text('تخطي الدور', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                                )
                        else
                          Text(
                            'السوق: $boneyardCount',
                            style: GoogleFonts.cairo(color: Colors.white60, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                      ],
                    ),
                  ),

                  // 5. يد اللاعب (My Hand)
                  Container(
                    height: 112,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF180A33),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      border: Border(top: BorderSide(color: Colors.white12)),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _myHand.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tile = _myHand[index];
                        final playable = _isMyTurn && (_canPlayOn(tile, 'left') || _canPlayOn(tile, 'right'));

                        return GestureDetector(
                          onTap: () => _onTapHandTile(tile),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            transform: Matrix4.translationValues(0, playable ? -6 : 0, 0),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: playable ? LammaColors.gold500 : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: playable
                                  ? [BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.35), blurRadius: 10)]
                                  : [],
                            ),
                            child: Opacity(
                              opacity: (!_isMyTurn || playable) ? 1.0 : 0.45,
                              child: _DominoTileWidget(a: tile[0], b: tile[1], isVertical: true, scale: 0.92),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // نافذة نهاية الجولة (حتى الوصول لـ 100 نقطة)
              if (roundEnded) _buildRoundEndedOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundEndedOverlay() {
    final winner = _domino['round_winner'] as Map<String, dynamic>? ?? {};
    final winPid = (winner['player_id'] as int?) ?? 0;
    final ptsWon = (winner['points_won'] as int?) ?? 0;
    final blocked = winner['blocked'] == true;

    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF231048),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: LammaColors.gold500, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: LammaColors.gold500, size: 54),
              const SizedBox(height: 10),
              Text(
                blocked ? 'قفلت الطاولة! 🔒' : 'انتهت الجولة! 🎉',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'فاز ${_playerNameById(winPid)} وحصد +$ptsWon نقطة',
                style: GoogleFonts.cairo(color: LammaColors.gold300, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              GameButton(
                text: _isSubmitting ? 'جاري التوزيع...' : 'الجولة التالية 🔄',
                showArrow: false,
                height: 52,
                onPressed: _isSubmitting ? () {} : _nextRound,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchOverView() {
    final sorted = List<Map<String, dynamic>>.from(_players)
      ..sort((a, b) => ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [Color(0xFF6A33C4), Color(0xFF2E1660), Color(0xFF150A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.emoji_events_rounded, color: LammaColors.gold500, size: 80),
                const SizedBox(height: 10),
                Text(
                  'مبروك الفوز بالدومينو! 🏆',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) {
                      final p = sorted[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: idx == 0 ? const Color(0xFF4A1E9A) : Colors.black26,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: idx == 0 ? LammaColors.gold500 : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text('#${idx + 1}', style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(p['player_name']?.toString() ?? 'لاعب', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            ),
                            Text('${p['score'] ?? 0} نقطة', style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w900, fontSize: 15)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                GameButton(
                  text: 'العودة للرئيسية 🏠',
                  showArrow: false,
                  height: 54,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ودجت بلاطة الدومينو ثلاثية الأبعاد
class _DominoTileWidget extends StatelessWidget {
  final int a;
  final int b;
  final bool isVertical;
  final double scale;

  const _DominoTileWidget({
    required this.a,
    required this.b,
    this.isVertical = true,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final w = (isVertical ? 44.0 : 80.0) * scale;
    final h = (isVertical ? 84.0 : 42.0) * scale;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8EE),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: const Color(0xFFD6C7AE), width: 1.4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), offset: const Offset(0, 3), blurRadius: 3),
        ],
      ),
      child: isVertical
          ? Column(
              children: [
                Expanded(child: _PipFace(value: a, scale: scale)),
                Container(height: 1.5, width: w * 0.75, color: const Color(0xFF9E8E76)),
                Expanded(child: _PipFace(value: b, scale: scale)),
              ],
            )
          : Row(
              children: [
                Expanded(child: _PipFace(value: a, scale: scale)),
                Container(width: 1.5, height: h * 0.75, color: const Color(0xFF9E8E76)),
                Expanded(child: _PipFace(value: b, scale: scale)),
              ],
            ),
    );
  }
}

class _PipFace extends StatelessWidget {
  final int value;
  final double scale;

  const _PipFace({required this.value, required this.scale});

  static const Map<int, List<int>> _pipMap = {
    0: [],
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  @override
  Widget build(BuildContext context) {
    final active = _pipMap[value] ?? const [];
    final dotSize = 5.4 * scale;

    return Padding(
      padding: EdgeInsets.all(4.5 * scale),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: 9,
        itemBuilder: (_, idx) {
          if (!active.contains(idx)) return const SizedBox.shrink();
          return Center(
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: value == 6 ? const Color(0xFFB91C1C) : const Color(0xFF1F1638),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
