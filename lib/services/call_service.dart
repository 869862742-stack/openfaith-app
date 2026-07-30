import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 通话状态枚举
enum CallState {
  idle,
  calling,
  ringing,
  incoming,
  connected,
  disconnected,
}

/// 通话状态数据类
class CallStateData {
  final CallState status;
  final String? callType; // 'voice' | 'video'
  final String? remoteUserId;
  final String? remoteUserName;
  final String? channelName;
  final int remoteUid;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoEnabled;
  final Duration callDuration;
  final String? callerName;
  final String? callerAvatar;
  final String? callId;

  const CallStateData({
    this.status = CallState.idle,
    this.callType,
    this.remoteUserId,
    this.remoteUserName,
    this.channelName,
    this.remoteUid = 0,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isVideoEnabled = false,
    this.callDuration = Duration.zero,
    this.callerName,
    this.callerAvatar,
    this.callId,
  });

  CallStateData copyWith({
    CallState? status,
    String? callType,
    String? remoteUserId,
    String? remoteUserName,
    String? channelName,
    int? remoteUid,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoEnabled,
    Duration? callDuration,
    String? callerName,
    String? callerAvatar,
    String? callId,
  }) {
    return CallStateData(
      status: status ?? this.status,
      callType: callType ?? this.callType,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      channelName: channelName ?? this.channelName,
      remoteUid: remoteUid ?? this.remoteUid,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      callDuration: callDuration ?? this.callDuration,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      callId: callId ?? this.callId,
    );
  }
}

/// 原生音视频通话服务 - 使用 Agora SDK
/// 信令通过 Supabase messages 表，媒体通过 Agora RTC
class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Agora 配置
  static const String appId = '57edbb1ef7cf48c9815533cb2c3989cd';

  RtcEngine? _engine;
  bool _engineInitialized = false;
  CallStateData _stateData = const CallStateData();
  Timer? _timeoutTimer;
  Timer? _durationTimer;
  bool _isBusy = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  CallStateData get state => _stateData;
  bool get isBusy => _isBusy;

  /// 初始化 Agora 引擎
  Future<void> initialize() async {
    if (_engineInitialized) return;
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('[CallService] Joined channel: ${connection.channelId}');
            _stateData = _stateData.copyWith(
              channelName: connection.channelId,
            );
            notifyListeners();
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('[CallService] Remote user joined: $remoteUid');
            _timeoutTimer?.cancel();
            _stateData = _stateData.copyWith(
              status: CallState.connected,
              remoteUid: remoteUid,
            );
            _startDurationTimer();
            notifyListeners();
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('[CallService] Remote user offline: $remoteUid, reason: $reason');
            endCall();
          },
          onUserMuteAudio: (connection, remoteUid, muted) {
            debugPrint('[CallService] User $remoteUid mute audio: $muted');
            notifyListeners();
          },
          onUserMuteVideo: (connection, remoteUid, muted) {
            debugPrint('[CallService] User $remoteUid mute video: $muted');
            notifyListeners();
          },
          onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
            debugPrint('[CallService] Remote audio state changed: uid=$remoteUid state=$state reason=$reason');
            if (state == RemoteAudioState.remoteAudioStateDecoding) {
              // 确保远端音频流未被静音
              try {
                _engine!.muteRemoteAudioStream(uid: remoteUid, mute: false);
                debugPrint('[CallService] Ensured remote audio unmuted for $remoteUid');
              } catch (e) {
                debugPrint('[CallService] Unmute remote audio error: $e');
              }
            }
          },
          onLocalAudioStateChanged: (connection, state, error) {
            debugPrint('[CallService] Local audio state changed: state=$state error=$error');
          },
          onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
            // 音频音量指示回调，用于调试
            if (speakerNumber > 0) {
              debugPrint('[CallService] Volume indication: speakers=$speakerNumber totalVolume=$totalVolume');
            }
          },
          onConnectionLost: (connection) {
            debugPrint('[CallService] Connection lost');
            _stateData = _stateData.copyWith(status: CallState.disconnected);
            notifyListeners();
            endCall();
          },
          onError: (err, msg) {
            debugPrint('[CallService] Error: $err $msg');
            notifyListeners();
          },
        ),
      );

      await _engine!.enableAudio();
      
      // 设置语音通话场景（chatroom 优化实时双向语音）
      try {
        await _engine!.setAudioScenario(AudioScenarioType.audioScenarioChatroom);
        debugPrint('[CallService] Audio scenario set to chatroom');
      } catch (e) {
        debugPrint('[CallService] setAudioScenario error: $e');
      }
      
      // 设置音频 profile（speechStandard 专门优化语音通话）
      try {
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioChatroom,
        );
        debugPrint('[CallService] Audio profile set to speechStandard');
      } catch (e) {
        debugPrint('[CallService] setAudioProfile error: $e');
      }
      
      // 默认音频路由到扬声器（免提模式）
      try {
        await _engine!.setEnableSpeakerphone(true);
        debugPrint('[CallService] Default to speakerphone');
      } catch (e) {
        debugPrint('[CallService] setEnableSpeakerphone error: $e');
      }
      
      // 启用音频音量指示（新增：用于监控音频流状态）
      try {
        await _engine!.enableAudioVolumeIndication(interval: 500, smooth: 3, reportVad: true);
        debugPrint('[CallService] Audio volume indication enabled');
      } catch (e) {
        debugPrint('[CallService] enableAudioVolumeIndication error: $e');
      }
      
      _engineInitialized = true;
      debugPrint('[CallService] Engine initialized');
    } catch (e) {
      debugPrint('[CallService] Init error: $e');
      _engine = null;
    }
  }

  /// 获取 Agora Token（优先 Supabase Edge Function，fallback 空 token 测试模式）
  Future<String> _getToken(String channelName) async {
    try {
      final response = await _supabase.functions.invoke(
        'agora-token',
        body: {'channelName': channelName},
      );
      if (response.data != null && response.data['token'] != null) {
        return response.data['token'] as String;
      }
    } catch (e) {
      debugPrint('[CallService] Token fetch failed, using empty token: $e');
    }
    return '';
  }

  /// 获取当前用户 ID
  String _getCurrentUserId() {
    try {
      final user = _supabase.auth.currentUser;
      return user?.id ?? '';
    } catch (e) {
      debugPrint('[CallService] Get current user error: $e');
      return '';
    }
  }

  /// 生成频道名（基于双方ID排序，确保一致）
  String _generateChannelName(String currentUserId, String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    final id1 = ids[0].length > 8 ? ids[0].substring(0, 8) : ids[0];
    final id2 = ids[1].length > 8 ? ids[1].substring(0, 8) : ids[1];
    return 'call_${id1}_$id2';
  }

  /// 发起通话
  Future<void> startCall({
    required String peerUserId,
    required String peerName,
    required String type, // 'voice' | 'video'
    String? myUserId,
  }) async {
    // 防抖：如果已经在通话中，直接返回
    if (_isBusy) {
      debugPrint('[CallService] Already busy, rejecting duplicate startCall');
      return;
    }

    if (_stateData.status != CallState.idle) {
      _isBusy = true;
      debugPrint('[CallService] Busy, rejecting new call');
      return;
    }

    await initialize();

    if (!_engineInitialized || _engine == null) {
      debugPrint('[CallService] Engine not available, cannot start call');
      return;
    }

    final currentUserId = myUserId ?? _getCurrentUserId();
    if (currentUserId.isEmpty) {
      debugPrint('[CallService] No current user ID');
      return;
    }

    final channelName = _generateChannelName(currentUserId, peerUserId);
    final token = await _getToken(channelName);

    // 启用视频（如果需要）
    if (type == 'video') {
      try {
        await _engine!.enableVideo();
      } catch (e) {
        debugPrint('[CallService] enableVideo error: $e');
      }
    }

    // 更新状态
    _stateData = CallStateData(
      status: CallState.calling,
      callType: type,
      remoteUserId: peerUserId,
      remoteUserName: peerName,
      channelName: channelName,
      isVideoEnabled: type == 'video',
    );

    // 发送通话邀请消息（信令）
    try {
      final callData = {
        'callType': type,
        'status': 'calling',
        'callerName': peerName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'channelName': channelName,
      };
      final result = await _supabase
          .from('private_messages')
          .insert({
            'sender_id': currentUserId,
            'receiver_id': peerUserId,
            'content': '[CALL_INVITE]${_encodeJson(callData)}',
            'message_type': 'call_invite',
          })
          .select();

      if (result.isNotEmpty) {
        final callId = result[0]['id']?.toString();
        _stateData = _stateData.copyWith(callId: callId);
      }
    } catch (e) {
      debugPrint('[CallService] Failed to send call invite: $e');
    }

    // 生成 UID（修复：确保不为 0）
    int myUid = currentUserId.hashCode.abs() % 99999 + 1;
    if (myUid == 0) myUid = 1;
    
    // 设置主播角色（在 joinChannel 之前）
    try {
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      debugPrint('[CallService] Client role set to broadcaster');
    } catch (e) {
      debugPrint('[CallService] setClientRole error: $e');
    }
    
    // 通话音频配置（每次通话重新设置，确保生效）
    try {
      await _engine!.setAudioScenario(AudioScenarioType.audioScenarioChatroom);
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      await _engine!.setEnableSpeakerphone(true);
      debugPrint('[CallService] Call audio configured: speech + speaker');
    } catch (e) {
      debugPrint('[CallService] Call audio config error: $e');
    }
    
    // 确保本地音频流未静音（在 joinChannel 之前）
    try {
      await _engine!.muteLocalAudioStream(false);
      debugPrint('[CallService] Local audio unmuted');
    } catch (e) {
      debugPrint('[CallService] muteLocalAudioStream(false) error: $e');
    }
    
    // 加入 Agora 频道
    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: myUid,
        options: ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      debugPrint('[CallService] Joined channel: $channelName, uid: $myUid');
      
      // 加入后再次确认扬声器和音频发布
      try {
        await _engine!.setEnableSpeakerphone(true);
        await _engine!.muteLocalAudioStream(false);
        debugPrint('[CallService] Post-join: speaker on, mic unmuted');
      } catch (e) {
        debugPrint('[CallService] Post-join audio config error: $e');
      }
    } catch (e) {
      debugPrint('[CallService] joinChannel error: $e');
      _stateData = const CallStateData(status: CallState.idle);
      notifyListeners();
      return;
    }

    // 30秒超时自动挂断
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_stateData.status == CallState.calling) {
        debugPrint('[CallService] Call timeout after 30s');
        endCall();
      }
    });

    notifyListeners();
  }

  /// 接听通话
  Future<void> acceptCall({
    required String channelName,
    required String type,
    required String callerName,
    String? callId,
    String? myUserId,
    String? remoteUserId,
  }) async {
    // 防抖：如果已经在通话中，直接返回
    if (_isBusy) {
      debugPrint('[CallService] Already busy, rejecting duplicate acceptCall');
      return;
    }

    if (_stateData.status != CallState.idle && _stateData.status != CallState.incoming) {
      _isBusy = true;
      return;
    }

    await initialize();

    final currentUserId = myUserId ?? _getCurrentUserId();
    final token = await _getToken(channelName);

    // 启用视频（如果需要）
    if (type == 'video') {
      try {
        await _engine!.enableVideo();
      } catch (e) {
        debugPrint('[CallService] enableVideo error: $e');
      }
    }

    // 更新消息状态为 connected
    if (callId != null) {
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
    }

    // 更新状态
    _stateData = CallStateData(
      status: CallState.connected,
      callType: type,
      channelName: channelName,
      remoteUserId: remoteUserId,
      callerName: callerName,
      isVideoEnabled: type == 'video',
      callId: callId,
    );

    // 生成 UID（修复：确保不为 0）
    int myUid = currentUserId.isNotEmpty
        ? currentUserId.hashCode.abs() % 99999 + 1
        : 1;
    
    // 设置主播角色（在 joinChannel 之前）
    try {
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      debugPrint('[CallService] Client role set to broadcaster (accept)');
    } catch (e) {
      debugPrint('[CallService] setClientRole error: $e');
    }
    
    // 通话音频配置（每次通话重新设置，确保生效）
    try {
      await _engine!.setAudioScenario(AudioScenarioType.audioScenarioChatroom);
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      await _engine!.setEnableSpeakerphone(true);
      debugPrint('[CallService] Accept call audio configured: speech + speaker');
    } catch (e) {
      debugPrint('[CallService] Accept call audio config error: $e');
    }
    
    // 确保本地音频流未静音（在 joinChannel 之前）
    try {
      await _engine!.muteLocalAudioStream(false);
      debugPrint('[CallService] Local audio unmuted (accept)');
    } catch (e) {
      debugPrint('[CallService] muteLocalAudioStream(false) error: $e');
    }
    
    // 加入 Agora 频道
    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: myUid,
        options: ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      debugPrint('[CallService] Joined channel (accept): $channelName, uid: $myUid');
      
      // 加入后再次确认扬声器和音频发布
      try {
        await _engine!.setEnableSpeakerphone(true);
        await _engine!.muteLocalAudioStream(false);
        debugPrint('[CallService] Post-join (accept): speaker on, mic unmuted');
      } catch (e) {
        debugPrint('[CallService] Post-join audio config error: $e');
      }
    } catch (e) {
      debugPrint('[CallService] joinChannel error: $e');
      _stateData = const CallStateData(status: CallState.idle);
      notifyListeners();
      return;
    }

    _startDurationTimer();
    notifyListeners();
  }

  /// 设置来电状态（用于推送通知触发）
  void setIncomingCall({
    required String channelName,
    required String type,
    required String callerName,
    String? callId,
    String? remoteUserId,
  }) {
    if (_stateData.status != CallState.idle) {
      _isBusy = true;
      return;
    }
    _stateData = CallStateData(
      status: CallState.incoming,
      callType: type,
      channelName: channelName,
      remoteUserId: remoteUserId,
      callerName: callerName,
      isVideoEnabled: type == 'video',
      callId: callId,
    );
    notifyListeners();
  }

  /// 挂断
  Future<void> endCall() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;

    final callId = _stateData.callId;
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

    try {
      await _engine?.leaveChannel();
    } catch (e) {
      debugPrint('[CallService] leaveChannel error: $e');
    }

    _stateData = const CallStateData(status: CallState.idle);
    _isBusy = false;
    notifyListeners();
  }

  /// 静音/取消静音
  Future<void> toggleMute() async {
    final muted = !_stateData.isMuted;
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (e) {
      debugPrint('[CallService] toggleMute error: $e');
    }
    _stateData = _stateData.copyWith(isMuted: muted);
    notifyListeners();
  }

  /// 扬声器/听筒切换
  Future<void> toggleSpeaker() async {
    final speakerOn = !_stateData.isSpeakerOn;
    try {
      await _engine?.setEnableSpeakerphone(speakerOn);
    } catch (e) {
      debugPrint('[CallService] toggleSpeaker error: $e');
    }
    _stateData = _stateData.copyWith(isSpeakerOn: speakerOn);
    notifyListeners();
  }

  /// 视频开关
  Future<void> toggleVideo() async {
    final enabled = !_stateData.isVideoEnabled;
    try {
      if (enabled) {
        await _engine?.enableVideo();
      } else {
        await _engine?.disableVideo();
      }
    } catch (e) {
      debugPrint('[CallService] toggleVideo error: $e');
    }
    _stateData = _stateData.copyWith(isVideoEnabled: enabled);
    notifyListeners();
  }

  /// 切换摄像头
  Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
    } catch (e) {
      debugPrint('[CallService] switchCamera error: $e');
    }
    notifyListeners();
  }

  /// 获取本地视频视图控制器
  VideoViewController? getLocalVideoController() {
    if (_engine == null) return null;
    return VideoViewController(
      rtcEngine: _engine!,
      canvas: const VideoCanvas(uid: 0),
    );
  }

  /// 获取远端视频视图控制器
  VideoViewController? getRemoteVideoController(int uid) {
    if (_engine == null) return null;
    return VideoViewController(
      rtcEngine: _engine!,
      canvas: VideoCanvas(uid: uid),
    );
  }

  /// 通话计时
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _stateData = _stateData.copyWith(
        callDuration: _stateData.callDuration + const Duration(seconds: 1),
      );
      notifyListeners();
    });
  }

  String _encodeJson(Map<String, dynamic> map) {
    final pairs = map.entries.map((e) {
      final key = '"${e.key}"';
      final value = e.value is String ? '"${e.value}"' : '${e.value}';
      return '$key:$value';
    }).join(',');
    return '{$pairs}';
  }


  /// 从 WebView Bridge 调用：直接加入 Agora 频道（信令由 Web 端处理）
  Future<void> joinChannelFromWebView({
    required String channelName,
    required int uid,
    required String token,
    bool isVideo = false,
  }) async {
    await initialize();
    
    if (!_engineInitialized || _engine == null) {
      debugPrint('[CallService] Engine not available for WebView call');
      throw Exception('Agora engine not initialized');
    }

    if (isVideo) {
      try {
        await _engine!.enableVideo();
      } catch (e) {
        debugPrint('[CallService] enableVideo error: $e');
      }
    }

    _stateData = CallStateData(
      status: CallState.connected,
      channelName: channelName,
      isVideoEnabled: isVideo,
    );

    // 通话音频配置 - 在 join 前完成所有音频设置
    try {
      // 设置主播角色（必须在 join 前设置）
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // 设置语音通话优化配置（与 startCall/acceptCall 保持一致）
      await _engine!.setAudioScenario(AudioScenarioType.audioScenarioChatroom);
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      
      // 默认扬声器模式
      await _engine!.setEnableSpeakerphone(true);
      
      debugPrint('[CallService] WebView pre-join audio configured: broadcaster, speechStandard, speakerphone');
    } catch (e) {
      debugPrint('[CallService] WebView pre-join audio config error: $e');
    }
    
    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideo,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideo,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      debugPrint('[CallService] WebView call joined: channel=$channelName, uid=$uid');
      
      // 加入后等待 SDK 稳定，再确认音频发布
      await Future.delayed(const Duration(milliseconds: 300));
      
      try {
        // 确保角色是主播（某些 SDK 版本 join 后可能回退到观众）
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.setEnableSpeakerphone(true);
        
        // 关键：显式取消静音并发布麦克风音频流
        await _engine!.muteLocalAudioStream(false);
        
        debugPrint('[CallService] WebView post-join: broadcaster, speaker on, mic unmuted');
      } catch (e) {
        debugPrint('[CallService] WebView post-join audio config error: $e');
      }
    } catch (e) {
      debugPrint('[CallService] WebView joinChannel error: $e');
      _stateData = const CallStateData(status: CallState.idle);
      rethrow;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _durationTimer?.cancel();
    // 确保 leaveChannel 完成后再 release，避免 SDK 状态冲突
    () async {
      try {
        await _engine?.leaveChannel();
      } catch (e) {
        debugPrint('[CallService] dispose leaveChannel error: $e');
      }
      try {
        await _engine?.release();
      } catch (e) {
        debugPrint('[CallService] dispose release error: $e');
      }
      _engine = null;
      _engineInitialized = false;
    }();
    super.dispose();
  }
}
