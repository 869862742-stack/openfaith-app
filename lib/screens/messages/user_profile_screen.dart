import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import 'private_chat_screen.dart';

/// 用户/好友详情页 - 对齐网页版 UserProfile.tsx / Profile.tsx
class UserProfileScreen extends StatefulWidget {
  final String userId; // auth.uid (user_id in profiles)

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
  bool _loading = true;
  bool _loadingPosts = true;
  bool _loadingFavorites = true;
  String? _currentUserId;
  String? _profileId;  static const List<Color> _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),


    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.width, size.height) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

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

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url,faith_tag,bio,created_at')
        .eq('user_id', widget.userId)
        .limit(1);
      if (res.isNotEmpty) {
        setState(() {
          _profile = Map<String, dynamic>.from(res[0]);
          _profileId = _profile!['id'] as String?;
          _loading = false;
        });
        _loadUserPosts();
        _loadFavoritePosts();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFollowStatus() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;
    try {
      final res = await _supabase.from('follows')
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
    } catch (_) {}
  }

  Future<void> _loadUserPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final res = await _supabase.from('posts')
        .select('id,title,content,tags,heat_count,status,created_at')
        .eq('user_id', widget.userId)
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .limit(50);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(res);
        _loadingPosts = false;
      });
    } catch (_) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadFavoritePosts() async {
    setState(() => _loadingFavorites = true);
    try {
      final favRes = await _supabase.from('post_likes')
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
      final posts = await _supabase.from('posts')
        .select('id,title,content,tags,heat_count,status,created_at,user_id')
        .inFilter('id', postIds)
        .eq('status', 'published')
        .order('created_at', ascending: false);
      setState(() {
        _favoritePosts = List<Map<String, dynamic>>.from(posts);
        _loadingFavorites = false;
      });
    } catch (_) {
      try {
        final favRes = await _supabase.from('favorites')
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
        final posts = await _supabase.from('posts')
          .select('id,title,content,tags,heat_count,status,created_at,user_id')
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

  Future<void> _toggleFollow() async {
    if (_currentUserId == null) return;
    if (_isFollowing) {
      try {
        await _supabase.from('follows').delete()
          .eq('follower_id', _currentUserId!)
          .eq('following_id', widget.userId)
          .eq('status', 'active');
        setState(() => _isFollowing = false);
      } catch (_) {}
    } else {
      try {
        await _supabase.from('follows').insert({
          'follower_id': _currentUserId!,
          'following_id': widget.userId,
          'status': 'active',
        });
        setState(() => _isFollowing = true);
      } catch (_) {}
    }
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
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        title: const Text('添加好友',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              _buildAvatar(40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _profile?['nickname'] as String? ??
                      _profile?['username'] as String? ??
                      '未命名用户',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
          TextField(
            controller: mc,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '添加好友时发送的招呼语...',
              hintStyle: const TextStyle(color: Color(0xFF484F58), fontSize: 14),
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
            child: const Text('取消',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('发送请求',
                style: TextStyle(color: Colors.white, fontSize: 14)),
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
            const SnackBar(
              content: Text('好友请求已发送'),
              backgroundColor: Color(0xFF1A1F36),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('发送失败，请重试'),
              backgroundColor: Color(0xFF1A1F36),
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

  Widget _buildAvatar(double size) {
    final avatarUrl = _profile?['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              width: 0.7, color: const Color(0xFFFF4D6D).withOpacity(0.5)),
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.person, color: const Color(0xFF484F58), size: size * 0.5),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
            width: 0.7, color: const Color(0xFFFF4D6D).withOpacity(0.5)),
      ),
      child: Center(
        child:
            Icon(Icons.person, color: const Color(0xFF484F58), size: size * 0.5),
      ),
    );
  }

  Widget _rainbowBordered({required Widget child, double radius = 12}) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius + 1),
          gradient: _diagonalGradient(size),
        ),
        padding: const EdgeInsets.all(0.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.bgColor,
          ),
          child: child,
        ),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.rainbowEnd),
        ),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: AppBar(
          backgroundColor: AppColors.bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('用户不存在',
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ),
      );
    }

    final isSelf = _currentUserId == widget.userId;
    final nickname = _profile!['nickname'] as String? ??
        _profile!['username'] as String? ??
        '未命名用户';
    final username = _profile!['username'] as String? ?? '';
    final faithTag = _profile!['faith_tag'] as String?;
    final bio = _profile!['bio'] as String?;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF8B949E)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHeader(nickname, username, faithTag, bio, isSelf),
          const SizedBox(height: 16),
          if (!isSelf) _buildActionButtons(),
          if (!isSelf) const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.of(context).size.height - 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildFavoritesTab(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildHeader(String nickname, String username, String? faithTag,
      String? bio, bool isSelf) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        _buildAvatar(80),
        const SizedBox(height: 16),
        Text(nickname,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 4),
        Text('@$username',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 8),
        if (faithTag != null && faithTag.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C)],
              ),
            ),
            child: Text(faithTag,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        const SizedBox(height: 12),
        if (bio != null && bio.isNotEmpty)
          Text(bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              )),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Expanded(
          child: _rainbowBordered(
            radius: 12,
            child: GestureDetector(
              onTap: _goToChat,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('发消息',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _isFollowing
                ? _toggleFollow
                : _isPending
                    ? null
                    : _sendFriendRequest,
            child:LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isFollowing || _isPending
                    ? Colors.white.withOpacity(0.06)
                    : null,
                gradient: _isFollowing || _isPending
                    ? null
                    : _diagonalGradient(size),
              ),
              child: _isFollowing
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check,
                          color: Color(0xFF484F58), size: 16),
                      const SizedBox(width: 4),
                      Text('已关注',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14)),
                    ])
                  : _isPending
                      ? Text('请求已发送',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('加好友',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
            );
    }),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
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
    final isActive = _tabController.index == index;
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
                color: active
                    ? Colors.white.withOpacity(0.08)
                    : Colors.transparent,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon,
                    size: 16,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                    )),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_loadingPosts) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.rainbowEnd));
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.article,
              size: 40, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 8),
          Text('暂无帖子',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.rainbowEnd,
      onRefresh: _loadUserPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _posts.length,
        itemBuilder: (context, index) => _buildPostItem(_posts[index]),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_loadingFavorites) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.rainbowEnd));
    }
    if (_favoritePosts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bookmark_border,
              size: 40, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 8),
          Text('暂无收藏',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.rainbowEnd,
      onRefresh: _loadFavoritePosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _favoritePosts.length,
        itemBuilder: (context, index) =>
            _buildPostItem(_favoritePosts[index]),
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
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
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          if (content.isNotEmpty && content != title) ...[
            const SizedBox(height: 6),
            Text(content,
                style:
                    const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
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
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            if (heatCount > 0)
              Text('🔥 $heatCount',
                  style:
                      const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
            const Spacer(),
            Text(_formatTime(createdAt),
                style:
                    const TextStyle(color: Color(0xFF484F58), fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}
