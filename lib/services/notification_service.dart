import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 通知服务 - 处理 FCM 推送和来电通知
/// 注意：FCM 需要 google-services.json (Android) 和 GoogleService-Info.plist (iOS)
/// 这些文件需要在 Firebase Console 生成后手动添加
class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  
  bool _initialized = false;
  String? _fcmToken;
  
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;
  
  /// 初始化通知服务
  ///
  /// TODO(FCM): 要启用 Firebase 推送通知，需要完成以下步骤：
  ///   1. 在 Firebase Console 创建项目并添加 Android/iOS 应用
  ///   2. 下载 google-services.json (Android) 和 GoogleService-Info.plist (iOS)
  ///   3. 在 pubspec.yaml 添加 firebase_core 和 firebase_messaging 依赖
  ///   4. 运行 `flutterfire configure` 生成配置文件
  ///   5. 在 Android 的 build.gradle 和 iOS 的 AppDelegate 中完成初始化
  ///   6. 取消下方 Firebase 初始化代码的注释
  ///
  /// 当前状态：FCM 未配置，仅支持前台本地通知作为临时替代方案。
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // TODO(FCM): 取消以下代码的注释以启用 FCM
      // await Firebase.initializeApp();
      // final messaging = FirebaseMessaging.instance;
      // final settings = await messaging.requestPermission(
      //   alert: true, badge: true, sound: true,
      // );
      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   _fcmToken = await messaging.getToken();
      //   FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      //   FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      // }

      if (kDebugMode) {
        print('[NotificationService] Initialized without FCM (Firebase not configured)');
        print('[NotificationService] Using local notifications as fallback');
      }
      
      _initialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Initialization error: $e');
      }
    }
  }
  
  /// 更新 FCM token 到 Supabase
  Future<void> updateFcmToken(String userId) async {
    if (_fcmToken == null) return;
    
    try {
      // 通过 Supabase Edge Function 或直接更新 users 表
      // UPDATE users SET fcm_token = $1 WHERE id = $2
      if (kDebugMode) {
        print('[NotificationService] FCM token update deferred for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] FCM token update error: $e');
      }
    }
  }
  
  /// 发送通话推送通知
  /// 通常由服务端触发（通过 Supabase Edge Function 或自建推送服务）
  Future<void> sendCallNotification({
    required String targetUserId,
    required String callerName,
    required String callType,
    required String channelName,
  }) async {
    try {
      // 调用 Supabase Edge Function 发送 FCM 推送
      // POST https://rdhwmeittgdosmkxtpak.supabase.co/functions/v1/send-call-notification
      // Body: { targetUserId, callerName, callType, channelName }
      if (kDebugMode) {
        print('[NotificationService] Call notification deferred: $callerName -> $targetUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Call notification error: $e');
      }
    }
  }
  
  /// 获取本地通知列表（前台时的临时替代方案）
  /// 在没有 FCM 的情况下，使用此方法在前台显示来电通知
  /// TODO: 替换为 flutter_local_notifications 包实现
  List<Map<String, dynamic>> getLocalNotifications() {
    // TODO: 接入 flutter_local_notifications 后实现持久化本地通知
    // 当前返回空列表，后续需要：
    // 1. 添加 flutter_local_notifications 依赖
    // 2. 初始化 FlutterLocalNotificationsPlugin
    // 3. 配置 Android notification channel
    // 4. 实现通知的本地存储和检索
    return [];
  }

  /// 显示本地前台通知（临时方案）
  /// 当应用在前台且收到通话邀请时调用
  void showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    // TODO: 使用 flutter_local_notifications 显示本地通知
    // final plugin = FlutterLocalNotificationsPlugin();
    // plugin.show(0, title, body, NotificationDetails(
    //   android: AndroidNotificationDetails('calls', '通话通知',
    //     importance: Importance.high, priority: Priority.high),
    //   iOS: const DarwinNotificationDetails(),
    // ), payload: jsonEncode(payload ?? {}));
    if (kDebugMode) {
      print('[NotificationService] Local notification: $title - $body');
    }
  }

  /// 处理收到的推送通知
  void handleRemoteMessage(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'incoming_call':
        // 触 coming call 流程
        // 通知 CallService 显示来电界面
        break;
      case 'call_ended':
        // 通话结束通知
        break;
    }
  }
}
