import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class CardGameSetupScreen extends StatefulWidget {
  final String slug; // komi, tarneeb, estimation, shayeb
  final Map<String, dynamic>? gameData;

  const CardGameSetupScreen({
    super.key,
    required this.slug,
    this.gameData,
  });

  @override
  State<CardGameSetupScreen> createState() => _CardGameSetupScreenState();
}

class _CardGameSetupScreenState extends State<CardGameSetupScreen> {
  int _playersCount = 4;
  int _targetScore = 121;
  int _roundsCount = 5;
  int _turnSeconds = 30;
  bool _isLandscape = false;
  bool _botMedium = true;
  bool _isCreatingRoom = false;

  @override
  void initState() {
    super.initState();
    if (widget.slug == 'komi') {
      _playersCount = 2;
      _targetScore = 121;
    } else if (widget.slug == 'tarneeb') {
      _playersCount = 4;
      _targetScore = 41;
    } else if (widget.slug == 'estimation') {
      _playersCount = 4;
      _roundsCount = 10;
    } else if (widget.slug == 'shayeb') {
      _playersCount = 4;
      _roundsCount = 5;
    }
  }

  String get _title {
    switch (widget.slug) {
      case 'komi':
        return 'الكومي (البصرة) 🃏';
      case 'tarneeb':
        return 'طرنيب مصري ♠️';
      case 'estimation':
        return 'استيميشن 🎯';
      case 'shayeb':
        return 'الشايب 👴';
      default:
        return 'لعبة كوتشينة';
    }
  }

  String get _subtitle {
    switch (widget.slug) {
      case 'komi':
        return 'اجمع ورق الأرض بالمساواة أو الجمع، والولد والـ 7♦ بيكنسوا!';
      case 'tarneeb':
        return 'مزايدة 7–13 وتحديد حكم الطرنيب في فرق 2 ضد 2';
      case 'estimation':
        return 'توقّع عدد الأكلات بدقة — وممنوع مجموع التوقعات يساوي 13!';
      case 'shayeb':
        return 'تخلص من الأزواج المتشابهة ولا تبقَ معك ورقة الشايب K♥!';
      default:
        return '';
    }
  }

  void _playVsBots() {
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();
    context.push(
      '/card-play/${widget.slug}',
      extra: {
        'playersCount': _playersCount,
        'targetScore': _targetScore,
        'roundsCount': _roundsCount,
        'turnSeconds': _turnSeconds,
        'isLandscape': _isLandscape,
        'botDifficulty': _botMedium ? 'medium' : 'easy',
      },
    );
  }

  Future<void> _playOnlineWithFriends() async {
    setState(() => _isCreatingRoom = true);
    try {
      final hostName = AuthService.instance.userName.isNotEmpty
          ? AuthService.instance.userName
          : 'مضيف فرفشة';
      final data = await ApiService.instance.createRoom(
        gameSlug: widget.slug,
        hostName: hostName,
        totalRounds: _roundsCount,
        roundDurationSeconds: _turnSeconds,
        maxPlayers: _playersCount,
        targetScore: _targetScore,
      );
      if (!mounted) return;
      context.push(
        '/online-room',
        extra: {
          'code': data['room']['code'],
          'playerToken': data['player_token'],
          'isHost': true,
          'gameName': _title,
          'totalRounds': _roundsCount,
          'durationSeconds': _turnSeconds,
          'gameSlug': widget.slug,
          'maxPlayers': _playersCount,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingRoom = false);
    }
  }

  Widget _buildOptionChips<T>({
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((val) {
              final active = val == selected;
              return GestureDetector(
                onTap: () {
                  SoundService.instance.playClick();
                  onSelect(val);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFA35BFF) : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? LammaColors.gold500 : Colors.white24),
                  ),
                  child: Text(
                    labelBuilder(val),
                    style: GoogleFonts.cairo(
                      color: active ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      showBokeh: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: LammaColors.gold300, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    if (widget.slug == 'komi') ...[
                      _buildOptionChips<int>(
                        label: 'عدد اللاعبين',
                        values: const [2, 4],
                        selected: _playersCount,
                        labelBuilder: (v) => v == 2 ? 'لاعبين (1 ضد 1)' : '4 لاعبين (فريقين)',
                        onSelect: (v) => setState(() => _playersCount = v),
                      ),
                      _buildOptionChips<int>(
                        label: 'نقاط الفوز',
                        values: const [101, 121, 151],
                        selected: _targetScore,
                        labelBuilder: (v) => '$v نقطة',
                        onSelect: (v) => setState(() => _targetScore = v),
                      ),
                    ] else if (widget.slug == 'tarneeb') ...[
                      _buildOptionChips<int>(
                        label: 'نقاط الفوز',
                        values: const [31, 41],
                        selected: _targetScore,
                        labelBuilder: (v) => '$v نقطة',
                        onSelect: (v) => setState(() => _targetScore = v),
                      ),
                    ] else if (widget.slug == 'estimation') ...[
                      _buildOptionChips<int>(
                        label: 'عدد الجولات',
                        values: const [10, 18],
                        selected: _roundsCount,
                        labelBuilder: (v) => '$v جولات',
                        onSelect: (v) => setState(() => _roundsCount = v),
                      ),
                    ] else if (widget.slug == 'shayeb') ...[
                      _buildOptionChips<int>(
                        label: 'عدد اللاعبين',
                        values: const [2, 3, 4],
                        selected: _playersCount,
                        labelBuilder: (v) => '$v لاعبين',
                        onSelect: (v) => setState(() => _playersCount = v),
                      ),
                      _buildOptionChips<int>(
                        label: 'عدد الجولات',
                        values: const [3, 5, 7],
                        selected: _roundsCount,
                        labelBuilder: (v) => '$v جولات',
                        onSelect: (v) => setState(() => _roundsCount = v),
                      ),
                    ],

                    _buildOptionChips<int>(
                      label: 'مؤقت الدور',
                      values: const [15, 30, 60],
                      selected: _turnSeconds,
                      labelBuilder: (v) => '$v ثانية',
                      onSelect: (v) => setState(() => _turnSeconds = v),
                    ),

                    _buildOptionChips<bool>(
                      label: 'مستوى البوتات',
                      values: const [false, true],
                      selected: _botMedium,
                      labelBuilder: (v) => v ? 'متوسط (ذكي)' : 'سهل',
                      onSelect: (v) => setState(() => _botMedium = v),
                    ),

                    _buildOptionChips<bool>(
                      label: 'اتجاه الطاولة',
                      values: const [false, true],
                      selected: _isLandscape,
                      labelBuilder: (v) => v ? 'عرضي (Landscape)' : 'طولي (Portrait)',
                      onSelect: (v) => setState(() => _isLandscape = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              GameButton(
                text: 'العب الآن ضد الكمبيوتر 🤖',
                showArrow: false,
                height: 58,
                onPressed: _playVsBots,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: LammaColors.gold500,
                  side: const BorderSide(color: LammaColors.gold500, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: _isCreatingRoom ? null : _playOnlineWithFriends,
                icon: _isCreatingRoom
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.group_rounded),
                label: Text(
                  'إنشاء غرفة أونلاين للشلة 👥',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
