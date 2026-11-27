import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

/// شاشة طاولة الدومينو الأونلاين (بالعرض Landscape — مطابقة لتصاميم Domino2 / Domino3 / Domino4 / DominoEnd)
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
  List<int>? _selectedHandTile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // قفل الشاشة بالوضع الأفقي (Landscape) أثناء مباراة الدومينو حسب المواصفات
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
        _selectedHandTile = null;
        _remainingSeconds = (domino['remaining_seconds'] as int?) ?? _turnDuration;
      });
    }
    _fetchState();
  }

  bool get _isMyTurn =>
      (_domino['current_turn_player_id'] as int?) == _myPlayerId && _domino['round_ended'] != true;

  int? get _leftEnd => _domino['left_end'] as int?;
  int? get _rightEnd => _domino['right_end'] as int?;
  String get _playMode => _domino['play_mode']?.toString() ?? 'draw';

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

  void _onTapHandTile(List<int> tile) {
    if (!_isMyTurn || _isSubmitting) return;
    final fitsLeft = _canPlayOn(tile, 'left');
    final fitsRight = _canPlayOn(tile, 'right');
    if (!fitsLeft && !fitsRight) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.selectionClick();
    // إذا كانت نفس البلاطة مختارة مسبقاً وتركب على طرف واحد، نلعبها مباشرة
    if (_selectedHandTile != null &&
        _selectedHandTile![0] == tile[0] &&
        _selectedHandTile![1] == tile[1]) {
      if (_board.isEmpty || (fitsLeft && !fitsRight)) {
        _playTile(tile, 'left');
      } else if (!fitsLeft && fitsRight) {
        _playTile(tile, 'right');
      }
      return;
    }

    setState(() => _selectedHandTile = tile);
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
    HapticFeedback.mediumImpact();

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

  Map<String, dynamic>? _playerById(int pid) {
    for (final p in _players) {
      if ((p['id'] as int?) == pid) return p;
    }
    return null;
  }

  List<Map<String, dynamic>> get _orderedOpponents {
    final turnOrder = (_domino['turn_order'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList();
    if (turnOrder.isEmpty) {
      return _players.where((p) => (p['id'] as int?) != _myPlayerId).toList();
    }
    final myIdx = turnOrder.indexOf(_myPlayerId);
    final orderedIds = myIdx >= 0
        ? [...turnOrder.sublist(myIdx + 1), ...turnOrder.sublist(0, myIdx)]
        : turnOrder.where((id) => id != _myPlayerId).toList();
    return orderedIds.map(_playerById).whereType<Map<String, dynamic>>().toList();
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
    final targetScore = (_domino['target_score'] as int?) ?? 101;
    final boneyardCount = (_domino['boneyard_count'] as int?) ?? 0;
    final matchScores = _domino['match_scores'] as Map<String, dynamic>? ?? {};
    final handCounts = _domino['hand_counts'] as Map<String, dynamic>? ?? {};
    final turnPid = (_domino['current_turn_player_id'] as int?) ?? 0;
    final roundEnded = _domino['round_ended'] == true;
    final lastMove = _domino['last_move'] as Map<String, dynamic>?;
    final lastPlayedTile = lastMove?['type'] == 'play' ? lastMove!['tile'] as List<dynamic>? : null;

    final opponents = _orderedOpponents;
    // 2 لاعبين: خصم بالأعلى | 3 لاعبين: يمين + يسار | 4 لاعبين: يمين + شريك بالأعلى + يسار
    final Map<String, dynamic>? topOpponent = opponents.length == 1
        ? opponents[0]
        : (opponents.length >= 3 ? opponents[1] : null);
    final Map<String, dynamic>? rightOpponent = opponents.length >= 2 ? opponents[0] : null;
    final Map<String, dynamic>? leftOpponent = opponents.length == 2
        ? opponents[1]
        : (opponents.length >= 3 ? opponents[2] : null);

    final myPlayer = _playerById(_myPlayerId);
    final bool canDraw = _isMyTurn && !_hasAnyValidMove && _playMode == 'draw' && boneyardCount > 0;
    final bool canPass = _isMyTurn && !_hasAnyValidMove && (_playMode == 'block' || boneyardCount == 0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF3E1C78), Color(0xFF200F45), Color(0xFF120829)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. الشريط العلوي (النقاط + الخصم/الشريك العلوي أو حالة الدور + إيقاف)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        _buildScoreChip(teamMode, targetScore, matchScores),
                        const Spacer(),
                        if (topOpponent != null)
                          _TopSeatWidget(
                            player: topOpponent,
                            tileCount: (handCounts['${topOpponent['id']}'] as int?) ?? 0,
                            isTurn: topOpponent['id'] == turnPid && !roundEnded,
                            isPartner: teamMode,
                            progress: _remainingSeconds / (_turnDuration > 0 ? _turnDuration : 25),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _isMyTurn
                                  ? '• دورك الآن!'
                                  : '• دور ${_playerById(turnPid)?['player_name'] ?? "لاعب"}... بيفكّر',
                              style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showPauseDialog(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(Icons.pause_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. الطاولة الخضراء (Green Felt Table)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: [Color(0xFF175E49), Color(0xFF0E3F31)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.7), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // المقعد الأيمن / المخزن
                          if (rightOpponent != null)
                            _SideSeatWidget(
                              player: rightOpponent,
                              tileCount: (handCounts['${rightOpponent['id']}'] as int?) ?? 0,
                              isTurn: rightOpponent['id'] == turnPid && !roundEnded,
                              lastMove: lastMove?['player_id'] == rightOpponent['id'] ? lastMove : null,
                            )
                          else if (_playMode == 'draw')
                            _BoneyardPanel(
                              count: boneyardCount,
                              canDraw: canDraw,
                              isSubmitting: _isSubmitting,
                              onDraw: _drawTile,
                            ),

                          // سلسلة البلاطات في المنتصف
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (opponents.length == 2 && _playMode == 'draw')
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'المخزن · $boneyardCount',
                                        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                _buildBoardChain(lastPlayedTile),
                              ],
                            ),
                          ),

                          // المقعد الأيسر
                          if (leftOpponent != null)
                            _SideSeatWidget(
                              player: leftOpponent,
                              tileCount: (handCounts['${leftOpponent['id']}'] as int?) ?? 0,
                              isTurn: leftOpponent['id'] == turnPid && !roundEnded,
                              lastMove: lastMove?['player_id'] == leftOpponent['id'] ? lastMove : null,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 3. الشريط السفلي: زر دق/سحب + يد اللاعب + أفاتار اللاعب ومؤقت الدور
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        // زر دق (باص) أو رسالة التوجيه
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_playMode == 'block' || opponents.length >= 3 || boneyardCount == 0)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canPass ? const Color(0xFFFF8A4C) : Colors.white10,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  ),
                                  onPressed: (canPass && !_isSubmitting) ? _passTurn : null,
                                  child: Text(
                                    'دق (باص)',
                                    style: GoogleFonts.cairo(
                                      color: canPass ? Colors.white : Colors.white38,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else if (canDraw)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8A4C),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  onPressed: _isSubmitting ? null : _drawTile,
                                  child: Text(
                                    'اسحب ($boneyardCount)',
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                _isMyTurn
                                    ? (_selectedHandTile != null
                                        ? 'دوس على المكان المنوّر عشان تحط القطعة'
                                        : 'اختار قطعة من إيدك للعب')
                                    : 'استنى دورك — القطع المنوّرة هتنفع لو الأطراف فضلت زي ما هي',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        // يد اللاعب في المنتصف
                        Expanded(
                          child: SizedBox(
                            height: 76,
                            child: Center(
                              child: ListView.separated(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _myHand.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 6),
                                itemBuilder: (context, index) {
                                  final tile = _myHand[index];
                                  final playable = _canPlayOn(tile, 'left') || _canPlayOn(tile, 'right');
                                  final isSelected = _selectedHandTile != null &&
                                      _selectedHandTile![0] == tile[0] &&
                                      _selectedHandTile![1] == tile[1];

                                  return GestureDetector(
                                    onTap: () => _onTapHandTile(tile),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      transform: Matrix4.translationValues(0, isSelected ? -8 : (playable && _isMyTurn ? -3 : 0), 0),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? LammaColors.gold500
                                              : (playable ? LammaColors.gold500.withValues(alpha: 0.45) : Colors.transparent),
                                          width: isSelected ? 2.2 : 1.2,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.55), blurRadius: 10)]
                                            : [],
                                      ),
                                      child: Opacity(
                                        opacity: playable ? 1.0 : 0.45,
                                        child: _DominoTileWidget(a: tile[0], b: tile[1], isVertical: true, scale: 0.78),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // أفاتار اللاعب + مؤقت الدور
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    value: _isMyTurn
                                        ? (_remainingSeconds / (_turnDuration > 0 ? _turnDuration : 25)).clamp(0.0, 1.0)
                                        : 0.0,
                                    strokeWidth: 3,
                                    color: LammaColors.gold500,
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF4A1E9A),
                                  child: Text(
                                    (myPlayer?['player_name']?.toString() ?? 'أ').characters.first,
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isMyTurn ? LammaColors.gold500 : Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _isMyTurn ? 'دورك · $_remainingSecondsث' : 'أنا',
                                style: GoogleFonts.cairo(
                                  color: _isMyTurn ? const Color(0xFF1B0E38) : Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (roundEnded) _buildRoundEndedOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(bool teamMode, int targetScore, Map<String, dynamic> matchScores) {
    String label;
    if (teamMode) {
      label = 'إحنا ${matchScores['team_a'] ?? 0}  |  هم ${matchScores['team_b'] ?? 0}  / $targetScore';
    } else {
      final parts = _players.map((p) {
        final pid = p['id'];
        final name = pid == _myPlayerId ? 'أنا' : (p['player_name']?.toString() ?? '');
        return '$name ${matchScores['$pid'] ?? 0}';
      }).join(' | ');
      label = '$parts / $targetScore';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
      ),
    );
  }

  Widget _buildBoardChain(List<dynamic>? lastPlayedTile) {
    final sel = _selectedHandTile;
    final showLeftSlot = _isMyTurn && sel != null && _canPlayOn(sel, 'left') && _board.isNotEmpty;
    final showRightSlot = _isMyTurn && sel != null && _canPlayOn(sel, 'right');

    if (_board.isEmpty) {
      if (showRightSlot) {
        return GestureDetector(
          onTap: () => _playTile(sel, 'right'),
          child: const _DashedDropSlot(isVertical: false),
        );
      }
      return Text(
        _isMyTurn ? 'اختار أعلى دبل عندك عشان تبدأ 🎯' : 'الطاولة فاضية — في انتظار البداية...',
        style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w700),
      );
    }

    final List<Widget> items = [];
    if (showLeftSlot) {
      items.add(GestureDetector(
        onTap: () => _playTile(sel, 'left'),
        child: const _DashedDropSlot(isVertical: false),
      ));
    }

    for (final tile in _board) {
      final isDouble = tile[0] == tile[1];
      final isLast = lastPlayedTile != null &&
          lastPlayedTile.length == 2 &&
          ((lastPlayedTile[0] == tile[0] && lastPlayedTile[1] == tile[1]) ||
              (lastPlayedTile[0] == tile[1] && lastPlayedTile[1] == tile[0]));

      items.add(_DominoTileWidget(
        a: tile[0],
        b: tile[1],
        isVertical: isDouble,
        isLastPlayed: isLast,
        scale: _board.length > 12 ? 0.56 : 0.68,
      ));
    }

    if (showRightSlot) {
      items.add(GestureDetector(
        onTap: () => _playTile(sel, 'right'),
        child: const _DashedDropSlot(isVertical: false),
      ));
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 6,
          children: items,
        ),
      ),
    );
  }

  /// شاشة نهاية الدور (مطابقة لتصميم 05-DominoEnd)
  Widget _buildRoundEndedOverlay() {
    final winner = _domino['round_winner'] as Map<String, dynamic>? ?? {};
    final winPid = (winner['player_id'] as int?) ?? 0;
    final ptsWon = (winner['points_won'] as int?) ?? 0;
    final blocked = winner['blocked'] == true;
    final losingHands = winner['losing_hands'] as Map<String, dynamic>? ?? {};
    final remainingPips = winner['remaining_pips'] as Map<String, dynamic>? ?? {};
    final teamMode = _domino['team_mode'] == true;
    final matchScores = _domino['match_scores'] as Map<String, dynamic>? ?? {};
    final targetScore = (_domino['target_score'] as int?) ?? 101;
    final winnerName = _playerById(winPid)?['player_name']?.toString() ?? 'البطل';

    final losers = _players.where((p) {
      final pid = p['id'] as int?;
      final tiles = losingHands['$pid'] as List<dynamic>? ?? [];
      return pid != winPid && tiles.isNotEmpty;
    }).toList();

    return Container(
      color: Colors.black.withValues(alpha: 0.76),
      child: Center(
        child: Container(
          width: 680,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF211044),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFA35BFF), width: 1.8),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Text('+$ptsWon', style: GoogleFonts.cairo(color: LammaColors.gold500, fontSize: 22, fontWeight: FontWeight.w900)),
                          Text('نقطة', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          blocked ? 'قفلت الطاولة! $winnerName كسب الدور 🔒' : 'دومينو! $winnerName خلّص قطعه 🎉',
                          style: GoogleFonts.cairo(color: LammaColors.gold300, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          teamMode ? 'فريقكم كسب الدور' : 'كسب $winnerName الدور!',
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // قطع الخاسرين المتبقية
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: losers.map((p) {
                    final pid = '${p['id']}';
                    final tiles = losingHands[pid] as List<dynamic>? ?? [];
                    final pips = remainingPips[pid] ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$pips', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(width: 8),
                          ...tiles.map((t) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _DominoTileWidget(a: t[0], b: t[1], isVertical: false, scale: 0.52),
                              )),
                          const SizedBox(width: 8),
                          Text('${p['player_name']} فاضل معاه', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // أشرطة التقدم نحو الهدف
                if (teamMode) ...[
                  _buildProgressRow('إحنا', (matchScores['team_a'] as int?) ?? 0, targetScore, const Color(0xFFFFC24B)),
                  const SizedBox(height: 6),
                  _buildProgressRow('هم', (matchScores['team_b'] as int?) ?? 0, targetScore, const Color(0xFFFF8A4C)),
                ] else
                  ..._players.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _buildProgressRow(
                          p['player_name']?.toString() ?? 'لاعب',
                          (matchScores['${p['id']}'] as int?) ?? 0,
                          targetScore,
                          const Color(0xFFFFC24B),
                        ),
                      )),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GameButton(
                        text: _isSubmitting ? 'جاري التوزيع...' : 'الدور الجاي',
                        showArrow: false,
                        height: 46,
                        onPressed: _isSubmitting ? () {} : _nextRound,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () => context.go('/home'),
                        child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int score, int target, Color color) {
    final pct = (score / (target > 0 ? target : 101)).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text('$target / $score', style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(label, textAlign: TextAlign.end, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ],
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, color: LammaColors.gold500, size: 64),
                Text(
                  'مبروك الفوز بالدومينو! 🏆',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) {
                      final p = sorted[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: idx == 0 ? const Color(0xFF4A1E9A) : Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: idx == 0 ? LammaColors.gold500 : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text('#${idx + 1}', style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(p['player_name']?.toString() ?? 'لاعب', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                            ),
                            Text('${p['score'] ?? 0} نقطة', style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                GameButton(
                  text: 'العودة للرئيسية 🏠',
                  showArrow: false,
                  height: 48,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F0F42),
        title: Text('إيقاف مؤقت', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('هل تريد الخروج من مباراة الدومينو؟', style: GoogleFonts.cairo(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('متابعة اللعب', style: GoogleFonts.cairo(color: LammaColors.gold500))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: Text('خروج', style: GoogleFonts.cairo(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _TopSeatWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final int tileCount;
  final bool isTurn;
  final bool isPartner;
  final double progress;

  const _TopSeatWidget({
    required this.player,
    required this.tileCount,
    required this.isTurn,
    required this.isPartner,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final name = player['player_name']?.toString() ?? 'لاعب';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(
            tileCount.clamp(0, 7),
            (_) => Container(
              width: 14,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA35BFF), Color(0xFF6A24C9)]),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white30, width: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPartner ? '$name (شريكك)' : name,
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text('معاه $tileCount قطع', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10)),
          ],
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            if (isTurn)
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), strokeWidth: 2.5, color: LammaColors.gold500),
              ),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF5A25B8),
              child: Text(name.characters.first, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SideSeatWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final int tileCount;
  final bool isTurn;
  final Map<String, dynamic>? lastMove;

  const _SideSeatWidget({
    required this.player,
    required this.tileCount,
    required this.isTurn,
    this.lastMove,
  });

  @override
  Widget build(BuildContext context) {
    final name = player['player_name']?.toString() ?? 'لاعب';
    final isPass = lastMove?['type'] == 'pass';
    final playedTile = lastMove?['type'] == 'play' ? lastMove!['tile'] as List<dynamic>? : null;

    return SizedBox(
      width: 86,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isPass)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text('دق! معهاش', style: GoogleFonts.cairo(color: const Color(0xFF1F1638), fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isTurn ? LammaColors.gold500 : Colors.white24, width: isTurn ? 2.5 : 1.2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF5A25B8),
              child: Text(name.characters.first, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 3),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: List.generate(
              tileCount.clamp(0, 7),
              (_) => Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA35BFF), Color(0xFF6A24C9)]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          if (playedTile != null && playedTile.length == 2) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4))),
              child: Text('حط ${playedTile[0]}|${playedTile[1]}', style: GoogleFonts.cairo(color: Colors.cyanAccent, fontSize: 9.5, fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BoneyardPanel extends StatelessWidget {
  final int count;
  final bool canDraw;
  final bool isSubmitting;
  final VoidCallback onDraw;

  const _BoneyardPanel({
    required this.count,
    required this.canDraw,
    required this.isSubmitting,
    required this.onDraw,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFA35BFF), Color(0xFF6A24C9)]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38),
            ),
            child: Center(
              child: Text('$count', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 4),
          Text('المخزن · $count', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canDraw ? const Color(0xFFFF8A4C) : Colors.white10,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: const Size(0, 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: (canDraw && !isSubmitting) ? onDraw : null,
            child: Text('اسحب', style: GoogleFonts.cairo(color: canDraw ? Colors.white : Colors.white38, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _DashedDropSlot extends StatelessWidget {
  final bool isVertical;
  const _DashedDropSlot({required this.isVertical});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isVertical ? 30 : 54,
      height: isVertical ? 54 : 30,
      decoration: BoxDecoration(
        color: LammaColors.gold500.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LammaColors.gold500, width: 1.8),
        boxShadow: [BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.35), blurRadius: 8)],
      ),
      child: const Icon(Icons.add_rounded, color: LammaColors.gold500, size: 16),
    );
  }
}

class _DominoTileWidget extends StatelessWidget {
  final int a;
  final int b;
  final bool isVertical;
  final bool isLastPlayed;
  final double scale;

  const _DominoTileWidget({
    required this.a,
    required this.b,
    this.isVertical = true,
    this.isLastPlayed = false,
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
        border: Border.all(
          color: isLastPlayed ? Colors.cyanAccent : const Color(0xFFD6C7AE),
          width: isLastPlayed ? 2.2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isLastPlayed ? Colors.cyanAccent.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: isLastPlayed ? 10 : 3,
          ),
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
      padding: EdgeInsets.all(4.2 * scale),
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
