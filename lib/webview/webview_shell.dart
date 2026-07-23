import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/app_update_service.dart';

/// WebView 壳 - 加载网页版 OpenFaith
class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String _appVersion = '';

  static const String _baseUrl = 'https://openfaithhub.com';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 获取 APP 版本号
    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    debugPrint('[WebView] APP version: $_appVersion');

    _requestPermissions();
    _checkForUpdate();
  }

  /// 启动时请求必要权限
  Future<void> _requestPermissions() async {
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      await Permission.microphone.request();
    }
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
  }

  /// 启动时检查新版本
  Future<void> _checkForUpdate() async {
    try {
      final updateService = AppUpdateService();
      final updateInfo = await updateService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      debugPrint('[WebView] Update check failed: $e');
    }
  }

  /// 手动触发版本检查（从 JS Bridge 调用）
  Future<void> _manualCheckForUpdate() async {
    try {
      final updateService = AppUpdateService();
      final updateInfo = await updateService.checkForUpdate();
      
      if (!mounted) return;
      
      if (updateInfo != null) {
        _showUpdateDialog(updateInfo);
      } else {
        // 显示"已是最新版本"提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('当前已是最新版本 v${_appVersion.split('+').first}'),
            backgroundColor: const Color(0xFF9D4EDD),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查更新失败: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// 显示更新对话框
  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDownloading = false;
        double downloadProgress = 0.0;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final updateService = AppUpdateService();
            updateService.onProgressUpdate = (progress) {
              setDialogState(() => downloadProgress = progress);
            };
            updateService.onStatusChange = (status, {error}) {
              if (status == 'installing' || status == 'completed') {
                if (mounted) Navigator.of(dialogContext).pop();
              }
            };
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF9D4EDD), width: 1),
              ),
              title: Text(
                '发现新版本 v${updateInfo.latestVersion}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (updateInfo.changelog.isNotEmpty) ...[
                    Text(
                      updateInfo.changelog,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isDownloading) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: downloadProgress > 0 ? downloadProgress : null,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '下载中 ${(downloadProgress * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFF9D4EDD), fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      '稍后再说',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D4EDD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      setDialogState(() => isDownloading = true);
                      await updateService.downloadAndInstall(updateInfo);
                    },
                    child: const Text('立即更新'),
                  ),
                ] else ...[
                  const Text(
                    '正在下载...',
                    style: TextStyle(color: Color(0xFF9D4EDD)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final controller = _webViewController;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(_baseUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  cacheEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  transparentBackground: true,
                  supportZoom: false,
                  thirdPartyCookiesEnabled: true,
                  allowFileAccess: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  verticalScrollbarThumbColor: Colors.white24,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  
                  // 注册 JS Bridge handler
                  controller.addJavaScriptHandler(
                    handlerName: 'getAppVersion',
                    callback: (args) {
                      return json.encode({
                        'version': _appVersion.split('+').first,
                        'buildNumber': _appVersion.contains('+') 
                            ? _appVersion.split('+').last 
                            : '0',
                        'fullVersion': _appVersion,
                      });
                    },
                  );
                  
                  controller.addJavaScriptHandler(
                    handlerName: 'checkForAppUpdate',
                    callback: (args) async {
                      debugPrint('[JS Bridge] checkForAppUpdate called');
                      await _manualCheckForUpdate();
                      return json.encode({'status': 'checked'});
                    },
                  );
                },
                onPermissionRequest: (controller, request) async {
                  debugPrint('[WebView] Permission requested: ${request.resources}');
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100);
                },
                onLoadStop: (controller, url) {
                  setState(() => _isLoading = false);
                  
                  // 页面加载完成后注入 JS Bridge
                  controller.evaluateJavascript(source: '''
                    (function() {
                      // 注入 APP 版本信息到 window
                      window.flutterInAppWebView.callHandler('getAppVersion').then(function(result) {
                        try {
                          var data = typeof result === 'string' ? JSON.parse(result) : result;
                          window.__OF_APP_VERSION__ = data.version;
                          window.__OF_APP_BUILD__ = data.buildNumber;
                          window.__OF_IS_NATIVE_APP__ = true;
                          console.log('[OF Bridge] APP version: ' + data.version + ' (build ' + data.buildNumber + ')');
                          
                          // 更新页面上显示的版本号
                          var versionEls = document.querySelectorAll('[class*="version"], [data-version]');
                          versionEls.forEach(function(el) {
                            if (el.textContent && el.textContent.includes('版本')) {
                              el.textContent = el.textContent.replace(/\\d+\\.\\d+\\.\\d+/, data.version);
                            }
                          });
                          
                          // 拦截"检查版本更新"按钮
                          var checkBtns = document.querySelectorAll('button');
                          checkBtns.forEach(function(btn) {
                            if (btn.textContent && (btn.textContent.includes('检查版本') || btn.textContent.includes('检查更新'))) {
                              btn.addEventListener('click', function(e) {
                                e.preventDefault();
                                e.stopPropagation();
                                console.log('[OF Bridge] Intercepted version check button');
                                window.flutterInAppWebView.callHandler('checkForAppUpdate');
                              }, true);
                            }
                          });
                        } catch(e) {
                          console.error('[OF Bridge] Error:', e);
                        }
                      });
                    })();
                  ''');
                },
                onLoadError: (controller, url, code, message) {
                  debugPrint('[WebView] Load error: $code $message');
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('[WebView Console] ${consoleMessage.message}');
                },
              ),
              if (_isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
