import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
  final String size;
  final int? patchNumber;

  AppUpdateInfo({
    required this.type,
    required this.latestVersion,
    this.downloadUrl = '',
    this.fallbackUrl = '',
    this.changelog = '',
    this.size = '',
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
  void Function(double progress, {int? receivedBytes, int? totalBytes})? onProgressUpdate;

  CancelToken? _downloadCancelToken;

  /// 取消正在进行的下载
  void cancelDownload() {
    _downloadCancelToken?.cancel();
    _downloadCancelToken = null;
    debugPrint('[AppUpdate] Download cancelled');
  }

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
    final size = data['size'] as String? ?? '';

    if (latestVersion.isEmpty || downloadUrl.isEmpty) return null;

    if (_isNewerVersion(currentVersion, latestVersion)) {
      return AppUpdateInfo(
        type: UpdateType.fullApk,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        fallbackUrl: fallbackUrl,
        changelog: changelog,
        size: size,
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
  /// 对于完整 APK（原生平台）：
  /// 1. APP内下载 APK 文件到缓存目录（带进度回调）
  /// 2. 下载完成后调用系统安装器自动弹出安装界面
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

    // ===== 原生平台：APP内下载 APK + 安装 =====
    return await _downloadAndInstallApk(url, updateInfo);
  }

  /// APP内下载 APK 并安装
  Future<bool> _downloadAndInstallApk(String url, AppUpdateInfo updateInfo) async {
    try {
      onStatusChange?.call('downloading');
      _downloadCancelToken = CancelToken();

      // 获取缓存目录
      final cacheDir = await getApplicationCacheDirectory();
      final apkFileName = 'openfaith_v${updateInfo.latestVersion}.apk';
      final apkFilePath = '${cacheDir.path}/$apkFileName';

      // 如果已存在同版本APK，直接安装
      final existingFile = File(apkFilePath);
      if (await existingFile.exists()) {
        final fileSize = await existingFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          // 大于10MB说明是完整APK
          debugPrint('[AppUpdate] Found existing APK ($fileSize bytes), installing directly');
          onStatusChange?.call('installing');
          final result = await OpenFilex.open(apkFilePath);
          if (result.type == ResultType.done) {
            onStatusChange?.call('completed');
            return true;
          }
          // 安装失败，删除旧文件重新下载
          debugPrint('[AppUpdate] Install from cache failed: ${result.message}, re-downloading');
          await existingFile.delete();
        }
      }

      debugPrint('[AppUpdate] Starting in-app APK download: $url');
      debugPrint('[AppUpdate] Saving to: $apkFilePath');

      // 使用 Dio 下载文件，跟踪进度
      final response = await _dio.download(
        url,
        apkFilePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total <= 0) {
            // 总大小未知时，只报告已接收字节数
            onProgressUpdate?.call(
              received > 0 ? received / (received + 50 * 1024 * 1024) : 0,
              receivedBytes: received,
              totalBytes: null,
            );
          } else {
            onProgressUpdate?.call(
              received / total,
              receivedBytes: received,
              totalBytes: total,
            );
          }
        },
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      _downloadCancelToken = null;

      if (response.statusCode != null && response.statusCode! < 300) {
        final apkFile = File(apkFilePath);
        final fileSize = await apkFile.length();
        debugPrint('[AppUpdate] APK downloaded successfully: ${fileSize ~/ (1024 * 1024)} MB');

        // 触发安装
        onStatusChange?.call('installing');
        final result = await OpenFilex.open(apkFilePath);
        
        if (result.type == ResultType.done) {
          debugPrint('[AppUpdate] APK installer launched successfully');
          onStatusChange?.call('completed');
          return true;
        } else {
          debugPrint('[AppUpdate] Failed to open APK for install: ${result.type} - ${result.message}');
          // 打开失败但文件已下载成功，尝试用 Intent 方式
          if (Platform.isAndroid) {
            final intentResult = await _installApkViaIntent(apkFilePath);
            if (intentResult) {
              onStatusChange?.call('completed');
              return true;
            }
          }
          onStatusChange?.call('error', error: '无法启动安装程序: ${result.message}');
          return false;
        }
      } else {
        onStatusChange?.call('error', error: '下载失败: HTTP ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      _downloadCancelToken = null;
      if (e.type == DioExceptionType.cancel) {
        debugPrint('[AppUpdate] Download cancelled by user');
        onStatusChange?.call('cancelled');
        return false;
      }
      debugPrint('[AppUpdate] Download failed: $e');
      onStatusChange?.call('error', error: '下载失败: ${e.message}');
      return false;
    } catch (e) {
      _downloadCancelToken = null;
      debugPrint('[AppUpdate] Install failed: $e');
      onStatusChange?.call('error', error: e.toString());
      return false;
    }
  }

  /// Android 备用安装方式：通过 Intent
  Future<bool> _installApkViaIntent(String apkFilePath) async {
    try {
      // open_filex 已经处理了 FileProvider，这里作为兜底
      final result = await OpenFilex.open(
        apkFilePath,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('[AppUpdate] Intent install also failed: $e');
      return false;
    }
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
