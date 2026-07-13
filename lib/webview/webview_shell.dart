import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView 壳 - 加载网页版 OpenFaith
/// 所有页面、导航、业务逻辑都由网页版处理
/// Flutter 仅提供原生容器 + 未来逐步替换的原生模块
class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String _currentUrl = '';

  // 网页版地址
  static const String _baseUrl = 'https://openfaithhub.com';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Android 返回键处理：WebView 有历史则后退，否则退出
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
            // WebView 主体
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_baseUrl)),
              initialSettings: InAppWebViewSettings(
                // 基础设置
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                // 缓存策略
                cacheEnabled: true,
                // 媒体自动播放
                mediaPlaybackRequiresUserGesture: false,
                // 允许混合内容（HTTPS 页面加载 HTTP 资源）
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                // 透明背景，避免白屏闪烁
                transparentBackground: true,
                // 支持缩放
                supportZoom: false,
                // 隐藏滚动条（和原生APP一致）
                verticalScrollbarThumbColor: Colors.white24,
                // 安全区域
                useShouldOverrideUrlLoading: false,
                // 允许文件访问
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                // 注册 JS Bridge（未来原生模块通信用）
                _registerJsBridge(controller);
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _currentUrl = url?.toString() ?? '';
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onLoadError: (controller, url, code, message) {
                debugPrint('[WebView] Load error: $code $message for $url');
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('[WebView Console] ${consoleMessage.message}');
              },
            ),
            // 加载指示器
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

  /// 注册 JS Bridge，供网页版调用原生能力
  void _registerJsBridge(InAppWebViewController controller) {
    // 预留：未来在此注册原生模块的 JS 桥接
    // 示例：
    // controller.addJavaScriptHandler(
    //   handlerName: 'getDeviceInfo',
    //   callback: (args) => {'platform': 'android', 'version': '...'},
    // );
    debugPrint('[WebView] JS Bridge registered');
  }
}
