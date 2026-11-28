import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/network/api_service.dart';
import 'core/router/app_router.dart';
import 'core/services/app_update_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // منع تحميل الخطوط عبر الشبكة والاعتماد 100% على الخط المحلي المدمج Cairo.ttf لتسريع الإقلاع
  GoogleFonts.config.allowRuntimeFetching = false;

  // في الإنتاج نتصل مباشرة بـ farafsha.com بدون أي فحص شبكة يستهلك وقت الإقلاع
  if (!kReleaseMode) {
    await ApiService.instance.detectWorkingHost();
  }

  // تهيئة إعدادات المستخدم والمصادقة والخدمات الأساسية
  await SettingsService.instance.init();
  await AuthService.instance.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF160B2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: LammahApp(),
    ),
  );

  // تهيئة الاستماع للـ Deep Links بعد تشغيل التطبيق وربط الـ Activity
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DeepLinkService.instance.init();
  });
}

class LammahApp extends StatefulWidget {
  const LammahApp({super.key});

  @override
  State<LammahApp> createState() => _LammahAppState();
}

class _LammahAppState extends State<LammahApp> with WidgetsBindingObserver {
  DateTime? _lastResumeUpdateCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AuthService.instance.isLoggedIn) {
      ApiService.instance.updatePresence();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStoreUpdateOnResume();
      if (AuthService.instance.isLoggedIn) {
        ApiService.instance.updatePresence();
      }
    }
  }

  Future<void> _checkStoreUpdateOnResume() async {
    final now = DateTime.now();
    if (_lastResumeUpdateCheck != null &&
        now.difference(_lastResumeUpdateCheck!) < const Duration(seconds: 60)) {
      return;
    }
    _lastResumeUpdateCheck = now;

    final info = await AppUpdateService.instance.checkUpdate();
    if (info != null && info.isForceUpdate) {
      appRouter.go('/force-update', extra: info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final isDarkMode = SettingsService.instance.isDarkMode;

        return MaterialApp.router(
          title: 'فرفشة - لعبة الجماعة',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
          locale: const Locale('ar', 'EG'),
          supportedLocales: const [
            Locale('ar', 'EG'),
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
        );
      },
    );
  }
}
