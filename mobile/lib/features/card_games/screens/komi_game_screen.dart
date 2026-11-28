import 'dart:async';
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

class KomiGameScreen extends StatefulWidget {
  final int playersCount;
  final int targetScore;
  final int turnSeconds;
  final bool isLandscape;
  final String botDifficulty;

  const KomiGameScreen({
    super.key,
    this.playersCount = 2,
    this.targetScore = 121,
    this.turnSeconds = 30,
    this.isLandscape = false,
    this.botDifficulty = 'medium',
  });

  @override
  State<KomiGameScreen> createState() => _KomiGameScreenState();
}

class _KomiGameScreenState extends State<KomiGameScreen> {
  late bool _isLandscape;
  late List<List<PlayingCard>> _hands;
  late List<PlayingCard> _floor;
  late List<PlayingCard> _deck;
  late List<int> _teamCapturedCount;
  late List<int> _teamBasraCount;
  late List<int> _teamScores;
  late List<List<PlayingCard>> _teamCapturedCards;

  int _currentTurn = 0; // 0 = أنا
  int _dealNumber = 1;
  int _lastCapturerTeam = 0;
  int _carriedMajorityBonus = 0;
  PlayingCard? _selectedCard;
  List<PlayingCard> _previewCaptures = [];
  String _hintText = 'اختر ورقة من يدك للعب';
  String? _basraToast;
  int _secondsLeft = 30;
  Timer? _timer;
  bool _handEnded = false;

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
    _teamScores = [0, 0];
    _startNewHand();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewHand() {
    _deck = PlayingCard.standardDeck();
    _hands = List.generate(widget.playersCount, (_) => []);
    _floor = [];
    _teamCapturedCount = [0, 0];
    _teamBasraCount = [0, 0];
    _teamCapturedCards = [[], []];
    _dealNumber = 1;
    _handEnded = false;
    _selectedCard = null;
    _previewCaptures = [];

    for (int i = 0; i < 4; i++) {
      for (int p = 0; p < widget.playersCount; p++) {
        _hands[p].add(_deck.removeLast());
      }
    }
    PlayingCard.sortHand(_hands[0]);

    // 4 ورقات على الأرض بدون J أو 7♦
    while (_floor.length < 4 && _deck.isNotEmpty) {
      final c = _deck.removeLast();
      if (c.rank == CardRank.jack || c.isKomiSeven) {
        _deck.insert(_deck.length ~/ 2, c);
      } else {
        _floor.add(c);
      }
    }

    _currentTurn = 0;
    _hintText = 'اختر ورقة من يدك للعب';
    _startTurnTimer();
    setState(() {});
  }

  void _dealNextRoundOfHand() {
    if (_deck.length < widget.playersCount * 4) {
      _finishHand();
      return;
    }
    _dealNumber++;
    for (int i = 0; i < 4; i++) {
      for (int p = 0; p < widget.playersCount; p++) {
        _hands[p].add(_deck.removeLast());
      }
    }
    PlayingCard.sortHand(_hands[0]);
    setState(() {});
  }

  void _startTurnTimer() {
    _timer?.cancel();
    _secondsLeft = widget.turnSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _handEnded) {
        t.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        if (_currentTurn == 0 && _hands[0].isNotEmpty) {
          _playCard(0, _hands[0].first);
        }
      }
    });
  }

  List<PlayingCard> _computeCaptures(PlayingCard played, List<PlayingCard> floor) {
    if (floor.isEmpty) return [];
    if (played.rank == CardRank.jack || played.isKomiSeven) {
      return List<PlayingCard>.from(floor);
    }
    if (played.rank == CardRank.queen || played.rank == CardRank.king) {
      return floor.where((c) => c.rank == played.rank).toList();
    }

    final target = played.komiValue;
    final directMatches = floor.where((c) => c.rank == played.rank).toList();
    final remaining = floor.where((c) => c.rank != played.rank && c.komiValue > 0 && c.komiValue < target).toList();

    // إيجاد أكبر مجموعة ورقات منفصلة مجموعها يساوي target
    final bestCombo = _findMaxDisjointSum(remaining, target);
    return [...directMatches, ...bestCombo];
  }

  List<PlayingCard> _findMaxDisjointSum(List<PlayingCard> cards, int target) {
    final subsets = <List<int>>[];
    void dfs(int idx, int sum, List<int> cur) {
      if (sum == target && cur.isNotEmpty) {
        subsets.add(List<int>.from(cur));
        return;
      }
      if (sum > target || idx >= cards.length) return;
      cur.add(idx);
      dfs(idx + 1, sum + cards[idx].komiValue, cur);
      cur.removeLast();
      dfs(idx + 1, sum, cur);
    }

    dfs(0, 0, []);
    if (subsets.isEmpty) return [];

    List<int> bestIndices = [];
    void pickDisjoint(int sIdx, int usedMask, List<int> picked) {
      if (picked.length > bestIndices.length) {
        bestIndices = List<int>.from(picked);
      }
      for (int i = sIdx; i < subsets.length; i++) {
        int mask = 0;
        bool overlap = false;
        for (final idx in subsets[i]) {
          final bit = 1 << idx;
          if ((usedMask & bit) != 0) {
            overlap = true;
            break;
          }
          mask |= bit;
        }
        if (!overlap) {
          pickDisjoint(i + 1, usedMask | mask, [...picked, ...subsets[i]]);
        }
      }
    }

    pickDisjoint(0, 0, []);
    return bestIndices.map((i) => cards[i]).toList();
  }

  void _onSelectMyCard(PlayingCard card) {
    if (_currentTurn != 0 || _handEnded) return;
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();

    if (_selectedCard == card) {
      _playCard(0, card);
      return;
    }

    final captures = _computeCaptures(card, _floor);
    String hint;
    if (card.rank == CardRank.jack) {
      hint = _floor.isEmpty ? 'الأرض فاضية — الولد هينزل على الأرض' : 'الولد بيكنس كل ورق الأرض (${_floor.length})';
    } else if (card.isKomiSeven) {
      hint = _floor.isEmpty ? 'الأرض فاضية — الكومي هينزل على الأرض' : 'الكومي 7♦ بيكنس كل الأرض (${_floor.length})';
    } else if (captures.isEmpty) {
      hint = 'مش هتاكل حاجة — اضغط تاني لرميها';
    } else {
      hint = '${card.rankLabel} هتاكل ${captures.length} ورقات — اضغط تاني للتأكيد';
    }

    setState(() {
      _selectedCard = card;
      _previewCaptures = captures;
      _hintText = hint;
    });
  }

  void _playCard(int playerIdx, PlayingCard card) {
    if (_handEnded) return;
    _timer?.cancel();
    final teamIdx = playerIdx % 2;
    final isVeryLastCard = _deck.isEmpty && _hands.every((h) => h.length <= 1);
    final captures = _computeCaptures(card, _floor);

    setState(() {
      _hands[playerIdx].remove(card);
      _selectedCard = null;
      _previewCaptures = [];

      if (captures.isEmpty) {
        _floor.add(card);
        if (playerIdx == 0) SoundService.instance.playClick();
      } else {
        final floorHadNoFaces = !_floor.any((c) => c.isFaceCard);
        final floorSum = _floor.fold<int>(0, (s, c) => s + c.komiValue);
        for (final c in captures) {
          _floor.remove(c);
        }
        _teamCapturedCards[teamIdx].add(card);
        _teamCapturedCards[teamIdx].addAll(captures);
        _teamCapturedCount[teamIdx] += 1 + captures.length;
        _lastCapturerTeam = teamIdx;

        // فحص البصرة
        bool isBasra = false;
        if (_floor.isEmpty && !isVeryLastCard) {
          if (card.isKomiSeven) {
            isBasra = floorHadNoFaces && floorSum <= 10;
          } else if (card.rank != CardRank.jack) {
            isBasra = true;
          }
        }
        if (isBasra) {
          _teamBasraCount[teamIdx]++;
          _basraToast = 'بصرة! 🎉 (${_names[playerIdx]})';
          SoundService.instance.playCorrect();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _basraToast = null);
          });
        } else if (playerIdx == 0) {
          SoundService.instance.playClick();
        }
      }
    });

    // فحص نهاية التوزيعة أو اليد
    if (_hands.every((h) => h.isEmpty)) {
      if (_deck.isNotEmpty) {
        _dealNextRoundOfHand();
      } else {
        _finishHand();
        return;
      }
    }

    _currentTurn = (_currentTurn + 1) % widget.playersCount;
    if (_currentTurn == 0) {
      setState(() => _hintText = 'دورك — اختر ورقة من يدك');
      _startTurnTimer();
    } else {
      setState(() => _hintText = 'دور ${_names[_currentTurn]}...');
      Future.delayed(const Duration(milliseconds: 850), () {
        if (mounted && !_handEnded && _currentTurn != 0) {
          _playBotTurn(_currentTurn);
        }
      });
    }
  }

  void _playBotTurn(int pIdx) {
    final hand = _hands[pIdx];
    if (hand.isEmpty) return;
    PlayingCard chosen = hand.first;
    int bestCount = -1;
    for (final c in hand) {
      final caps = _computeCaptures(c, _floor);
      int score = caps.length * 10;
      if (widget.botDifficulty == 'medium' && (c.rank == CardRank.jack || c.isKomiSeven) && _floor.length < 3) {
        score -= 15; // البوت الذكي يحتفظ بالولد والكومي للأرض الكبيرة
      }
      if (score > bestCount) {
        bestCount = score;
        chosen = c;
      }
    }
    _playCard(pIdx, chosen);
  }

  void _finishHand() {
    _timer?.cancel();
    _handEnded = true;

    // باقي الأرض يذهب لآخر فريق أكل
    if (_floor.isNotEmpty) {
      _teamCapturedCards[_lastCapturerTeam].addAll(_floor);
      _teamCapturedCount[_lastCapturerTeam] += _floor.length;
      _floor.clear();
    }

    final handPoints = [0, 0];
    for (int t = 0; t < 2; t++) {
      int pts = _teamBasraCount[t] * 10;
      for (final c in _teamCapturedCards[t]) {
        if (c.rank == CardRank.ace) pts += 1;
        if (c.rank == CardRank.jack) pts += 1;
        if (c.suit == CardSuit.clubs && c.rank == CardRank.two) pts += 2;
        if (c.suit == CardSuit.diamonds && c.rank == CardRank.ten) pts += 3;
      }
      handPoints[t] = pts;
    }

    if (_teamCapturedCount[0] > _teamCapturedCount[1]) {
      handPoints[0] += 30 + _carriedMajorityBonus;
      _carriedMajorityBonus = 0;
    } else if (_teamCapturedCount[1] > _teamCapturedCount[0]) {
      handPoints[1] += 30 + _carriedMajorityBonus;
      _carriedMajorityBonus = 0;
    } else {
      _carriedMajorityBonus += 30;
    }

    _teamScores[0] += handPoints[0];
    _teamScores[1] += handPoints[1];

    final matchOver = _teamScores[0] >= widget.targetScore || _teamScores[1] >= widget.targetScore;
    if (matchOver && AuthService.instance.isLoggedIn) {
      ApiService.instance.recordGameScore(
        score: handPoints[0],
        isWin: _teamScores[0] > _teamScores[1],
      );
    }

    setState(() {});
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          matchOver ? (_teamScores[0] > _teamScores[1] ? 'مبروك! كسبت الماتش 🏆' : 'انتهى الماتش!') : 'نتيجة اليد',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'فريقك: +${handPoints[0]} (الإجمالي: ${_teamScores[0]})\nالخصم: +${handPoints[1]} (الإجمالي: ${_teamScores[1]})',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'الورق: ${_teamCapturedCount[0]} مقابل ${_teamCapturedCount[1]} • البصرة: ${_teamBasraCount[0]} - ${_teamBasraCount[1]}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
            onPressed: () {
              Navigator.pop(ctx);
              if (matchOver) {
                _teamScores = [0, 0];
                _carriedMajorityBonus = 0;
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
    final totalDeals = widget.playersCount == 2 ? 6 : 3;
    return CardTableScaffold(
      title: 'الكومي (البصرة)',
      roundSummary: 'التوزيعة $_dealNumber من $totalDeals • المتبقي ${_deck.length} ورقة',
      scoreSummary: 'أنت ${_teamScores[0]} - ${_teamScores[1]} / ${widget.targetScore}',
      isLandscape: _isLandscape,
      onToggleOrientation: () => setState(() => _isLandscape = !_isLandscape),
      tableContent: Stack(
        children: [
          Column(
            children: [
              // الخصوم بالأعلى
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: List.generate(widget.playersCount - 1, (idx) {
                  final p = idx + 1;
                  return CardSeatBadge(
                    name: _names[p],
                    avatarPath: _avatars[p],
                    cardsCount: _hands[p].length,
                    isTurn: _currentTurn == p,
                    subText: '${_hands[p].length} ورقة • بصرة ${_teamBasraCount[p % 2]}',
                  );
                }),
              ),
              const Spacer(),
              // ورق الأرض
              _floor.isEmpty
                  ? Text('الأرض فاضية ✨', style: GoogleFonts.cairo(color: Colors.white54, fontWeight: FontWeight.w700))
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: _floor.map((c) {
                        final willCapture = _previewCaptures.contains(c);
                        return PlayingCardWidget(
                          card: c,
                          width: _isLandscape ? 54 : 62,
                          state: _selectedCard != null
                              ? (willCapture ? CardVisualState.captured : CardVisualState.disabled)
                              : CardVisualState.normal,
                        );
                      }).toList(),
                    ),
              const Spacer(),
              Text(
                'أكلك: ${_teamCapturedCount[0]} ورقة • بصرة: ${_teamBasraCount[0]}',
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (_basraToast != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: LammaColors.gold500,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: LammaColors.gold500.withOpacity(0.5), blurRadius: 20)],
                ),
                child: Text(
                  _basraToast!,
                  style: GoogleFonts.cairo(color: const Color(0xFF1F0C3C), fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
      actionHintBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _hintText,
                style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            if (_selectedCard != null && _currentTurn == 0)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FD1A5),
                  foregroundColor: const Color(0xFF0E2A22),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => _playCard(0, _selectedCard!),
                child: Text('العب الورقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
          ],
        ),
      ),
      bottomHand: SizedBox(
        height: _isLandscape ? 88 : 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _hands[0].length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = _hands[0][i];
            final isSel = _selectedCard == c;
            return PlayingCardWidget(
              card: c,
              width: _isLandscape ? 56 : 66,
              state: _currentTurn != 0
                  ? CardVisualState.disabled
                  : (isSel ? CardVisualState.selected : CardVisualState.playable),
              onTap: () => _onSelectMyCard(c),
            );
          },
        ),
      ),
    );
  }
}
