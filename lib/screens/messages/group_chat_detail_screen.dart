import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import 'user_profile_screen.dart';

/// 群聊详情页 - 100% 对齐网页版 GroupChatDetail.tsx
class GroupChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const GroupChatDetailScreen({super.key, required this.groupData});

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  // 群信息
  String? _groupId;
  String? _groupTitle;
  String? _groupContent;
  List<String> _groupTags = [];
  String? _creatorId;
  List<Map<String, dynamic>> _members = [];
  bool _isMember = false;
  bool _loading = true;
  bool _loadingMembers = true;
  String? _currentUserId;
  String? _currentUserProfileId;
  Map<String, dynamic>? _currentUserProfile;

  // 消息
  List<Map<String, dynamic>> _messages = [];
  Map<String, Map<String, dynamic>> _senderProfiles = {};
  bool _isSending = false;

  // 语音录制
  bool _isVoiceMode = false;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // UI 状态
  bool _showEmojiPicker = false;
  bool _showMoreMenu = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _parseGroupData();
    _fetchCurrentUserProfile();
    _loadMembers();
    _loadMessages();
    _startMessagePolling();
    // 监听输入框变化
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _parseGroupData() {
    final g = widget.groupData;
    setState(() {
      _groupId = g['id'] as String?;
      _groupTitle = g['title'] as String? ?? '群聊';
      _groupContent = g['content'] as String?;
      _groupTags = (g['tags'] as List?)?.cast<String>() ?? [];
      _creatorId = g['user_id'] as String?;
      _isMember = _currentUserId != null &&
          _groupTags.contains('member_$_currentUserId');
      _loading = false;
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

  Future<void> _loadMembers() async {
    if (_groupId == null) return;
    setState(() => _loadingMembers = true);
    try {
      final memberTags = _groupTags
          .where((t) => t.startsWith('member_'))
          .map((t) => t.replaceFirst('member_', ''))
          .toList();

      if (memberTags.isEmpty) {
        setState(() {
          _members = [];
          _loadingMembers = false;
        });
        return;
      }

      final profiles = await _supabase
          .from('profiles')
          .select('id,user_id,username,nickname,avatar_url')
          .inFilter('user_id', memberTags);
      if (!mounted) return;
      setState(() {
        _members = List<Map<String, dynamic>>.from(profiles);
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_groupId == null) return;
    try {
      final res = await _supabase
          .from('group_messages')
          .select('id,group_id,sender_id,content,message_type,is_read,created_at')
          .eq('group_id', _groupId!)
          .order('created_at', ascending: true)
          .limit(200);
      if (!mounted) return;
      setState(() {
        _messages = List<Map<String, dynamic>>.from(res);
      });
      _fetchSenderProfiles();
      _scrollToBottom();
    } catch (e) { debugPrint('加载群聊消息失败: $e'); }
  }

  Future<void> _fetchSenderProfiles() async {
    if (_messages.isEmpty) return;
    final unknownSenderIds = _messages
        .map((m) => m['sender_id'] as String?)
        .where((id) => id != null && !_senderProfiles.containsKey(id))
        .toSet()
        .toList();
    if (unknownSenderIds.isEmpty) return;
    try {
      final res = await _supabase
          .from('profiles')
          .select('id,username,nickname,avatar_url')
          .inFilter('id', unknownSenderIds.whereType<String>().toList());
      if (res.isNotEmpty) {
        final newProfiles = <String, Map<String, dynamic>>{};
        for (final p in res) {
          newProfiles[p['id'] as String] = Map<String, dynamic>.from(p);
        }
        if (!mounted) return;
        setState(() => _senderProfiles.addAll(newProfiles));
      }
    } catch (e) { debugPrint('加载消息发送者资料失败: $e'); }
  }

  void _startMessagePolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadMessages();
        _startMessagePolling();
      }
    });
  }

  Future<void> _sendMessage([String? content, String? type]) async {
    final msgContent = content ?? _messageController.text.trim();
    final msgType = type ?? 'text';
    if (msgContent.isEmpty || _groupId == null || _currentUserProfileId == null) return;

    setState(() => _isSending = true);
    if (content == null) _messageController.clear();

    try {
      await _supabase.from('group_messages').insert({
        'group_id': _groupId,
        'sender_id': _currentUserProfileId,
        'content': msgContent,
        'message_type': msgType,
      });
      _loadMessages();
    } catch (e) { debugPrint('发送群聊消息失败: $e'); }
    if (!mounted) return;
    setState(() => _isSending = false);
  }

  Future<void> _toggleMembership() async {
    if (_currentUserId == null || _groupId == null) return;
    final memberTag = 'member_$_currentUserId';

    if (_isMember) {
      try {
        final res = await _supabase.from('posts').select('id,tags').eq('id', _groupId!);
        if (res.isNotEmpty) {
          final tags = (res[0]['tags'] as List?)?.cast<String>() ?? [];
          tags.remove(memberTag);
          await _supabase.from('posts').update({'tags': tags}).eq('id', _groupId!);
        }
        if (!mounted) return;
        setState(() => _isMember = false);
        _loadMembers();
      } catch (e) { debugPrint('退出群聊失败: $e'); }
    } else {
      try {
        final res = await _supabase.from('posts').select('id,tags').eq('id', _groupId!);
        if (res.isNotEmpty) {
          final tags = (res[0]['tags'] as List?)?.cast<String>() ?? [];
          if (!tags.contains(memberTag)) tags.add(memberTag);
          await _supabase.from('posts').update({'tags': tags}).eq('id', _groupId!);
        }
        if (!mounted) return;
        setState(() => _isMember = true);
        _loadMembers();
      } catch (e) { debugPrint('加入群聊失败: $e'); }
    }
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
    if (d.year == now.year && d.month == now.month && d.day == now.day) return '今天';
    return '${d.year}/${d.month}/${d.day}';
  }

  bool _shouldShowDateDivider(int index) {
    if (index == 0) return true;
    final curr = DateTime.parse(_messages[index]['created_at'] as String);
    final prev = DateTime.parse(_messages[index - 1]['created_at'] as String);
    return curr.year != prev.year || curr.month != prev.month || curr.day != prev.day;
  }

  String _getDisplayName(String profileId) {
    final profile = _senderProfiles[profileId];
    if (profile == null) return '...';
    return (profile['nickname'] as String?) ?? (profile['username'] as String?) ?? '未知';
  }

  String? _getAvatarUrl(String profileId) {
    return _senderProfiles[profileId]?['avatar_url'] as String?;
  }

  bool _isOwnMessage(Map<String, dynamic> msg) {
    return msg['sender_id'] == _currentUserProfileId;
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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.auroraPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isMember ? _buildMessageArea() : _buildNotMemberView(),
            ),
            if (_isMember) _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ===== 顶部导航栏（毛玻璃）=====
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
              bottom: BorderSide(color: AppColors.borderDefault, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.hoverBg,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showGroupInfo(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.inputBg,
                      ),
                      child: const Icon(Icons.groups,
                          size: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _groupTitle ?? '群聊',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showGroupOptions(),
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

  // ===== 未加入状态 =====
  Widget _buildNotMemberView() {
    final tags = _groupTags
        .where((t) =>
            !t.startsWith('__') &&
            !t.startsWith('member_') &&
            !t.startsWith('group_'))
        .toList();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.groups,
                  size: 40, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(_groupTitle ?? '群聊',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            if (_groupContent != null && _groupContent!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_groupContent!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  )),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        )),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _toggleMembership,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  gradient: AppColors.auroraGradient,
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.bgColor,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text('加入群聊',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          )),
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

  // ===== 消息区域 =====
  Widget _buildMessageArea() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.textPrimary),
            SizedBox(height: 12),
            Text('开始群聊吧',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                )),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isOwn = _isOwnMessage(msg);
        final showDate = _shouldShowDateDivider(index);
        final senderName = isOwn
            ? ((_currentUserProfile?['nickname'] as String?) ??
                (_currentUserProfile?['username'] as String?) ??
                '我')
            : _getDisplayName(msg['sender_id'] as String);
        final avatarUrl = isOwn
            ? (_currentUserProfile?['avatar_url'] as String?)
            : _getAvatarUrl(msg['sender_id'] as String);

        return Column(
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDate(msg['created_at'] as String),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isOwn) ...[
                    _buildAvatar(avatarUrl, senderName, 32),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isOwn)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(senderName,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                )),
                          ),
                        _buildMessageBubble(msg),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTime(msg['created_at'] as String),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
      },
    );
  }

  Widget _buildAvatar(String? url, String name, double size) {
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultAvatar(name, size)),
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

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final content = msg['content'] as String? ?? '';
    final msgType = msg['message_type'] as String? ?? 'text';
    final isOwn = _isOwnMessage(msg);

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
                      style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                )),
      );
    }

    // 语音消息
    if (content.startsWith('[voice:')) {
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

    // 普通文本消息 - 对齐网页版七彩边框
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOwn ? 4 : 16),
          bottomRight: Radius.circular(isOwn ? 16 : 4),
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

    // 对齐网页版语音气泡样式
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
          const Icon(Icons.volume_up, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 4),
          // 声波条 - 对齐网页版
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
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFaithBubble(String content) {
    final data = _tryParseJson(content);
    if (data == null) {
      return Text(content,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14));
    }
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
          // 标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // 正文
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          // 来源
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
              ),
            ),
            child: Text('— ${data['source'] ?? ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCardBubble(String content) {
    final data = _tryParseJson(content);
    if (data == null) {
      return Text(content,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14));
    }
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.auroraRed.withOpacity(0.08),
                  AppColors.auroraCyan.withOpacity(0.08),
                  AppColors.auroraPurple.withOpacity(0.08),
                ],
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📝 ', style: TextStyle(fontSize: 14)),
                Text('笔记分享',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          if (data['cover_image'] != null && (data['cover_image'] as String).isNotEmpty)
            Image.network(data['cover_image'] as String,
                height: 96,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                if (data['content'] != null && (data['content'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data['content'] as String,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
              ),
            ),
            child: const Text('点击阅读 · 长按复制',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: AppColors.borderDefault, width: 0.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isRecording ? '${_recordingDuration}″ 松开发送' : '按住说话',
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
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '输入消息...',
                            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                            filled: true,
                            fillColor: AppColors.bgSecondary,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                  color: AppColors.borderDefault, width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                  color: AppColors.borderDefault, width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                  color: AppColors.borderActive, width: 0.5),
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
                      if (_showEmojiPicker) _inputFocusNode.unfocus();
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
                      _showEmojiPicker ? Icons.keyboard : Icons.tag_faces,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 发送 / 加号
                _messageController.text.trim().isNotEmpty && !_isVoiceMode
                    ? GestureDetector(
                        onTap: _isSending ? null : () => _sendMessage(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.inputBg,
                          ),
                          child: Icon(
                            _isSending ? Icons.hourglass_empty : Icons.send,
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
                            _showMoreMenu ? Icons.keyboard : Icons.add,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _emojiList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _sendMessage(_emojiList[index]),
                      child: Center(
                        child: Text(_emojiList[index],
                            style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textWeak,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(_groupTitle ?? '群聊',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${_members.length} 位成员',
                style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.copy,
              label: '复制群聊信息',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            _buildOptionItem(
              icon: Icons.share,
              label: '分享群聊',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            if (_isMember)
              _buildOptionItem(
                icon: Icons.exit_to_app,
                label: '退出群聊',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _toggleMembership();
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.hoverBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
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

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textWeak,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_groupTitle ?? '群聊',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                if (_groupContent != null && _groupContent!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_groupContent!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      )),
                ],
                const SizedBox(height: 20),
                Text('成员 (${_members.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 12),
                ...List.generate(_members.length, (i) {
                  final m = _members[i];
                  final name = m['nickname'] as String? ??
                      m['username'] as String? ??
                      '未命名用户';
                  final uid = m['user_id'] as String? ?? m['id'] as String?;
                  final avatarUrl = m['avatar_url'] as String?;
                  return GestureDetector(
                    onTap: uid != null
                        ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(userId: uid),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: i < _members.length - 1
                            ? Border(
                                bottom: BorderSide(
                                    color: AppColors.borderSubtle, width: 0.5))
                            : null,
                      ),
                      child: Row(children: [
                        _buildAvatar(avatarUrl, name, 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.textWeak),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          );
        },
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
    super.dispose();
  }
}
