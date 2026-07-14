import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';

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
  int _duration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _callService.onStateChanged = () {
      if (mounted) setState(() {});
      if (_callService.state == CallState.connected && _timer == null) {
        _startTimer();
      }
    };
    _callService.onError = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    };

    if (widget.isIncoming && widget.callId != null && widget.channelName != null) {
      // 自动接听
      _callService.acceptCall(
        myUserId: widget.myUserId,
        callId: widget.callId!,
        channelName: widget.channelName!,
        type: widget.callType,
        callerName: widget.peerName,
      );
    } else if (!widget.isIncoming) {
      // 发起通话
      debugPrint('[CallScreen] Starting outgoing call to ${widget.peerName} (${widget.peerUserId})');
      _callService.startCall(
        myUserId: widget.myUserId,
        peerUserId: widget.peerUserId,
        peerName: widget.peerName,
        type: widget.callType,
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _callService.state;
    final isVoice = widget.callType == 'voice';
    
    String statusText;
    if (state == CallState.calling) {
      statusText = '呼叫中...';
    } else if (state == CallState.connected) {
      statusText = _formatDuration(_duration);
    } else if (state == CallState.incoming) {
      statusText = '来电中...';
    } else {
      statusText = isVoice ? '语音通话' : '视频通话';
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 头像
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.auroraGradientWithOpacity(0.6),
              ),
              child: Center(
                child: Text(
                  widget.peerName.isNotEmpty ? widget.peerName[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 名字
            Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // 状态
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // 操作按钮
            _buildControls(state, isVoice),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(CallState state, bool isVoice) {
    if (state == CallState.calling || state == CallState.connected) {
      // 呼叫中/通话中：显示静音、扬声器、挂断
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
            label: _callService.isMuted ? '取消静音' : '静音',
            onTap: () => setState(() => _callService.toggleMute()),
            isActive: _callService.isMuted,
          ),
          // 挂断按钮
          GestureDetector(
            onTap: () {
              _callService.endCall();
              widget.onCallEnd?.call();
              Navigator.of(context).pop();
            },
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
                Text('挂断', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          _buildControlButton(
            icon: _callService.isSpeakerOff ? Icons.volume_off : Icons.volume_up,
            label: _callService.isSpeakerOff ? '听筒' : '扬声器',
            onTap: () => setState(() => _callService.toggleSpeaker()),
            isActive: _callService.isSpeakerOff,
          ),
        ],
      );
    }
    
    // 来电：显示接听和挂断
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 挂断
        GestureDetector(
          onTap: () {
            _callService.endCall();
            widget.onCallEnd?.call();
            Navigator.of(context).pop();
          },
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
              Text('拒绝', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
        // 接听
        GestureDetector(
          onTap: () {
            if (widget.callId != null && widget.channelName != null) {
              _callService.acceptCall(
                myUserId: widget.myUserId,
                callId: widget.callId!,
                channelName: widget.channelName!,
                type: widget.callType,
                callerName: widget.peerName,
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
        ),
      ],
    );
  }

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
              color: isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }
}
