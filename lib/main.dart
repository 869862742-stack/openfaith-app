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
import 'theme/app_colors.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

/// 待展示的更新信息（模块级变量，启动时检查一次）
AppUpdateInfo? _pendingUpdate;

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

  // APP 版本更新检查（静默，不阻塞启动）
  await _checkAppUpdate();

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

/// 检查 APP 是否有新版本可更新（启动时调用）
Future<void> _checkAppUpdate() async {
  try {
    final updateInfo = await AppUpdateService().checkForUpdate();
    if (updateInfo != null) {
      _pendingUpdate = updateInfo;
    }
  } catch (e) {
    debugPrint('[AppUpdate] Check skipped: $e');
  }
}

class OpenFaithApp extends StatefulWidget {
  final bool supabaseReady;
  final bool callServiceReady;

  const OpenFaithApp({
    super.key,
    this.supabaseReady = false,
    this.callServiceReady = false,
  });

  @override
  State<OpenFaithApp> createState() => _OpenFaithAppState();
}

class _OpenFaithAppState extends State<OpenFaithApp> {
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowUpdateDialog();
    });
  }

  void _maybeShowUpdateDialog() {
    if (_updateDialogShown || _pendingUpdate == null) return;
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
        if (!widget.supabaseReady) {
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

/// 更新弹窗组件：显示版本信息 -> 下载进度 -> 自动安装
/// 可被 main.dart 启动弹窗和 about_screen 手动检查复用
class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo update;
  const UpdateDialog({super.key, required this.update});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _status = 'info'; // 'info' | 'downloading' | 'error'
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    final service = AppUpdateService();
    service.onProgressUpdate = (progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
        });
      }
    };
    service.onStatusChange = (status, {error}) {
      if (!mounted) return;
      setState(() {
        _status = status;
        if (status == 'error' && error != null) {
          _errorMessage = error;
          _isDownloading = false;
        }
        if (status == 'completed') {
          Navigator.of(context).pop();
        }
      });
    };
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'downloading';
      _downloadProgress = 0.0;
      _errorMessage = '';
    });

    await AppUpdateService().downloadAndInstall(widget.update);

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderColor, width: 0.5),
      ),
      title: Row(
        children: [
          Icon(
            _isDownloading ? Icons.downloading : Icons.system_update_alt,
            color: AppColors.auroraBlue,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isDownloading
                  ? '正在下载更新'
                  : '发现新版本 v${widget.update.latestVersion}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDownloading) ...[
            // 下载进度界面
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppColors.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'v${widget.update.latestVersion}',
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '下载失败: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ] else ...[
            // 版本信息界面
            if (widget.update.changelog.isNotEmpty) ...[
              const Text(
                '更新内容',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    widget.update.changelog,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (_isDownloading)
          TextButton(
            onPressed: () {
              AppUpdateService().cancelDownload();
              Navigator.pop(context);
            },
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '稍后提醒',
              style: TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D4EDD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _errorMessage.isNotEmpty ? '重试' : '立即更新',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}
