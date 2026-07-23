import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'router/app_router.dart';
import 'services/call_service.dart';
import 'services/app_update_service.dart';
import 'widgets/update_dialog.dart';
import 'theme/app_colors.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

/// 待展示的更新信息（启动时检查一次）
AppUpdateInfo? _pendingUpdate;

/// 最小 splash 显示时间（毫秒）
const int _minSplashDurationMs = 2000;

void main() {
  // 最小化同步初始化，确保 UI 立即渲染
  WidgetsFlutterBinding.ensureInitialized();

  // 尽早隐藏系统 UI，防止系统栏闪烁
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 全局错误处理 —— 增加本地文件日志
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
    _writeCrashLog('FlutterError', details.exception.toString(), details.stack?.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    _writeCrashLog('PlatformError', error.toString(), stack.toString());
    return true; // 吞掉异常，防止 APP 崩溃
  };

  // 覆盖默认 ErrorWidget —— 显示可见的错误提示而非静默黑屏
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[ErrorWidget] ${details.exception}');
    return Container(
      color: const Color(0xFF050816),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '渲染错误: ${details.exception}',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

  // 立即 runApp —— 不再等待后台初始化
  runApp(
    ChangeNotifierProvider(
      create: (_) => CallService(),
      child: const OpenFaithApp(),
    ),
  );
}

/// 写入崩溃日志到本地文件（用于事后诊断）
Future<void> _writeCrashLog(String type, String error, String? stack) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/crash_log.txt');
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString(
      '\n--- $timestamp ---\n[$type] $error\n${stack ?? ''}\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // 日志写入失败不应影响 APP 运行
  }
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
    debugPrint('[OpenFaith] initState called, starting background init');
    _runBackgroundInit();
  }

  /// 后台初始化：所有耗时操作移到此处，UI 先展示 Splash
  Future<void> _runBackgroundInit() async {
    // ⏱ 记录开始时间
    final stopwatch = Stopwatch()..start();
    debugPrint('[Init] Background init started');

    try {
      // 1. APP 版本检查（Shorebird 补丁检查已移至延迟执行，避免原生崩溃）
      debugPrint('[Init] Step 1: Checking app updates...');
      try {
        await _checkAppUpdate().timeout(const Duration(seconds: 8));
        debugPrint('[Init] Step 1: App update check completed (${stopwatch.elapsedMilliseconds}ms)');
      } on TimeoutException {
        debugPrint('[Init] Step 1: App update check timed out after 8s');
      } catch (e) {
        debugPrint('[Init] Step 1: App update check error: $e');
      }

      // 2. Supabase 初始化
      debugPrint('[Init] Step 2: Initializing Supabase...');
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        ).timeout(const Duration(seconds: 10));
        _supabaseReady = true;
        debugPrint('[Init] Step 2: Supabase initialized (${stopwatch.elapsedMilliseconds}ms)');
      } catch (e) {
        debugPrint('[Init] Step 2: Supabase init failed: $e');
      }

      // 3. CallService 初始化（依赖 Supabase）— 不再 rethrow
      if (_supabaseReady) {
        debugPrint('[Init] Step 3: Initializing CallService...');
        try {
          await CallService().initialize();
          debugPrint('[Init] Step 3: CallService initialized (${stopwatch.elapsedMilliseconds}ms)');
        } catch (e) {
          debugPrint('[Init] Step 3: CallService init failed (non-fatal): $e');
        }
      } else {
        debugPrint('[Init] Step 3: CallService skipped - Supabase not available');
      }

      // 4. Sentry 错误监控
      debugPrint('[Init] Step 4: Initializing Sentry...');
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
          debugPrint('[Init] Step 4: Sentry initialized (${stopwatch.elapsedMilliseconds}ms)');
        } else {
          debugPrint('[Init] Step 4: Sentry skipped (no DSN configured)');
        }
      } catch (e) {
        debugPrint('[Init] Step 4: Sentry init skipped: $e');
      }

      // 5. Shorebird 补丁检查 —— 延迟执行 + 仅检查不下载
      _deferredShorebirdCheck();
    } catch (e) {
      debugPrint('[Init] Unexpected error: $e');
      _writeCrashLog('InitError', e.toString(), null);
    }

    // ⏱ 确保 splash 至少显示 _minSplashDurationMs 毫秒
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < _minSplashDurationMs) {
      final remaining = _minSplashDurationMs - elapsed;
      debugPrint('[Init] Waiting ${remaining}ms for minimum splash display...');
      await Future.delayed(Duration(milliseconds: remaining));
    }
    stopwatch.stop();

    debugPrint('[Init] All init done, total time: ${stopwatch.elapsedMilliseconds}ms, switching UI');

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

  /// 延迟 Shorebird 检查 —— 不阻塞启动，不下载补丁，仅检查
  void _deferredShorebirdCheck() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      if (kIsWeb) return;

      try {
        final updater = ShorebirdUpdater();
        final status = await updater.checkForUpdate().timeout(
          const Duration(seconds: 5),
          onTimeout: () => UpdateStatus.upToDate,
        );
        if (status == UpdateStatus.outdated) {
          debugPrint('[Shorebird] Patch available (deferred, not downloading)');
        }
      } on NoSuchMethodError catch (e) {
        debugPrint('[Shorebird] Not available in this build: $e');
      } on PlatformException catch (e) {
        debugPrint('[Shorebird] Platform error: $e');
      } catch (e) {
        debugPrint('[Shorebird] Deferred check skipped: $e');
      }
    });
  }

  /// 检查并下载 Shorebird 补丁（保留供将来安全版本使用）
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
    } on NoSuchMethodError catch (e) {
      debugPrint('[Shorebird] Not available: $e');
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
    debugPrint('[OpenFaith] build() called, _initialized=$_initialized');
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
        // 🔑 关键修复：始终将 child (Router) 保留在 widget tree 中
        // 这样 GoRouter 始终挂载，初始化完成后可无缝切换
        if (!_initialized) {
          // 初始化未完成 → 叠加品牌启动画面在路由之上
          debugPrint('[OpenFaith] builder: showing SplashScreen overlay');
          return Stack(
            children: [
              // 底层：路由（始终挂载，但不可见）
              if (child != null)
                Opacity(opacity: 0, child: child),
              // 顶层：品牌启动画面（完全覆盖）
              const _SplashScreen(),
            ],
          );
        }
        // 初始化完成但 Supabase 失败 → 显示错误页面
        if (_initError) {
          return _buildInitErrorScreen(
            '无法连接到服务器',
            '请检查网络连接后重试。',
          );
        }
        // 一切正常 → 显示主路由，包裹深色背景防止过渡闪烁
        return ColoredBox(
          color: const Color(0xFF050816),
          child: child ?? const SizedBox.shrink(),
        );
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
    debugPrint('[SplashScreen] build() called');
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
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
