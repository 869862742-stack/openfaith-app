import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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
  final int? patchNumber;

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
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  final Dio _dio = Dio();

  void Function(String status, {String? error})? onStatusChange;
  void Function(double progress)? onProgressUpdate;

  /// 检查是否有新版本
  Future<AppUpdateInfo?> checkForUpdate() async {
    onStatusChange?.call('checking');

    // 检查 Shorebird 增量补丁
    final patchInfo = await _checkShorebirdPatch();
    if (patchInfo != null) {
      debugPrint('[AppUpdate] Shorebird patch available: #${patchInfo.patchNumber}');
      return patchInfo;
    }

    // 检查完整 APK 更新
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
      if (!updater.isAvailable) {
        debugPrint('[AppUpdate] Shorebird updater not available');
        return null;
      }
      
      final status = await updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        final currentPatch = await updater.readCurrentPatch();
        final patchNum = currentPatch?.number ?? 0;
        final packageInfo = await PackageInfo.fromPlatform();
        
        debugPrint('[AppUpdate] Shorebird patch available (current: #$patchNum)');
        return AppUpdateInfo(
          type: UpdateType.patch,
          latestVersion: packageInfo.version,
          patchNumber: patchNum,
          changelog: '增量更新补丁 #${patchNum + 1}',
        );
      }
    } catch (e) {
      debugPrint('[AppUpdate] Shorebird check failed: $e');
    }
    return null;
  }

  /// 检查完整 APK 更新
  Future<AppUpdateInfo?> _checkFullApkUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

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
        final cdnCode = (cdnData ?? const {})['versionCode'] as int? ?? 0;
        if (cdnCode > bestVersionCode) {
          bestData = cdnData;
          bestVersionCode = cdnCode;
        }
      }
    } catch (e) {
      debugPrint('[AppUpdate] CDN version check failed: $e');
    }

    // 来源 2: GitHub raw URL
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
        final ghCode = (ghData ?? const {})['versionCode'] as int? ?? 0;
        if (ghCode > bestVersionCode) {
          bestData = ghData;
          bestVersionCode = ghCode;
        }
      }
    } catch (e) {
      debugPrint('[AppUpdate] GitHub raw failed: $e');
    }

    final data = bestData;
    if (data == null) return null;

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
  /// 
  /// 对于完整 APK：直接调用系统浏览器/下载管理器下载
  /// - 系统 DownloadManager 支持后台下载、断点续传
  /// - 下载完成后系统通知栏提示，用户点击安装
  Future<bool> downloadAndInstall(AppUpdateInfo updateInfo) async {
    String url = updateInfo.downloadUrl;
    if (url.isEmpty) url = updateInfo.fallbackUrl;
    if (url.isEmpty) {
      onStatusChange?.call('error', error: 'No download URL');
      return false;
    }

    // Web 平台：浏览器下载
    if (kIsWeb) {
      debugPrint('[AppUpdate] Web platform: opening download URL in browser');
      onStatusChange?.call('downloading');
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (launched) {
        onStatusChange?.call('completed');
        return true;
      }
      onStatusChange?.call('error', error: 'Failed to open browser');
      return false;
    }

    // Shorebird 增量补丁
    if (updateInfo.isPatch) {
      return await _applyShorebirdPatch();
    }

    // 完整 APK：调用系统下载
    debugPrint('[AppUpdate] Opening download URL in system: $url');
    onStatusChange?.call('downloading');
    
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (launched) {
      debugPrint('[AppUpdate] System download initiated successfully');
      onStatusChange?.call('completed');
      return true;
    }

    onStatusChange?.call('error', error: 'Failed to open download URL');
    return false;
  }

  Map<String, dynamic>? _parseVersionData(dynamic responseData) {
    try {
      if (responseData is String) return json.decode(responseData) as Map<String, dynamic>;
      if (responseData is Map<String, dynamic>) return responseData;
    } catch (e) {
      debugPrint('[AppUpdate] Parse failed: $e');
    }
    return null;
  }

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
