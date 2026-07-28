import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/app_update_service.dart';
import '../services/call_service.dart';

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
  
  // APP 内更新下载状态
  bool _isApkDownloading = false;
  double _apkDownloadProgress = 0.0;
  String _apkDownloadStatus = 'idle'; // idle, downloading, completed, error
  String _apkDownloadError = '';
  CancelToken? _apkCancelToken;

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
    
    // 请求安装未知应用权限（用于APP内更新）
    final installStatus = await Permission.requestInstallPackages.status;
    if (!installStatus.isGranted) {
      await Permission.requestInstallPackages.request();
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
        bool isUpdating = false;
        double downloadProgress = 0.0;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final updateService = AppUpdateService();
            updateService.onProgressUpdate = (progress) {
              setDialogState(() => downloadProgress = progress);
            };
            updateService.onStatusChange = (status, {error}) {
              if (status == 'completed') {
                if (mounted) Navigator.of(dialogContext).pop();
              }
              if (status == 'error') {
                setDialogState(() => isUpdating = false);
              }
            };
            
            final bool isPatch = updateInfo.isPatch;
            final String title = isPatch 
                ? '发现增量更新补丁 #${updateInfo.patchNumber ?? ""}'
                : '发现新版本 v${updateInfo.latestVersion}';
            final String subtitle = isPatch
                ? '增量补丁，无需下载完整安装包'
                : '需要下载完整安装包';
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF9D4EDD), width: 1),
              ),
              title: Text(
                title,
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
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF9D4EDD), fontSize: 12),
                  ),
                  if (updateInfo.changelog.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      updateInfo.changelog,
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ],
                  if (isUpdating) ...[
                    const SizedBox(height: 12),
                    if (isPatch)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF9D4EDD),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '正在应用补丁...',
                            style: TextStyle(color: Color(0xFF9D4EDD), fontSize: 13),
                          ),
                        ],
                      )
                    else ...[
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
                ],
              ),
              actions: [
                if (!isUpdating) ...[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('稍后再说', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D4EDD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      setDialogState(() => isUpdating = true);
                      await updateService.downloadAndInstall(updateInfo);
                    },
                    child: Text(isPatch ? '立即应用' : '立即更新'),
                  ),
                ] else ...[
                  const Text('正在更新...', style: TextStyle(color: Color(0xFF9D4EDD))),
                ],
              ],
            );
          },
        );
      },
    );
  }

  /// 注入完整的 JavaScript Bridge（包括版本信息 + Agora 原生通话桥接）
  Future<void> _injectJavaScriptBridge(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      (function() {
        console.log('[OF Bridge] Injecting JavaScript Bridge...');
        
        // ========== 1. 版本信息注入 ==========
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
          } catch(e) {
            console.error('[OF Bridge] Version injection error:', e);
          }
        });
        
        // ========== 2. Agora 原生通话桥接（兼容 Capacitor 接口）==========
        // 模拟 window.Capacitor 对象，让 Web 端的 hasNativeAgoraPlugin() 返回 true
        if (!window.Capacitor) {
          window.Capacitor = {
            isNativePlatform: function() { return true; },
            Plugins: {}
          };
        }
        
        // 注册 AgoraNative 插件
        window.Capacitor.Plugins.AgoraNative = {
          initialize: function(params) {
            console.log('[AgoraNative Bridge] initialize called', params);
            return window.flutterInAppWebView.callHandler('agoraInitialize', params)
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          
          requestPermissions: function(params) {
            console.log('[AgoraNative Bridge] requestPermissions called', params);
            return window.flutterInAppWebView.callHandler('agoraRequestPermissions', params)
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          
          startNativeCall: function(params) {
            console.log('[AgoraNative Bridge] startNativeCall called', params);
            return window.flutterInAppWebView.callHandler('agoraStartCall', params)
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          
          leaveChannel: function() {
            console.log('[AgoraNative Bridge] leaveChannel called');
            return window.flutterInAppWebView.callHandler('agoraLeaveChannel')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          
          getStatus: function() {
            return window.flutterInAppWebView.callHandler('agoraGetStatus')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          
          destroy: function() {
            console.log('[AgoraNative Bridge] destroy called');
            return window.flutterInAppWebView.callHandler('agoraDestroy')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          
          addListener: function(eventName, callback) {
            console.log('[AgoraNative Bridge] addListener:', eventName);
            // 将回调注册到全局，供 Flutter 调用
            if (!window.__AgoraCallbacks__) {
              window.__AgoraCallbacks__ = {};
            }
            if (!window.__AgoraCallbacks__[eventName]) {
              window.__AgoraCallbacks__[eventName] = [];
            }
            window.__AgoraCallbacks__[eventName].push(callback);
            
            return {
              remove: function() {
                if (window.__AgoraCallbacks__ && window.__AgoraCallbacks__[eventName]) {
                  var idx = window.__AgoraCallbacks__[eventName].indexOf(callback);
                  if (idx > -1) {
                    window.__AgoraCallbacks__[eventName].splice(idx, 1);
                  }
                }
            };
        };
        
        // 全局回调触发函数（供 Flutter 调用）
        window.triggerAgoraCallback = function(eventName, data) {
          console.log('[AgoraNative Bridge] Triggering callback:', eventName, data);
          if (window.__AgoraCallbacks__ && window.__AgoraCallbacks__[eventName]) {
            window.__AgoraCallbacks__[eventName].forEach(function(callback) {
              try {
                callback(data);
              } catch(e) {
                console.error('[AgoraNative Bridge] Callback error:', e);
              }
            });
        };
        

        // ========== 2.5 拦截 AgoraRTC SDK（将通话路由到原生 SDK）==========
        if (window.__OF_IS_NATIVE_APP__) {
          var _agoraCheckInterval = setInterval(function() {
            if (typeof AgoraRTC !== 'undefined' && AgoraRTC && AgoraRTC.createClient) {
              clearInterval(_agoraCheckInterval);
              
              console.log('[OF Bridge] Intercepting AgoraRTC for native call routing');
              
              var _origCreateClient = AgoraRTC.createClient;
              
              AgoraRTC.createClient = function(config) {
                console.log('[OF Bridge] Native Agora bridge: createClient intercepted');
                
                var _nativeJoined = false;
                var _eventHandlers = {};
                
                var nativeClient = {
                  setClientRole: function() { return Promise.resolve(); },
                  setAudioProfile: function() { return Promise.resolve(); },
                  setAudioSubscriptionOptions: function() { return Promise.resolve(); },
                  
                  join: function(appId, channel, token, uid) {
                    console.log('[OF Bridge] Native join: channel=' + channel + ', uid=' + uid);
                    return window.flutterInAppWebView.callHandler('agoraStartCall', {
                      channelName: channel,
                      uid: typeof uid === 'number' ? uid : parseInt(uid) || 1,
                      token: token || '',
                      isVideo: config && config.codec === 'vp8'
                    }).then(function(result) {
                      var data = typeof result === 'string' ? JSON.parse(result) : result;
                      if (data && data.success) {
                        _nativeJoined = true;
                        if (_eventHandlers['connection-state-change']) {
                          _eventHandlers['connection-state-change'].forEach(function(cb) {
                            try { cb({curState:'CONNECTED',curReason:'JoinSuccess'}); } catch(e){}
                          });
                        }
                      return data;
                    });
                  },
                  
                  publish: function(tracks) {
                    console.log('[OF Bridge] Native publish: tracks=' + (tracks ? tracks.length : 0));
                    return Promise.resolve();
                  },
                  
                  unpublish: function() { return Promise.resolve(); },
                  
                  subscribe: function(user, mediaType) {
                    console.log('[OF Bridge] Native subscribe: uid=' + user.uid + ', type=' + mediaType);
                    return Promise.resolve();
                  },
                  
                  unsubscribe: function() { return Promise.resolve(); },
                  
                  leave: function() {
                    console.log('[OF Bridge] Native leave channel');
                    _nativeJoined = false;
                    return window.flutterInAppWebView.callHandler('agoraLeaveChannel')
                      .then(function(result) {
                        return typeof result === 'string' ? JSON.parse(result) : result;
                      });
                  },
                  
                  destroy: function() { return Promise.resolve(); },
                  
                  on: function(event, callback) {
                    if (!_eventHandlers[event]) _eventHandlers[event] = [];
                    _eventHandlers[event].push(callback);
                  },
                  
                  off: function(event, callback) {
                    if (!_eventHandlers[event]) return;
                    if (callback) {
                      var idx = _eventHandlers[event].indexOf(callback);
                      if (idx > -1) _eventHandlers[event].splice(idx, 1);
                    } else {
                      delete _eventHandlers[event];
                    }
                  },
                  
                  getConnectionState: function() { return _nativeJoined ? 'CONNECTED' : 'DISCONNECTED'; },
                  setParameters: function() { return Promise.resolve(); }
                };
                
                return nativeClient;
              };
              
              // 也拦截 createMicrophoneAudioTrack，返回模拟轨道
              AgoraRTC.createMicrophoneAudioTrack = function() {
                console.log('[OF Bridge] Native audio track mock created');
                return Promise.resolve({
                  _isMock: true,
                  play: function() {},
                  stop: function() {},
                  close: function() {},
                  enabled: true,
                  muted: false,
                  setEnabled: function(v) { this.enabled = v; return Promise.resolve(); },
                  setMuted: function(v) { this.muted = v; return Promise.resolve(); },
                  setVolume: function() {},
                  setFilter: function() {},
                  setPlayoutVolume: function() {},
                  getMediaStreamTrack: function() { return null; },
                  getTrackLabel: function() { return 'Native Microphone'; },
                  addTrackOperation: function() { return Promise.resolve(); },
                  pipe: function() { return this; },
                  on: function() { return this; },
                  off: function() { return this; },
                  once: function() { return this; },
                  getStats: function() { return {}; }
                });
              };
              
              console.log('[OF Bridge] AgoraRTC intercepted successfully');
            }
          }, 200);
          
          setTimeout(function() { clearInterval(_agoraCheckInterval); }, 15000);
        }
        
        // ========== 3. APP内更新桥接（AppUpdater 插件模拟）==========
        window.Capacitor.Plugins.AppUpdater = {
          getAppVersion: function() {
            return window.flutterInAppWebView.callHandler('getAppVersion')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          checkInstallPermission: function() {
            return window.flutterInAppWebView.callHandler('checkInstallPermission')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          openInstallSettings: function() {
            return window.flutterInAppWebView.callHandler('openInstallSettings')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          downloadAndInstall: function(options) {
            console.log('[AppUpdater Bridge] downloadAndInstall called', options);
            return window.flutterInAppWebView.callHandler('downloadApk', options.url || '', options.fileName || '')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          },
          getDownloadProgress: function() {
            return window.flutterInAppWebView.callHandler('getDownloadProgress')
              .then(function(result) {
                return typeof result === 'string' ? JSON.parse(result) : result;
              });
          }
        console.log('[OF Bridge] AppUpdater bridge injected successfully');
        console.log('[OF Bridge] Agora native bridge injected successfully');
      })();
    ''');
    
    // 注册 Agora 相关的 JavaScript handlers
    _registerAgoraHandlers(controller);
    _registerAppUpdaterHandlers(controller);
  }

  /// 注册 Agora 通话相关的 JavaScript handlers
  void _registerAgoraHandlers(InAppWebViewController controller) {
    final callService = CallService();
    
    // 初始化 Agora 引擎
    controller.addJavaScriptHandler(
      handlerName: 'agoraInitialize',
      callback: (args) async {
        try {
          await callService.initialize();
          return json.encode({
            'success': true,
            'sdkVersion': '6.5.4',
          });
        } catch (e) {
          debugPrint('[WebView Bridge] agoraInitialize error: $e');
          return json.encode({
            'success': false,
            'message': e.toString(),
          });
        }
      },
    );
    
    // 请求权限
    controller.addJavaScriptHandler(
      handlerName: 'agoraRequestPermissions',
      callback: (args) async {
        try {
          final micStatus = await Permission.microphone.request();
          bool granted = micStatus.isGranted;
          
          // 如果需要视频，也请求摄像头权限
          if (args.isNotEmpty && args[0] is Map && args[0]['enableVideo'] == true) {
            final cameraStatus = await Permission.camera.request();
            granted = granted && cameraStatus.isGranted;
          }
          
          return json.encode({'granted': granted, 'success': granted});
        } catch (e) {
          debugPrint('[WebView Bridge] agoraRequestPermissions error: $e');
          return json.encode({'granted': false, 'success': false});
        }
      },
    );
    
    // 启动原生通话
    controller.addJavaScriptHandler(
      handlerName: 'agoraStartCall',
      callback: (args) async {
        try {
          if (args.isEmpty || args[0] is! Map) {
            return json.encode({'success': false, 'message': 'Invalid params'});
          }
          
          final params = args[0] as Map<String, dynamic>;
          final channelName = params['channelName'] as String;
          final uid = params['uid'] as int;
          final token = params['token'] as String;
          final isVideo = params['isVideo'] as bool? ?? false;
          
          debugPrint('[WebView Bridge] Starting native call: channel=$channelName, uid=$uid, video=$isVideo');
          
          // 调用 CallService 的 joinChannel
          await callService.joinChannelFromWebView(
            channelName: channelName,
            uid: uid,
            token: token,
            isVideo: isVideo,
          );
          
          // 监听通话状态变化，通过 JS 回调通知 Web 端
          callService.addListener(() {
            final state = callService.state;
            _notifyWebCallState(controller, state);
          });
          
          return json.encode({
            'success': true,
            'message': 'Call started',
          });
        } catch (e) {
          debugPrint('[WebView Bridge] agoraStartCall error: $e');
          return json.encode({
            'success': false,
            'message': e.toString(),
          });
        }
      },
    );
    
    // 离开频道
    controller.addJavaScriptHandler(
      handlerName: 'agoraLeaveChannel',
      callback: (args) async {
        try {
          await callService.endCall();
          return json.encode({'success': true});
        } catch (e) {
          debugPrint('[WebView Bridge] agoraLeaveChannel error: $e');
          return json.encode({'success': false, 'message': e.toString()});
        }
      },
    );
    
    // 获取状态
    controller.addJavaScriptHandler(
      handlerName: 'agoraGetStatus',
      callback: (args) async {
        final state = callService.state;
        return json.encode({
          'initialized': true,
          'joined': state.status == CallState.connected,
          'channelName': state.channelName,
          'remoteUid': state.remoteUid,
        });
      },
    );
    
    // 销毁
    controller.addJavaScriptHandler(
      handlerName: 'agoraDestroy',
      callback: (args) async {
        try {
          callService.dispose();
          return json.encode({'success': true});
        } catch (e) {
          return json.encode({'success': false, 'message': e.toString()});
        }
      },
    );
  }

  /// 通知 Web 端通话状态变化
  void _notifyWebCallState(InAppWebViewController controller, CallStateData state) {
    switch (state.status) {
      case CallState.connected:
        // 通知 web 端: 远端用户发布音频
        controller.evaluateJavascript(
          source: '''
            window.triggerAgoraCallback("user-published", {
              "uid": ${state.remoteUid},
              "audioTrack": {"_isMock": true, "play": function(){}, "stop": function(){}},
              "videoTrack": null,
              "mediaType": "audio"
            })
          ''',
        );
        break;
      case CallState.disconnected:
        controller.evaluateJavascript(
          source: '''
            window.triggerAgoraCallback("user-unpublished", {
              "uid": ${state.remoteUid},
              "mediaType": "audio"
            })
          ''',
        );
        break;
      default:
        return;
    }
  }


  /// 处理 APK 下载（从 WebView URL 拦截触发）
  Future<void> _handleApkDownload(String url) async {
    debugPrint('[WebView] Handling APK download: $url');
    
    // 获取版本信息
    final packageInfo = await PackageInfo.fromPlatform();
    final versionInfo = await AppUpdateService().checkForUpdate();
    
    if (!mounted) return;
    
    if (versionInfo != null) {
      _showUpdateDialog(versionInfo);
    } else {
      // 无法获取版本信息，直接用默认参数下载
      final updateInfo = AppUpdateInfo(
        type: UpdateType.fullApk,
        latestVersion: packageInfo.version,
        downloadUrl: url,
        fallbackUrl: url,
        changelog: '版本更新',
      );
      _showUpdateDialog(updateInfo);
    }
  }

  /// 注册 AppUpdater 相关的 JavaScript handlers
  void _registerAppUpdaterHandlers(InAppWebViewController controller) {
    // 检查安装权限
    controller.addJavaScriptHandler(
      handlerName: 'checkInstallPermission',
      callback: (args) async {
        try {
          final status = await Permission.requestInstallPackages.status;
          final canInstall = status.isGranted;
          return json.encode({'canInstall': canInstall});
        } catch (e) {
          return json.encode({'canInstall': false});
        }
      },
    );

    // 打开安装设置 - 打开"安装未知应用"权限页
    controller.addJavaScriptHandler(
      handlerName: 'openInstallSettings',
      callback: (args) async {
        try {
          const channel = MethodChannel('openfaith/install_settings');
          await channel.invokeMethod('openInstallSettings');
          return json.encode({'success': true});
        } catch (e) {
          // 降级方案
          try {
            await openAppSettings();
          } catch (_) {}
          return json.encode({'success': false, 'message': e.toString()});
        }
      },
    );

    // 下载 APK（核心方法）
    controller.addJavaScriptHandler(
      handlerName: 'downloadApk',
      callback: (args) async {
        try {
          final url = args.isNotEmpty ? args[0] as String : '';
          final fileName = args.length > 1 ? args[1] as String : 'OpenFaith.apk';
          
          if (url.isEmpty) {
            return json.encode({'downloadId': 0, 'status': 'error', 'message': 'No URL'});
          }

          if (_isApkDownloading) {
            return json.encode({'downloadId': 1, 'status': 'downloading'});
          }

          _isApkDownloading = true;
          _apkDownloadProgress = 0.0;
          _apkDownloadStatus = 'downloading';
          _apkDownloadError = '';
          _apkCancelToken = CancelToken();

          // 异步启动下载
          _startApkDownload(url, fileName);

          return json.encode({'downloadId': 1, 'status': 'downloading'});
        } catch (e) {
          _isApkDownloading = false;
          _apkDownloadStatus = 'error';
          _apkDownloadError = e.toString();
          return json.encode({'downloadId': 0, 'status': 'error', 'message': e.toString()});
        }
      },
    );

    // 获取下载进度
    controller.addJavaScriptHandler(
      handlerName: 'getDownloadProgress',
      callback: (args) async {
        return json.encode({
          'progress': (_apkDownloadProgress * 100).toInt(),
          'status': _apkDownloadStatus,
          'error': _apkDownloadError,
        });
      },
    );
  }

  /// 实际执行 APK 下载
  Future<void> _startApkDownload(String url, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';
      
      final file = await File(savePath).exists() 
          ? File(savePath) 
          : File(savePath);
      if (await file.exists()) await file.delete();

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        cancelToken: _apkCancelToken!,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _apkDownloadProgress = received / total;
          }
        },
      );

      final downloadedFile = File(savePath);
      if (!await downloadedFile.exists()) {
        throw Exception('Downloaded file not found');
      }
      final fileSize = await downloadedFile.length();
      if (fileSize < 1024 * 1024) {
        throw Exception('File too small: $fileSize bytes');
      }

      debugPrint('[WebView] APK download complete: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
      _apkDownloadStatus = 'completed';
      _apkDownloadProgress = 1.0;
      _isApkDownloading = false;

      // 通知 Web 端下载完成
      if (_webViewController != null) {
        _webViewController!.evaluateJavascript(
          source: 'window.dispatchEvent(new CustomEvent("apk-download-complete"))',
        );
      }

      // 打开安装界面
      await OpenFilex.open(savePath, type: 'application/vnd.android.package-archive');

    } catch (e) {
      debugPrint('[WebView] APK download failed: $e');
      _apkDownloadStatus = 'error';
      _apkDownloadError = e.toString();
      _isApkDownloading = false;

      // 通知 Web 端下载失败
      if (_webViewController != null) {
        _webViewController!.evaluateJavascript(
          source: 'window.dispatchEvent(new CustomEvent("apk-download-failed", {detail: {error: "${e.toString().replaceAll('"', '\\"')}"}}))',
        );
      }
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
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    source: '''
                      // 提前注入 Capacitor 模拟 + Flutter WebView 标记
                      window.__OF_FLUTTER_WEBVIEW__ = true;
                      if (!window.Capacitor) {
                        window.Capacitor = {
                          isNativePlatform: function() { return true; },
                          Plugins: {}
                        };
                      }
                    ''',
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  ),
                ]),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  
                  // 注册基础 JS Bridge handler
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
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  // 拦截 APK 下载链接，走原生下载流程
                  if (url.contains('.apk') || url.contains('/apk/latest') || url.contains('/apk/v')) {
                    debugPrint('[WebView] Intercepted APK download URL: $url');
                    _handleApkDownload(url);
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100);
                },
                onLoadStop: (controller, url) async {
                  setState(() => _isLoading = false);
                  await _injectJavaScriptBridge(controller);
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
