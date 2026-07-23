import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
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

  static const String _baseUrl = 'https://openfaithhub.com';

  @override
  void initState() {
    super.initState();
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
      // 静默失败，不影响正常使用
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
        body: Stack(
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
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
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
    );
  }
}
