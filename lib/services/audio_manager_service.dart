import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 原生音频管理器 - 通过 PlatformChannel 控制 Android AudioManager
/// 解决 WebView 与原生 Agora SDK 的音频焦点冲突
class AudioManagerService {
  static const _channel = MethodChannel('openfaith/audio_mode');
  
  static bool _callModeActive = false;

  /// 通话开始时调用：设置通信模式 + 扬声器
  static Future<void> startCallAudioMode({bool speakerOn = true}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setCallMode', {
        'mode': 'communication',
        'speakerOn': speakerOn,
      });
      _callModeActive = true;
      debugPrint('[AudioManager] Call audio mode activated (speaker=$speakerOn)');
    } catch (e) {
      debugPrint('[AudioManager] startCallAudioMode error: $e');
    }
  }

  /// 通话结束时调用：恢复正常模式
  static Future<void> stopCallAudioMode() async {
    if (!Platform.isAndroid) return;
    if (!_callModeActive) return;
    try {
      await _channel.invokeMethod('setCallMode', {
        'mode': 'normal',
        'speakerOn': false,
      });
      _callModeActive = false;
      debugPrint('[AudioManager] Call audio mode deactivated, restored to normal');
    } catch (e) {
      debugPrint('[AudioManager] stopCallAudioMode error: $e');
    }
  }

  /// 切换扬声器/听筒
  static Future<void> setSpeakerphone(bool on) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSpeakerphone', {'on': on});
      debugPrint('[AudioManager] Speakerphone set to: $on');
    } catch (e) {
      debugPrint('[AudioManager] setSpeakerphone error: $e');
    }
  }

  /// 获取当前是否在通话音频模式
  static bool get isCallModeActive => _callModeActive;
}
