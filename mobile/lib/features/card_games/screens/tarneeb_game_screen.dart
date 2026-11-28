import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../models/playing_card.dart';
import '../widgets/card_table_scaffold.dart';
import '../widgets/playing_card_widget.dart';

class TarneebGameScreen extends StatefulWidget {
  final int targetScore;
  final int turnSeconds;
  final bool isLandscape;

  const TarneebGameScreen({
    super.key,
    this.targetScore = 41,
    this.turnSeconds = 30,
    this.isLandscape = false,
  });

  @override
  State<TarneebGameScreen> createState() => _TarneebGameScreenState();
}

class _TarneebGameScreenState extends State<TarneebGameScreen> {
  late bool _isLandscape;
  late List<List<PlayingCard>> _hands;
  final List<int> _teamScores = [0, 0];
  final List<int> _teamTricks = [0, 0];
  final List<PlayingCard?> _currentTrick = [null, null, null, null];

  bool _isBidding = true;
  int _highBid = 0;
  CardSuit _highSuit = CardSuit.clubs;
  int _declarer = 0;
  int _consecutivePasses = 0;
  bool _isDoubled = false;
  CardSuit? _trumpSuit;
  CardSuit? _ledSuit;
  int _currentTurn = 0;
  int _trickLeader = 0;
  int _tricksPlayed = 0;

  int _pickerNumber = 7;
  CardSuit _pickerSuit = CardSuit.spades;

  final List<String> _names = ['أنت', 'كريم 🤖', 'شريكك 🤖', 'ياسين 🤖'];
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
    _startNewHand();
  }

  void _startNewHand() {
    final deck = PlayingCard.standardDeck();
    _hands = List.generate(4, (_) => []);
    for (int i = 0; i < 52; i++) {
      _hands[i % 4].add(deck[i]);
    }
    for (final h in _hands) {
      PlayingCard.sortHand(h);
    }
    _teamTricks[0] = 0;
    _teamTricks[1] = 0;
    for (int i = 0; i < 4; i++) {
      _currentTrick[i] = null;
    }
    _isBidding = true;
    _highBid = 0;
    _highSuit = CardSuit.clubs;
    _declarer = 0;
    _consecutivePasses = 0;
    _isDoubled = false;
    _trumpSuit = null;
    _ledSuit = null;
    _tricksPlayed = 0;
    _currentTurn = 0;
    _pickerNumber = 7;
    _pickerSuit = CardSuit.spades;
    setState(() {});
  }

  bool _isBidHigher(int num, CardSuit suit) {
    if (_highBid == 0) return num >= 7 && num <= 13;
    if (num > _highBid) return true;
    if (num == _highBid && suit.index > _highSuit.index) return true;
    return false;
  }

  void _submitBid(int player, int num, CardSuit suit) {
    setState(() {
      _highBid = num;
      _highSuit = suit;
      _declarer = player;
      _consecutivePasses = 0;
    });
    _advanceBidding();
  }

  void _submitPass({bool isDouble = false}) {
    setState(() {
      if (isDouble) _isDoubled = true;
      _consecutivePasses++;
    });
    if (_highBid > 0 && _consecutivePasses >= 3) {
      setState(() {
        _isBidding = false;
        _trumpSuit = _highSuit;
        _currentTurn = _declarer;
        _trickLeader = _declarer;
      });
      if (_currentTurn != 0) _scheduleBotPlay();
      return;
    }
    if (_highBid == 0 && _consecutivePasses >= 4) {
      _startNewHand();
      return;
    }
    _advanceBidding();
  }

  void _advanceBidding() {
    _currentTurn = (_currentTurn + 1) % 4;
    if (_currentTurn != 0) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted || !_isBidding) return;
        _botBid(_currentTurn);
      });
    }
  }

  void _botBid(int p) {
    // تقييم بسيط ليد البوت
    final suitCounts = <CardSuit, int>{};
    for (final c in _hands[p]) {
      suitCounts[c.suit] = (suitCounts[c.suit] ?? 0) + 1;
    }
    final bestEntry = suitCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final est = (bestEntry.value + 2).clamp(6, 10);
    if (est >= 7 && _isBidHigher(est, bestEntry.key)) {
      _submitBid(p, est, bestEntry.key);
    } else {
      _submitPass();
    }
  }

  List<PlayingCard> _legalCards(int p) {
    final hand = _hands[p];
    if (_ledSuit == null) return hand;
    final matching = hand.where((c) => c.suit == _ledSuit).toList();
    return matching.isNotEmpty ? matching : hand;
  }

  void _playCard(int p, PlayingCard card) {
    if (_isBidding || _currentTurn != p) return;
    if (!_legalCards(p).contains(card)) return;
    SoundService.instance.playClick();

    setState(() {
      _hands[p].remove(card);
      _currentTrick[p] = card;
      _ledSuit ??= card.suit;
    });

    if (_currentTrick.every((c) => c != null)) {
      // تحديد الفائز بالأكلة
      int winner = _trickLeader;
      PlayingCard best = _currentTrick[winner]!;
      for (int i = 1; i < 4; i++) {
        final idx = (_trickLeader + i) % 4;
        final c = _currentTrick[idx]!;
        final cIsTrump = c.suit == _trumpSuit;
        final bIsTrump = best.suit == _trumpSuit;
        if (cIsTrump && !bIsTrump) {
          winner = idx;
          best = c;
        } else if (cIsTrump == bIsTrump && c.suit == best.suit && c.trickPower > best.trickPower) {
          winner = idx;
          best = c;
        }
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _teamTricks[winner % 2]++;
          _tricksPlayed++;
          for (int i = 0; i < 4; i++) {
            _currentTrick[i] = null;
          }
          _ledSuit = null;
          _trickLeader = winner;
          _currentTurn = winner;
        });
        if (_tricksPlayed >= 13) {
          _finishHand();
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
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || _isBidding || _currentTurn == 0) return;
      final legal = _legalCards(_currentTurn);
      if (legal.isNotEmpty) {
        _playCard(_currentTurn, legal.first);
      }
    });
  }

  void _finishHand() {
    final bidTeam = _declarer % 2;
    final otherTeam = 1 - bidTeam;
    final taken = _teamTricks[bidTeam];
    final mult = _isDoubled ? 2 : 1;

    if (taken >= _highBid) {
      final pts = (_highBid == 13 ? 26 : (taken == 13 ? 16 : taken)) * mult;
      _teamScores[bidTeam] += pts;
    } else {
      final loss = (_highBid == 13 ? 16 : _highBid) * mult;
      _teamScores[bidTeam] -= loss;
      _teamScores[otherTeam] += _teamTricks[otherTeam] * mult;
    }

    final matchOver = _teamScores[0] >= widget.targetScore || _teamScores[1] >= widget.targetScore;
    if (matchOver && AuthService.instance.isLoggedIn) {
      ApiService.instance.recordGameScore(score: _teamTricks[0] * 2, isWin: _teamScores[0] >= widget.targetScore);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        title: Text(
          matchOver ? 'نهاية الماتش 🏆' : 'نتيجة اليد',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'طلب ${_names[_declarer]}: $_highBid ${_highSuit.suitSymbol}\n'
          'أكلات فريقك: ${_teamTricks[0]} | الخصم: ${_teamTricks[1]}\n'
          'الإجمالي: فريقك ${_teamScores[0]} - ${_teamScores[1]} الخصم',
          style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w700),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
            onPressed: () {
              Navigator.pop(ctx);
              if (matchOver) {
                _teamScores[0] = 0;
                _teamScores[1] = 0;
              }
              _startNewHand();
            },
            child: Text(matchOver ? 'ماتش جديد' : 'اليد التالية', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final legal = _isBidding ? <PlayingCard>[] : _legalCards(0);

    return CardTableScaffold(
      title: 'طرنيب مصري',
      roundSummary: _isBidding
          ? 'مرحلة المزايدة • أعلى طلب: ${_highBid > 0 ? '$_highBid ${_highSuit.suitSymbol}' : 'لا يوجد'}'
          : 'الحكم: ${_trumpSuit?.suitSymbol ?? ''} (${_names[_declarer]} $_highBid) • الأكلات ${_teamTricks[0]}-${_teamTricks[1]}',
      scoreSummary: 'فريقك ${_teamScores[0]} - ${_teamScores[1]} / ${widget.targetScore}',
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
              );
            }).toList(),
          ),
          const Spacer(),
          if (_isBidding && _currentTurn == 0)
            _buildBiddingPanel()
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
                    child: Center(
                      child: Text(_names[i].characters.first, style: GoogleFonts.cairo(color: Colors.white38)),
                    ),
                  );
                }
                return PlayingCardWidget(card: c, width: 54);
              }),
            ),
          const Spacer(),
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
            final canPlay = !_isBidding && _currentTurn == 0 && legal.contains(c);
            return PlayingCardWidget(
              card: c,
              width: _isLandscape ? 52 : 60,
              state: _isBidding
                  ? CardVisualState.normal
                  : (canPlay ? CardVisualState.playable : CardVisualState.disabled),
              onTap: canPlay ? () => _playCard(0, c) : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBiddingPanel() {
    final validBid = _isBidHigher(_pickerNumber, _pickerSuit);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F0C3C).withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LammaColors.gold500.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('دورك في المزايدة', style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) => 7 + i).map((n) {
              final sel = _pickerNumber == n;
              return GestureDetector(
                onTap: () => setState(() => _pickerNumber = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFA35BFF) : Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$n', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: CardSuit.values.map((s) {
              final sel = _pickerSuit == s;
              final sym = PlayingCard(suit: s, rank: CardRank.ace).suitSymbol;
              return GestureDetector(
                onTap: () => setState(() => _pickerSuit = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? LammaColors.gold500 : Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(sym, style: TextStyle(fontSize: 18, color: sel ? Colors.black : Colors.white)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4FD1A5)),
                onPressed: validBid ? () => _submitBid(0, _pickerNumber, _pickerSuit) : null,
                child: Text(
                  'زايد $_pickerNumber ${PlayingCard(suit: _pickerSuit, rank: CardRank.ace).suitSymbol}',
                  style: GoogleFonts.cairo(color: const Color(0xFF0E2A22), fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _submitPass(),
                child: Text('باص', style: GoogleFonts.cairo(color: Colors.white70, fontWeight: FontWeight.w800)),
              ),
              if (_highBid > 0 && _declarer % 2 != 0 && !_isDoubled) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => _submitPass(isDouble: true),
                  child: Text('دبل', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
