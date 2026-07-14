import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

/// WebView 壳 - 加载网页版 OpenFaith
/// 所有页面、导航、业务逻辑都由网页版处理
/// Flutter 仅提供原生容器 + 逐步替换的原生模块（如藏书、通话）
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
            // 在首页按返回键 = 退出APP
            SystemNavigator.pop();
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
                verticalScrollbarThumbColor: Colors.white24,
                useShouldOverrideUrlLoading: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _registerJsBridge(controller);
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (controller, url) async {
                setState(() => _isLoading = false);
                // 密码门控自动填充
                await _tryAutoFillPassword(controller, url);
              },
              onLoadError: (controller, url, code, message) {
                debugPrint('[WebView] Load error: $code $message for $url');
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('[WebView Console] ${consoleMessage.message}');
              },
              // 拦截导航 — 原生路由跳转
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url?.toString() ?? '';
                
                if (url.startsWith(_baseUrl)) {
                  final path = url.substring(_baseUrl.length);
                  
                  // 藏书 → 原生
                  if (path == '/books' || path.startsWith('/books/')) {
                    if (mounted) context.go(path);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                
                return NavigationActionPolicy.ALLOW;
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

  /// 密码门控自动填充
  Future<void> _tryAutoFillPassword(InAppWebViewController controller, Uri? url) async {
    if (url == null) return;
    if (!url.toString().startsWith(_baseUrl)) return;
    
    try {
      await controller.evaluateJavascript(source: '''
        (function() {
          var form = document.querySelector('form[action="/login"]');
          if (!form) return 'no_form';
          var pwd = form.querySelector('input[type="password"]');
          if (!pwd) return 'no_input';
          if (pwd.value.length > 0) return 'already_filled';
          pwd.value = 'openfaith2026';
          pwd.dispatchEvent(new Event('input', {bubbles: true}));
          pwd.dispatchEvent(new Event('change', {bubbles: true}));
          setTimeout(function() { form.submit(); }, 300);
          return 'submitted';
        })()
      ''');
    } catch (e) {
      debugPrint('[WebView] Password auto-fill error: $e');
    }
  }

  /// JS Bridge — 网页调用原生能力
  void _registerJsBridge(InAppWebViewController controller) {
    // 导航到原生页面
    controller.addJavaScriptHandler(
      handlerName: 'navigateToNative',
      callback: (args) {
        if (args.isNotEmpty && mounted) {
          final path = args[0] as String;
          context.go(path);
        }
      },
    );
    
    // 返回上一页
    controller.addJavaScriptHandler(
      handlerName: 'goBack',
      callback: (args) async {
        if (await _webViewController?.canGoBack() == true) {
          await _webViewController?.goBack();
        }
      },
    );
    
    debugPrint('[WebView] JS Bridge registered');
  }
}
