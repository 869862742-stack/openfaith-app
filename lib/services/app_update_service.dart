import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// APP 版本更新信息模型
class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String fallbackUrl;
  final String changelog;

  AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.fallbackUrl,
    required this.changelog,
  });
}

/// APP 更新服务 - 负责下载 APK 并触发安装
///
/// 使用方式:
/// 1. 调用 checkForUpdate() 检查是否有新版本
/// 2. 如果有新版本，调用 downloadAndInstall() 下载并安装
/// 3. 通过 onProgressUpdate / onStatusChange 监听进度和状态
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
  /// 状态回调: 'downloading' | 'installing' | 'completed' | 'error'
  void Function(String status, {String? error})? onStatusChange;

  /// 检查是否有新版本
  /// 先尝试 raw GitHub URL，失败后 fallback 到 GitHub API
  /// 网络异常（两个源都失败）时抛出异常，无新版本时返回 null
  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    Map<String, dynamic>? data;

    // 尝试 1: raw GitHub URL
    try {
      final rawUrl = 'https://raw.githubusercontent.com/869862742-stack/openfaith-app/main/version.json';
      debugPrint('[AppUpdateService] Trying raw URL: $rawUrl');
      final response = await _dio.get(
        rawUrl,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        data = _parseVersionData(response.data);
        if (data != null) {
          debugPrint('[AppUpdateService] Successfully fetched from raw URL');
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Raw URL failed: $e');
    }

    // 尝试 2: GitHub API (fallback)
    if (data == null) {
      try {
        final apiUrl = 'https://api.github.com/repos/869862742-stack/openfaith-app/contents/version.json';
        debugPrint('[AppUpdateService] Falling back to GitHub API: $apiUrl');
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
            if (data != null) {
              debugPrint('[AppUpdateService] Successfully fetched from GitHub API');
            }
          }
        }
      } catch (e) {
        debugPrint('[AppUpdateService] GitHub API fallback also failed: $e');
      }
    }

    // 两个源都失败，抛出异常让调用方感知网络错误
    if (data == null) {
      throw Exception('无法获取版本信息，请检查网络连接后重试');
    }

    final latestVersion = data['latestVersion'] as String? ?? '';
    final downloadUrl = data['downloadUrl'] as String? ?? '';
    final fallbackUrl = data['fallbackUrl'] as String? ?? '';
    final changelog = data['changelog'] as String? ?? '';

    if (latestVersion.isEmpty || downloadUrl.isEmpty) return null;

    if (_isNewerVersion(currentVersion, latestVersion)) {
      debugPrint('[AppUpdateService] New version: $latestVersion (current: $currentVersion)');
      return AppUpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        fallbackUrl: fallbackUrl,
        changelog: changelog,
      );
    }
    debugPrint('[AppUpdateService] Already up to date: $currentVersion');
    return null;
  }

  /// 解析 version.json 数据
  Map<String, dynamic>? _parseVersionData(dynamic responseData) {
    try {
      if (responseData is String) {
        return json.decode(responseData) as Map<String, dynamic>;
      } else if (responseData is Map<String, dynamic>) {
        return responseData;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Parse version data failed: $e');
    }
    return null;
  }

  /// 下载 APK 并触发系统安装
  /// 下载保存到 APP 缓存目录，完成后自动弹出系统安装器
  Future<bool> downloadAndInstall(AppUpdateInfo updateInfo) async {
    if (_isDownloading) {
      debugPrint('[AppUpdateService] Already downloading');
      return false;
    }

    _isDownloading = true;
    _progress = 0.0;
    _cancelToken = CancelToken();

    try {
      onStatusChange?.call('downloading');

      // 确定下载 URL
      String url = updateInfo.downloadUrl;
      if (url.isEmpty && updateInfo.fallbackUrl.isNotEmpty) {
        url = updateInfo.fallbackUrl;
      }
      if (url.isEmpty) throw Exception('No download URL available');

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/OpenFaith-v${updateInfo.latestVersion}.apk';

      // 删除旧文件
      final file = File(savePath);
      if (await file.exists()) await file.delete();

      debugPrint('[AppUpdateService] Downloading to: $savePath');
      debugPrint('[AppUpdateService] URL: $url');

      // dio 下载，支持进度回调
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

      // 验证文件
      if (!await file.exists()) throw Exception('Downloaded file not found');
      final fileSize = await file.length();
      if (fileSize < 1024 * 1024) throw Exception('File too small: $fileSize bytes');

      debugPrint('[AppUpdateService] Download complete: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');

      // 触发系统安装
      onStatusChange?.call('installing');
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        debugPrint('[AppUpdateService] Install dialog opened');
        onStatusChange?.call('completed');
        _isDownloading = false;
        return true;
      } else {
        // Fallback: 不指定 type 让系统自行处理
        debugPrint('[AppUpdateService] First attempt result: ${result.type} - ${result.message}');
        final result2 = await OpenFilex.open(savePath);
        if (result2.type == ResultType.done) {
          debugPrint('[AppUpdateService] Install dialog opened (fallback)');
          onStatusChange?.call('completed');
          _isDownloading = false;
          return true;
        }
        throw Exception('Failed to open APK: ${result2.message}');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Download/install failed: $e');
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
    debugPrint('[AppUpdateService] Download cancelled');
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
