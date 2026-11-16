import 'package:go_router/go_router.dart';
import '../models/game_session.dart';
import '../services/app_update_service.dart';
import '../services/auth_service.dart';
import '../../features/splash_onboarding/screens/splash_screen.dart';
import '../../features/splash_onboarding/screens/force_update_screen.dart';
import '../../features/splash_onboarding/screens/onboarding_flow_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/mode_selection/screens/mode_selection_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/game_lobby/screens/game_setup_screen.dart';
import '../../features/game_lobby/screens/players_screen.dart';
import '../../features/game_lobby/screens/handoff_screen.dart';
import '../../features/game_lobby/screens/online_room_screen.dart';
import '../../features/game_lobby/screens/online_gameplay_screen.dart';
import '../../features/game_lobby/screens/join_room_screen.dart';
import '../../features/game_lobby/screens/results_screen.dart';
import '../../features/games/screens/amthal_game_screen.dart';
import '../../features/games/screens/movie_quotes_game_screen.dart';
import '../../features/games/screens/taboo_game_screen.dart';
import '../../features/games/screens/drawing_game_screen.dart';
import '../../features/games/screens/lamma_host_game_screen.dart';
import '../../features/games/screens/autobus_game_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/store/screens/store_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/force-update',
      builder: (context, state) {
        final updateInfo = state.extra as AppUpdateInfo? ??
            AppUpdateService.instance.currentUpdateInfo ??
            const AppUpdateInfo(
              isUpdateAvailable: true,
              isForceUpdate: true,
              currentBuildNumber: 1,
              minBuildNumber: 8,
              currentVersion: '1.0.0',
              latestVersion: '1.0.0+8',
              title: 'تحديث إجباري جديد متوفر 🚀',
              message:
                  'يتوفر إصدار جديد من تطبيق فرفشة بميزات وتحسينات جديدة. يرجى التحديث الآن للمتابعة!',
              storeUrl:
                  'https://play.google.com/store/apps/details?id=com.farafsha.app',
              directDownloadUrl: 'https://farafsha.com/farafsha.aab',
            );
        return ForceUpdateScreen(updateInfo: updateInfo);
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingFlowScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return OtpScreen(
            phoneNumber: data['phone']?.toString() ?? '',
            registrationData: data,
          );
        }
        final phone = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/mode-select',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/mode-selection',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game-setup',
      redirect: (context, state) {
        final gameData = state.extra as Map<String, dynamic>?;
        final gameId = gameData?['slug']?.toString() ?? 'amthal-shaabiya';
        if (!AuthService.instance.isGameUnlocked(gameId)) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final gameData = state.extra as Map<String, dynamic>?;
        final gameId = gameData?['slug']?.toString() ?? 'amthal-shaabiya';
        return GameSetupScreen(gameId: gameId, initialGameData: gameData);
      },
    ),
    GoRoute(
      path: '/game-setup/:id',
      redirect: (context, state) {
        final gameId = state.pathParameters['id'] ?? 'amthal-shaabiya';
        if (!AuthService.instance.isGameUnlocked(gameId)) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final gameId = state.pathParameters['id'] ?? 'amthal-shaabiya';
        final gameData = state.extra as Map<String, dynamic>?;
        return GameSetupScreen(gameId: gameId, initialGameData: gameData);
      },
    ),
    GoRoute(
      path: '/players',
      redirect: (context, state) {
        String slug = 'amthal-shaabiya';
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          slug = data['gameSlug']?.toString() ?? slug;
        }
        if (!AuthService.instance.isGameUnlocked(slug)) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return PlayersScreen(
            targetRoute: data['targetRoute']?.toString() ?? '/game/amthal',
            gameSlug: data['gameSlug']?.toString() ?? 'amthal-shaabiya',
            gameTitle: data['gameTitle']?.toString() ?? 'أمثال شعبية',
            totalRounds: data['totalRounds'] as int? ?? 10,
            playersCount: data['playersCount'] as int? ?? 4,
          );
        }
        final target = state.extra as String? ?? '/game/amthal';
        return PlayersScreen(targetRoute: target);
      },
    ),
    GoRoute(
      path: '/handoff',
      builder: (context, state) {
        if (state.extra is GameSession) {
          final session = state.extra as GameSession;
          return HandoffScreen(
            playerName: session.activePlayer.name,
            teamName: session.activePlayer.teamName,
            playerAvatar: session.activePlayer.avatar,
            round: session.currentRoundNumber,
            totalRounds: session.totalRounds,
            targetRoute: session.gameRoute,
          );
        } else if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return HandoffScreen(
            playerName: data['playerName']?.toString() ?? 'اللاعب التالي',
            teamName: data['teamName']?.toString() ?? 'فريق الأبطال',
            playerAvatar: data['playerAvatar']?.toString() ?? 'assets/images/av-ahmed.webp',
            round: data['round'] as int? ?? 1,
            totalRounds: data['totalRounds'] as int? ?? 10,
            targetRoute: data['targetRoute']?.toString() ?? '/game/amthal',
          );
        }
        final target = state.extra as String? ?? '/game/amthal';
        return HandoffScreen(targetRoute: target);
      },
    ),
    GoRoute(
      path: '/game/amthal',
      builder: (context, state) {
        final session = state.extra as GameSession?;
        return AmthalGameScreen(session: session);
      },
    ),
    GoRoute(
      path: '/game/quotes',
      redirect: (context, state) {
        if (!AuthService.instance.isGameUnlocked('famous-quotes')) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final session = state.extra as GameSession?;
        return MovieQuotesGameScreen(session: session);
      },
    ),
    GoRoute(
      path: '/game/taboo',
      redirect: (context, state) {
        if (!AuthService.instance.isGameUnlocked('forbidden-words')) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final session = state.extra as GameSession?;
        return TabooGameScreen(session: session);
      },
    ),
    GoRoute(
      path: '/game/draw',
      redirect: (context, state) {
        if (!AuthService.instance.isGameUnlocked('acting-drawing')) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) => const DrawingGameScreen(),
    ),
    GoRoute(
      path: '/game/autobus-complete',
      redirect: (context, state) {
        if (!AuthService.instance.isGameUnlocked('autobus-complete')) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final session = state.extra as GameSession?;
        return AutobusGameScreen(session: session);
      },
    ),
    GoRoute(
      path: '/game/lammah-host',
      redirect: (context, state) {
        if (!AuthService.instance.isModeUnlocked('lammah')) {
          return '/mode-select';
        }
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final gameSlug = extra['gameSlug'] as String? ?? 'amthal-shaabiya';
        if (!AuthService.instance.isGameUnlocked(gameSlug)) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final gameSlug = extra['gameSlug'] as String? ?? 'amthal-shaabiya';
        final subMode = extra['subMode'] as String? ?? 'teams';
        final teams = extra['teams'] as List<Map<String, dynamic>>? ?? [];
        final totalQuestions = extra['totalQuestions'] as int? ?? 50;
        return LammaHostGameScreen(
          gameSlug: gameSlug,
          subMode: subMode,
          initialTeams: teams,
          totalQuestions: totalQuestions,
        );
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        if (state.extra is GameSession) {
          return ResultsScreen.fromSession(state.extra as GameSession);
        } else if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return ResultsScreen(
            winnerTeam: data['winnerTeam']?.toString() ?? 'فرفوش',
            winnerScore: data['winnerScore'] as int? ?? 24,
            runnerUpTeam: data['runnerUpTeam']?.toString() ?? 'قفوش',
            runnerUpScore: data['runnerUpScore'] as int? ?? 19,
            mvpName: data['mvpName']?.toString() ?? 'سارة',
            mvpAvatar: data['mvpAvatar']?.toString() ?? 'assets/images/av-sara.webp',
            mvpStats: data['mvpStats']?.toString() ?? 'أعلى نقاط',
          );
        }
        return const ResultsScreen();
      },
    ),
    GoRoute(
      path: '/online-room',
      redirect: (context, state) {
        if (!AuthService.instance.isModeUnlocked('online')) {
          return '/mode-select';
        }
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OnlineRoomScreen(
          roomCode: extra?['code']?.toString() ?? '784521',
          playerToken: extra?['token']?.toString(),
          isHost: extra?['isHost'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/join-room',
      redirect: (context, state) {
        if (!AuthService.instance.isModeUnlocked('online')) {
          return '/mode-select';
        }
        return null;
      },
      builder: (context, state) {
        final code = state.uri.queryParameters['code'] ?? (state.extra as String?);
        return JoinRoomScreen(initialCode: code);
      },
    ),
    GoRoute(
      path: '/online-gameplay',
      redirect: (context, state) {
        if (!AuthService.instance.isModeUnlocked('online')) {
          return '/mode-select';
        }
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OnlineGameplayScreen(
          roomCode: extra['code']?.toString() ?? '',
          playerToken: extra['token']?.toString(),
          isHost: extra['isHost'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) => const StoreScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
