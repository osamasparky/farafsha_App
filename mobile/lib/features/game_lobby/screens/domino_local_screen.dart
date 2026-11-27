import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../widgets/domino_board_widgets.dart';

/// لعبة الدومينو المحلية (أوفلاين ضد البوت الذكي 🤖) — تدعم الطول والعرض + 2/3/4 لاعبين + فردي أو 2 ضد 2
class DominoLocalScreen extends StatefulWidget {
  final int playersCount;
  final String playMode; // 'draw' | 'block'
  final bool teamMode;
  final int targetScore;
  final String playerName;

  const DominoLocalScreen({
    super.key,
    this.playersCount = 2,
    this.playMode = 'draw',
    this.teamMode = false,
    this.targetScore = 101,
    this.playerName = 'أنت',
  });

  @override
  State<DominoLocalScreen> createState() => _DominoLocalScreenState();
}

class _DominoLocalScreenState extends State<DominoLocalScreen> {
  final Random _rng = Random();
  bool _isPortrait = true; // دعم الشاشة بالطول افتراضياً مع زر تبديل للعرض
  bool _autoDraw = false; // زرار السحب الأوتوماتيك أو اليدوي
  int _roundNumber = 1;
  int _currentTurn = 0; // 0 = أنت
  int? _leftEnd;
  int? _rightEnd;
  List<List<int>> _board = [];
  List<List<int>> _boneyard = [];
  List<List<List<int>>> _hands = [];
  List<String> _names = [];
  List<int> _scores = [0, 0, 0, 0];
  int _teamAScore = 0;
  int _teamBScore = 0;
  int _consecutivePasses = 0;
  bool _roundEnded = false;
  bool _matchOver = false;
  int _winnerIdx = 0;
  int _pointsWon = 0;
  bool _blockedWin = false;
  List<int>? _selectedTile;
  List<int>? _lastPlayedTile;
  String _statusBanner = '';
  bool _syncedScore = false;

  @override
  void initState() {
    super.initState();
    _applyOrientation();
    _initNames();
    _dealRound(firstRound: true);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _applyOrientation() {
    if (_isPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _toggleOrientation() {
    HapticFeedback.selectionClick();
    setState(() => _isPortrait = !_isPortrait);
    _applyOrientation();
  }

  void _initNames() {
    final botNames = ['سارة 🤖', 'محمود 🤖', 'منة 🤖'];
    _names = [
      widget.playerName,
      for (int i = 0; i < widget.playersCount - 1; i++) botNames[i],
    ];
    _scores = List.filled(widget.playersCount, 0);
  }

  void _dealRound({bool firstRound = false, int? preferredStarter}) {
    final deck = <List<int>>[];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        deck.add([i, j]);
      }
    }
    deck.shuffle(_rng);

    _hands = List.generate(widget.playersCount, (i) => deck.sublist(i * 7, (i + 1) * 7));
    _boneyard = widget.playMode == 'block' ? [] : deck.sublist(widget.playersCount * 7);
    _board = [];
    _leftEnd = null;
    _rightEnd = null;
    _consecutivePasses = 0;
    _roundEnded = false;
    _selectedTile = null;
    _lastPlayedTile = null;

    int starter = preferredStarter ?? 0;
    if (firstRound) {
      int bestDouble = -1;
      for (int p = 0; p < widget.playersCount; p++) {
        for (final t in _hands[p]) {
          if (t[0] == t[1] && t[0] > bestDouble) {
            bestDouble = t[0];
            starter = p;
          }
        }
      }
    }
    _currentTurn = starter;
    _statusBanner = _currentTurn == 0 ? 'دورك! اختار قطعة للبدء 🎯' : 'دور ${_names[_currentTurn]}...';
    setState(() {});

    if (_currentTurn != 0) {
      _scheduleBotTurn();
    }
  }

  bool _canPlayOn(List<int> tile, String side) {
    if (_leftEnd == null || _rightEnd == null) return true;
    final target = side == 'left' ? _leftEnd! : _rightEnd!;
    return tile[0] == target || tile[1] == target;
  }

  bool _hasValidMove(int playerIdx) {
    for (final t in _hands[playerIdx]) {
      if (_canPlayOn(t, 'left') || _canPlayOn(t, 'right')) return true;
    }
    return false;
  }

  void _placeTile(int playerIdx, int handIdx, String side) {
    final tile = _hands[playerIdx].removeAt(handIdx);
    List<int> placed;
    if (_board.isEmpty) {
      placed = [tile[0], tile[1]];
      _board.add(placed);
      _leftEnd = placed[0];
      _rightEnd = placed[1];
    } else if (side == 'left') {
      placed = tile[1] == _leftEnd ? [tile[0], tile[1]] : [tile[1], tile[0]];
      _board.insert(0, placed);
      _leftEnd = placed[0];
    } else {
      placed = tile[0] == _rightEnd ? [tile[0], tile[1]] : [tile[1], tile[0]];
      _board.add(placed);
      _rightEnd = placed[1];
    }

    _lastPlayedTile = placed;
    _selectedTile = null;
    _consecutivePasses = 0;
    SoundService.instance.playClick();

    if (_hands[playerIdx].isEmpty) {
      _finishRound(playerIdx, blocked: false);
      return;
    }

    _advanceTurn();
  }

  void _advanceTurn() {
    _currentTurn = (_currentTurn + 1) % widget.playersCount;
    _statusBanner = _currentTurn == 0 ? 'دورك الآن! ✨' : 'دور ${_names[_currentTurn]}...';
    setState(() {});
    if (_currentTurn != 0 && !_roundEnded && !_matchOver) {
      _scheduleBotTurn();
    } else if (_currentTurn == 0 && _autoDraw && !_roundEnded && !_matchOver) {
      _scheduleAutoDrawIfNeeded();
    }
  }

  void _scheduleAutoDrawIfNeeded() {
    if (!_autoDraw || _currentTurn != 0 || _roundEnded || _matchOver) return;
    if (_hasValidMove(0) || widget.playMode != 'draw' || _boneyard.isEmpty) return;

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted || !_autoDraw || _currentTurn != 0 || _roundEnded || _matchOver) return;
      if (!_hasValidMove(0) && _boneyard.isNotEmpty) {
        setState(() => _hands[0].add(_boneyard.removeAt(0)));
        if (!_hasValidMove(0) && _boneyard.isNotEmpty) {
          _scheduleAutoDrawIfNeeded();
        }
      }
    });
  }

  void _scheduleBotTurn() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _roundEnded || _matchOver || _currentTurn == 0) return;
      final bot = _currentTurn;
      int? bestIdx;
      String bestSide = 'right';
      int bestSum = -1;

      for (int i = 0; i < _hands[bot].length; i++) {
        final t = _hands[bot][i];
        final s = t[0] + t[1];
        if (_canPlayOn(t, 'right') && s > bestSum) {
          bestIdx = i;
          bestSide = 'right';
          bestSum = s;
        } else if (_canPlayOn(t, 'left') && s > bestSum) {
          bestIdx = i;
          bestSide = 'left';
          bestSum = s;
        }
      }

      if (bestIdx != null) {
        _placeTile(bot, bestIdx, bestSide);
        return;
      }

      if (widget.playMode == 'draw' && _boneyard.isNotEmpty) {
        final drawn = _boneyard.removeAt(0);
        _hands[bot].add(drawn);
        _statusBanner = '${_names[bot]} سحب قطعة من المخزن';
        setState(() {});
        _scheduleBotTurn();
        return;
      }

      _consecutivePasses++;
      _statusBanner = '${_names[bot]} دق (معهوش)!';
      if (_consecutivePasses >= widget.playersCount) {
        _finishRound(null, blocked: true);
      } else {
        _advanceTurn();
      }
    });
  }

  int _pipSum(List<List<int>> hand) => hand.fold(0, (sum, t) => sum + t[0] + t[1]);

  void _finishRound(int? directWinner, {required bool blocked}) {
    int winIdx = directWinner ?? 0;
    if (blocked || directWinner == null) {
      int low = 9999;
      for (int i = 0; i < widget.playersCount; i++) {
        final s = _pipSum(_hands[i]);
        if (s < low) {
          low = s;
          winIdx = i;
        }
      }
    }

    int pts = 0;
    final is2v2 = widget.teamMode && widget.playersCount == 4;
    if (is2v2) {
      final teamAWon = winIdx == 0 || winIdx == 2;
      final losingIndices = teamAWon ? [1, 3] : [0, 2];
      for (final idx in losingIndices) {
        pts += _pipSum(_hands[idx]);
      }
      if (teamAWon) {
        _teamAScore += pts;
      } else {
        _teamBScore += pts;
      }
      _matchOver = (_teamAScore >= widget.targetScore) || (_teamBScore >= widget.targetScore);
    } else {
      for (int i = 0; i < widget.playersCount; i++) {
        if (i != winIdx) pts += _pipSum(_hands[i]);
      }
      _scores[winIdx] += pts;
      _matchOver = _scores[winIdx] >= widget.targetScore;
    }

    _winnerIdx = winIdx;
    _pointsWon = pts;
    _blockedWin = blocked;
    _roundEnded = true;

    if (_matchOver && !_syncedScore && !AuthService.instance.isGuest && AuthService.instance.isLoggedIn) {
      _syncedScore = true;
      final isUserWin = is2v2 ? (_teamAScore > _teamBScore) : (winIdx == 0);
      final leaderboardPts = ApiService.instance.getPointsForGame('domino', fallback: isUserWin ? 15 : 5);
      ApiService.instance.recordGameScore(score: isUserWin ? leaderboardPts : 5, isWin: isUserWin);
    }
    setState(() {});
  }

  void _onTapMyTile(List<int> tile) {
    if (_currentTurn != 0 || _roundEnded || _matchOver) return;
    final fitsL = _canPlayOn(tile, 'left');
    final fitsR = _canPlayOn(tile, 'right');
    if (!fitsL && !fitsR) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.selectionClick();
    if (_selectedTile != null && _selectedTile![0] == tile[0] && _selectedTile![1] == tile[1]) {
      final idx = _hands[0].indexWhere((t) => t[0] == tile[0] && t[1] == tile[1]);
      if (idx >= 0 && (_board.isEmpty || (fitsL && !fitsR) || (!fitsL && fitsR))) {
        _placeTile(0, idx, fitsR ? 'right' : 'left');
      }
      return;
    }
    setState(() => _selectedTile = tile);
  }

  void _playSelectedOn(String side) {
    if (_selectedTile == null || _currentTurn != 0) return;
    final idx = _hands[0].indexWhere((t) => t[0] == _selectedTile![0] && t[1] == _selectedTile![1]);
    if (idx >= 0) _placeTile(0, idx, side);
  }

  void _onDrawMyTile() {
    if (_currentTurn != 0 || _boneyard.isEmpty || _hasValidMove(0)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _hands[0].add(_boneyard.removeAt(0));
    });
  }

  void _onPassMyTurn() {
    if (_currentTurn != 0 || _hasValidMove(0)) return;
    if (widget.playMode == 'draw' && _boneyard.isNotEmpty) return;
    HapticFeedback.mediumImpact();
    _consecutivePasses++;
    if (_consecutivePasses >= widget.playersCount) {
      _finishRound(null, blocked: true);
    } else {
      _advanceTurn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final is2v2 = widget.teamMode && widget.playersCount == 4;
    final scoreLabel = is2v2
        ? 'إحنا $_teamAScore | هم $_teamBScore / ${widget.targetScore}'
        : '${List.generate(widget.playersCount, (i) => '${_names[i]} ${_scores[i]}').join(' | ')} / ${widget.targetScore}';

    final myValid = _hasValidMove(0);
    final canDraw = _currentTurn == 0 && !myValid && widget.playMode == 'draw' && _boneyard.isNotEmpty;
    final canPass = _currentTurn == 0 && !myValid && (widget.playMode == 'block' || _boneyard.isEmpty);
    final sel = _selectedTile;

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
                  // الشريط العلوي المدمج (النقاط + رقم المخزن + أيقونة السحب التلقائي/اليدوي + التدوير)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.45)),
                            ),
                            child: Text(
                              'جولة $_roundNumber · $scoreLabel',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                        ),
                        if (widget.playMode == 'draw') ...[
                          const SizedBox(width: 6),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.layers_rounded, color: Color(0xFFA35BFF), size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${_boneyard.length}',
                                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _autoDraw = !_autoDraw);
                              if (_autoDraw) _scheduleAutoDrawIfNeeded();
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _autoDraw ? const Color(0xFF35B88E).withValues(alpha: 0.25) : Colors.black38,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _autoDraw ? const Color(0xFF35B88E) : Colors.white12),
                              ),
                              child: Icon(
                                _autoDraw ? Icons.bolt_rounded : Icons.pan_tool_alt_rounded,
                                color: _autoDraw ? const Color(0xFF6FD9B5) : Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: _toggleOrientation,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(Icons.screen_rotation_rounded, color: LammaColors.gold500, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // مقاعد الخصوم (أفاتار + عدد القطع فقط لتوفير المساحة)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.playersCount - 1, (idx) {
                        final pIdx = idx + 1;
                        final isTurn = _currentTurn == pIdx && !_roundEnded;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isTurn ? const Color(0xFF5A25B8) : Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isTurn ? LammaColors.gold500 : Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF6A24C9),
                                child: Text(
                                  _names[pIdx].characters.first,
                                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_hands[pIdx].length} 🁣',
                                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // الطاولة الخضراء بدون Scroll (Snake Board)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: [Color(0xFF175E49), Color(0xFF0E3F31)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.7), width: 2),
                      ),
                      child: SnakeDominoBoard(
                        board: _board,
                        lastPlayedTile: _lastPlayedTile,
                        showLeftSlot: _currentTurn == 0 && sel != null && _canPlayOn(sel, 'left') && _board.isNotEmpty,
                        showRightSlot: _currentTurn == 0 && sel != null && _canPlayOn(sel, 'right'),
                        onTapLeftSlot: () => _playSelectedOn('left'),
                        onTapRightSlot: () => _playSelectedOn('right'),
                        emptyMessage: _statusBanner,
                      ),
                    ),
                  ),

                  // أزرار السحب الأوتوماتيك/اليدوي + الدق + شريط الحالة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _statusBanner,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                        if (canDraw && !_autoDraw)
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A4C),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _onDrawMyTile,
                            icon: const Icon(Icons.add_box_rounded, color: Colors.white, size: 22),
                            tooltip: 'اسحب',
                          )
                        else if (canPass)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: _onPassMyTurn,
                            child: Text('دق (باص)', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),

                  // يد اللاعب
                  Container(
                    height: 92,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF180A33),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(top: BorderSide(color: Colors.white12)),
                    ),
                    child: Center(
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: _hands[0].length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, idx) {
                          final tile = _hands[0][idx];
                          final playable = _canPlayOn(tile, 'left') || _canPlayOn(tile, 'right');
                          final isSel = sel != null && sel[0] == tile[0] && sel[1] == tile[1];
                          return GestureDetector(
                            onTap: () => _onTapMyTile(tile),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              transform: Matrix4.translationValues(0, isSel ? -8 : 0, 0),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? LammaColors.gold500 : (playable ? LammaColors.gold500.withValues(alpha: 0.4) : Colors.transparent),
                                  width: isSel ? 2.2 : 1.2,
                                ),
                              ),
                              child: Opacity(
                                opacity: playable ? 1.0 : 0.45,
                                child: DominoTileWidget(a: tile[0], b: tile[1], isVertical: true, scale: 0.80),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              if (_roundEnded)
                Container(
                  color: Colors.black.withValues(alpha: 0.78),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF211044),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: LammaColors.gold500, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: LammaColors.gold500, size: 54),
                          const SizedBox(height: 8),
                          Text(
                            _matchOver
                                ? 'انتهى الجيم! 🏆'
                                : (_blockedWin ? 'قفلت الطاولة! 🔒' : 'انتهى الدور! 🎉'),
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'فاز ${_names[_winnerIdx]} وحصد +$_pointsWon نقطة',
                            style: GoogleFonts.cairo(color: LammaColors.gold300, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 18),
                          GameButton(
                            text: _matchOver ? 'العودة للرئيسية 🏠' : 'الدور الجاي 🔄',
                            showArrow: false,
                            height: 50,
                            onPressed: () {
                              if (_matchOver) {
                                context.go('/home');
                              } else {
                                _roundNumber++;
                                _dealRound(preferredStarter: _winnerIdx);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
