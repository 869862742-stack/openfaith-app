import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import '../../theme/rainbow_widgets.dart';
import 'private_chat_screen.dart';
import 'user_profile_screen.dart';
import 'group_chat_detail_screen.dart';

/// 消息页面 - 4Tab结构，完全对齐网页版 Messages.tsx
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  int _currentTabIndex = 0;

  List<UnifiedMessage> _unifiedMessages = [];
  bool _loadingMessages = true;
  String? _loadError;
  List<Map<String, dynamic>> _announcementsData = [];
  List<Map<String, dynamic>> _notificationsData = [];
  List<Map<String, dynamic>> _commentRecordsData = [];

  List<Map<String, dynamic>> _friendsList = [];
  Map<String, Map<String, dynamic>> _latestChatMessages = {};
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _recommendedUsers = [];
  Set<String> _followingIds = {};
  Set<String> _pendingRequests = {};
  String? _sendingRequestId;
  bool _isLoadingFriends = false;
  bool _isLoadingRecommended = false;
  bool _isLoadingRequests = false;
  String? _processingRequestId;
  final _friendSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  List<Map<String, dynamic>> _groupChats = [];
  List<Map<String, dynamic>> _pendingGroupChats = [];
  bool _isLoadingGroups = false;

  final _searchController = TextEditingController();
  String _searchQuery = '';  static const List<Color> _rainbowColors = [


    AppColors.auroraRed, AppColors.auroraOrange, AppColors.auroraYellow,


    AppColors.auroraGreen, AppColors.auroraCyan, AppColors.auroraBlue, AppColors.auroraPurple,
  ];

  LinearGradient _diagonalGradient(Size size) {
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(0.785398));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAllData();
    _subscribeToMessages();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _currentTabIndex = _tabController.index);
    if (_currentTabIndex == 0) _loadAllData();
    else if (_currentTabIndex == 1) _loadFriendsTab();
    else if (_currentTabIndex == 2) _loadGroupChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _friendSearchController.dispose();
    super.dispose();
  }

  void _subscribeToMessages() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase.channel('messages_screen_$userId')
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public',
        table: 'private_messages', callback: (_) => _loadAllData())
      .subscribe();
  }

  Future<void> _loadAllData() async {
    setState(() { _loadingMessages = true; _loadError = null; });
    try {
      await Future.wait([
        _loadFriendsList(), _loadLatestChatMessages(), _loadGroupChatsData(),
        _loadAnnouncements(), _loadNotifications(), _loadCommentRecords(),
      ]);
      _buildUnifiedMessages();
    } catch (e) {
      setState(() => _loadError = '加载失败: $e');
    } finally { setState(() => _loadingMessages = false); }
  }

  Future<void> _loadFriendsTab() async {
    await Future.wait([_loadFriendsList(), _loadFriendRequests(), _loadRecommendedUsers()]);
    setState(() {});
  }

  Future<void> _loadFriendsList() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoadingFriends = true);
    try {
      final res1 = await _supabase.from('follows').select('following_id,created_at')
        .eq('follower_id', userId).eq('status', 'active');
      final res2 = await _supabase.from('follows').select('follower_id,created_at')
        .eq('following_id', userId).eq('status', 'active');
      final s = <String>{};
      for (final r in (res1 as List)) s.add(r['following_id'] as String);
      for (final r in (res2 as List)) s.add(r['follower_id'] as String);
      if (s.isEmpty) { setState(() { _friendsList = []; _isLoadingFriends = false; }); return; }
      final p = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url,created_at').inFilter('user_id', s.toList());
      setState(() { _friendsList = List<Map<String, dynamic>>.from(p); _isLoadingFriends = false; });
    } catch (e) { setState(() => _isLoadingFriends = false); }
  }

  Future<void> _loadLatestChatMessages() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final pr = await _supabase.from('profiles').select('id').eq('user_id', userId).limit(1);
      if (pr.isEmpty) return;
      final myId = pr[0]['id'] as String;
      final msgs = await _supabase.from('private_messages')
        .select('sender_id,receiver_id,content,message_type,created_at,is_read')
        .or('sender_id.eq.$myId,receiver_id.eq.$myId')
        .order('created_at', ascending: false).limit(200);
      final lm = <String, Map<String, dynamic>>{};
      for (final m in msgs) {
        final oid = m['sender_id'] == myId ? m['receiver_id'] as String : m['sender_id'] as String;
        if (!lm.containsKey(oid)) {
          var dc = m['content']?.toString() ?? '';
          final mt = m['message_type']?.toString() ?? 'text';
          if (mt == 'image') dc = '[图片]'; else if (mt == 'voice') dc = '[语音]';
          else if (mt == 'faith_bubble') dc = '[信仰之光]';
          else if (dc.startsWith('[emoji:')) dc = '[表情]'; else if (dc.startsWith('[CALL_')) dc = '[通话]';
          final uc = msgs.where((x) => x['sender_id'] == oid && x['receiver_id'] == myId && x['is_read'] != true).length;
          lm[oid] = {'content': dc, 'time': m['created_at'], 'message_type': mt, 'unreadCount': uc};
        }
      }
      setState(() => _latestChatMessages = lm);
    } catch (_) {}
  }

  Future<void> _loadAnnouncements() async {
    try {
      final d = await _supabase.from('announcements')
        .select('id,title,content,type,is_pinned,is_active,created_at')
        .eq('is_active', true).order('is_pinned', ascending: false)
        .order('created_at', ascending: false).limit(50);
      _announcementsData = List<Map<String, dynamic>>.from(d);
    } catch (_) {}
  }

  Future<void> _loadNotifications() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final d = await _supabase.from('notifications')
        .select('id,type,title,content,is_read,created_at')
        .eq('user_id', uid).order('created_at', ascending: false).limit(50);
      _notificationsData = List<Map<String, dynamic>>.from(d);
    } catch (_) {}
  }

  Future<void> _loadCommentRecords() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final notes = await _supabase.from('posts').select('id,title').eq('user_id', uid);
      final nids = notes.map((n) => n['id'] as String).toList();
      if (nids.isEmpty) { _commentRecordsData = []; return; }
      final comms = await _supabase.from('comments')
        .select('id,post_id,user_id,content,created_at')
        .inFilter('post_id', nids).neq('user_id', uid)
        .order('created_at', ascending: false).limit(50);
      if (comms.isEmpty) { _commentRecordsData = []; return; }
      final cids = comms.map((c) => c['user_id'] as String).toSet().toList();
      final pros = await _supabase.from('profiles')
        .select('user_id,username,nickname,avatar_url').inFilter('user_id', cids);
      final pm = {for (final p in pros) p['user_id'] as String: p};
      final ntm = {for (final n in notes) n['id'] as String: n['title'] as String? ?? ''};
      _commentRecordsData = comms.map((c) {
        final pf = pm[c['user_id']] ?? {};
        return {'id': c['id'], 'post_id': c['post_id'], 'content': c['content'],
          'created_at': c['created_at'], 'commenter_username': pf['username'],
          'commenter_nickname': pf['nickname'], 'commenter_avatar_url': pf['avatar_url'],
          'note_title': ntm[c['post_id']] ?? ''};
      }).toList();
    } catch (_) {}
  }

  Future<void> _loadGroupChatsData() async => _loadGroupChats();
  Future<void> _loadGroupChats() async {
    setState(() => _isLoadingGroups = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      final mt = uid != null ? 'member_$uid' : '';
      final d = await _supabase.from('posts')
        .select('id,title,content,tags,user_id,heat_count,status,created_at')
        .order('heat_count', ascending: false).order('created_at', ascending: false).limit(100);
      final all = List<Map<String, dynamic>>.from(d);
      setState(() {
        _groupChats = all.where((p) {
          final t = (p['tags'] as List?)?.cast<String>() ?? [];
          if (!t.contains('__group_chat__') || p['status'] != 'published') return false;
          return mt.isNotEmpty && t.contains(mt);
        }).toList();
        _pendingGroupChats = all.where((p) {
          final t = (p['tags'] as List?)?.cast<String>() ?? [];
          if (!t.contains('__group_chat__') || p['status'] == 'published') return false;
          return mt.isNotEmpty && t.contains(mt);
        }).toList();
        _isLoadingGroups = false;
      });
    } catch (_) { setState(() => _isLoadingGroups = false); }
  }

  Future<void> _loadFriendRequests() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _isLoadingRequests = true);
    try {
      final d = await _supabase.from('follows')
        .select('follower_id,following_id,status,message,created_at')
        .eq('following_id', uid).eq('status', 'pending')
        .order('created_at', ascending: false).limit(20);
      final fids = (d as List).map((r) => r['follower_id'] as String).toList();
      if (fids.isEmpty) { setState(() { _friendRequests = []; _isLoadingRequests = false; }); return; }
      final pros = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url').inFilter('user_id', fids);
      setState(() {
        _friendRequests = d.map((rq) {
          final pf = (pros as List).firstWhere((p) => p['user_id'] == rq['follower_id'], orElse: () => {});
          return {...((pf as Map<String, dynamic>?) ?? {}), 'message': rq['message'], 'requestId': rq['follower_id']};
        }).toList();
        _isLoadingRequests = false;
      });
    } catch (_) { setState(() => _isLoadingRequests = false); }
  }

  Future<void> _loadRecommendedUsers() async {
    final uid = _supabase.auth.currentUser?.id;
    setState(() => _isLoadingRecommended = true);
    try {
      final d = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url,faith_tag,bio,created_at')
        .order('created_at', ascending: false).limit(50);
      var f = (d as List).map((e) => Map<String, dynamic>.from(e as Map))
        .where((u) => (u['user_id'] ?? u['id']) != uid).toList();
      f.shuffle(); f = f.take(10).toList();
      setState(() { _recommendedUsers = f; _isLoadingRecommended = false; });
      if (f.isNotEmpty) await _loadFollowingStatus(f.map<String>((u) => (u['user_id'] ?? u['id']) as String).toList());
    } catch (_) { setState(() => _isLoadingRecommended = false); }
  }

  Future<void> _loadFollowingStatus(List<String> uids) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || uids.isEmpty) return;
    try {
      final d = await _supabase.from('follows').select('following_id,status')
        .eq('follower_id', uid).inFilter('following_id', uids);
      final fo = <String>{}; final pe = <String>{};
      for (final r in d) {
        if (r['status'] == 'active') fo.add(r['following_id'] as String);
        else if (r['status'] == 'pending') pe.add(r['following_id'] as String);
      }
      setState(() { _followingIds = fo; _pendingRequests = pe; });
    } catch (_) {}
  }

  Future<void> _handleFriendSearch() async {
    final q = _friendSearchController.text.trim();
    if (q.isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      final r1 = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url,created_at')
        .ilike('username', '%$q%').order('created_at', ascending: false).limit(30);
      final r2 = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url,created_at')
        .ilike('nickname', '%$q%').order('created_at', ascending: false).limit(30);
      final um = <String, Map<String, dynamic>>{};
      for (final u in [...r1, ...r2]) um[u['id'] as String] = Map<String, dynamic>.from(u);
      final res = um.values.where((u) => (u['user_id'] ?? u['id']) != uid).toList();
      setState(() { _searchResults = res; _isSearching = false; });
      if (res.isNotEmpty) await _loadFollowingStatus(res.map<String>((u) => (u['user_id'] ?? u['id']) as String).toList());
    } catch (_) { setState(() => _isSearching = false); }
  }

  Future<void> _sendFriendRequest(String tid, String msg) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _sendingRequestId = tid);
    try {
      await _supabase.from('follows').insert({
        'follower_id': uid, 'following_id': tid, 'status': 'pending',
        if (msg.trim().isNotEmpty) 'message': msg.trim(),
      });
      setState(() { _pendingRequests.add(tid); _sendingRequestId = null; });
    } catch (_) { setState(() => _sendingRequestId = null); }
  }

  Future<void> _acceptFriendRequest(String rid) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _processingRequestId = rid);
    try {
      await _supabase.from('follows').update({'status': 'active'})
        .eq('follower_id', rid).eq('following_id', uid).eq('status', 'pending');
      setState(() {
        _friendRequests.removeWhere((r) => r['requestId'] == rid);
        _followingIds.add(rid); _processingRequestId = null;
      });
    } catch (_) { setState(() => _processingRequestId = null); }
  }

  Future<void> _rejectFriendRequest(String rid) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _processingRequestId = rid);
    try {
      await _supabase.from('follows').delete()
        .eq('follower_id', rid).eq('following_id', uid).eq('status', 'pending');
      setState(() { _friendRequests.removeWhere((r) => r['requestId'] == rid); _processingRequestId = null; });
    } catch (_) { setState(() => _processingRequestId = null); }
  }

  String _formatTime(String ds) {
    final d = DateTime.parse(ds); final now = DateTime.now(); final diff = now.difference(d);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${d.month}/${d.day}';
  }
  void _buildUnifiedMessages() {
    final msgs = <UnifiedMessage>[];
    for (final f in _friendsList) {
      final fid = f['user_id'] as String? ?? f['id'] as String;
      final lm = _latestChatMessages[fid];
      msgs.add(UnifiedMessage(id: 'private_$fid', type: 'private',
        title: f['nickname'] as String? ?? f['username'] as String? ?? '未命名用户',
        subtitle: lm != null ? lm['content'] as String : '点击开始聊天',
        avatar: f['avatar_url'] as String?, avatarType: 'user',
        time: lm != null ? _formatTime(lm['time'] as String) : _formatTime(f['created_at'] as String),
        timeRaw: lm != null ? lm['time'] as String : f['created_at'] as String,
        isRead: lm == null || (lm['unreadCount'] as int) == 0,
        badge: lm != null ? lm['unreadCount'] as int : 0, rawData: f));
    }
    for (final g in _groupChats) {
      msgs.add(UnifiedMessage(id: 'group_${g['id']}', type: 'group',
        title: g['title'] as String? ?? '群聊', subtitle: g['content'] as String? ?? '群聊',
        avatarType: 'group', time: _formatTime(g['created_at'] as String),
        timeRaw: g['created_at'] as String, isRead: true,
        badge: g['heat_count'] as int? ?? 0, rawData: g));
    }
    for (final a in _announcementsData) {
      msgs.add(UnifiedMessage(id: 'announcement_${a['id']}', type: 'announcement',
        title: '📢 ${a['title'] as String? ?? '公告'}', subtitle: a['content'] as String? ?? '',
        avatarType: 'system', time: _formatTime(a['created_at'] as String),
        timeRaw: a['created_at'] as String, isRead: false,
        isPinned: a['is_pinned'] as bool? ?? false, rawData: a));
    }
    for (final n in _notificationsData) {
      msgs.add(UnifiedMessage(id: 'notification_${n['id']}', type: 'notification',
        title: n['title'] as String? ?? '系统通知', subtitle: n['content'] as String? ?? '',
        avatarType: 'system', time: _formatTime(n['created_at'] as String),
        timeRaw: n['created_at'] as String,
        isRead: n['is_read'] as bool? ?? false, rawData: n));
    }
    if (_commentRecordsData.isNotEmpty) {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final c in _commentRecordsData) {
        grouped.putIfAbsent(c['post_id'] as String, () => []);
        grouped[c['post_id'] as String]!.add(c);
      }
      grouped.forEach((pid, cs) {
        cs.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
        final lt = cs.first;
        final nt = (lt['note_title'] as String?) ?? '你的笔记';
        final ntp = nt.length > 15 ? '${nt.substring(0, 15)}...' : nt;
        final ln = lt['commenter_nickname'] as String? ?? lt['commenter_username'] as String? ?? '某用户';
        msgs.add(UnifiedMessage(id: 'comment_group_$pid', type: 'comment', title: '评论',
          subtitle: cs.length == 1
            ? '$ln：${(lt['content'] as String?)?.replaceAll('\n', ' ') ?? ''}'
            : '$ln等${cs.length}条评论 - $ntp',
          avatarType: 'system', badge: cs.length,
          time: _formatTime(lt['created_at'] as String), timeRaw: lt['created_at'] as String,
          isRead: true, rawData: {'is_comment': true, 'post_id': pid, 'is_group': true,
            'comment_summaries': cs.map((c) => {
              'id': c['id'], 'username': c['commenter_nickname'] ?? c['commenter_username'] ?? '某用户',
              'avatar_url': c['commenter_avatar_url'],
              'content': (c['content'] as String?) != null && (c['content'] as String).length > 40
                ? '${(c['content'] as String).substring(0, 40)}...' : (c['content'] as String? ?? ''),
              'time': _formatTime(c['created_at'] as String),
            }).toList()}));
      });
    }
    msgs.sort((a, b) => b.timeRaw.compareTo(a.timeRaw));
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      msgs.removeWhere((m) => !m.title.toLowerCase().contains(q) && !m.subtitle.toLowerCase().contains(q));
    }
    setState(() => _unifiedMessages = msgs);
  }

  Widget _rainbowBordered({required Widget child, double radius = 12}) {
    return LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius + 2),
        gradient: _diagonalGradient(size)),
      padding: const EdgeInsets.all(2.0),
      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius),
        color: AppColors.bgColor), child: child),
    );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(child: Column(children: [
        _buildSearchBar(), _buildTabBar(),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _buildMessagesTab(), _buildFriendsTab(), _buildGroupsTab(), _buildRoomsTab(),
        ])),
      ])),
    );
  }

  Widget _buildSearchBar() {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(height: 40,
        decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Icon(Icons.search, size: 18, color: AppColors.textWeak),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: '搜索消息...',
              hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            onChanged: (v) { setState(() => _searchQuery = v); _buildUnifiedMessages(); })),
          if (_searchQuery.isNotEmpty) GestureDetector(onTap: () {
            _searchController.clear(); setState(() => _searchQuery = ''); _buildUnifiedMessages();
          }, child: Icon(Icons.close, size: 16, color: AppColors.textWeak)),
        ])));
  }

  Widget _buildTabBar() {
    const tabs = ['消息', '好友', '群聊', '房间'];
    return Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final isActive = _currentTabIndex == i;
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: isActive
              ? _rainbowBordered(radius: 20, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(tabs[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))))
              : GestureDetector(onTap: () => _tabController.animateTo(i),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.textPlaceholder)),
                    child: Text(tabs[i], style: TextStyle(color: AppColors.textWeak, fontSize: 14, fontWeight: FontWeight.w500)))),
          );
        })));
  }

  Widget _buildMessagesTab() {
    if (_loadingMessages) return const Center(child: CircularProgressIndicator(color: AppColors.rainbowEnd));
    if (_loadError != null && _unifiedMessages.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 48, color: AppColors.textWeak),
        const SizedBox(height: 12),
        Text('加载失败', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        _rainbowBordered(child: TextButton(onPressed: _loadAllData,
          child: const Text('重试', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
      ]));
    }
    if (_unifiedMessages.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.borderActive),
        const SizedBox(height: 12),
        Text('暂无消息', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 4),
        Text('暂无新消息，下拉刷新试试', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ]));
    }
    return RefreshIndicator(color: AppColors.rainbowEnd, onRefresh: _loadAllData,
      child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _unifiedMessages.length,
        itemBuilder: (context, index) => _buildUnifiedMessageItem(_unifiedMessages[index])));
  }

  Widget _buildUnifiedMessageItem(UnifiedMessage msg) {
    Widget av;
    final abg = msg.type == 'announcement' ? const AppColors.auroraOrange.withOpacity(0.15)
      : msg.type == 'notification' ? const AppColors.auroraPurple.withOpacity(0.15)
      : msg.type == 'comment' ? const AppColors.auroraGreen.withOpacity(0.15)
      : msg.type == 'group' ? const AppColors.auroraBlue.withOpacity(0.15)
      : const AppColors.auroraOrange.withOpacity(0.15);
    if (msg.avatar != null && msg.avatar!.isNotEmpty) {
      av = ClipOval(child: Image.network(msg.avatar!, width: 48, height: 48, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defAv(msg)));
    } else { av = _defAv(msg); }
    return Container(margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
        border: msg.type == 'announcement' ? const Border(left: BorderSide(color: AppColors.auroraOrange, width: 3)) : null),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => _handleMessageTap(msg),
          child: Padding(padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!msg.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6, right: 4),
                decoration: const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle))
              else const SizedBox(width: 12),
              Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: abg), child: av),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(msg.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14,
                    fontWeight: msg.type == 'announcement' ? FontWeight.w700 : FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (msg.badge > 0 && msg.type == 'private')
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [AppColors.auroraRed, Color(0xFFFF6B6B)])),
                      child: Text(msg.badge > 99 ? '99+' : '${msg.badge}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)))
                  else if (msg.badge > 0)
                    Text('🔥 ${msg.badge}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Text(msg.subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(msg.time, style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
              ])),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textPlaceholder),
            ])))));
  }

  Widget _defAv(UnifiedMessage msg) {
    final ic = msg.type == 'announcement' ? Icons.notifications_active
      : msg.type == 'notification' ? Icons.notifications
      : msg.type == 'comment' ? Icons.comment
      : msg.type == 'group' ? Icons.groups : Icons.person;
    final cl = msg.type == 'announcement' ? const AppColors.auroraOrange
      : msg.type == 'notification' ? const AppColors.auroraPurple
      : msg.type == 'comment' ? const AppColors.auroraGreen
      : msg.type == 'group' ? const AppColors.auroraBlue : const AppColors.auroraOrange;
    return Center(child: Icon(ic, size: 22, color: cl));
  }

  void _handleMessageTap(UnifiedMessage msg) {
    switch (msg.type) {
      case 'private':
        final fd = msg.rawData as Map<String, dynamic>;
        final tid = fd['user_id'] as String? ?? fd['id'] as String;
        final nm = fd['nickname'] as String? ?? fd['username'] as String? ?? '用户';
        Navigator.push(context, MaterialPageRoute(builder: (_) =>
          PrivateChatScreen(otherUserId: tid, otherUserName: nm)));
        break;
      case 'group':
        final gd = msg.rawData as Map<String, dynamic>;
        Navigator.push(context, MaterialPageRoute(builder: (_) =>
          GroupChatDetailScreen(groupData: gd)));
        break;
      case 'announcement':
        _showAnnDlg(msg.rawData as Map<String, dynamic>);
        break;
      case 'notification':
        if (!msg.isRead) {
          final n = msg.rawData as Map<String, dynamic>;
          _supabase.from('notifications').update({'is_read': true}).eq('id', n['id']);
        }
        break;
      default: break;
    }
  }

  void _showAnnDlg(Map<String, dynamic> ann) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.notifications_active, color: AppColors.auroraOrange, size: 22),
        SizedBox(width: 8),
        Text('公告详情', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      ]),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (ann['is_pinned'] == true) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: const AppColors.auroraOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Text('置顶', style: TextStyle(color: AppColors.auroraOrange, fontSize: 11))),
        Text(ann['title'] as String? ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(ann['content'] as String? ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 12),
        Text(_formatTime(ann['created_at'] as String), style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: Text('关闭', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))],
    ));
  }

  // TAB2: 好友
  Widget _buildFriendsTab() {
    final isSearch = _friendSearchController.text.trim().isNotEmpty;
    final du = isSearch ? _searchResults : _recommendedUsers;
    final fids = _friendsList.map((f) => f['user_id'] ?? f['id']).toSet();
    final fu = du.where((u) => !fids.contains(u['user_id'] ?? u['id'])).toList();
    return RefreshIndicator(color: AppColors.rainbowEnd, onRefresh: _loadFriendsTab,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        _buildFriendSearchBar(), const SizedBox(height: 12),
        if (_friendRequests.isNotEmpty) ...[_buildFriendReqSec(), const SizedBox(height: 12)],
        _buildFriendsListSec(), const SizedBox(height: 12),
        if (_isSearching || _isLoadingRecommended)
          const Padding(padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.rainbowEnd)))
        else if (fu.isNotEmpty) _buildRecSec(fu, isSearch)
        else if (isSearch) Padding(padding: const EdgeInsets.all(24),
          child: Center(child: Column(children: [
            Icon(Icons.person_search, size: 40, color: AppColors.borderActive),
            const SizedBox(height: 8),
            Text('未找到匹配的用户', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14)),
          ]))),
        const SizedBox(height: 24),
      ]));
  }

  Widget _buildFriendSearchBar() {
    return Row(children: [
      Expanded(child: Container(height: 40,
        decoration: BoxDecoration(color: AppColors.hoverBg, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Icon(Icons.search, size: 16, color: AppColors.textWeak),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _friendSearchController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: '搜索昵称、ID...',
              hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _handleFriendSearch())),
          if (_friendSearchController.text.isNotEmpty) GestureDetector(onTap: () {
            _friendSearchController.clear(); setState(() => _searchResults = []);
          }, child: Icon(Icons.close, size: 16, color: AppColors.textWeak)),
        ]))),
      const SizedBox(width: 8),
      _rainbowBordered(radius: 12, child: GestureDetector(onTap: _handleFriendSearch,
        child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
          child: _isSearching
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
            : const Text('搜索', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))))),
    ]);
  }

  Widget _buildFriendReqSec() {
    return _rainbowBordered(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppColors.bgColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(children: [
          const Icon(Icons.notifications, size: 14, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text('好友请求 (${_friendRequests.length})',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ])),
      if (_isLoadingRequests)
        const Padding(padding: EdgeInsets.all(12), child: Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))))
      else ...List.generate(_friendRequests.length, (i) {
        final rq = _friendRequests[i];
        final ip = _processingRequestId == rq['requestId'];
        return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: i < _friendRequests.length - 1
            ? Border(bottom: BorderSide(color: AppColors.borderColor)) : null),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.hoverBg),
              child: ClipOval(child: rq['avatar_url'] != null
                ? Image.network(rq['avatar_url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.textPlaceholder, size: 18))
                : const Icon(Icons.person, color: AppColors.textPlaceholder, size: 18))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rq['nickname'] as String? ?? rq['username'] as String? ?? '未命名用户',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              if (rq['message'] != null) Text(rq['message'] as String,
                style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(onTap: ip ? null : () => _acceptFriendRequest(rq['requestId'] as String),
                child: LayoutBuilder(builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 0.5, color: Colors.transparent),
                    gradient: _diagonalGradient(size)),
                  child: Text(ip ? '...' : '✓ 接受',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)));
                })),
              const SizedBox(width: 6),
              GestureDetector(onTap: ip ? null : () => _rejectFriendRequest(rq['requestId'] as String),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.borderColor),
                  child: Text(ip ? '...' : '✕ 拒绝',
                    style: TextStyle(color: AppColors.textWeak, fontSize: 12)))),
            ]),
          ]));
      }),
    ]));
  }

  Widget _buildFriendsListSec() {
    final sorted = List<Map<String, dynamic>>.from(_friendsList);
    sorted.sort((a, b) {
      final nA = (a['nickname'] as String? ?? a['username'] as String? ?? '').toLowerCase();
      final nB = (b['nickname'] as String? ?? b['username'] as String? ?? '').toLowerCase();
      return nA.compareTo(nB);
    });
    return Container(decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppColors.hoverBgLight),
          child: Row(children: [
            Icon(Icons.groups, size: 14, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text('我的好友 (${_friendsList.length})',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ])),
        if (_isLoadingFriends)
          const Padding(padding: EdgeInsets.all(16), child: Center(
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))))
        else if (sorted.isEmpty)
          Padding(padding: const EdgeInsets.all(12),
            child: Center(child: Text('暂无好友',
              style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12))))
        else ...List.generate(sorted.length, (i) {
          final f = sorted[i];
          final nm = f['nickname'] as String? ?? f['username'] as String? ?? '未命名用户';
          final fuid = f['user_id'] as String? ?? f['id'] as String;
          return Container(decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
            child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(width: 40, height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(child: f['avatar_url'] != null
                  ? Image.network(f['avatar_url'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20))
                  : const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20))),
              title: Text(nm, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.textPlaceholder),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                UserProfileScreen(userId: fuid))),
          ));
        }),
      ]));
  }

  Widget _buildRecSec(List<Map<String, dynamic>> users, bool isSearch) {
    return _rainbowBordered(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppColors.bgColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(children: [
          const Icon(Icons.person_add, size: 14, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(isSearch ? '搜索结果 (${users.length})' : '推荐用户 (${users.length})',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
      ...List.generate(users.length, (i) {
        final u = users[i];
        final uid = u['user_id'] ?? u['id'];
        final isF = _followingIds.contains(uid);
        final isP = _pendingRequests.contains(uid) || _sendingRequestId == uid;
        return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: i < users.length - 1
            ? Border(bottom: BorderSide(color: AppColors.borderColor)) : null),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.hoverBg),
              child: ClipOval(child: u['avatar_url'] != null
                ? Image.network(u['avatar_url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20))
                : const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Text(u['nickname'] as String? ?? u['username'] as String? ?? '未命名用户',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isF) Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check, size: 14, color: AppColors.textPlaceholder),
              const SizedBox(width: 4),
              Text('已添加', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ])
            else if (isP) Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5,
                color: AppColors.textWeak)),
              const SizedBox(width: 4),
              Text('待确认', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ])
            else GestureDetector(onTap: () => _showAddFriendDlg(u),
              child: LayoutBuilder(builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 0.5, color: Colors.transparent),
                  gradient: _diagonalGradient(size)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_add, size: 12, color: AppColors.textPrimary),
                  SizedBox(width: 4),
                  Text('添加', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                ]));
              })),
          ]));
      }),
    ]));
  }

  void _showAddFriendDlg(Map<String, dynamic> u) {
    final mc = TextEditingController(text: '你好，希望添加你为好友');
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderColor, width: 0.5)),
      title: const Text('添加好友', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.hoverBg),
              child: ClipOval(child: u['avatar_url'] != null
                ? Image.network(u['avatar_url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.textPlaceholder, size: 24))
                : const Icon(Icons.person, color: AppColors.textPlaceholder, size: 24))),
            const SizedBox(width: 12),
            Expanded(child: Text(u['nickname'] as String? ?? u['username'] as String? ?? '未命名用户',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          ])),
        TextField(controller: mc, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14), maxLines: 3,
          decoration: InputDecoration(hintText: '添加好友时发送的招呼语...',
            hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
            filled: true, fillColor: AppColors.bgSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('取消', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
        ElevatedButton(onPressed: () {
          _sendFriendRequest(u['user_id'] as String? ?? u['id'] as String, mc.text);
          Navigator.pop(context);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('发送请求', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
      ],
    ));
  }

  // TAB3: 群聊
  Widget _buildGroupsTab() {
    if (_isLoadingGroups) return const Center(child: CircularProgressIndicator(color: AppColors.rainbowEnd));
    if (_groupChats.isEmpty && _pendingGroupChats.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.groups, size: 56, color: AppColors.borderActive),
        const SizedBox(height: 12),
        Text('暂无群聊', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        _rainbowBordered(child: TextButton.icon(
          onPressed: () {}, icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 18),
          label: const Text('创建群聊', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
      ]));
    }
    return RefreshIndicator(color: AppColors.rainbowEnd, onRefresh: _loadGroupChats,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        if (_pendingGroupChats.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.auroraOrange),
            const SizedBox(width: 8),
            Text('待审核群聊 (${_pendingGroupChats.length})',
              style: const TextStyle(color: AppColors.auroraOrange, fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
          ..._pendingGroupChats.map((g) => _buildPendingGroupItem(g)),
          const SizedBox(height: 16),
        ],
        ..._groupChats.map((g) => _buildGroupItem(g)),
        const SizedBox(height: 12),
        _rainbowBordered(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () {},
          child: Container(padding: const EdgeInsets.all(16), alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('创建新群聊',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
            ])))),
        const SizedBox(height: 24),
      ]));
  }

  Widget _buildPendingGroupItem(Map<String, dynamic> g) {
    final tags = (g['tags'] as List?)?.cast<String>() ?? [];
    final dt = tags.where((t) => t != '__group_chat__').take(3).toList();
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.groups, color: AppColors.textSecondary, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(g['title'] as String? ?? '',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: g['status'] == 'pending'
                ? const AppColors.auroraOrange.withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text(g['status'] == 'pending' ? '待审核' : '已拒绝',
                style: TextStyle(color: g['status'] == 'pending' ? const AppColors.auroraOrange : const Color(0xFFEF4444), fontSize: 11))),
          ]),
          if (g['content'] != null) ...[const SizedBox(height: 4),
            Text(g['content'] as String, style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis)],
          if (dt.isNotEmpty) ...[const SizedBox(height: 8),
            Wrap(spacing: 4, children: dt.map<Widget>((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)))).toList())],
          const SizedBox(height: 8),
          Text('提交时间: ${_formatTime(g['created_at'] as String)}',
            style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
        ])),
      ]));
  }

  Widget _buildGroupItem(Map<String, dynamic> g) {
    final tags = (g['tags'] as List?)?.cast<String>() ?? [];
    final dt = tags.where((t) => t != '__group_chat__').take(3).toList();
    final hc = g['heat_count'] as int? ?? 0;
    return Container(margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>
            GroupChatDetailScreen(groupData: g)));
        },
          child: Padding(padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: const AppColors.auroraBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.groups, color: AppColors.textMuted, size: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(g['title'] as String? ?? '',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (hc > 0) Text('🔥 $hc', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
                if (g['content'] != null) ...[const SizedBox(height: 4),
                  Text(g['content'] as String, style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis)],
                if (dt.isNotEmpty) ...[const SizedBox(height: 8),
                  Wrap(spacing: 4, children: dt.map<Widget>((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(tag, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)))).toList())],
              ])),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textPlaceholder),
            ])))));
  }

  // TAB4: 房间
  Widget _buildRoomsTab() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [
          const AppColors.auroraBlue.withOpacity(0.15), const AppColors.auroraPurple.withOpacity(0.15)])),
        child: const Icon(Icons.meeting_room, size: 36, color: AppColors.auroraBlue)),
      const SizedBox(height: 20),
      Text('房间功能即将开放',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text('敬请期待，即将上线多人语音房间功能',
        style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
    ]));
  }
}

/// 统一消息模型
class UnifiedMessage {
  final String id, type, title, subtitle, time, timeRaw;
  final String? avatar, avatarType;
  final bool isRead, isPinned;
  final int badge;
  final dynamic rawData;
  UnifiedMessage({
    required this.id, required this.type, required this.title, required this.subtitle,
    this.avatar, this.avatarType, required this.time, required this.timeRaw,
    required this.isRead, this.isPinned = false, this.badge = 0, this.rawData,
  });
}