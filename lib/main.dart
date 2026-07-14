import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:go_router/go_router.dart';
import 'router/app_router.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

void main() {
  // 全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    return true;
  };

  runZonedGuarded<Future<void>>(
    () async {
      await _initApp();
      runApp(const OpenFaithApp());
    },
    (error, stack) {
      debugPrint('[ZoneError] $error');
    },
  );
}

Future<void> _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Shorebird OTA 热更新
  try {
    final updater = ShorebirdUpdater();
    final status = await updater.checkForUpdate().timeout(
      const Duration(seconds: 5),
      onTimeout: () => UpdateStatus.upToDate,
    );
    if (status == UpdateStatus.outdated) {
      debugPrint('[Shorebird] New patch available, downloading...');
      await updater.update().timeout(const Duration(seconds: 10));
      debugPrint('[Shorebird] Patch downloaded');
    }
  } catch (e) {
    debugPrint('[Shorebird] Update check skipped: $e');
  }

  // Supabase 初始化
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Supabase] Init failed: $e');
  }

  // Sentry 错误监控
  try {
    const sentryDsn = 'YOUR_SENTRY_DSN_HERE';
    if (!sentryDsn.contains('YOUR_') && sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.environment = kReleaseMode ? 'production' : 'development';
          options.tracesSampleRate = kReleaseMode ? 1.0 : 0.5;
        },
      );
    }
  } catch (e) {
    debugPrint('[Sentry] Init skipped: $e');
  }
}

class OpenFaithApp extends StatelessWidget {
  const OpenFaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: appRouter,
    );
  }
}
