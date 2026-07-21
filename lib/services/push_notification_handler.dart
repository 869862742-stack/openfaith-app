import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 处理推送通知的点击事件和前台通知展示
class PushNotificationHandler {
  static final PushNotificationHandler instance = PushNotificationHandler._();
  PushNotificationHandler._();
  
  /// 处理通知点击 - 用户点击通知时的回调
  Future<void> onNotificationTap(Map<String, dynamic> data) async {
    final type = data['type'];
    
    switch (type) {
      case 'incoming_call':
        // 导航到来电界面
        final callerName = data['caller_name'] as String?;
        final callType = data['call_type'] as String? ?? 'voice';
        final channelName = data['channel_name'] as String?;
        final remoteUserId = data['remote_user_id'] as String?;
        
        if (channelName != null && remoteUserId != null) {
          // 通过 GlobalKey 或 Navigator 导航到来电界面
          if (kDebugMode) {
            print('[PushHandler] Navigate to incoming call: $callerName, $callType');
          }
        }
        break;
        
      case 'new_message':
        // 导航到私聊界面
        break;
        
      default:
        if (kDebugMode) {
          print('[PushHandler] Unknown notification type: $type');
        }
    }
  }
  
  /// 前台收到通知时的处理
  Future<void> onForegroundMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    
    if (type == 'incoming_call') {
      // 前台收到来电 - 直接显示来电界面，不需要通知
      await onNotificationTap(data);
    } else {
      // 其他类型通知 - 显示本地通知
      // 需要 flutter_local_notifications 包
    }
  }
}
