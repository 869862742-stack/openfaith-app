import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

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
  }

  /// 启动时请求必要权限
  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.camera.request();
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
              // 处理网页权限请求 - 自动授予
              onPermissionRequest: (controller, request) async {
                debugPrint('[WebView] Permission requested: ${request.resources}');
                // 直接授予所有权限
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
