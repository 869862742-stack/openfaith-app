import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/discover/discover_screen.dart';
import 'navigation/bottom_nav.dart';

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
  runApp(const OpenFaithApp());
}

class OpenFaithApp extends StatelessWidget {
  const OpenFaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenFaith',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const BottomNavScreen(),
        '/discover': (context) => const DiscoverScreen(),
      },
    );
  }
}
