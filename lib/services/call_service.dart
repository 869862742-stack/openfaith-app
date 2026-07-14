import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 原生音视频通话服务 - 使用 Agora SDK
/// 信令通过 Supabase messages 表，媒体通过 Agora RTC
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Agora 配置（与网页版共享）
  static const String appId = '57edbb1ef7cf48c9815533cb2c3989cd';
  
  RtcEngine? _engine;
  bool _joined = false;
  int _remoteUid = 0;
  bool _isMuted = false;
  bool _isSpeakerOff = false;
  
  // 通话状态
  String? _currentCallId;
  String? _currentChannelName;
  CallState _state = CallState.idle;
  String? _callType; // 'voice' | 'video'
  String? _peerId;
  String? _peerName;
  
  // 回调
  VoidCallback? onStateChanged;
  Function(String)? onError;
  
  SupabaseClient get _supabase => Supabase.instance.client;
  
  bool get isJoined => _joined;
  CallState get state => _state;
  String? get callType => _callType;
  String? get peerName => _peerName;
  bool get isMuted => _isMuted;
  bool get isSpeakerOff => _isSpeakerOff;
  int get remoteUid => _remoteUid;
  
  Future<void> initEngine() async {
    if (_engine != null) return;
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('[CallService] Joined channel: ${connection.channelId}');
          _joined = true;
          onStateChanged?.call();
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint('[CallService] Remote user joined: $uid');
          _remoteUid = uid;
          _state = CallState.connected;
          onStateChanged?.call();
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint('[CallService] Remote user left: $uid');
          _remoteUid = 0;
          endCall();
        },
        onError: (err, msg) {
          debugPrint('[CallService] Error: $err $msg');
          onError?.call('通话错误: $err');
        },
      ),
    );
  }
  
  /// 发起通话
  Future<void> startCall({
    required String myUserId,
    required String peerUserId,
    required String peerName,
    required String type, // 'voice' | 'video'
  }) async {
    await initEngine();
    
    _callType = type;
    _peerId = peerUserId;
    _peerName = peerName;
    _state = CallState.calling;
    
    // 生成频道名（基于双方ID，确保一致）
    final ids = [myUserId, peerUserId]..sort();
    _currentChannelName = 'call_${ids[0].substring(0, 8)}_${ids[1].substring(0, 8)}';
    
    // 发送通话邀请消息
    final callData = {
      'callType': type,
      'status': 'calling',
      'callerName': '我',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'channelName': _currentChannelName,
    };
    
    try {
      final result = await _supabase
          .from('private_messages')
          .insert({
            'sender_id': myUserId,
            'receiver_id': peerUserId,
            'content': '[CALL_INVITE]${_encodeJson(callData)}',
            'message_type': 'call_invite',
          })
          .select();
      
      if (result.isNotEmpty) {
        _currentCallId = result[0]['id']?.toString();
      }
    } catch (e) {
      debugPrint('[CallService] Failed to send call invite: $e');
      _state = CallState.idle;
      onError?.call('发起通话失败');
      return;
    }
    
    // 加入 Agora 频道（使用临时token，不设token）
    final myUid = myUserId.hashCode.abs() % 100000;
    await _engine!.joinChannel(
      token: '',
      channelId: _currentChannelName!,
      uid: myUid,
      options: const ChannelMediaOptions(),
    );
    
    onStateChanged?.call();
  }
  
  /// 接听通话
  Future<void> acceptCall({
    required String myUserId,
    required String callId,
    required String channelName,
    required String type,
    required String callerName,
  }) async {
    await initEngine();
    
    _currentCallId = callId;
    _currentChannelName = channelName;
    _callType = type;
    _peerName = callerName;
    _state = CallState.connected;
    
    // 更新消息状态为 connected
    try {
      await _supabase
          .from('private_messages')
          .update({
            'content': '[CALL_INVITE]${_encodeJson({
              'callType': type,
              'status': 'connected',
              'duration': 0,
            })}',
          })
          .eq('id', callId);
    } catch (e) {
      debugPrint('[CallService] Failed to update call status: $e');
    }
    
    // 加入 Agora 频道
    final myUid = myUserId.hashCode.abs() % 100000;
    await _engine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: myUid,
      options: const ChannelMediaOptions(),
    );
    
    onStateChanged?.call();
  }
  
  /// 挂断
  Future<void> endCall() async {
    final callId = _currentCallId;
    if (callId != null) {
      try {
        await _supabase
            .from('private_messages')
            .update({
              'content': '[CALL_HANGUP]${_encodeJson({
                'callId': callId,
                'status': 'hangup',
              })}',
            })
            .eq('id', callId);
      } catch (e) {
        debugPrint('[CallService] Failed to send hangup: $e');
      }
    }
    
    if (_joined) {
      await _engine?.leaveChannel();
      _joined = false;
    }
    
    _state = CallState.idle;
    _currentCallId = null;
    _currentChannelName = null;
    _remoteUid = 0;
    _callType = null;
    _peerId = null;
    _peerName = null;
    
    onStateChanged?.call();
  }
  
  /// 静音/取消静音
  void toggleMute() {
    _isMuted = !_isMuted;
    _engine?.muteLocalAudioStream(_isMuted);
    onStateChanged?.call();
  }
  
  /// 扬声器/听筒切换
  void toggleSpeaker() {
    _isSpeakerOff = !_isSpeakerOff;
    _engine?.setEnableSpeakerphone(!_isSpeakerOff);
    onStateChanged?.call();
  }
  
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _engine = null;
  }
  
  String _encodeJson(Map<String, dynamic> map) {
    // 简单的JSON编码，避免引入额外依赖
    final pairs = map.entries.map((e) {
      final key = '"${e.key}"';
      final value = e.value is String ? '"${e.value}"' : '${e.value}';
      return '$key:$value';
    }).join(',');
    return '{$pairs}';
  }
}

enum CallState {
  idle,
  calling,
  incoming,
  connected,
}
