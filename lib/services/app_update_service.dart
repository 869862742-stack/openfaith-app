import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// 更新类型
enum UpdateType {
  patch,      // Shorebird 增量补丁
  fullApk,    // 完整 APK 下载
}

/// APP 版本更新信息模型
class AppUpdateInfo {
  final UpdateType type;
  final String latestVersion;
  final String downloadUrl;
  final String fallbackUrl;
  final String changelog;
  final int? patchNumber; // Shorebird 补丁编号

  AppUpdateInfo({
    required this.type,
    required this.latestVersion,
    this.downloadUrl = '',
    this.fallbackUrl = '',
    this.changelog = '',
    this.patchNumber,
  });

  bool get isPatch => type == UpdateType.patch;
}

/// APP 更新服务
/// 
/// 更新策略（增量优先，降级兜底）：
/// 1. 优先检查 Shorebird 增量补丁（小更新，几KB-几MB）
/// 2. 无补丁时检查 version.json 完整 APK 更新（大版本更新）
/// 3. Shorebird auto_update: true 时，启动自动下载应用补丁
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  double _progress = 0.0;
  double get progress => _progress;
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  /// 进度回调
  void Function(double progress)? onProgressUpdate;
  /// 状态回调: 'checking' | 'downloading' | 'installing' | 'completed' | 'error'
  void Function(String status, {String? error})? onStatusChange;

  /// 检查是否有新版本
  /// 优先检查 Shorebird 补丁，无补丁则检查完整 APK
  Future<AppUpdateInfo?> checkForUpdate() async {
    onStatusChange?.call('checking');

    // 步骤1: 检查 Shorebird 增量补丁
    final patchInfo = await _checkShorebirdPatch();
    if (patchInfo != null) {
      debugPrint('[AppUpdate] Shorebird patch available: #${patchInfo.patchNumber}');
      return patchInfo;
    }

    // 步骤2: 检查完整 APK 更新
    final apkInfo = await _checkFullApkUpdate();
    if (apkInfo != null) {
      debugPrint('[AppUpdate] Full APK update available: ${apkInfo.latestVersion}');
      return apkInfo;
    }

    debugPrint('[AppUpdate] Already up to date');
    return null;
  }

  /// 检查 Shorebird 增量补丁
  Future<AppUpdateInfo?> _checkShorebirdPatch() async {
    try {
      final updater = ShorebirdUpdater();
      
      // 检查 Shorebird 是否可用
      if (!updater.isAvailable) {
        debugPrint('[AppUpdate] Shorebird updater not available');
        return null;
      }
      
      final status = await updater.checkForUpdate();
      
      if (status == UpdateStatus.outdated) {
        // 获取当前补丁信息
        final currentPatch = await updater.readCurrentPatch();
        final patchNum = currentPatch?.number ?? 0;
        
        // 获取当前 APP 版本号
        final packageInfo = await PackageInfo.fromPlatform();
        
        debugPrint('[AppUpdate] Shorebird patch available (current: #$patchNum, status: $status)');
        return AppUpdateInfo(
          type: UpdateType.patch,
          latestVersion: packageInfo.version,
          patchNumber: patchNum,
          changelog: '增量更新补丁 #${patchNum + 1}',
        );
      }
      debugPrint('[AppUpdate] No Shorebird patch available (status: $status)');
    } catch (e) {
      debugPrint('[AppUpdate] Shorebird check failed: $e');
    }
    return null;
  }

  /// 检查完整 APK 更新（通过 version.json）
  Future<AppUpdateInfo?> _checkFullApkUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 从所有来源获取版本信息，取最高版本
    Map<String, dynamic>? bestData;
    int bestVersionCode = 0;

    // 来源 1: Cloudflare CDN
    try {
      final cdnUrl = 'https://download.openfaithhub.com/version.json';
      final cdnResponse = await _dio.get(
        cdnUrl,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (cdnResponse.statusCode == 200 && cdnResponse.data != null) {
        final cdnData = _parseVersionData(cdnResponse.data);
        final cdnCode = cdnData['versionCode'] as int? ?? 0;
        if (cdnCode > bestVersionCode) {
          bestData = cdnData;
          bestVersionCode = cdnCode;
        }
        debugPrint('[AppUpdate] CDN versionCode: $cdnCode');
      }
    } catch (e) {
      debugPrint('[AppUpdate] CDN version check failed: $e');
    }

    // 来源 2: GitHub raw URL（始终检查，取最高版本）
    try {
      final rawUrl = 'https://raw.githubusercontent.com/869862742-stack/openfaith-app/main/version.json';
      final response = await _dio.get(
        rawUrl,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final ghData = _parseVersionData(response.data);
        final ghCode = ghData['versionCode'] as int? ?? 0;
        if (ghCode > bestVersionCode) {
          bestData = ghData;
          bestVersionCode = ghCode;
        }
        debugPrint('[AppUpdate] GitHub raw versionCode: $ghCode');
      }
    } catch (e) {
      debugPrint('[AppUpdate] GitHub raw failed: $e');
    }

    // 来源 3: GitHub API (fallback)
    if (bestData == null) {
      try {
        final apiUrl = 'https://api.github.com/repos/869862742-stack/openfaith-app/contents/version.json';
        final response = await _dio.get(
          apiUrl,
          options: Options(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          ),
        );
        if (response.statusCode == 200 && response.data != null) {
          final Map<String, dynamic> apiResp;
          if (response.data is String) {
            apiResp = json.decode(response.data as String) as Map<String, dynamic>;
          } else if (response.data is Map<String, dynamic>) {
            apiResp = response.data as Map<String, dynamic>;
          } else {
            apiResp = {};
          }
          final content = apiResp['content'] as String?;
          if (content != null && content.isNotEmpty) {
            final decoded = utf8.decode(base64.decode(content));
            final apiData = _parseVersionData(decoded);
            final apiCode = apiData['versionCode'] as int? ?? 0;
            if (apiCode > bestVersionCode) {
              bestData = apiData;
              bestVersionCode = apiCode;
            }
          }
        }
      } catch (e) {
        debugPrint('[AppUpdate] GitHub API fallback also failed: $e');
      }
    }

    final data = bestData;
    if (data == null) {
      return null; // 网络异常时不抛异常，静默处理
    }

    final latestVersion = data['latestVersion'] as String? ?? '';
    final downloadUrl = data['downloadUrl'] as String? ?? '';
    final fallbackUrl = data['fallbackUrl'] as String? ?? '';
    final changelog = data['changelog'] as String? ?? '';

    if (latestVersion.isEmpty || downloadUrl.isEmpty) return null;

    if (_isNewerVersion(currentVersion, latestVersion)) {
      return AppUpdateInfo(
        type: UpdateType.fullApk,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        fallbackUrl: fallbackUrl,
        changelog: changelog,
      );
    }
    return null;
  }

  /// 应用 Shorebird 增量补丁
  Future<bool> _applyShorebirdPatch() async {
    try {
      onStatusChange?.call('downloading');
      final updater = ShorebirdUpdater();
      await updater.update();
      onStatusChange?.call('completed');
      debugPrint('[AppUpdate] Shorebird patch applied successfully');
      return true;
    } catch (e) {
      debugPrint('[AppUpdate] Shorebird patch apply failed: $e');
      onStatusChange?.call('error', error: e.toString());
      return false;
    }
  }

  /// 下载并安装更新
  /// 根据更新类型自动选择：补丁 or 完整 APK
  Future<bool> downloadAndInstall(AppUpdateInfo updateInfo) async {
    if (_isDownloading) {
      debugPrint('[AppUpdate] Already downloading');
      return false;
    }

    // Web 平台：用浏览器下载 APK
    if (kIsWeb) {
      String url = updateInfo.downloadUrl;
      if (url.isEmpty && updateInfo.fallbackUrl.isNotEmpty) {
        url = updateInfo.fallbackUrl;
      }
      if (url.isEmpty) {
        onStatusChange?.call('error', error: 'No download URL');
        _isDownloading = false;
        return false;
      }
      debugPrint('[AppUpdate] Web platform: opening download URL in browser');
      onStatusChange?.call('downloading');
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        onStatusChange?.call('completed');
      } else {
        onStatusChange?.call('error', error: 'Failed to open browser');
      }
      _isDownloading = false;
      return launched;
    }

    _isDownloading = true;
    _progress = 0.0;

    // 增量补丁：直接应用
    if (updateInfo.isPatch) {
      final success = await _applyShorebirdPatch();
      _isDownloading = false;
      return success;
    }

    // 完整 APK：下载安装
    _cancelToken = CancelToken();
    try {
      onStatusChange?.call('downloading');

      String url = updateInfo.downloadUrl;
      if (url.isEmpty && updateInfo.fallbackUrl.isNotEmpty) {
        url = updateInfo.fallbackUrl;
      }
      if (url.isEmpty) throw Exception('No download URL available');

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/OpenFaith-v${updateInfo.latestVersion}.apk';

      final file = File(savePath);
      if (await file.exists()) await file.delete();

      debugPrint('[AppUpdate] Downloading APK to: $savePath');

      // 大文件下载：增加超时和重试
      final downloadDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 300),
      ));
      int retryCount = 0;
      const maxRetries = 2;
      while (true) {
        try {
          await downloadDio.download(
            url,
            savePath,
            cancelToken: _cancelToken!,
            options: Options(headers: {'Connection': 'keep-alive'}),
            onReceiveProgress: (received, total) {
              if (total > 0) {
                _progress = received / total;
                onProgressUpdate?.call(_progress);
              }
            },
          );
          break;
        } catch (e) {
          retryCount++;
          if (retryCount <= maxRetries) {
            debugPrint('[AppUpdate] Download retry #$retryCount: $e');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          rethrow;
        }
      }

      if (!await file.exists()) throw Exception('Downloaded file not found');
      final fileSize = await file.length();
      if (fileSize < 1024 * 1024) throw Exception('File too small: $fileSize bytes');

      debugPrint('[AppUpdate] Download complete: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');

      onStatusChange?.call('installing');
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        onStatusChange?.call('completed');
        _isDownloading = false;
        return true;
      } else {
        final result2 = await OpenFilex.open(savePath);
        if (result2.type == ResultType.done) {
          onStatusChange?.call('completed');
          _isDownloading = false;
          return true;
        }
        throw Exception('Failed to open APK: ${result2.message}');
      }
    } catch (e) {
      debugPrint('[AppUpdate] Download/install failed: $e');
      onStatusChange?.call('error', error: e.toString());
      _isDownloading = false;
      return false;
    }
  }

  /// 取消下载
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    _isDownloading = false;
    _progress = 0.0;
  }

  /// 解析 version.json
  Map<String, dynamic>? _parseVersionData(dynamic responseData) {
    try {
      if (responseData is String) {
        return json.decode(responseData) as Map<String, dynamic>;
      } else if (responseData is Map<String, dynamic>) {
        return responseData;
      }
    } catch (e) {
      debugPrint('[AppUpdate] Parse failed: $e');
    }
    return null;
  }

  /// 比较语义化版本号
  static bool _isNewerVersion(String current, String remote) {
    try {
      final cp = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final rp = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final maxLen = cp.length > rp.length ? cp.length : rp.length;
      while (cp.length < maxLen) cp.add(0);
      while (rp.length < maxLen) rp.add(0);
      for (int i = 0; i < maxLen; i++) {
        if (rp[i] > cp[i]) return true;
        if (rp[i] < cp[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
