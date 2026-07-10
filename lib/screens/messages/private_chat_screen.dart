import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';

/// 私聊页面 - 100% 对齐网页版 PrivateChat.tsx
class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _isSending = false;
  String? _currentUserId;
  String? _currentUserProfileId;
  Map<String, dynamic>? _currentUserProfile;
  Map<String, dynamic>? _friendProfile;

  // 通话状态映射
  Map<String, Map<String, dynamic>> _callStatusMap = {};

  // 功能状态
  bool _isVoiceMode = false;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  bool _showEmojiPicker = false;
  bool _showMoreMenu = false;
  bool _showChatMenu = false;
  bool _isMuted = false;
  bool _isPinned = false;
  bool _isFolded = false;

  // Realtime 订阅
  RealtimeChannel? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _fetchCurrentUserProfile();
    _fetchFriendProfile();
    _loadMessages();
    _subscribeToMessages();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchCurrentUserProfile() async {
    if (_currentUserId == null) return;
    try {
      final res = await _supabase
          .from('profiles')
          .select('id,username,nickname,avatar_url,user_id')
          .eq('user_id', _currentUserId!)
          .limit(1);
      if (res.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _currentUserProfile = Map<String, dynamic>.from(res[0]);
          _currentUserProfileId = res[0]['id'] as String?;
        });
      }
    } catch (e) { debugPrint('加载当前用户资料失败: $e'); }
  }

  Future<void> _fetchFriendProfile() async {
    try {
      // 先尝试 user_id 查询
      var res = await _supabase
          .from('profiles')
          .select('id,username,nickname,avatar_url,user_id')
          .eq('user_id', widget.otherUserId)
          .limit(1);

      // 如果没查到，尝试用 id 查询
      if (res.isEmpty) {
        res = await _supabase
            .from('profiles')
            .select('id,username,nickname,avatar_url,user_id')
            .eq('id', widget.otherUserId)
            .limit(1);
      }

      if (res.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _friendProfile = Map<String, dynamic>.from(res[0]);
        });
      }
    } catch (e) { debugPrint('加载好友资料失败: $e'); }
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;
    try {
      final response = await _supabase
          .from('private_messages')
          .select(
              '*, sender:sender_id(nickname, username, avatar_url), receiver:receiver_id(nickname, username, avatar_url)')
          .or(
              'and(sender_id.eq.${_currentUserId!},receiver_id.eq.${widget.otherUserId}),and(sender_id.eq.${widget.otherUserId},receiver_id.eq.${_currentUserId!})')
          .order('created_at', ascending: true)
          .limit(100);

      final msgs = response != null
          ? List<Map<String, dynamic>>.from(response)
          : <Map<String, dynamic>>[];

      // 提取通话状态映射
      final statusMap = <String, Map<String, dynamic>>{};
      for (final msg in msgs) {
        final content = msg['content'] as String? ?? '';
        if (content.startsWith('[CALL_STATUS]')) {
          try {
            final data = jsonDecode(content.substring('[CALL_STATUS]'.length));
            if (data is Map && data['callId'] != null) {
              statusMap[data['callId'] as String] = {
                'status': data['status'],
                'duration': data['duration'],
                'callType': data['callType'],
              };
            }
          } catch (e) { debugPrint('解析通话状态数据失败: $e'); }
        }
      }

      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _callStatusMap = statusMap;
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _subscribeToMessages() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeSubscription = _supabase
        .channel('private_chat_${userId}_${widget.otherUserId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'private_messages',
          callback: (payload) {
            final data = payload.newRecord;
            final senderId = data['sender_id'];
            final receiverId = data['receiver_id'];
            if ((senderId == userId &&
                    receiverId == widget.otherUserId) ||
                (senderId == widget.otherUserId && receiverId == userId)) {
              _loadMessages();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage([String? content, String? type]) async {
    final text = content ?? _messageController.text.trim();
    final msgType = type ?? 'text';
    if (text.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _currentUserProfileId == null) return;

    setState(() => _isSending = true);
    if (content == null) _messageController.clear();

    try {
      await _supabase.from('private_messages').insert({
        'sender_id': _currentUserProfileId ?? userId,
        'receiver_id': widget.otherUserId,
        'content': text,
        'message_type': msgType,
      });
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送失败，请重试')),
        );
      }
    }
    if (!mounted) return;
    setState(() => _isSending = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(String ds) {
    final d = DateTime.parse(ds);
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${d.month}/${d.day}';
  }

  String _formatDate(String ds) {
    final d = DateTime.parse(ds);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '今天';
    }
    return '${d.year}/${d.month}/${d.day}';
  }

  bool _shouldShowDateDivider(int index) {
    if (index == 0) return true;
    final curr = DateTime.parse(_messages[index]['created_at'] as String);
    final prev = DateTime.parse(_messages[index - 1]['created_at'] as String);
    return curr.year != prev.year ||
        curr.month != prev.month ||
        curr.day != prev.day;
  }

  bool _isOwnMessage(Map<String, dynamic> msg) {
    return msg['sender_id'] == _currentUserProfileId;
  }

  String _getDisplayName() {
    return _friendProfile?['nickname'] as String? ??
        _friendProfile?['username'] as String? ??
        widget.otherUserName;
  }

  String? _getAvatarUrl() {
    return _friendProfile?['avatar_url'] as String?;
  }

  Map<String, dynamic>? _tryParseJson(String s) {
    try {
      final result = jsonDecode(s);
      if (result is Map<String, dynamic>) return result;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            // 消息列表
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.auroraPurple))
                  : _messages.isEmpty
                      ? const Center(
                          child: Text('开始对话吧',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              )))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = _isOwnMessage(msg);
                            return _buildMessageItem(msg, isMe, index);
                          },
                        ),
            ),
            // 输入栏
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ===== 顶部导航栏 =====
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border(
              bottom: BorderSide(
                  color: AppColors.borderDefault, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // 返回按钮
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.hoverBg,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 18,
                      color: AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              // 好友头像 + 名字
              GestureDetector(
                onTap: () {
                  // Could navigate to profile
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(_getAvatarUrl(), _getDisplayName(), 32),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getDisplayName(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const Spacer(),
              // 更多按钮
              GestureDetector(
                onTap: () => _showChatOptions(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.hoverBg,
                  ),
                  child: const Icon(Icons.more_vert,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String name, double size) {
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildDefaultAvatar(name, size)),
      );
    }
    return _buildDefaultAvatar(name, size);
  }

  Widget _buildDefaultAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textPrimary,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.bgColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ===== 消息项（含日期分隔）=====
  Widget _buildMessageItem(
      Map<String, dynamic> msg, bool isMe, int index) {
    final showDate = _shouldShowDateDivider(index);
    final content = msg['content'] as String? ?? '';
    final msgType = msg['message_type'] as String? ?? 'text';

    // 过滤掉通话系统消息（CALL_ANSWER, CALL_HANGUP, CALL_STATUS）
    if (content.startsWith('[CALL_ANSWER]') ||
        content.startsWith('[CALL_HANGUP]') ||
        content.startsWith('[CALL_STATUS]')) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDate(msg['created_at'] as String),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                GestureDetector(
                  onTap: () {
                    // Could navigate to profile
                  },
                  child: _buildAvatar(_getAvatarUrl(), _getDisplayName(), 36),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildMessageBubble(msg),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(msg['created_at'] as String),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final content = msg['content'] as String? ?? '';
    final msgType = msg['message_type'] as String? ?? 'text';
    final isMe = _isOwnMessage(msg);

    // 通话消息
    if (msgType == 'call_invite' || content.startsWith('[CALL_INVITE]')) {
      return _buildCallInviteBubble(msg);
    }

    // 图片消息
    if (msgType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(content,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('图片加载失败',
                      style: TextStyle(
                          color: AppColors.textWeak, fontSize: 13)),
                )),
      );
    }

    // 语音消息
    if (msgType == 'voice' || content.startsWith('[voice:')) {
      return _buildVoiceBubble(msg);
    }

    // 信仰气泡
    if (msgType == 'faith_bubble') {
      return _buildFaithBubble(content);
    }

    // 笔记卡片
    if (msgType == 'note_card') {
      return _buildNoteCardBubble(content);
    }

    // 普通文本消息
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 4 : 16),
          bottomRight: Radius.circular(isMe ? 16 : 4),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgColor.withOpacity(0.85),
            AppColors.bgColor.withOpacity(0.85),
          ],
        ),
        border: Border.all(
          color: AppColors.auroraRed.withOpacity(0.18),
          width: 1.3,
        ),
      ),
      child: Text(content,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          )),
    );
  }

  Widget _buildVoiceBubble(Map<String, dynamic> msg) {
    final content = msg['content'] as String;
    int duration = 0;
    try {
      final match = RegExp(r'\[voice:(.+):(\d+)\]').firstMatch(content);
      if (match != null) duration = int.parse(match.group(2) ?? '0');
    } catch (e) { debugPrint('解析语音时长失败: $e'); }

    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.auroraRed.withOpacity(0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.volume_up,
              size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 4),
          ...List.generate(4, (i) {
            return Container(
              width: 2,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.auroraCyan.withOpacity(0.3 + i * 0.15),
                borderRadius: BorderRadius.circular(1),
              ),
              height: (6 + (i + 1) * 3).toDouble(),
            );
          }),
          const SizedBox(width: 8),
          Text('$duration″',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCallInviteBubble(Map<String, dynamic> msg) {
    final content = msg['content'] as String;
    Map<String, dynamic>? callData;
    try {
      var raw = content;
      for (final prefix in [
        '[CALL_INVITE]',
        '[CALL_ANSWER]',
        '[CALL_HANGUP]',
        '[CALL_STATUS]'
      ]) {
        if (raw.startsWith(prefix)) {
          raw = raw.substring(prefix.length);
          break;
        }
      }
      callData = jsonDecode(raw) as Map<String, dynamic>?;
    } catch (e) { debugPrint('解析通话信令数据失败: $e'); }

    // 使用 callStatusMap 获取最新状态
    final callId = callData?['callId'] as String? ?? msg['id'] as String?;
    final latestStatus = callId != null ? _callStatusMap[callId] : null;
    final status = latestStatus?['status'] ?? callData?['status'];
    final isVoice = (latestStatus?['callType'] ?? callData?['callType'] ?? 'voice') != 'video';
    final duration = latestStatus?['duration'] ?? callData?['duration'];
    final isMe = _isOwnMessage(msg);

    final isMissed = status == 'missed';
    final isRejected = status == 'rejected';
    final isCancelled = status == 'cancelled';
    final isConnected = status == 'connected';

    String statusText;
    if (isMissed) {
      statusText = isMe ? '无人接听' : '未接来电';
    } else if (isRejected) {
      statusText = isMe ? '对方已拒绝' : '已拒绝';
    } else if (isCancelled) {
      statusText = isMe ? '已取消' : '对方已取消';
    } else if (isConnected && duration != null && duration > 0) {
      final mins = (duration as int) ~/ 60;
      final secs = duration % 60;
      statusText =
          '通话时长 ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else if (isConnected) {
      statusText = '通话中';
    } else {
      statusText = isVoice ? '语音通话' : '视频通话';
    }

    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 4 : 16),
          bottomRight: Radius.circular(isMe ? 16 : 4),
        ),
        border: Border.all(
          color: AppColors.auroraRed.withOpacity(0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVoice ? Icons.phone : Icons.videocam,
            size: 18,
            color: (isMissed || isRejected)
                ? AppColors.error
                : AppColors.auroraCyan,
          ),
          const SizedBox(width: 8),
          Text(statusText,
              style: TextStyle(
                color: (isMissed || isRejected)
                    ? AppColors.error
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildFaithBubble(String content) {
    final data = _tryParseJson(content);
    if (data == null) {
      return Text(content,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14));
    }
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.auroraRed.withOpacity(0.25),
          width: 1.3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.auroraRed.withOpacity(0.08),
                  AppColors.auroraCyan.withOpacity(0.08),
                  AppColors.auroraPurple.withOpacity(0.08),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📜 ', style: TextStyle(fontSize: 14)),
                const Text('信仰之光',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              '"${data['text'] ?? ''}"',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: AppColors.borderSubtle, width: 0.5),
              ),
            ),
            child: Text('— ${data['source'] ?? ''}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCardBubble(String content) {
    final data = _tryParseJson(content);
    if (data == null) {
      return Text(content,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14));
    }
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.auroraRed.withOpacity(0.2),
          width: 1.3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.auroraRed.withOpacity(0.08),
                  AppColors.auroraCyan.withOpacity(0.08),
                  AppColors.auroraPurple.withOpacity(0.08),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📝 ', style: TextStyle(fontSize: 14)),
                const Text('笔记分享',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          if (data['cover_image'] != null &&
              (data['cover_image'] as String).isNotEmpty)
            Image.network(data['cover_image'] as String,
                height: 96,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink()),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (data['content'] != null &&
                    (data['content'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data['content'] as String,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: AppColors.borderSubtle, width: 0.5),
              ),
            ),
            child: const Text('点击阅读 · 长按复制',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ===== 输入栏 =====
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.borderDefault, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                // 语音/文字切换
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isVoiceMode = !_isVoiceMode;
                      _showEmojiPicker = false;
                      _showMoreMenu = false;
                    });
                    if (!_isVoiceMode) {
                      _inputFocusNode.requestFocus();
                    } else {
                      _inputFocusNode.unfocus();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgSecondary,
                    ),
                    child: Icon(
                      _isVoiceMode ? Icons.keyboard : Icons.mic,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 输入框 / 按住说话
                Expanded(
                  child: _isVoiceMode
                      ? GestureDetector(
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressEnd: (_) => _stopRecording(),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.bgSecondary,
                              borderRadius:
                                  BorderRadius.circular(22),
                              border: Border.all(
                                  color: AppColors.borderDefault,
                                  width: 0.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isRecording
                                  ? '$_recordingDuration″ 松开发送'
                                  : '按住说话',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: _messageController,
                          focusNode: _inputFocusNode,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '输入消息...',
                            hintStyle: const TextStyle(
                                color: AppColors.textPlaceholder),
                            filled: true,
                            fillColor: AppColors.bgSecondary,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(22),
                              borderSide: BorderSide(
                                  color: AppColors.borderDefault,
                                  width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(22),
                              borderSide: BorderSide(
                                  color: AppColors.borderDefault,
                                  width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(22),
                              borderSide: BorderSide(
                                  color: AppColors.borderActive,
                                  width: 0.5),
                            ),
                          ),
                          maxLines: 4,
                          minLines: 1,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                ),
                const SizedBox(width: 8),
                // 表情按钮
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                      _showMoreMenu = false;
                      if (_showEmojiPicker) {
                        _inputFocusNode.unfocus();
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgSecondary,
                    ),
                    child: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard
                          : Icons.tag_faces,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 发送 / 加号
                _messageController.text.trim().isNotEmpty &&
                        !_isVoiceMode
                    ? GestureDetector(
                        onTap:
                            _isSending ? null : () => _sendMessage(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.inputBg,
                          ),
                          child: Icon(
                            _isSending
                                ? Icons.hourglass_empty
                                : Icons.send,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            _showMoreMenu = !_showMoreMenu;
                            _showEmojiPicker = false;
                            _inputFocusNode.unfocus();
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bgSecondary,
                          ),
                          child: Icon(
                            _showMoreMenu
                                ? Icons.keyboard
                                : Icons.add,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
              ],
            ),
            // 表情面板
            if (_showEmojiPicker)
              Container(
                height: 200,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _emojiList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () =>
                          _sendMessage(_emojiList[index]),
                      child: Center(
                        child: Text(_emojiList[index],
                            style: const TextStyle(
                                fontSize: 24)),
                      ),
                    );
                  },
                ),
              ),
            // 更多功能菜单
            if (_showMoreMenu)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMoreMenuItem(
                        Icons.photo, '图片', _pickAndSendImage),
                    _buildMoreMenuItem(
                        Icons.camera_alt, '拍照', _takePhoto),
                    _buildMoreMenuItem(
                        Icons.description, '文件', _pickAndSendFile),
                    _buildMoreMenuItem(
                        Icons.book, '笔记', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('笔记功能即将开放')),
                      );
                    }),
                    _buildMoreMenuItem(
                        Icons.menu_book, '经文', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('经文分享功能即将开放')),
                      );
                    }),
                    _buildMoreMenuItem(
                        Icons.phone, '通话', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('语音通话功能即将开放')),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenuItem(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                size: 24, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              )),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _isSending = true);
      final file = File(picked.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final storagePath = 'chat-images/$fileName';
      await _supabase.storage.from('post-images').upload(storagePath, file);
      final publicUrl = _supabase.storage.from('post-images').getPublicUrl(storagePath);
      await _sendMessage(publicUrl, 'image');
    } catch (e) {
      debugPrint('发送图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送图片失败，请重试')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _isSending = true);
      final file = File(picked.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final storagePath = 'chat-images/$fileName';
      await _supabase.storage.from('post-images').upload(storagePath, file);
      final publicUrl = _supabase.storage.from('post-images').getPublicUrl(storagePath);
      await _sendMessage(publicUrl, 'image');
    } catch (e) {
      debugPrint('拍照发送失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拍照发送失败，请重试')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
      if (result == null || result.files.isEmpty) return;
      if (!mounted) return;
      setState(() => _isSending = true);
      final file = File(result.files.single.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final storagePath = 'chat-files/$fileName';
      await _supabase.storage.from('post-images').upload(storagePath, file);
      final publicUrl = _supabase.storage.from('post-images').getPublicUrl(storagePath);
      await _sendMessage(publicUrl, 'file');
    } catch (e) {
      debugPrint('发送文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送文件失败，请重试')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording) {
        setState(() => _recordingDuration++);
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() => _isRecording = false);
    // Placeholder for actual voice message sending
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textWeak,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_getDisplayName(),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                _buildOptionItem(
                  icon: Icons.search,
                  label: '查找聊天内容',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                _buildOptionItem(
                  icon: _isMuted
                      ? Icons.notifications_off
                      : Icons.notifications,
                  label: _isMuted ? '取消免打扰' : '消息免打扰',
                  onTap: () {
                    setState(() => _isMuted = !_isMuted);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                _buildOptionItem(
                  icon: Icons.vertical_align_top,
                  label: _isPinned ? '取消置顶' : '置顶聊天',
                  onTap: () {
                    setState(() => _isPinned = !_isPinned);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                _buildOptionItem(
                  icon: Icons.folder,
                  label: _isFolded ? '取消折叠' : '折叠该聊天',
                  onTap: () {
                    setState(() => _isFolded = !_isFolded);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ]),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.hoverBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon,
              size: 20,
              color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: color ?? AppColors.textSecondary,
                fontSize: 14,
              )),
        ]),
      ),
    );
  }

  static const _emojiList = [
    '❤️', '🔥', '😊', '😂', '🙏', '💪', '👍', '🎉',
    '✨', '🌟', '💫', '⭐', '🌈', '☀️', '🌙', '💎',
    '🕊️', '🌸', '🍀', '🦋', '🐦', '🌊', '🏔️', '🌅',
    '🎵', '📖', '📜', '🗝️', '⚖️', '🎁', '🌍', '👁️',
    '💡', '🔑', '🏆', '🎯', '🧭', '🛡️', '⛪', '✝️',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _recordingTimer?.cancel();
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }
}
