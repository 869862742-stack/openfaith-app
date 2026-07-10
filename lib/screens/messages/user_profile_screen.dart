import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import 'private_chat_screen.dart';

/// 用户/好友详情页 - 对齐网页版 UserProfile.tsx
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _favoritePosts = [];
  bool _isFollowing = false;
  bool _isPending = false;
  bool _isFriend = false;
  bool _accessDenied = false;
  bool _loading = true;
  bool _loadingPosts = true;
  bool _loadingFavorites = true;
  bool _followLoading = false;
  String? _currentUserId;
  String? _profileId;

  // 计数
  int _followersCount = 0;
  int _followingCount = 0;
  int _heatCount = 0;
  int _hotPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadProfile();
    _loadFollowStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===== 数据加载 =====

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', widget.userId)
          .limit(1);
      if (res.isNotEmpty) {
        final profile = Map<String, dynamic>.from(res[0]);
        setState(() {
          _profile = profile;
          _profileId = profile['id'] as String?;
          _hotPoints = (profile['hot_points'] as num?)?.toInt() ?? 0;
        });

        // 检查访问权限
        final hasAccess = await _checkAccessPermission(profile);
        if (!hasAccess) {
          setState(() {
            _accessDenied = true;
            _loading = false;
          });
          return;
        }

        // 获取真实计数
        await _loadFollowCounts();
        _loadUserPosts();
        _loadFavoritePosts();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('loadProfile error: $e');
      setState(() => _loading = false);
    }
  }

  Future<bool> _checkAccessPermission(Map<String, dynamic> profile) async {
    if (_currentUserId == null || _currentUserId == widget.userId) return true;
    if (profile['allow_stranger_visit'] != false) return true;

    try {
      final followRes = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', _currentUserId!)
          .eq('following_id', widget.userId)
          .eq('status', 'active')
          .limit(1);
      final reverseFollowRes = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', widget.userId)
          .eq('following_id', _currentUserId!)
          .eq('status', 'active')
          .limit(1);

      final isMutual = followRes.isNotEmpty && reverseFollowRes.isNotEmpty;
      if (profile['allow_friend_visit'] != false && isMutual) return true;
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      final followersRes = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', widget.userId)
          .eq('status', 'active');
      final followingRes = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', widget.userId)
          .eq('status', 'active');
      setState(() {
        _followersCount = followersRes.length;
        _followingCount = followingRes.length;
      });
    } catch (_) {}
  }

  Future<void> _loadFollowStatus() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;
    try {
      final res = await _supabase
          .from('follows')
          .select('status')
          .eq('follower_id', _currentUserId!)
          .eq('following_id', widget.userId)
          .limit(1);
      if (res.isNotEmpty) {
        final status = res[0]['status'] as String?;
        setState(() {
          _isFollowing = status == 'active';
          _isPending = status == 'pending';
        });
      }
      // 检查是否是好友（双向关注）
      if (_isFollowing) {
        final reverse = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', widget.userId)
            .eq('following_id', _currentUserId!)
            .eq('status', 'active')
            .limit(1);
        setState(() => _isFriend = reverse.isNotEmpty);
      }
    } catch (_) {}
  }

  Future<void> _loadUserPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final res = await _supabase
          .from('posts')
          .select(
              'id,title,cover_image,tags,heat_count,likes_count,comments_count,views_count,shares_count,favorites_count,status,created_at')
          .eq('user_id', widget.userId)
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(50);
      final posts = List<Map<String, dynamic>>.from(res);
      // 计算热值
      int heat = 0;
      for (final p in posts) {
        heat += _calcHotValue(p);
      }
      setState(() {
        _posts = posts;
        _heatCount = heat;
        _loadingPosts = false;
      });
    } catch (_) {
      setState(() => _loadingPosts = false);
    }
  }

  int _calcHotValue(Map<String, dynamic> note) {
    final views = (note['views_count'] as num?)?.toInt() ?? 0;
    final heat = (note['heat_count'] as num?)?.toInt() ?? 0;
    final comments = (note['comments_count'] as num?)?.toInt() ?? 0;
    final shares = (note['shares_count'] as num?)?.toInt() ?? 0;
    final favorites = (note['favorites_count'] as num?)?.toInt() ?? 0;
    return (views * 0.5 + heat * 5 + comments * 2 + shares * 3 + favorites * 2)
        .toInt();
  }

  Future<void> _loadFavoritePosts() async {
    setState(() => _loadingFavorites = true);
    try {
      final favRes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', widget.userId)
          .limit(50);
      if (favRes.isEmpty) {
        setState(() {
          _favoritePosts = [];
          _loadingFavorites = false;
        });
        return;
      }
      final postIds = favRes.map((r) => r['post_id'] as String).toList();
      final posts = await _supabase
          .from('posts')
          .select(
              'id,title,cover_image,tags,heat_count,likes_count,comments_count,status,created_at,user_id')
          .inFilter('id', postIds)
          .eq('status', 'published')
          .order('created_at', ascending: false);
      setState(() {
        _favoritePosts = List<Map<String, dynamic>>.from(posts);
        _loadingFavorites = false;
      });
    } catch (_) {
      try {
        final favRes = await _supabase
            .from('favorites')
            .select('post_id')
            .eq('user_id', widget.userId)
            .limit(50);
        if (favRes.isEmpty) {
          setState(() {
            _favoritePosts = [];
            _loadingFavorites = false;
          });
          return;
        }
        final postIds = favRes.map((r) => r['post_id'] as String).toList();
        final posts = await _supabase
            .from('posts')
            .select(
                'id,title,cover_image,tags,heat_count,likes_count,comments_count,status,created_at,user_id')
            .inFilter('id', postIds)
            .eq('status', 'published')
            .order('created_at', ascending: false);
        setState(() {
          _favoritePosts = List<Map<String, dynamic>>.from(posts);
          _loadingFavorites = false;
        });
      } catch (_) {
        setState(() {
          _favoritePosts = [];
          _loadingFavorites = false;
        });
      }
    }
  }

  // ===== 操作 =====

  Future<void> _toggleFollow() async {
    if (_currentUserId == null) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', _currentUserId!)
            .eq('following_id', widget.userId)
            .eq('status', 'active');
        setState(() {
          _isFollowing = false;
          _followersCount = max(0, _followersCount - 1);
        });
      } else {
        await _supabase.from('follows').insert({
          'follower_id': _currentUserId!,
          'following_id': widget.userId,
          'status': 'active',
        });
        setState(() => _isFollowing = true);
        await _loadFollowCounts();
      }
    } catch (_) {}
    setState(() => _followLoading = false);
  }

  Future<void> _sendFriendRequest() async {
    if (_currentUserId == null) return;
    final mc = TextEditingController(text: '你好，希望添加你为好友');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
        title: const Text('添加好友',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              _buildAvatarWidget(40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _profile?['nickname'] as String? ??
                      _profile?['username'] as String? ??
                      '未命名用户',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
          TextField(
            controller: mc,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '添加好友时发送的招呼语...',
              hintStyle:
                  const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消',
                style:
                    TextStyle(color: AppColors.textWeak, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('发送请求',
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _supabase.from('follows').insert({
          'follower_id': _currentUserId!,
          'following_id': widget.userId,
          'status': 'pending',
          if (mc.text.trim().isNotEmpty) 'message': mc.text.trim(),
        });
        setState(() {
          _isPending = true;
          _isFollowing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('好友请求已发送'),
              backgroundColor: AppColors.bgSecondary,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('发送失败，请重试'),
              backgroundColor: AppColors.bgSecondary,
            ),
          );
        }
      }
    }
  }

  void _goToChat() {
    final name = _profile?['nickname'] as String? ??
        _profile?['username'] as String? ??
        '用户';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(
          otherUserId: widget.userId,
          otherUserName: name,
        ),
      ),
    );
  }

  // ===== 工具 =====

  String _formatCount(int num) {
    if (num < 10000) return '$num';
    final wan = num / 10000;
    if (wan < 10) {
      return wan % 1 == 0 ? '${wan.toInt()}W' : '${wan.toStringAsFixed(1)}W';
    }
    return '${wan.floor()}W';
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

  // ===== UI 组件 =====

  /// 头像（带七彩渐变边框环）- 对齐网页版
  Widget _buildAvatarWidget(double size) {
    final avatarUrl = _profile?['avatar_url'] as String?;
    final isVip = _profile?['is_vip'] == true;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isVip ? AppColors.auroraGradient : null,
        border: isVip
            ? null
            : Border.all(
                width: 0.7, color: AppColors.auroraRed.withOpacity(0.5)),
      ),
      padding: isVip ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, __, ___) => _avatarPlaceholder(size),
                )
              : _avatarPlaceholder(size),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
      color: AppColors.bgSecondary,
      child: Center(
        child: Icon(Icons.person,
            color: AppColors.textPlaceholder, size: size * 0.5),
      ),
    );
  }

  /// 返回按钮 - 网页版样式
  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textSecondary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.bgColor, size: 20),
        ),
      ),
    );
  }

  /// 统计数字项
  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 笔记网格卡片 - 对齐网页版 2 列网格 + 封面图 + 底部渐变遮罩
  Widget _buildPostGridItem(Map<String, dynamic> post) {
    final title = post['title'] as String? ?? '';
    final coverImage = post['cover_image'] as String?;
    final likesCount = (post['likes_count'] as num?)?.toInt() ?? 0;
    final commentsCount = (post['comments_count'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () {
        // TODO: open post detail
      },
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.bgSecondary,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 封面图
              if (coverImage != null && coverImage.isNotEmpty)
                Image.network(
                  coverImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image,
                      color: AppColors.textPlaceholder, size: 32),
                )
              else
                Center(
                  child: Icon(Icons.article,
                      color: AppColors.textPlaceholder, size: 32),
                ),
              // 底部渐变遮罩
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite,
                                  size: 12,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                _formatCount(likesCount),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble,
                                  size: 12,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                _formatCount(commentsCount),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 帖子列表项（用于收藏 tab）
  Widget _buildPostListItem(Map<String, dynamic> post) {
    final title = post['title'] as String? ?? '';
    final content = post['content'] as String? ?? '';
    final heatCount = post['heat_count'] as int? ?? 0;
    final createdAt = post['created_at'] as String? ?? '';
    final tags = (post['tags'] as List?)?.cast<String>() ?? [];
    final displayTags = tags
        .where((t) => !t.startsWith('__') && t.length < 20)
        .take(3)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          if (content.isNotEmpty && content != title) ...[
            const SizedBox(height: 6),
            Text(content,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          if (displayTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: displayTags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            if (heatCount > 0)
              Text('🔥 $heatCount',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            Text(_formatTime(createdAt),
                style:
                    const TextStyle(color: AppColors.textWeak, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    // 加载中
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.auroraOrange),
        ),
      );
    }

    // 访问被拒绝
    if (_accessDenied) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgSecondary,
                  ),
                  child: const Icon(Icons.lock,
                      color: AppColors.auroraPurple, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  '该用户未开放主页',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '该用户设置了隐私保护，暂不允许访问主页',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.auroraCyan,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('返回',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 用户不存在
    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('用户不存在',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.auroraCyan,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('返回',
                      style:
                          TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isSelf = _currentUserId == widget.userId;
    final nickname = _profile!['nickname'] as String? ??
        _profile!['username'] as String? ??
        '用户';
    final faithTag = _profile!['faith_tag'] as String?;
    final bio = _profile!['bio'] as String?;
    final bgUrl = _profile!['background_url'] as String?;
    final isVip = _profile!['is_vip'] == true;
    final level = (_profile!['level'] as num?)?.toInt() ?? 1;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ===== 背景区域 + 返回按钮 =====
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // 背景图区域（h-36 = 144px）
                Container(
                  height: 144 + MediaQuery.of(context).padding.top,
                  color: AppColors.bgSecondary,
                  child: bgUrl != null && bgUrl.isNotEmpty
                      ? Image.network(
                          bgUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        )
                      : null,
                ),
                // 返回按钮
                _buildBackButton(),
              ],
            ),
          ),

          // ===== 头像 + 信息区 =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 头像行：头像 + 名字 + 操作按钮
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 头像（向上偏移 -mt-16 = -64px 的一半）
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: _buildAvatarWidget(96),
                      ),
                      const SizedBox(width: 12),
                      // 名字 + 标签
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nickname,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isVip) ...[
                                  const SizedBox(width: 6),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        AppColors.auroraGradient
                                            .createShader(bounds),
                                    child: const Icon(Icons.shield,
                                        size: 16, color: AppColors.textPrimary),
                                  ),
                                ],
                              ],
                            ),
                            if (faithTag != null && faithTag.isNotEmpty)
                              const SizedBox(height: 4),
                            if (faithTag != null && faithTag.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.hoverBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  faithTag,
                                  style: const TextStyle(
                                    color: AppColors.auroraCyan,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // 操作按钮
                      if (!isSelf) ...[
                        // 发消息圆形按钮
                        GestureDetector(
                          onTap: _goToChat,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgSecondary,
                            ),
                            child: const Icon(Icons.chat_bubble_outline,
                                color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 关注按钮
                        GestureDetector(
                          onTap: _followLoading
                              ? null
                              : _isFollowing
                                  ? _toggleFollow
                                  : _toggleFollow,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _isFollowing
                                  ? Colors.transparent
                                  : AppColors.auroraCyan,
                              border: Border.all(
                                color: _isFollowing
                                    ? AppColors.borderColor
                                    : AppColors.auroraCyan,
                              ),
                            ),
                            child: Text(
                              _followLoading
                                  ? '...'
                                  : (_isFollowing ? '已关注' : '关注'),
                              style: TextStyle(
                                color: _isFollowing
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 个人简介
                  if (bio != null && bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        bio,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  // 统计信息 - 水平 4 项
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(
                            _formatCount(_followersCount), '粉丝'),
                        const SizedBox(width: 24),
                        _buildStatItem(
                            _formatCount(_followingCount), '关注'),
                        const SizedBox(width: 24),
                        _buildStatItem(
                            _formatCount(_heatCount), '热值'),
                        const SizedBox(width: 24),
                        _buildStatItem(
                            _formatCount(_hotPoints), '热点'),
                      ],
                    ),
                  ),

                  // 等级
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'LV.$level',
                        style: const TextStyle(
                          color: AppColors.auroraCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== 笔记列表标题 =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                '${isSelf ? '我的笔记' : '他的笔记'} (${_posts.length})',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ===== 笔记 2 列网格 =====
          if (_posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text('暂无笔记',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostGridItem(_posts[index]),
                  childCount: _posts.length,
                ),
              ),
            ),

          // ===== Tab 区域（帖子 + 收藏）=====
          SliverToBoxAdapter(
            child: _buildTabBar(),
          ),

          // ===== Tab 内容 =====
          SliverFillRemaining(
            hasScrollBody: false,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(), // 收藏
                _buildFavoritesTab(), // 第二个 tab 也用收藏
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 切换栏
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          _buildTabItem('帖子', 0, Icons.article),
          _buildTabItem('收藏', 1, Icons.bookmark_border),
        ]),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: ListenableBuilder(
          listenable: _tabController,
          builder: (context, _) {
            final active = _tabController.index == index;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color:
                    active ? AppColors.hoverBg : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 16,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textPlaceholder),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textPlaceholder,
                        fontSize: 14,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_loadingFavorites) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.auroraPurple));
    }
    if (_favoritePosts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bookmark_border,
              size: 40, color: AppColors.textPlaceholder),
          const SizedBox(height: 8),
          Text('暂无收藏',
              style: TextStyle(
                  color: AppColors.textPlaceholder, fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.auroraPurple,
      onRefresh: _loadFavoritePosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _favoritePosts.length,
        itemBuilder: (context, index) =>
            _buildPostListItem(_favoritePosts[index]),
      ),
    );
  }
}
