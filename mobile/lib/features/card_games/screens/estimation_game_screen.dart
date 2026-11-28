import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../models/playing_card.dart';
import '../widgets/card_table_scaffold.dart';
import '../widgets/playing_card_widget.dart';

class EstimationGameScreen extends StatefulWidget {
  final int roundsCount;
  final int turnSeconds;
  final bool isLandscape;

  const EstimationGameScreen({
    super.key,
    this.roundsCount = 10,
    this.turnSeconds = 30,
    this.isLandscape = false,
  });

  @override
  State<EstimationGameScreen> createState() => _EstimationGameScreenState();
}

class _EstimationGameScreenState extends State<EstimationGameScreen> {
  late bool _isLandscape;
  late List<List<PlayingCard>> _hands;
  final List<int> _scores = [0, 0, 0, 0];
  final List<int> _estimates = [-1, -1, -1, -1];
  final List<int> _wonTricks = [0, 0, 0, 0];
  final List<PlayingCard?> _currentTrick = [null, null, null, null];

  int _round = 1;
  bool _isEstimating = true;
  CardSuit _trumpSuit = CardSuit.spades;
  int _caller = 0;
  int _callerBid = 4;
  CardSuit? _ledSuit;
  int _currentTurn = 0;
  int _trickLeader = 0;
  int _tricksPlayed = 0;

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
    _startRound();
  }

  void _startRound() {
    final deck = PlayingCard.standardDeck();
    _hands = List.generate(4, (_) => []);
    for (int i = 0; i < 52; i++) {
      _hands[i % 4].add(deck[i]);
    }
    for (final h in _hands) {
      PlayingCard.sortHand(h);
    }

    for (int i = 0; i < 4; i++) {
      _estimates[i] = -1;
      _wonTricks[i] = 0;
      _currentTrick[i] = null;
    }

    _trumpSuit = CardSuit.values[(_round - 1) % 4];
    _caller = (_round - 1) % 4;
    _callerBid = 5;
    _isEstimating = true;
    _ledSuit = null;
    _tricksPlayed = 0;
    _currentTurn = _caller;

    if (_currentTurn != 0) {
      _runBotEstimationsUntilMe();
    }
    setState(() {});
  }

  void _runBotEstimationsUntilMe() {
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || !_isEstimating) return;
      if (_currentTurn == 0) return;

      final est = _botEstimate(_currentTurn);
      setState(() => _estimates[_currentTurn] = est);
      _advanceEstimation();
    });
  }

  int _botEstimate(int p) {
    final sumSoFar = _estimates.where((e) => e >= 0).fold<int>(0, (s, e) => s + e);
    final isLast = _estimates.where((e) => e < 0).length == 1;
    int guess = _hands[p].where((c) => c.rank == CardRank.ace || c.rank == CardRank.king || c.suit == _trumpSuit).length.clamp(0, 6);
    if (isLast && sumSoFar + guess == 13) {
      guess = guess > 0 ? guess - 1 : guess + 1;
    }
    return guess;
  }

  void _submitMyEstimate(int val) {
    setState(() => _estimates[0] = val);
    _advanceEstimation();
  }

  void _advanceEstimation() {
    if (_estimates.every((e) => e >= 0)) {
      setState(() {
        _isEstimating = false;
        _currentTurn = _caller;
        _trickLeader = _caller;
      });
      if (_currentTurn != 0) _scheduleBotPlay();
      return;
    }
    _currentTurn = (_currentTurn + 1) % 4;
    setState(() {});
    if (_currentTurn != 0) _runBotEstimationsUntilMe();
  }

  List<PlayingCard> _legalCards(int p) {
    final hand = _hands[p];
    if (_ledSuit == null) return hand;
    final matching = hand.where((c) => c.suit == _ledSuit).toList();
    return matching.isNotEmpty ? matching : hand;
  }

  void _playCard(int p, PlayingCard card) {
    if (_isEstimating || _currentTurn != p) return;
    if (!_legalCards(p).contains(card)) return;
    SoundService.instance.playClick();

    setState(() {
      _hands[p].remove(card);
      _currentTrick[p] = card;
      _ledSuit ??= card.suit;
    });

    if (_currentTrick.every((c) => c != null)) {
      int winner = _trickLeader;
      PlayingCard best = _currentTrick[winner]!;
      for (int i = 1; i < 4; i++) {
        final idx = (_trickLeader + i) % 4;
        final c = _currentTrick[idx]!;
        final cTrump = c.suit == _trumpSuit;
        final bTrump = best.suit == _trumpSuit;
        if (cTrump && !bTrump) {
          winner = idx;
          best = c;
        } else if (cTrump == bTrump && c.suit == best.suit && c.trickPower > best.trickPower) {
          winner = idx;
          best = c;
        }
      }

      Future.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        setState(() {
          _wonTricks[winner]++;
          _tricksPlayed++;
          for (int i = 0; i < 4; i++) {
            _currentTrick[i] = null;
          }
          _ledSuit = null;
          _trickLeader = winner;
          _currentTurn = winner;
        });
        if (_tricksPlayed >= 13) {
          _finishRound();
        } else if (_currentTurn != 0) {
          _scheduleBotPlay();
        }
      });
    } else {
      _currentTurn = (_currentTurn + 1) % 4;
      setState(() {});
      if (_currentTurn != 0) _scheduleBotPlay();
    }
  }

  void _scheduleBotPlay() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _isEstimating || _currentTurn == 0) return;
      final legal = _legalCards(_currentTurn);
      if (legal.isNotEmpty) {
        _playCard(_currentTurn, legal.first);
      }
    });
  }

  void _finishRound() {
    final roundPts = List<int>.filled(4, 0);
    for (int i = 0; i < 4; i++) {
      final est = _estimates[i];
      final won = _wonTricks[i];
      if (est == 0 && won == 0) {
        final totalEst = _estimates.fold<int>(0, (s, e) => s + e);
        roundPts[i] = totalEst > 13 ? 25 : 33;
      } else if (won == est) {
        roundPts[i] = 10 + won + (i == _caller ? 10 : 0);
      } else {
        roundPts[i] = -(won - est).abs() - (i == _caller ? 10 : 0);
      }
      _scores[i] += roundPts[i];
    }

    final matchOver = _round >= widget.roundsCount;
    if (matchOver && AuthService.instance.isLoggedIn) {
      final maxScore = _scores.reduce((a, b) => a > b ? a : b);
      ApiService.instance.recordGameScore(score: _scores[0].clamp(0, 500), isWin: _scores[0] == maxScore);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        title: Text(
          matchOver ? 'نهاية الاستيميشن 🏆' : 'نتيجة الجولة $_round',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${_names[i]}: توقع ${_estimates[i]} / أكل ${_wonTricks[i]} (${roundPts[i] >= 0 ? '+' : ''}${roundPts[i]}) • الإجمالي: ${_scores[i]}',
                style: GoogleFonts.cairo(color: i == 0 ? LammaColors.gold500 : Colors.white70, fontSize: 13),
              ),
            );
          }),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
            onPressed: () {
              Navigator.pop(ctx);
              if (matchOver) {
                for (int i = 0; i < 4; i++) {
                  _scores[i] = 0;
                }
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
    final totalEst = _estimates.where((e) => e >= 0).fold<int>(0, (s, e) => s + e);
    final isLastEstimator = _estimates.where((e) => e < 0).length == 1;
    final lockedNumber = isLastEstimator ? (13 - totalEst) : -1;
    final legal = _isEstimating ? <PlayingCard>[] : _legalCards(0);

    return CardTableScaffold(
      title: 'استيميشن',
      roundSummary: 'الجولة $_round/${widget.roundsCount} • الحكم ${PlayingCard(suit: _trumpSuit, rank: CardRank.ace).suitSymbol} • المجموع $totalEst/13',
      scoreSummary: 'نقاطك: ${_scores[0]}',
      isLandscape: _isLandscape,
      onToggleOrientation: () => setState(() => _isLandscape = !_isLandscape),
      tableContent: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3].map((p) {
              return CardSeatBadge(
                name: _names[p],
                avatarPath: _avatars[p],
                cardsCount: _hands[p].length,
                isTurn: _currentTurn == p,
                subText: _estimates[p] >= 0 ? '${_wonTricks[p]}/${_estimates[p]}' : 'بيفكر...',
              );
            }).toList(),
          ),
          const Spacer(),
          if (_isEstimating && _currentTurn == 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F0C3C).withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LammaColors.gold500.withOpacity(0.6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('توقّع عدد أكلاتك (ممنوع المجموع يساوي 13)', style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_callerBid + 2, (n) {
                      final locked = n == lockedNumber;
                      return GestureDetector(
                        onTap: locked ? null : () => _submitMyEstimate(n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: locked ? Colors.red.withOpacity(0.25) : const Color(0xFFA35BFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: locked ? Colors.redAccent : LammaColors.gold500),
                          ),
                          child: Text(
                            locked ? '$n 🔒' : (n == 0 ? 'داش (0)' : '$n'),
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: List.generate(4, (i) {
                final c = _currentTrick[i];
                if (c == null) {
                  return Container(
                    width: 54,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(child: Text(_names[i].characters.first, style: GoogleFonts.cairo(color: Colors.white38))),
                  );
                }
                return PlayingCardWidget(card: c, width: 54);
              }),
            ),
          const Spacer(),
          Text(
            _estimates[0] >= 0 ? 'توقعك: ${_wonTricks[0]}/${_estimates[0]}' : 'اختر توقعك للجولة',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      bottomHand: SizedBox(
        height: _isLandscape ? 88 : 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _hands[0].length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final c = _hands[0][i];
            final canPlay = !_isEstimating && _currentTurn == 0 && legal.contains(c);
            return PlayingCardWidget(
              card: c,
              width: _isLandscape ? 52 : 60,
              state: _isEstimating
                  ? CardVisualState.normal
                  : (canPlay ? CardVisualState.playable : CardVisualState.disabled),
              onTap: canPlay ? () => _playCard(0, c) : null,
            );
          },
        ),
      ),
    );
  }
}
