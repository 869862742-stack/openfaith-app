import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'router/app_router.dart';
import 'services/call_service.dart';
import 'theme/app_colors.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

/// APP 版本更新信息
class _AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String fallbackUrl;
  final String changelog;

  _AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.fallbackUrl,
    required this.changelog,
  });
}

/// 待展示的更新信息（模块级变量，启动时检查一次）
_AppUpdateInfo? _pendingUpdate;

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

/// 检查 APP 是否有新版本可更新
/// 3秒超时，失败静默，不影响启动
Future<void> _checkAppUpdate() async {
  try {
    // 获取当前版本
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 获取远程版本信息
    final dio = Dio();
    final response = await dio.get(
      'https://openfaithhub.com/version.json',
      options: Options(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    if (response.statusCode != 200 || response.data == null) {
      debugPrint('[AppUpdate] Failed to fetch version.json: ${response.statusCode}');
      return;
    }

    final Map<String, dynamic> data;
    if (response.data is String) {
      data = json.decode(response.data as String) as Map<String, dynamic>;
    } else if (response.data is Map<String, dynamic>) {
      data = response.data as Map<String, dynamic>;
    } else {
      debugPrint('[AppUpdate] Unexpected response format');
      return;
    }

    final latestVersion = data['latestVersion'] as String? ?? '';
    final downloadUrl = data['downloadUrl'] as String? ?? '';
    final fallbackUrl = data['fallbackUrl'] as String? ?? '';
    final changelog = data['changelog'] as String? ?? '';

    if (latestVersion.isEmpty || downloadUrl.isEmpty) {
      debugPrint('[AppUpdate] Invalid version data');
      return;
    }

    // 比较版本号
    if (_isNewerVersion(currentVersion, latestVersion)) {
      debugPrint('[AppUpdate] New version available: $latestVersion (current: $currentVersion)');
      _pendingUpdate = _AppUpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        fallbackUrl: fallbackUrl,
        changelog: changelog,
      );
    } else {
      debugPrint('[AppUpdate] Already up to date: $currentVersion');
    }
  } catch (e) {
    debugPrint('[AppUpdate] Check skipped: $e');
  }
}

/// 比较语义化版本号，判断 remote 是否比 current 更新
bool _isNewerVersion(String current, String remote) {
  try {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 补齐长度
    final maxLen = currentParts.length > remoteParts.length
        ? currentParts.length
        : remoteParts.length;
    while (currentParts.length < maxLen) {
      currentParts.add(0);
    }
    while (remoteParts.length < maxLen) {
      remoteParts.add(0);
    }

    for (int i = 0; i < maxLen; i++) {
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }
    return false; // 相等
  } catch (e) {
    debugPrint('[AppUpdate] Version compare error: $e');
    return false;
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
    // 首帧渲染后检查并展示更新弹窗
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
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderColor, width: 0.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.system_update_alt, color: AppColors.auroraBlue, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '发现新版本 v${update.latestVersion}',
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
              if (update.changelog.isNotEmpty) ...[
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
                      update.changelog,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                '稍后再说',
                style: TextStyle(color: AppColors.textWeak, fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openUpdateUrl(update);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('立即更新', style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUpdateUrl(_AppUpdateInfo update) async {
    // 优先使用 downloadUrl，fallback 到 fallbackUrl
    String url = update.downloadUrl;
    if (url.isEmpty && update.fallbackUrl.isNotEmpty) {
      url = update.fallbackUrl;
    }
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppUpdate] Failed to open URL: $e');
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
