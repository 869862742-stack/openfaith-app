import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'router/app_router.dart';
import 'services/call_service.dart';

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
      final initResult = await _initApp();
      runApp(
        ChangeNotifierProvider(
          create: (_) => CallService(),
          child: OpenFaithApp(
            supabaseReady: initResult['supabase'] ?? false,
            callServiceReady: initResult['callService'] ?? false,
          ),
        ),
      );
    },
    (error, stack) {
      debugPrint('[ZoneError] $error');
    },
  );
}

Future<Map<String, bool>> _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Shorebird OTA 热更新 (仅在非Web平台启用)
  if (!kIsWeb) {
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
  } else {
    debugPrint('[Shorebird] Skipped on Web platform');
  }

  // Supabase 初始化
  bool supabaseReady = false;
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 10));
    supabaseReady = true;
  } catch (e) {
    debugPrint('[Supabase] Init failed: $e');
  }

  // CallService 初始化（依赖 Supabase）
  bool callServiceReady = false;
  if (supabaseReady) {
    try {
      await CallService().initialize();
      callServiceReady = true;
      debugPrint('[CallService] Initialized');
    } catch (e) {
      debugPrint('[CallService] Init failed: $e');
    }
  } else {
    debugPrint('[CallService] Skipped - Supabase not available');
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

  return {'supabase': supabaseReady, 'callService': callServiceReady};
}

class OpenFaithApp extends StatelessWidget {
  final bool supabaseReady;
  final bool callServiceReady;

  const OpenFaithApp({
    super.key,
    this.supabaseReady = false,
    this.callServiceReady = false,
  });

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
      builder: (context, child) {
        if (!supabaseReady) {
          return _buildInitErrorScreen(
            '无法连接到服务器',
            '请检查网络连接后重试。',
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitErrorScreen(String title, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white54, size: 64),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
                child: const Text('重试', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
