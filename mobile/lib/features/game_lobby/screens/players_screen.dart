import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/game_session.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class DefaultPlayerInfo {
  final String name;
  final bool isMale;
  final String avatar;

  const DefaultPlayerInfo({
    required this.name,
    required this.isMale,
    required this.avatar,
  });
}

const List<DefaultPlayerInfo> kDefaultPlayers = [
  DefaultPlayerInfo(name: 'ياسين', isMale: true, avatar: 'assets/images/av-ahmed.png'),
  DefaultPlayerInfo(name: 'رانيا', isMale: false, avatar: 'assets/images/av-sara.png'),
  DefaultPlayerInfo(name: 'ياسمين', isMale: false, avatar: 'assets/images/av-mena.png'),
  DefaultPlayerInfo(name: 'سيلين', isMale: false, avatar: 'assets/images/av-sara.png'),
  DefaultPlayerInfo(name: 'أسامة', isMale: true, avatar: 'assets/images/av-karim.png'),
  DefaultPlayerInfo(name: 'إيناس', isMale: false, avatar: 'assets/images/av-mena.png'),
  DefaultPlayerInfo(name: 'آيسن', isMale: false, avatar: 'assets/images/av-sara.png'),
  DefaultPlayerInfo(name: 'شدن', isMale: false, avatar: 'assets/images/av-mena.png'),
  DefaultPlayerInfo(name: 'محمد', isMale: true, avatar: 'assets/images/av-mahmoud.png'),
  DefaultPlayerInfo(name: 'أماني', isMale: false, avatar: 'assets/images/av-sara.png'),
  DefaultPlayerInfo(name: 'عمر', isMale: true, avatar: 'assets/images/av-ahmed.png'),
  DefaultPlayerInfo(name: 'ليان', isMale: false, avatar: 'assets/images/av-mena.png'),
  DefaultPlayerInfo(name: 'أميرة', isMale: false, avatar: 'assets/images/av-sara.png'),
  DefaultPlayerInfo(name: 'مليكة', isMale: false, avatar: 'assets/images/av-mena.png'),
];

class TeamModel {
  String name;
  Color color;
  List<String> players;

  TeamModel({
    required this.name,
    required this.color,
    required this.players,
  });
}

class PlayersScreen extends StatefulWidget {
  final String targetRoute;
  final String gameSlug;
  final String gameTitle;
  final int totalRounds;
  final int playersCount;

  const PlayersScreen({
    super.key,
    this.targetRoute = '/game/amthal',
    this.gameSlug = 'amthal-shaabiya',
    this.gameTitle = 'أمثال شعبية',
    this.totalRounds = 10,
    this.playersCount = 4,
  });

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  bool _isTeamsMode = true;
  final TextEditingController _newPlayerController = TextEditingController();

  final List<Color> _presetColors = const [
    Color(0xFFA35BFF), // بنفسجي
    Color(0xFFFF8A4C), // برتقالي
    Color(0xFF35B88E), // أخضر مائي
    Color(0xFFF2569A), // وردي
    Color(0xFFFFD27A), // ذهبي
    Color(0xFF38B6FF), // سماوي
  ];

  late List<TeamModel> _teams;
  late List<String> _soloPlayers;
  int _selectedTeamIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetToDefaults();
  }

  void _resetToDefaults() {
    final count = widget.playersCount.clamp(2, kDefaultPlayers.length);
    final selected = kDefaultPlayers.take(count).map((p) => p.name).toList();

    // توزيع اللاعبين على الفريقين بالتساوي
    final half = (selected.length / 2).ceil();
    final team1Players = selected.take(half).toList();
    final team2Players = selected.skip(half).toList();

    _teams = [
      TeamModel(
        name: 'فريق البنفسج',
        color: _presetColors[0],
        players: team1Players,
      ),
      TeamModel(
        name: 'فريق البرتقان',
        color: _presetColors[1],
        players: team2Players,
      ),
    ];
    _soloPlayers = List<String>.from(selected);
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var t in _teams) {
        t.players.clear();
      }
      _soloPlayers.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح جميع الأسماء، أضف أسماءك الخاصة الآن ✍️'),
        backgroundColor: Color(0xFF2A1050),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  void dispose() {
    _newPlayerController.dispose();
    super.dispose();
  }

  void _shuffleTeams() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isTeamsMode) {
        final all = _teams.expand((t) => t.players).toList()..shuffle();
        for (var t in _teams) {
          t.players.clear();
        }
        for (int i = 0; i < all.length; i++) {
          _teams[i % _teams.length].players.add(all[i]);
        }
      } else {
        _soloPlayers.shuffle();
      }
    });
  }

  void _addPlayer() {
    final text = _newPlayerController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      if (_isTeamsMode) {
        if (_selectedTeamIndex < _teams.length) {
          _teams[_selectedTeamIndex].players.add(text);
        } else {
          _teams.first.players.add(text);
        }
      } else {
        _soloPlayers.add(text);
      }
      _newPlayerController.clear();
    });
  }

  void _showEditPlayerDialog(String currentName, Function(String newName) onSave) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241050),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'تعديل اسم اللاعب',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'الاسم الجديد',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LammaColors.orange500),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                onSave(newName);
                Navigator.pop(ctx);
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditTeamNameDialog(int teamIndex) {
    final team = _teams[teamIndex];
    final controller = TextEditingController(text: team.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241050),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'تعديل اسم الفرقة',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'مثال: فريق البنات أو الأبطال',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: team.color),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => team.name = newName);
                Navigator.pop(ctx);
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addNewTeam() {
    final defaultIndex = _teams.length;
    final color = _presetColors[defaultIndex % _presetColors.length];
    final defaultName = 'فرقة ${defaultIndex + 1}';
    final controller = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241050),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'إضافة فرقة جديدة',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'اسم الفرقة',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _teams.add(TeamModel(name: name, color: color, players: []));
                });
                Navigator.pop(ctx);
              }
            },
            child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  int get _totalPlayersCount {
    if (_isTeamsMode) {
      return _teams.fold(0, (sum, t) => sum + t.players.length);
    }
    return _soloPlayers.length;
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. الشريط العلوي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'مين بيلعب؟ ($_totalPlayersCount)',
                    style: GoogleFonts.cairo(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'خلط الفرق عشوائياً',
                        icon: const Icon(Icons.shuffle_rounded, color: LammaColors.gold500, size: 24),
                        onPressed: _shuffleTeams,
                      ),
                      IconButton(
                        tooltip: 'مسح كل الأسماء',
                        icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF5252), size: 24),
                        onPressed: _clearAll,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 2. زر التبديل بين نمط الفرق والفردي
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: LammaColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isTeamsMode = true),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: _isTeamsMode ? LammaGradients.ctaSecondary : null,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _isTeamsMode
                                ? [BoxShadow(color: LammaColors.violet500.withValues(alpha: 0.55), blurRadius: 16)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'فِرق ومجموعات 👥',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: _isTeamsMode ? FontWeight.w900 : FontWeight.w700,
                                color: _isTeamsMode ? Colors.white : const Color(0xFFCFC6E4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isTeamsMode = false),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: !_isTeamsMode ? LammaGradients.ctaSecondary : null,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'فردي بالتناوب 📱',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: !_isTeamsMode ? FontWeight.w900 : FontWeight.w700,
                                color: !_isTeamsMode ? Colors.white : const Color(0xFFCFC6E4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. محتوى الفرق أو اللاعبين الفرديين
              Expanded(
                child: _isTeamsMode ? _buildTeamsList() : _buildSoloList(),
              ),

              const SizedBox(height: 10),

              // 4. حقل إضافة لاعب جديد
              _buildAddPlayerBar(),

              const SizedBox(height: 10),

              // 5. زر بدء اللعبة
              GameButton(
                text: 'ابدأ اللعبة 🚀',
                onPressed: _totalPlayersCount >= 2
                    ? _startGame
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('أضف لاعبين اثنين على الأقل لبدء اللعبة!'),
                            backgroundColor: Color(0xFFE94560),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  String _getAvatarForPlayer(String name, int index) {
    final matched = kDefaultPlayers.where((p) => p.name.trim() == name.trim()).firstOrNull;
    if (matched != null) {
      return matched.avatar;
    }
    final maleAvatars = [
      'assets/images/av-ahmed.png',
      'assets/images/av-karim.png',
      'assets/images/av-mahmoud.png',
    ];
    final femaleAvatars = [
      'assets/images/av-sara.png',
      'assets/images/av-mena.png',
    ];

    final isMale = _isMaleName(name);
    return isMale
        ? maleAvatars[index % maleAvatars.length]
        : femaleAvatars[index % femaleAvatars.length];
  }

  bool _isMaleName(String name) {
    const males = {
      'ياسين',
      'أسامة',
      'محمد',
      'عمر',
      'أحمد',
      'كريم',
      'محمود',
      'علي',
      'حازم',
      'مصطفى',
      'إبراهيم',
      'طارق',
      'يوسف',
      'خالد',
      'حسن',
      'حسين'
    };
    return males.contains(name.trim());
  }

  void _startGame() async {
    // 1. جمع اللاعبين الفعليين
    final List<GamePlayer> gamePlayers = [];
    int playerIndex = 0;

    if (_isTeamsMode) {
      for (final team in _teams) {
        for (final pName in team.players) {
          gamePlayers.add(
            GamePlayer(
              id: UniqueKey().toString(),
              name: pName,
              teamName: team.name,
              avatar: _getAvatarForPlayer(pName, playerIndex),
              teamColor: team.color,
            ),
          );
          playerIndex++;
        }
      }
    } else {
      for (final pName in _soloPlayers) {
        gamePlayers.add(
          GamePlayer(
            id: UniqueKey().toString(),
            name: pName,
            teamName: 'المتنافسين',
            avatar: _getAvatarForPlayer(pName, playerIndex),
            teamColor: const Color(0xFFA35BFF),
          ),
        );
        playerIndex++;
      }
    }

    if (gamePlayers.length < 2) {
      gamePlayers.addAll([
        GamePlayer(
          id: '1',
          name: 'ياسين',
          teamName: 'فريق البنفسج',
          avatar: 'assets/images/av-ahmed.png',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '2',
          name: 'رانيا',
          teamName: 'فريق البرتقان',
          avatar: 'assets/images/av-sara.png',
          teamColor: const Color(0xFFFF8A4C),
        ),
      ]);
    }

    // 2. جلب الأسئلة الفعلية
    final cardsRaw = await ApiService.instance.getGameCards(widget.gameSlug);
    final questions = cardsRaw.map((c) => GameQuestion.fromMap(c)).toList();

    // 3. بناء جلسة اللعبة
    final session = GameSession(
      gameSlug: widget.gameSlug,
      gameTitle: widget.gameTitle,
      gameRoute: widget.targetRoute,
      totalRounds: widget.totalRounds,
      players: gamePlayers,
      questions: questions,
      currentRoundIndex: 0,
    );

    if (!mounted) return;
    context.push(widget.targetRoute, extra: session);
  }

  Widget _buildTeamsList() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ...List.generate(_teams.length, (index) => _buildTeamCard(index)),
        const SizedBox(height: 8),
        // زر إضافة فرقة جديدة
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: LammaColors.orange300,
            side: const BorderSide(color: LammaColors.orange300, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _addNewTeam,
          icon: const Icon(Icons.group_add_rounded),
          label: Text(
            '+ إضافة فرقة جديدة',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(int index) {
    final team = _teams[index];
    final isSelected = _selectedTeamIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1142),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? team.color : Colors.white12,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showEditTeamNameDialog(index),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: team.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      team.name,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded, color: Colors.white38, size: 16),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${team.players.length} لاعبين',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700),
                  ),
                  if (_teams.length > 2) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                      onPressed: () {
                        setState(() {
                          _teams.removeAt(index);
                          if (_selectedTeamIndex >= _teams.length) {
                            _selectedTeamIndex = 0;
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (team.players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                'لا يوجد لاعبين في هذه الفرقة، اكتب اسماً بالأسفل لإضافته',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.white38),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: team.players.map((p) {
                return _buildPlayerChip(
                  name: p,
                  color: team.color,
                  onEdit: () {
                    _showEditPlayerDialog(p, (newName) {
                      setState(() {
                        final idx = team.players.indexOf(p);
                        if (idx != -1) team.players[idx] = newName;
                      });
                    });
                  },
                  onDelete: () {
                    setState(() => team.players.remove(p));
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSoloList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1142),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: _soloPlayers.isEmpty
          ? Center(
              child: Text(
                'لا يوجد لاعبين حالياً، أضف أسماء اللاعبين بالأسفل ✍️',
                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _soloPlayers.map((p) {
                    return _buildPlayerChip(
                      name: p,
                      color: LammaColors.gold500,
                      onEdit: () {
                        _showEditPlayerDialog(p, (newName) {
                          setState(() {
                            final idx = _soloPlayers.indexOf(p);
                            if (idx != -1) _soloPlayers[idx] = newName;
                          });
                        });
                      },
                      onDelete: () {
                        setState(() => _soloPlayers.remove(p));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerChip({
    required String name,
    required Color color,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onEdit,
            child: Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_rounded, color: Colors.white54, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlayerBar() {
    return Row(
      children: [
        if (_isTeamsMode && _teams.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF241050),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _teams[_selectedTeamIndex % _teams.length].color),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedTeamIndex < _teams.length ? _selectedTeamIndex : 0,
                dropdownColor: const Color(0xFF241050),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                items: List.generate(_teams.length, (i) {
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _teams[i].color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          _teams[i].name,
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTeamIndex = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LammaColors.cardBorder),
            ),
            child: TextField(
              controller: _newPlayerController,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'اكتب اسم لاعب جديد...',
                hintStyle: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addPlayer,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LammaGradients.ctaPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}
