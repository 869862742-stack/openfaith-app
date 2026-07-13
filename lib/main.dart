import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'splash/splash_screen.dart';
import 'webview/webview_shell.dart';
import 'utils/status_bar_controller.dart';
import 'utils/permission_manager.dart';
import 'utils/push_notification_manager.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Shorebird OTA 热更新检查
  try {
    final updater = ShorebirdUpdater();
    final status = await updater.checkForUpdate();
    if (status == UpdateStatus.outdated) {
      debugPrint('[Shorebird] New patch available, downloading...');
      await updater.update();
      debugPrint('[Shorebird] Patch downloaded, will apply on next restart');
    } else {
      debugPrint('[Shorebird] No new patches available');
    }
  } catch (e) {
    debugPrint('[Shorebird] Update check skipped: $e');
  }

  // Supabase 初始化（为未来原生模块准备）
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  // 状态栏初始化（深色主题，亮色图标）
  StatusBarHelper.reset();

  // 推送通知初始化（框架代码，需要 Firebase 配置后完善）
  await PushNotificationManager.initialize();

  // Sentry 错误监控
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN_HERE';
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 1.0 : 0.5;
    },
  );

  runApp(const OpenFaithApp());
}

class OpenFaithApp extends StatelessWidget {
  const OpenFaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenFaith',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050816),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          surface: Color(0xFF050816),
        ),
      ),
      home: const SplashScreen(
        child: WebViewShell(),
      ),
    );
  }
}
