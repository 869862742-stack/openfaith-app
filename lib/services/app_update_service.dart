import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
      final status = await updater.checkForUpdate();
      
      if (status == UpdateStatus.outdated) {
        // 获取当前补丁信息
        final currentPatch = await updater.currentPatch();
        final patchNum = currentPatch?.number ?? 0;
        
        debugPrint('[AppUpdate] Shorebird patch available (current: #$patchNum)');
        return AppUpdateInfo(
          type: UpdateType.patch,
          latestVersion: currentPatch?.displayVersion ?? '',
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

    Map<String, dynamic>? data;

    // 尝试 1: raw GitHub URL
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
        data = _parseVersionData(response.data);
      }
    } catch (e) {
      debugPrint('[AppUpdate] Raw URL failed: $e');
    }

    // 尝试 2: GitHub API (fallback)
    if (data == null) {
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
            data = _parseVersionData(decoded);
          }
        }
      } catch (e) {
        debugPrint('[AppUpdate] GitHub API fallback also failed: $e');
      }
    }

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

      await _dio.download(
        url,
        savePath,
        cancelToken: _cancelToken!,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _progress = received / total;
            onProgressUpdate?.call(_progress);
          }
        },
      );

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
