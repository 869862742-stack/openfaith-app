import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/permissions_helper.dart';

/// 通话页面 - 支持语音和视频两种模式
class CallScreen extends StatefulWidget {
  final String myUserId;
  final String peerUserId;
  final String peerName;
  final String callType; // 'voice' | 'video'
  final bool isIncoming;
  final String? callId;
  final String? channelName;
  final VoidCallback? onCallEnd;

  const CallScreen({
    super.key,
    required this.myUserId,
    required this.peerUserId,
    required this.peerName,
    required this.callType,
    required this.isIncoming,
    this.callId,
    this.channelName,
    this.onCallEnd,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  bool _permissionsGranted = false;
  bool _swappedVideo = false; // 切换大小窗
  bool _isHangingUp = false; // 挂断防抖

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    // 请求权限
    final granted = await PermissionsHelper.requestCallPermissions(
      needCamera: widget.callType == 'video',
    );
    if (!granted && mounted) {
      _showPermissionDeniedDialog();
      return;
    }
    _permissionsGranted = true;

    // 监听状态变化
    _callService.addListener(_onStateChanged);

    if (widget.isIncoming && widget.channelName != null) {
      // 来电 → 接听
      await _callService.acceptCall(
        channelName: widget.channelName!,
        type: widget.callType,
        callerName: widget.peerName,
        callId: widget.callId,
        myUserId: widget.myUserId,
        remoteUserId: widget.peerUserId,
      );
    } else if (!widget.isIncoming) {
      // 发起通话
      await _callService.startCall(
        peerUserId: widget.peerUserId,
        peerName: widget.peerName,
        type: widget.callType,
        myUserId: widget.myUserId,
      );
    }
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('权限请求', style: TextStyle(color: Colors.white)),
        content: const Text(
          '通话需要麦克风和摄像头权限，请在系统设置中开启。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              PermissionsHelper.openSettings();
            },
            child: const Text('去设置', style: TextStyle(color: Color(0xFF9D4EDD))),
          ),
        ],
      ),
    );
  }

  void _endCallAndPop() {
    // 防抖：防止重复触发挂断
    if (_isHangingUp) return;
    _isHangingUp = true;
    _callService.endCall();
    widget.onCallEnd?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callService.removeListener(_onStateChanged);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF9D4EDD)),
        ),
      );
    }

    final state = _callService.state;
    final isVideo = widget.callType == 'video';
    final isConnected = state.status == CallState.connected;

    if (isVideo && isConnected) {
      return _buildVideoLayout(state);
    } else if (isVideo && !isConnected) {
      // 视频通话接通前显示头像覆盖层
      return _buildVoiceLayout(state);
    } else {
      return _buildVoiceLayout(state);
    }
  }

  /// 语音通话布局
  Widget _buildVoiceLayout(CallStateData state) {
    final statusText = _getStatusText(state);
    final initial = widget.peerName.isNotEmpty ? widget.peerName[0] : '?';

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 头像
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF9D4EDD).withOpacity(0.6),
                    const Color(0xFF7B2FF7).withOpacity(0.4),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 名字
            Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // 状态文字
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // 操作按钮
            _buildCallControls(state),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
    );
  }

  /// 视频通话布局（接通后）
  Widget _buildVideoLayout(CallStateData state) {
    final remoteUid = state.remoteUid;
    final localController = _callService.getLocalVideoController();
    final remoteController = _callService.getRemoteVideoController(remoteUid);

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 全屏远端视频 / 本地视频（交换时）
          if (remoteController != null && !_swappedVideo)
            Positioned.fill(
              child: AgoraVideoView(controller: remoteController),
            )
          else if (localController != null && _swappedVideo)
            Positioned.fill(
              child: AgoraVideoView(controller: localController),
            )
          else
            Container(color: Colors.black),

          // 右下角小窗本地视频 / 远端视频（交换时）
          Positioned(
            right: 16,
            top: 80,
            width: 120,
            height: 160,
            child: GestureDetector(
              onTap: () => setState(() => _swappedVideo = !_swappedVideo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _swappedVideo && remoteController != null
                      ? AgoraVideoView(controller: remoteController)
                      : localController != null
                          ? AgoraVideoView(controller: localController)
                          : Container(color: Colors.black54),
                ),
              ),
            ),
          ),

          // 顶部信息栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.peerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDuration(state.callDuration),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部控制栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildVideoControlButton(
                      icon: state.isMuted ? Icons.mic_off : Icons.mic,
                      label: state.isMuted ? '取消静音' : '静音',
                      onTap: () => _callService.toggleMute(),
                      isActive: state.isMuted,
                    ),
                    _buildVideoControlButton(
                      icon: state.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: state.isSpeakerOn ? '扬声器' : '听筒',
                      onTap: () => _callService.toggleSpeaker(),
                      isActive: !state.isSpeakerOn,
                    ),
                    _buildVideoControlButton(
                      icon: Icons.cameraswitch,
                      label: '翻转',
                      onTap: () => _callService.switchCamera(),
                    ),
                    // 挂断
                    GestureDetector(
                      onTap: _endCallAndPop,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEF4444),
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '挂断',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// 获取状态文字
  String _getStatusText(CallStateData state) {
    switch (state.status) {
      case CallState.calling:
        return '呼叫中...';
      case CallState.connected:
        return _formatDuration(state.callDuration);
      case CallState.incoming:
        return '来电中...';
      case CallState.ringing:
        return '响铃中...';
      case CallState.disconnected:
        return '已断开';
      case CallState.idle:
        return widget.callType == 'voice' ? '语音通话' : '视频通话';
    }
  }

  /// 构建语音通话控制按钮
  Widget _buildCallControls(CallStateData state) {
    if (state.status == CallState.incoming) {
      // 来电：显示接听和拒绝
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHangUpButton(label: '拒绝'),
          _buildAcceptButton(),
        ],
      );
    }

    // 呼叫中/通话中
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: state.isMuted ? Icons.mic_off : Icons.mic,
          label: state.isMuted ? '取消静音' : '静音',
          onTap: () => _callService.toggleMute(),
          isActive: state.isMuted,
        ),
        _buildControlButton(
          icon: state.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          label: state.isSpeakerOn ? '扬声器' : '听筒',
          onTap: () => _callService.toggleSpeaker(),
          isActive: !state.isSpeakerOn,
        ),
        // 挂断按钮（红色）
        GestureDetector(
          onTap: _endCallAndPop,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                '挂断',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.channelName != null) {
          await _callService.acceptCall(
            channelName: widget.channelName!,
            type: widget.callType,
            callerName: widget.peerName,
            callId: widget.callId,
            myUserId: widget.myUserId,
            remoteUserId: widget.peerUserId,
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
            child: const Icon(Icons.phone, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text('接听', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHangUpButton({String label = '挂断'}) {
    return GestureDetector(
      onTap: _endCallAndPop,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEF4444),
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  /// 通用控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// 视频通话控制按钮（稍大）
  Widget _buildVideoControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withOpacity(0.25)
                  : Colors.white.withOpacity(0.15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
