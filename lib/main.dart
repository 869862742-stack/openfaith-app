import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/discover/discover_screen.dart';
import 'navigation/bottom_nav.dart';
import 'screens/gongjing/room_list_screen.dart';
import 'screens/gongjing/create_room_screen.dart';
import 'screens/gongjing/silent_room_screen.dart';
import 'screens/publish/publish_note_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'i18n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Shorebird OTA 热更新检查
  final updater = ShorebirdUpdater();
  try {
    final status = await updater.checkForUpdate();
    if (status == UpdateStatus.outdated) {
      debugPrint('[Shorebird] New patch available, downloading...');
      await updater.update();
      debugPrint('[Shorebird] Patch downloaded, will apply on next restart');
    } else {
      debugPrint('[Shorebird] No new patches available');
    }
  } catch (e) {
    debugPrint('[Shorebird] Update check failed: $e');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );
  debugPrint('[Auth] Supabase initialized');

  // Sentry 错误监控初始化
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN_HERE';
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 1.0 : 0.5;
      options.enableAutoSessionTracking = true;
      options.attachStacktrace = true;
    },
    appRunner: () => runApp(const OpenFaithApp()),
  );
}

class OpenFaithApp extends StatelessWidget {
  const OpenFaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 全局错误处理 - 捕获 Widget 构建错误并上报到 Sentry
    ErrorWidget.builder = (FlutterErrorDetails details) {
      SentryFlutter.captureException(details.exception, stackTrace: details.stack);
      return const SizedBox.shrink();
    };
    
    return MaterialApp(
      title: 'OpenFaith',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const BottomNavScreen(),
        '/discover': (context) => const DiscoverScreen(),
        '/room-list': (context) => const RoomListScreen(),
        '/create-room': (context) => const CreateRoomScreen(),
        '/publish-note': (context) => const PublishNoteScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/silent-room') {
          final args = settings.arguments as Map<String, dynamic>?;
          final roomId = args?['room_id']?.toString() ?? '';
          if (roomId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => SilentRoomScreen(roomId: roomId),
            );
          }
        }
        // Handle /room/:roomId path format
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null && uri.pathSegments.length == 2 && uri.pathSegments[0] == 'room') {
          final roomId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => SilentRoomScreen(roomId: roomId),
          );
        }
        return null;
      },
    );
  }
}
