import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'router/app_router.dart';
import 'services/call_service.dart';
import 'services/app_update_service.dart';
import 'widgets/update_dialog.dart';
import 'theme/app_colors.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

/// 待展示的更新信息（启动时检查一次）
AppUpdateInfo? _pendingUpdate;

void main() {
  // 最小化同步初始化，确保 UI 立即渲染
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    return true;
  };

  // 立即 runApp —— 不再等待后台初始化
  runApp(
    ChangeNotifierProvider(
      create: (_) => CallService(),
      child: const OpenFaithApp(),
    ),
  );
}

class OpenFaithApp extends StatefulWidget {
  const OpenFaithApp({super.key});

  @override
  State<OpenFaithApp> createState() => _OpenFaithAppState();
}

class _OpenFaithAppState extends State<OpenFaithApp> {
  bool _initialized = false;
  bool _supabaseReady = false;
  bool _initError = false;
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    _runBackgroundInit();
  }

  /// 后台初始化：所有耗时操作移到此处，UI 先展示 Splash
  Future<void> _runBackgroundInit() async {
    try {
      // 1. 并行执行：Shorebird补丁检查 + 版本检查（整体8秒超时）
      try {
        await Future.wait([
          _checkShorebirdPatch(),
          _checkAppUpdate(),
        ]).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        debugPrint('[Init] Parallel update checks timed out after 8s');
      } catch (e) {
        debugPrint('[Init] Parallel update checks error: $e');
      }

      // 2. Supabase 初始化
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        ).timeout(const Duration(seconds: 10));
        _supabaseReady = true;
      } catch (e) {
        debugPrint('[Supabase] Init failed: $e');
      }

      // 3. CallService 初始化（依赖 Supabase）
      if (_supabaseReady) {
        try {
          await CallService().initialize();
          debugPrint('[CallService] Initialized');
        } catch (e) {
          debugPrint('[CallService] Init failed: $e');
        }
      } else {
        debugPrint('[CallService] Skipped - Supabase not available');
      }

      // 4. Sentry 错误监控
      try {
        const sentryDsn = 'YOUR_SENTRY_DSN_HERE';
        if (!sentryDsn.contains('YOUR_') && sentryDsn.isNotEmpty) {
          await SentryFlutter.init(
            (options) {
              options.dsn = sentryDsn;
              options.environment = kReleaseMode ? 'production' : 'development';
              options.tracesSampleRate = kReleaseMode ? 1.0 : 0.5;
            },
          ).timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('[Sentry] Init skipped: $e');
      }
    } catch (e) {
      debugPrint('[Init] Unexpected error: $e');
    }

    // 初始化流程结束，切换 UI
    if (!mounted) return;
    setState(() {
      _initialized = true;
      _initError = !_supabaseReady;
    });

    // Supabase 就绪后弹窗提示版本更新
    if (_supabaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowUpdateDialog();
      });
    }
  }

  /// 检查并下载 Shorebird 补丁（超时5秒）
  static Future<void> _checkShorebirdPatch() async {
    if (kIsWeb) {
      debugPrint('[Shorebird] Skipped on Web platform');
      return;
    }
    try {
      final updater = ShorebirdUpdater();
      final status = await updater.checkForUpdate().timeout(
        const Duration(seconds: 5),
        onTimeout: () => UpdateStatus.upToDate,
      );
      if (status == UpdateStatus.outdated) {
        debugPrint('[Shorebird] New patch available, downloading...');
        await updater.update().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
        debugPrint('[Shorebird] Patch downloaded');
      }
    } catch (e) {
      debugPrint('[Shorebird] Update check skipped: $e');
    }
  }

  void _maybeShowUpdateDialog() {
    if (!mounted || _updateDialogShown || _pendingUpdate == null) return;
    _updateDialogShown = true;

    final update = _pendingUpdate!;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return UpdateDialog(update: update);
      },
    );
  }

  /// 检查 APP 是否有新版本可更新（启动时调用）
  static Future<void> _checkAppUpdate() async {
    try {
      final updateInfo = await AppUpdateService().checkForUpdate();
      if (updateInfo != null) {
        _pendingUpdate = updateInfo;
      }
    } catch (e) {
      debugPrint('[AppUpdate] Check skipped: $e');
    }
  }

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
        // 初始化未完成 → 显示品牌启动画面
        if (!_initialized) {
          return const _SplashScreen();
        }
        // 初始化完成但 Supabase 失败 → 显示错误页面
        if (_initError) {
          return _buildInitErrorScreen(
            '无法连接到服务器',
            '请检查网络连接后重试。',
          );
        }
        // 一切正常 → 显示主路由
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
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initialized = false;
                    _initError = false;
                    _supabaseReady = false;
                  });
                  _runBackgroundInit();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D4EDD)),
                child: const Text('重试', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 品牌启动画面 —— APP 启动后立即展示，后台初始化期间可见
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'OpenFaith',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
