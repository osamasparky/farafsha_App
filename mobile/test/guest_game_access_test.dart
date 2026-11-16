import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lammah/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Game Access Restriction Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.init();
    });

    test('Guest user can ONLY play amthal-shaabiya, other games are locked', () async {
      await AuthService.instance.loginAsGuest();

      expect(AuthService.instance.isGuest, isTrue);
      expect(AuthService.instance.isLoggedIn, isFalse);

      // Amthal game MUST be unlocked
      expect(AuthService.instance.isGameUnlocked('amthal-shaabiya'), isTrue);
      expect(AuthService.instance.isGameUnlocked('amthal'), isTrue);
      expect(AuthService.instance.isGameUnlocked('  AMTHAL-SHAABIYA  '), isTrue);

      // All other games MUST be locked for guests
      expect(AuthService.instance.isGameUnlocked('famous-quotes'), isFalse);
      expect(AuthService.instance.isGameUnlocked('forbidden-words'), isFalse);
      expect(AuthService.instance.isGameUnlocked('taboo-words'), isFalse);
      expect(AuthService.instance.isGameUnlocked('speed-trivia'), isFalse);
      expect(AuthService.instance.isGameUnlocked('guess-song'), isFalse);
      expect(AuthService.instance.isGameUnlocked('who-am-i'), isFalse);
      expect(AuthService.instance.isGameUnlocked('autobus-complete'), isFalse);
      expect(AuthService.instance.isGameUnlocked('two-truths-and-lie'), isFalse);
      expect(AuthService.instance.isGameUnlocked('acting-drawing'), isFalse);
      expect(AuthService.instance.isGameUnlocked('draw-guess'), isFalse);
    });

    test('Registered logged-in user can access all games without restriction', () async {
      await AuthService.instance.loginUser(
        name: 'أحمد محمود',
        email: 'ahmed@example.com',
        token: 'mock-jwt-token',
      );

      expect(AuthService.instance.isGuest, isFalse);
      expect(AuthService.instance.isLoggedIn, isTrue);

      // All games must be unlocked for logged in registered users
      expect(AuthService.instance.isGameUnlocked('amthal-shaabiya'), isTrue);
      expect(AuthService.instance.isGameUnlocked('famous-quotes'), isTrue);
      expect(AuthService.instance.isGameUnlocked('forbidden-words'), isTrue);
      expect(AuthService.instance.isGameUnlocked('taboo-words'), isTrue);
      expect(AuthService.instance.isGameUnlocked('speed-trivia'), isTrue);
      expect(AuthService.instance.isGameUnlocked('guess-song'), isTrue);
      expect(AuthService.instance.isGameUnlocked('who-am-i'), isTrue);
      expect(AuthService.instance.isGameUnlocked('autobus-complete'), isTrue);
      expect(AuthService.instance.isGameUnlocked('two-truths-and-lie'), isTrue);
      expect(AuthService.instance.isGameUnlocked('acting-drawing'), isTrue);
    });

    test('Guest user can ONLY access local gameplay mode, while lammah and online are locked', () async {
      await AuthService.instance.loginAsGuest();

      expect(AuthService.instance.isGuest, isTrue);
      expect(AuthService.instance.isLoggedIn, isFalse);

      // Local mode must be unlocked for guests
      expect(AuthService.instance.isModeUnlocked('local'), isTrue);
      expect(AuthService.instance.isModeUnlocked('LOCAL'), isTrue);
      expect(AuthService.instance.isModeUnlocked('  local  '), isTrue);

      // Lammah and Online modes must be locked for guests
      expect(AuthService.instance.isModeUnlocked('lammah'), isFalse);
      expect(AuthService.instance.isModeUnlocked('online'), isFalse);
      expect(AuthService.instance.isModeUnlocked('hybrid'), isFalse);
    });

    test('Registered user can access all gameplay modes', () async {
      await AuthService.instance.loginUser(
        name: 'أحمد محمود',
        email: 'ahmed@example.com',
        token: 'mock-jwt-token',
      );

      expect(AuthService.instance.isGuest, isFalse);
      expect(AuthService.instance.isLoggedIn, isTrue);

      // All modes must be unlocked for registered users
      expect(AuthService.instance.isModeUnlocked('local'), isTrue);
      expect(AuthService.instance.isModeUnlocked('lammah'), isTrue);
      expect(AuthService.instance.isModeUnlocked('online'), isTrue);
    });
  });
}
