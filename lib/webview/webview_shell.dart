import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import '../screens/call/call_screen.dart';
import '../services/call_service.dart';

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
  String? _currentUrl;

  static const String _baseUrl = 'https://openfaithhub.com';

  /// 需要拦截跳转原生的路径模式
  static const List<String> _nativePaths = [
    '/books',
    '/books/',
    '/book',     // 网页版阅读器URL
    '/book/',    // 网页版阅读器URL
    '/learn/books',
    '/classic-books',
  ];

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
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        body: Stack(
          children: [
            // 顶部安全区占位，防止汉堡菜单和搜索栏被状态栏遮挡
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top,
              child: Container(
                color: const Color(0xFF050816),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: InAppWebView(
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
                if (url != null) {
                  debugPrint('[WebView] LoadStart: $url');
                }
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (controller, url) async {
                setState(() => _isLoading = false);
                if (url != null) {
                  _currentUrl = url.toString();
                  debugPrint('[WebView] LoadStop: $_currentUrl');
                  // 检查是否需要跳转原生
                  _checkAndNavigateToNative(url.toString());
                }
                // 注入JS拦截通话按钮点击
                await _injectCallInterceptJs(controller);
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
                  // 提取路径部分（去掉base URL）
                  final rawPath = url.substring(_baseUrl.length);
                  
                  // 处理Hash路由：URL格式为 /#/book/:id 或 /#/chat/:userId
                  final hashPath = _extractHashPath(rawPath);
                  // 也要处理非hash的普通路径
                  final normalPath = rawPath.split('?')[0].split('#')[0];
                  
                  debugPrint('[WebView] URL intercept - raw: $rawPath, hash: $hashPath, normal: $normalPath');
                  
                  // 优先处理Hash路由
                  final pathToCheck = hashPath ?? normalPath;
                  
                  // 藏书/阅读器 → 原生
                  if (pathToCheck == '/books' || pathToCheck.startsWith('/books/') ||
                      pathToCheck == '/book' || pathToCheck.startsWith('/book/')) {
                    debugPrint('[WebView] Intercepting book URL: $url (path: $pathToCheck)');
                    // /book/:id 映射到 /books/:bookId 路由
                    String nativePath;
                    if (pathToCheck.startsWith('/book/')) {
                      nativePath = '/books/${pathToCheck.substring(6)}';
                    } else {
                      nativePath = pathToCheck;
                    }
                    if (mounted) context.go(nativePath);
                    return NavigationActionPolicy.CANCEL;
                  }
                  
                  // 通话/聊天 → 原生通话页面
                  if (pathToCheck.startsWith('/chat/')) {
                    final userId = pathToCheck.substring(6); // 去掉 /chat/
                    debugPrint('[WebView] Intercepting chat/call URL: $url, userId: $userId');
                    if (mounted) _navigateToNativeCall(userId);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                
                return NavigationActionPolicy.ALLOW;
              },
            ),
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

  /// 从URL路径中提取Hash路由部分
  /// 输入: /#/book/xxx 或 /#/chat/yyy 或 /some/path
  /// 输出: /book/xxx 或 /chat/yyy 或 null（如果不是hash路由）
  String? _extractHashPath(String rawPath) {
    // Hash路由格式: /#/something
    if (rawPath.startsWith('/#/')) {
      return rawPath.substring(2); // 去掉 /# 得到 /something
    }
    // 也处理 /#something (没有斜杠的情况)
    if (rawPath.startsWith('#/')) {
      return rawPath.substring(1); // 去掉 # 得到 /something
    }
    return null;
  }

  /// 检查当前URL是否需要跳转到原生页面
  void _checkAndNavigateToNative(String url) {
    if (!url.startsWith(_baseUrl)) return;
    
    final rawPath = url.substring(_baseUrl.length);
    
    // 先尝试提取hash路由
    final hashPath = _extractHashPath(rawPath);
    // 非hash的普通路径
    final normalPath = rawPath.split('?')[0].split('#')[0];
    
    final path = hashPath ?? normalPath;
    
    debugPrint('[WebView] Checking path: $path (hash: $hashPath)');
    
    // 检查是否匹配原生路径
    for (final nativePath in _nativePaths) {
      if (path == nativePath || path.startsWith(nativePath)) {
        debugPrint('[WebView] Navigating to native: $path');
        // /book/:id 映射到 /books/:bookId
        String goPath = path;
        if (path.startsWith('/book/')) {
          goPath = '/books/${path.substring(6)}';
        }
        if (mounted) {
          context.go(goPath);
        }
        return;
      }
    }
    
    // 也检查通话路径
    if (path.startsWith('/chat/')) {
      final userId = path.substring(6);
      debugPrint('[WebView] Navigating to native call: userId=$userId');
      if (mounted) _navigateToNativeCall(userId);
    }
  }

  /// 导航到原生通话页面
  void _navigateToNativeCall(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          myUserId: '', // TODO: 从登录状态获取
          peerUserId: userId,
          peerName: userId, // 网页版chat路由中userId即对方标识
          callType: 'voice',
          isIncoming: false,
        ),
      ),
    );
  }

  /// 注入JS拦截通话按钮点击
  Future<void> _injectCallInterceptJs(InAppWebViewController controller) async {
    try {
      await controller.evaluateJavascript(source: '''
        (function() {
          // 避免重复注入
          if (window.__openfaithCallIntercepted) return 'already_injected';
          window.__openfaithCallIntercepted = true;
          
          // 拦截所有可能的通话和书籍按钮点击
          document.addEventListener('click', function(e) {
            var target = e.target;
            while (target && target !== document.body) {
              var href = target.getAttribute && target.getAttribute('href');
              if (href) {
                // 检查是否是通话链接 (#/chat/xxx)
                var chatMatch = href.match(/#\/chat\/([^\/\?#]+)/);
                if (chatMatch) {
                  e.preventDefault();
                  e.stopPropagation();
                  var userId = chatMatch[1];
                  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('startNativeCall', userId);
                  }
                  return false;
                }
                // 检查是否是书籍链接 (#/book/xxx)
                var bookMatch = href.match(/#\/book\/([^\/\?#]+)/);
                if (bookMatch) {
                  e.preventDefault();
                  e.stopPropagation();
                  var bookId = bookMatch[1];
                  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('navigateToNative', '/books/' + bookId);
                  }
                  return false;
                }
              }
              var action = target.getAttribute && target.getAttribute('data-action');
              if (action === 'call' || action === 'voice-call' || action === 'video-call') {
                var peerId = target.getAttribute('data-peer-id') || target.getAttribute('data-user-id');
                if (peerId) {
                  e.preventDefault();
                  e.stopPropagation();
                  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('startNativeCall', peerId);
                  }
                  return false;
                }
              }
              target = target.parentElement;
            }
          }, true);
          
          // 监听hashchange事件 — 处理SPA内部导航
          window.addEventListener('hashchange', function(e) {
            var hash = window.location.hash;
            var chatMatch = hash.match(/#\/chat\/([^\/\?#]+)/);
            if (chatMatch) {
              var userId = chatMatch[1];
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('startNativeCall', userId);
              }
              return;
            }
            var bookMatch = hash.match(/#\/book\/([^\/\?#]+)/);
            if (bookMatch) {
              var bookId = bookMatch[1];
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('navigateToNative', '/books/' + bookId);
              }
            }
          });
          
          return 'injected';
        })()
      ''');
      debugPrint('[WebView] Call intercept JS injected');
    } catch (e) {
      debugPrint('[WebView] Call intercept JS injection error: $e');
    }
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
          debugPrint('[WebView] JS Bridge navigateToNative: $path');
          context.go(path);
        }
      },
    );
    
    // 发起原生通话
    controller.addJavaScriptHandler(
      handlerName: 'startNativeCall',
      callback: (args) {
        if (args.isNotEmpty && mounted) {
          final userId = args[0] as String;
          debugPrint('[WebView] JS Bridge startNativeCall: userId=$userId');
          _navigateToNativeCall(userId);
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
    
    // 获取当前URL（用于调试）
    controller.addJavaScriptHandler(
      handlerName: 'getCurrentUrl',
      callback: (args) {
        return _currentUrl ?? '';
      },
    );
    
    debugPrint('[WebView] JS Bridge registered');
  }
}
