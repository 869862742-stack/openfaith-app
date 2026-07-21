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
  /// 需要 firebase_messaging 和 flutter_local_notifications 依赖
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 尝试导入 firebase_messaging
      // 注意：需要先在 pubspec.yaml 中添加依赖
      // 这里预留接口，实际集成需要：
      // 1. 添加 firebase_core, firebase_messaging 依赖
      // 2. 添加 google-services.json / GoogleService-Info.plist
      // 3. 配置 Firebase 项目
      
      // 暂时使用占位实现
      if (kDebugMode) {
        print('[NotificationService] FCM initialization deferred - Firebase not configured yet');
        print('[NotificationService] To enable push notifications:');
        print('  1. Create Firebase project and add Android/iOS apps');
        print('  2. Download google-services.json and GoogleService-Info.plist');
        print('  3. Add firebase_core and firebase_messaging to pubspec.yaml');
        print('  4. Run flutterfire configure');
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
