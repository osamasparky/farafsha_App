import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../models/playing_card.dart';
import '../widgets/card_table_scaffold.dart';
import '../widgets/playing_card_widget.dart';

class ShayebGameScreen extends StatefulWidget {
  final int playersCount;
  final int roundsCount;
  final int turnSeconds;
  final bool isLandscape;

  const ShayebGameScreen({
    super.key,
    this.playersCount = 4,
    this.roundsCount = 5,
    this.turnSeconds = 20,
    this.isLandscape = false,
  });

  @override
  State<ShayebGameScreen> createState() => _ShayebGameScreenState();
}

class _ShayebGameScreenState extends State<ShayebGameScreen> {
  late bool _isLandscape;
  late List<List<PlayingCard>> _hands;
  late List<int> _scores;
  final List<int> _finishOrder = [];
  int _round = 1;
  int _currentTurn = 0;
  int? _selectedDrawIndex;
  String _statusMessage = '';

  final List<String> _names = ['أنت', 'كريم 🤖', 'سارة 🤖', 'ياسين 🤖'];
  final List<String> _avatars = [
    '',
    'assets/images/av-karim.webp',
    'assets/images/av-sara.webp',
    'assets/images/av-mahmoud.webp',
  ];

  @override
  void initState() {
    super.initState();
    _isLandscape = widget.isLandscape;
    _names[0] = AuthService.instance.userName.isNotEmpty ? AuthService.instance.userName : 'أنت';
    _avatars[0] = AuthService.instance.userAvatar;
    _scores = List.filled(widget.playersCount, 0);
    _startRound();
  }

  void _startRound() {
    final deck = PlayingCard.standardDeck(shayeb49: true);
    _hands = List.generate(widget.playersCount, (_) => []);
    for (int i = 0; i < deck.length; i++) {
      _hands[i % widget.playersCount].add(deck[i]);
    }
    _finishOrder.clear();
    _selectedDrawIndex = null;

    // رمي جميع الأزواج الأولية
    for (int p = 0; p < widget.playersCount; p++) {
      _discardPairs(_hands[p]);
      PlayingCard.sortHand(_hands[p]);
      if (_hands[p].isEmpty) {
        _finishOrder.add(p);
      }
    }

    _currentTurn = _nextActivePlayer(-1);
    _statusMessage = _currentTurn == 0
        ? 'اسحب ورقة مقلوبة من اللاعب السابق!'
        : 'دور ${_names[_currentTurn]} في السحب...';
    setState(() {});
    if (_currentTurn != 0) _scheduleBotDraw();
  }

  void _discardPairs(List<PlayingCard> hand) {
    final byRank = <CardRank, List<PlayingCard>>{};
    for (final c in hand) {
      byRank.putIfAbsent(c.rank, () => []).add(c);
    }
    hand.clear();
    for (final entry in byRank.entries) {
      if (entry.value.length.isOdd) {
        hand.add(entry.value.last);
      }
    }
  }

  int _previousActivePlayer(int from) {
    for (int step = 1; step < widget.playersCount; step++) {
      final p = (from - step + widget.playersCount) % widget.playersCount;
      if (_hands[p].isNotEmpty) return p;
    }
    return from;
  }

  int _nextActivePlayer(int from) {
    for (int step = 1; step <= widget.playersCount; step++) {
      final p = (from + step) % widget.playersCount;
      if (_hands[p].isNotEmpty) return p;
    }
    return 0;
  }

  void _drawFromTarget(int drawer, int cardIdx) {
    final target = _previousActivePlayer(drawer);
    if (target == drawer || cardIdx >= _hands[target].length) return;
    SettingsService.instance.triggerHaptic();

    setState(() {
      final drawn = _hands[target].removeAt(cardIdx);
      _hands[drawer].add(drawn);
      _selectedDrawIndex = null;

      final beforeLen = _hands[drawer].length;
      _discardPairs(_hands[drawer]);
      final discardedPair = _hands[drawer].length < beforeLen;
      PlayingCard.sortHand(_hands[drawer]);

      if (discardedPair && drawer == 0) {
        SoundService.instance.playCorrect();
        _statusMessage = 'كونت جوز ورميته تلقائياً! 🎉';
      } else {
        SoundService.instance.playClick();
      }

      if (_hands[target].isEmpty && !_finishOrder.contains(target)) {
        _finishOrder.add(target);
      }
      if (_hands[drawer].isEmpty && !_finishOrder.contains(drawer)) {
        _finishOrder.add(drawer);
      }
    });

    final activeCount = _hands.where((h) => h.isNotEmpty).length;
    if (activeCount <= 1) {
      _finishRound();
      return;
    }

    _currentTurn = _nextActivePlayer(drawer);
    setState(() {
      _statusMessage = _currentTurn == 0
          ? 'دورك! اسحب ورقة من ${_names[_previousActivePlayer(0)]}'
          : 'دور ${_names[_currentTurn]}...';
    });
    if (_currentTurn != 0) _scheduleBotDraw();
  }

  void _scheduleBotDraw() {
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || _currentTurn == 0) return;
      final target = _previousActivePlayer(_currentTurn);
      if (_hands[target].isEmpty) return;
      final idx = Random().nextInt(_hands[target].length);
      _drawFromTarget(_currentTurn, idx);
    });
  }

  void _finishRound() {
    final shayebHolder = _hands.indexWhere((h) => h.isNotEmpty);
    final ptsTable = widget.playersCount == 4
        ? [300, 150, 75, 0]
        : (widget.playersCount == 3 ? [300, 150, 0] : [300, 0]);

    for (int i = 0; i < _finishOrder.length; i++) {
      final p = _finishOrder[i];
      if (i < ptsTable.length) _scores[p] += ptsTable[i];
    }

    final matchOver = _round >= widget.roundsCount;
    if (matchOver && AuthService.instance.isLoggedIn) {
      final maxS = _scores.reduce(max);
      ApiService.instance.recordGameScore(score: (_scores[0] ~/ 20).clamp(5, 100), isWin: _scores[0] == maxS);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        title: Text(
          matchOver ? 'نهاية الشايب 🏆' : 'انتهت الجولة $_round',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'معاه الشايب 👴: ${shayebHolder >= 0 ? _names[shayebHolder] : '-'}\n\n${List.generate(widget.playersCount, (i) => '${_names[i]}: ${_scores[i]} نقطة').join('\n')}',
          style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w700),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
            onPressed: () {
              Navigator.pop(ctx);
              if (matchOver) {
                _scores = List.filled(widget.playersCount, 0);
                _round = 1;
              } else {
                _round++;
              }
              _startRound();
            },
            child: Text(matchOver ? 'لعب جديد' : 'الجولة التالية', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetPlayer = _previousActivePlayer(0);
    final targetCardsCount = _hands[targetPlayer].length;

    return CardTableScaffold(
      title: 'الشايب 👴',
      roundSummary: 'الجولة $_round من ${widget.roundsCount}',
      scoreSummary: 'نقاطك: ${_scores[0]}',
      isLandscape: _isLandscape,
      onToggleOrientation: () => setState(() => _isLandscape = !_isLandscape),
      tableContent: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: List.generate(widget.playersCount - 1, (idx) {
              final p = idx + 1;
              final finished = _hands[p].isEmpty;
              return CardSeatBadge(
                name: _names[p],
                avatarPath: _avatars[p],
                cardsCount: _hands[p].length,
                isTurn: _currentTurn == p,
                subText: finished ? 'خلّص ✅' : '${_hands[p].length} ورقة',
              );
            }),
          ),
          const Spacer(),
          Text(
            _currentTurn == 0
                ? 'اضغط على ورقة مقلوبة لسحبها من ${_names[targetPlayer]}:'
                : _statusMessage,
            style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: targetCardsCount,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final isSelected = _selectedDrawIndex == idx;
                return PlayingCardWidget(
                  faceDown: true,
                  width: 56,
                  state: _currentTurn == 0
                      ? (isSelected ? CardVisualState.selected : CardVisualState.playable)
                      : CardVisualState.disabled,
                  onTap: _currentTurn == 0
                      ? () {
                          if (_selectedDrawIndex == idx) {
                            _drawFromTarget(0, idx);
                          } else {
                            setState(() => _selectedDrawIndex = idx);
                          }
                        }
                      : null,
                );
              },
            ),
          ),
          if (_currentTurn == 0 && _selectedDrawIndex != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: LammaColors.gold500),
              onPressed: () => _drawFromTarget(0, _selectedDrawIndex!),
              child: Text('تأكيد السحب ✨', style: GoogleFonts.cairo(color: const Color(0xFF1F0C3C), fontWeight: FontWeight.w900)),
            ),
          ],
          const Spacer(),
        ],
      ),
      bottomHand: SizedBox(
        height: _isLandscape ? 88 : 104,
        child: _hands[0].isEmpty
            ? Center(
                child: Text('خلصت ورقك! في انتظار نهاية الجولة 🎉',
                    style: GoogleFonts.cairo(color: const Color(0xFF4FD1A5), fontWeight: FontWeight.w900)),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _hands[0].length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final c = _hands[0][i];
                  return PlayingCardWidget(
                    card: c,
                    width: _isLandscape ? 54 : 62,
                    badgeText: c.isShayeb ? 'الشايب!' : null,
                  );
                },
              ),
      ),
    );
  }
}
