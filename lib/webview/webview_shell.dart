import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

/// WebView 壳 - 加载网页版 OpenFaith
/// 所有页面、导航、业务逻辑都由网页版处理
/// Flutter 仅提供原生容器 + 音视频通话原生模块
class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String? _currentUrl;

  static const String _baseUrl = 'https://openfaithhub.com';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  /// 启动时请求必要权限
  Future<void> _requestPermissions() async {
    // 请求麦克风权限
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      await Permission.microphone.request();
    }
    
    // 请求摄像头权限（视频通话需要）
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
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
                // 关键修复：允许媒体自动播放
                mediaPlaybackRequiresUserGesture: false,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                transparentBackground: true,
                supportZoom: false,
                // 性能优化：启用硬件加速
                disableHardwareAcceleration: false,
                // 允许第三方 Cookie（网页版可能需要）
                thirdPartyCookiesEnabled: true,
                // 允许文件访问
                allowFileAccess: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                // 允许内容 URL 访问
                allowContentURLAccess: true,
                // 隐藏滚动条
                verticalScrollbarThumbColor: Colors.white24,
                // 安全区域
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _registerJsBridge(controller);
              },
              // 关键修复：处理网页权限请求
              onPermissionRequest: (controller, request) async {
                debugPrint('[WebView] Permission requested: ${request.resources}');
                for (final resource in request.resources) {
                  if (resource == PermissionResourceType.CAMERA) {
                    final status = await Permission.camera.request();
                    if (!status.isGranted) {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY,
                      );
                    }
                  } else if (resource == PermissionResourceType.MICROPHONE) {
                    final status = await Permission.microphone.request();
                    if (!status.isGranted) {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY,
                      );
                    }
                  }
                }
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
                debugPrint('[WebView] LoadStart: $url');
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (controller, url) async {
                setState(() => _isLoading = false);
                _currentUrl = url?.toString();
                debugPrint('[WebView] LoadStop: $url');
                // 注入权限状态到网页
                final micStatus = await Permission.microphone.status;
                final cameraStatus = await Permission.camera.status;
                final js = '''
                  window.OpenFaithPermissions = {
                    microphone: ${micStatus.isGranted},
                    camera: ${cameraStatus.isGranted}
                  };
                ''';
                controller.evaluateJavascript(source: js);
              },
              onLoadError: (controller, url, code, message) {
                debugPrint('[WebView] Load error: $code $message for $url');
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

  void _registerJsBridge(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'getDeviceInfo',
      callback: (args) {
        return {
          'platform': 'android',
          'appVersion': '1.3.9',
          'hasNativeCall': true,
        };
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'requestPermissions',
      callback: (args) async {
        final micStatus = await Permission.microphone.request();
        final cameraStatus = await Permission.camera.request();
        return {
          'microphone': micStatus.isGranted,
          'camera': cameraStatus.isGranted,
        };
      },
    );

    debugPrint('[WebView] JS Bridge registered');
  }
}
