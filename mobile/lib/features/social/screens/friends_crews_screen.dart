import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';
import '../../../core/widgets/player_avatar_widget.dart';

class FriendsCrewsScreen extends StatefulWidget {
  const FriendsCrewsScreen({super.key});

  @override
  State<FriendsCrewsScreen> createState() => _FriendsCrewsScreenState();
}

class _FriendsCrewsScreenState extends State<FriendsCrewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _isSearching = false;
  String _myUsername = '';

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friendsLeaderboard = [];
  List<Map<String, dynamic>> _crews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await ApiService.instance.updatePresence();
    final results = await Future.wait([
      ApiService.instance.getFriendsData(),
      ApiService.instance.getFriendsLeaderboard(),
      ApiService.instance.getMyCrews(),
    ]);

    if (!mounted) return;
    final friendsData = results[0] as Map<String, dynamic>?;
    final lb = results[1] as List<Map<String, dynamic>>;
    final crews = results[2] as List<Map<String, dynamic>>;

    setState(() {
      if (friendsData != null) {
        _myUsername = friendsData['my_username']?.toString() ?? '';
        _friends = List<Map<String, dynamic>>.from(friendsData['friends'] ?? []);
        _pendingRequests = List<Map<String, dynamic>>.from(friendsData['pending_requests'] ?? []);
      }
      _friendsLeaderboard = lb;
      _crews = crews;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final clean = value.trim();
    if (clean.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final list = await ApiService.instance.searchSocialUsers(clean);
      if (mounted) {
        setState(() {
          _searchResults = list;
          _isSearching = false;
        });
      }
    });
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E9D7B),
      ),
    );
  }

  Future<void> _editUsernameDialog() async {
    final ctrl = TextEditingController(text: _myUsername);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('تعديل @username', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: InputDecoration(
            prefixText: '@',
            prefixStyle: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900),
            hintText: 'مثال: osama_99',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty) {
      try {
        final saved = await ApiService.instance.updateUsername(updated);
        if (mounted) {
          setState(() => _myUsername = saved);
          _showMessage('تم تحديث اسم المستخدم إلى @$saved');
        }
      } catch (e) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _createCrewDialog() async {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '🔥';
    final emojis = ['🔥', '👑', '⚡', '🦁', '🎯', '🏆'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF24104B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text('إنشاء شلة / فريق جديد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.cairo(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اسم الشلة (مثلاً: شلة القهوة)',
                  hintStyle: GoogleFonts.cairo(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: emojis.map((em) {
                  final active = selectedEmoji == em;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedEmoji = em),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFA35BFF) : Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? LammaColors.gold500 : Colors.white24),
                      ),
                      child: Text(em, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('إنشاء', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        await ApiService.instance.createCrew(name: nameCtrl.text.trim(), emoji: selectedEmoji);
        _showMessage('تم إنشاء الشلة بنجاح! 🎉');
        _loadAll();
      } catch (e) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _joinCrewDialog() async {
    final codeCtrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('انضمام إلى شلة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.cairo(color: Colors.white, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: 'أدخل كود الشلة',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4FD1A5)),
            onPressed: () => Navigator.pop(ctx, codeCtrl.text.trim()),
            child: Text('انضمام', style: GoogleFonts.cairo(color: const Color(0xFF0E2A22), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty) {
      try {
        final msg = await ApiService.instance.joinCrewByCode(code);
        _showMessage(msg);
        _loadAll();
      } catch (e) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _openCrewDetailsSheet(int crewId) async {
    final data = await ApiService.instance.getCrewDetails(crewId);
    if (!mounted || data == null) return;
    final crew = data['crew'] as Map<String, dynamic>;
    final members = List<Map<String, dynamic>>.from(data['members'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF24104B), Color(0xFF14072B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFFA35BFF), width: 2.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(crew['emoji']?.toString() ?? '🔥', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crew['name']?.toString() ?? '',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'كود الشلة: ${crew['code']} • إجمالي النقاط: ${crew['total_score']}',
                        style: GoogleFonts.cairo(color: LammaColors.gold300, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: LammaColors.gold500),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: crew['code']?.toString() ?? ''));
                    _showMessage('تم نسخ كود الشلة');
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LammaColors.gold500,
                      foregroundColor: const Color(0xFF1F0C3C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startCrewChallenge(crew['name']?.toString() ?? 'الشلة');
                    },
                    icon: const Icon(Icons.sports_esports_rounded, size: 18),
                    label: Text('ابدأ تحدي للشلة 🎮', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
                if (_friends.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF341765),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _pickFriendToInvite(crewId),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text('إضافة صديق', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ترتيب أعضاء الشلة هذا الأسبوع 🏆',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (_, i) => _buildRankedUserTile(members[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCrewChallenge(String crewName) async {
    final games = [
      {'slug': 'komi', 'name': 'الكومي (البصرة) 🃏'},
      {'slug': 'tarneeb', 'name': 'طرنيب مصري ♠️'},
      {'slug': 'estimation', 'name': 'استيميشن 🎯'},
      {'slug': 'shayeb', 'name': 'الشايب 👴'},
      {'slug': 'domino', 'name': 'الدومينو 🎲'},
      {'slug': 'autobus-complete', 'name': 'أتوبيس كومبليت 🚌'},
    ];

    final picked = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: const Color(0xFF24104B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اختر لعبة لتحدي $crewName 🎮',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...games.map((g) => ListTile(
                  title: Text(g['name']!, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded, color: LammaColors.gold500, size: 16),
                  onTap: () => Navigator.pop(ctx, g),
                )),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;
    try {
      final data = await ApiService.instance.createRoom(
        gameSlug: picked['slug']!,
        maxPlayers: 4,
      );
      final code = data['room']['code']?.toString() ?? '';
      await ApiService.instance.updatePresence(currentRoomCode: code);
      if (!mounted) return;
      context.push(
        '/online-room',
        extra: {
          'code': code,
          'playerToken': data['player_token'],
          'isHost': true,
          'gameName': picked['name']!,
          'gameSlug': picked['slug']!,
          'maxPlayers': 4,
        },
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _pickFriendToInvite(int crewId) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF24104B),
        title: Text('اختر صديقاً لإضافته', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          height: 260,
          child: ListView.builder(
            itemCount: _friends.length,
            itemBuilder: (_, i) {
              final f = _friends[i];
              return ListTile(
                leading: PlayerAvatarWidget(avatarPath: f['avatar']?.toString() ?? '', size: 36),
                title: Text(f['name']?.toString() ?? '', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                subtitle: Text('@${f['username']}', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiService.instance.inviteFriendToCrew(crewId: crewId, userId: f['id'] as int);
                    _showMessage('تمت إضافة ${f['name']} للشلة!');
                  } catch (e) {
                    _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineDot(bool isOnline, {String? roomCode}) {
    final hasRoom = isOnline && roomCode != null && roomCode.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasRoom ? LammaColors.gold500 : (isOnline ? const Color(0xFF4FD1A5) : Colors.white38),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          hasRoom ? 'يلعب الآن (#$roomCode)' : (isOnline ? 'متصل الآن' : 'غير متصل'),
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: hasRoom ? LammaColors.gold300 : (isOnline ? const Color(0xFF4FD1A5) : Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildRankedUserTile(Map<String, dynamic> u) {
    final isMe = u['is_me'] == true;
    final isOnline = u['is_online'] == true;
    final roomCode = u['current_room_code']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF49228C) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? LammaColors.gold500.withOpacity(0.7) : Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${u['rank']}',
              style: GoogleFonts.cairo(
                color: (u['rank'] == 1) ? LammaColors.gold500 : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          PlayerAvatarWidget(avatarPath: u['avatar']?.toString() ?? '', size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${u['name']}${isMe ? ' (أنت)' : ''}',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Row(
                  children: [
                    Text('@${u['username']}', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11)),
                    const SizedBox(width: 8),
                    _buildOnlineDot(isOnline, roomCode: roomCode),
                  ],
                ),
              ],
            ),
          ),
          if (!isMe && isOnline && roomCode != null && roomCode.isNotEmpty)
            GestureDetector(
              onTap: () => context.push('/join-room?code=$roomCode'),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: LammaColors.gold500,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ادخل',
                  style: GoogleFonts.cairo(color: const Color(0xFF1E0B38), fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ),
          Text(
            '${u['weekly_score']} ن',
            style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w900, fontSize: 14),
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
        child: Column(
          children: [
            // الهيدر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  ),
                  Expanded(
                    child: Text(
                      'الأصدقاء والشلل 👥',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: _loadAll,
                  ),
                ],
              ),
            ),

            // التبويبات
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA35BFF), Color(0xFF6A24C9)]),
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'أصحابي'),
                  Tab(text: 'ترتيب الشلة'),
                  Tab(text: 'الفرق والشلل'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: LammaColors.gold500))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFriendsTab(),
                        _buildFriendsLeaderboardTab(),
                        _buildCrewsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // بطاقة @username الخاص بي
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF341765), Color(0xFF210E44)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LammaColors.gold500.withOpacity(0.45)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('معرّفك لإضافة الأصدقاء:', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                    Text(
                      _myUsername.isNotEmpty ? '@$_myUsername' : '@...',
                      style: GoogleFonts.cairo(color: LammaColors.gold500, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                onPressed: _editUsernameDialog,
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: LammaColors.gold500, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '@$_myUsername'));
                  _showMessage('تم نسخ @$_myUsername لمشاركته مع صحابك!');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // البحث عن صديق بـ @username
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث بـ @username أو الاسم لإضافة صديق...',
            hintStyle: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: LammaColors.gold500),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: CircularProgressIndicator(color: LammaColors.gold500)),
          )
        else if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._searchResults.map((u) {
            final status = u['friendship_status']?.toString() ?? 'none';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  PlayerAvatarWidget(avatarPath: u['avatar']?.toString() ?? '', size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['name']?.toString() ?? '', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                        Text('@${u['username']}', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (status == 'none')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA35BFF)),
                      onPressed: () async {
                        try {
                          final msg = await ApiService.instance.sendFriendRequest(friendId: u['id'] as int);
                          _showMessage(msg);
                          _onSearchChanged(_searchController.text);
                          _loadAll();
                        } catch (e) {
                          _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
                        }
                      },
                      child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                    )
                  else
                    Text(
                      status == 'accepted' ? 'صديق ✓' : 'قيد الانتظار',
                      style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                ],
              ),
            );
          }),
        ],

        if (_pendingRequests.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('طلبات صداقة واردة (${_pendingRequests.length})',
              style: GoogleFonts.cairo(color: LammaColors.gold300, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 8),
          ..._pendingRequests.map((req) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF341765),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LammaColors.gold500.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    PlayerAvatarWidget(avatarPath: req['avatar']?.toString() ?? '', size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req['name']?.toString() ?? '', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                          Text('@${req['username']}', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF4FD1A5)),
                      onPressed: () async {
                        await ApiService.instance.respondFriendRequest(friendId: req['id'] as int, action: 'accept');
                        _showMessage('أصبحتما أصدقاء الآن!');
                        _loadAll();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        await ApiService.instance.respondFriendRequest(friendId: req['id'] as int, action: 'decline');
                        _loadAll();
                      },
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 16),
        Text('قائمة الأصدقاء (${_friends.length})',
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 8),
        if (_friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'لا يوجد أصدقاء بعد — ابحث بـ @username وأضف صحابك لتلعبوا معاً وتروا ترتيبكم الأسبوعي!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
            ),
          )
        else
          ..._friends.map((f) {
            final isOnline = f['is_online'] == true;
            final roomCode = f['current_room_code']?.toString();
            final hasRoom = isOnline && roomCode != null && roomCode.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hasRoom ? LammaColors.gold500.withOpacity(0.5) : Colors.white12),
              ),
              child: Row(
                children: [
                  PlayerAvatarWidget(avatarPath: f['avatar']?.toString() ?? '', size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['name']?.toString() ?? '',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                        Text('@${f['username']}', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                        _buildOnlineDot(isOnline, roomCode: roomCode),
                      ],
                    ),
                  ),
                  if (hasRoom)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LammaColors.gold500,
                        foregroundColor: const Color(0xFF1F0C3C),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () {
                        SettingsService.instance.triggerHaptic();
                        SoundService.instance.playClick();
                        context.push('/join-room?code=$roomCode');
                      },
                      child: Text('ادخل معاه', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFriendsLeaderboardTab() {
    final myEntry = _friendsLeaderboard.where((e) => e['is_me'] == true).firstOrNull;
    final myRank = myEntry?['rank'] ?? 1;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B42F6), Color(0xFF4C1EA6)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LammaColors.gold500.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  myRank == 1
                      ? 'أنت الأول على صحابك هذا الأسبوع! حافظ على الصدارة 🔥'
                      : 'ترتيبك الحالي #$myRank بين صحابك هذا الأسبوع — العب جولة واصعد للقمة!',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._friendsLeaderboard.map(_buildRankedUserTile),
      ],
    );
  }

  Widget _buildCrewsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA35BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _createCrewDialog,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text('إنشاء شلة', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: LammaColors.gold500,
                  side: const BorderSide(color: LammaColors.gold500),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _joinCrewDialog,
                icon: const Icon(Icons.group_add_rounded),
                label: Text('انضمام بكود', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_crews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'أنشئ شلتك الخاصة أو انضم بكود شلة صحابك لتتنافسوا في الدوري الأسبوعي!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
            ),
          )
        else
          ..._crews.map((c) => GestureDetector(
                onTap: () => _openCrewDetailsSheet(c['id'] as int),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1357),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA35BFF).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(c['emoji']?.toString() ?? '🔥', style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name']?.toString() ?? '',
                              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            Text(
                              '${c['members_count']} أعضاء • كود: ${c['code']}',
                              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${c['total_score']} ن',
                            style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Text('عرض الترتيب ←', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
