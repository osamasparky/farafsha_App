import 'package:go_router/go_router.dart';
import '../../features/splash_onboarding/screens/splash_screen.dart';
import '../../features/splash_onboarding/screens/onboarding_flow_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/mode_selection/screens/mode_selection_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/game_lobby/screens/game_setup_screen.dart';
import '../../features/game_lobby/screens/players_screen.dart';
import '../../features/game_lobby/screens/handoff_screen.dart';
import '../../features/game_lobby/screens/online_room_screen.dart';
import '../../features/game_lobby/screens/join_room_screen.dart';
import '../../features/game_lobby/screens/results_screen.dart';
import '../../features/games/screens/amthal_game_screen.dart';
import '../../features/games/screens/movie_quotes_game_screen.dart';
import '../../features/games/screens/taboo_game_screen.dart';
import '../../features/games/screens/drawing_game_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/store/screens/store_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
        final phone = state.extra as String? ?? '01012345678';
        return OtpScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/mode-select',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game-setup/:id',
      builder: (context, state) {
        final gameId = state.pathParameters['id'] ?? 'amthal-shaabiya';
        return GameSetupScreen(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/players',
      builder: (context, state) {
        final target = state.extra as String? ?? '/game/amthal';
        return PlayersScreen(targetRoute: target);
      },
    ),
    GoRoute(
      path: '/handoff',
      builder: (context, state) {
        final target = state.extra as String? ?? '/game/amthal';
        return HandoffScreen(targetRoute: target);
      },
    ),
    GoRoute(
      path: '/game/amthal',
      builder: (context, state) => const AmthalGameScreen(),
    ),
    GoRoute(
      path: '/game/quotes',
      builder: (context, state) => const MovieQuotesGameScreen(),
    ),
    GoRoute(
      path: '/game/taboo',
      builder: (context, state) => const TabooGameScreen(),
    ),
    GoRoute(
      path: '/game/draw',
      builder: (context, state) => const DrawingGameScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/online-room',
      builder: (context, state) => const OnlineRoomScreen(),
    ),
    GoRoute(
      path: '/join-room',
      builder: (context, state) => const JoinRoomScreen(),
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
