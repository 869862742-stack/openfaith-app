import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _sendingComment = false;

  int _likeCount = 0;
  int _commentCount = 0;
  int _viewsCount = 0;

  Map<String, dynamic>? _authorProfile;

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.post['likes_count'] as num?)?.toInt() ?? 0;
    _commentCount = (widget.post['comments_count'] as num?)?.toInt() ?? 0;
    _viewsCount = (widget.post['views_count'] as num?)?.toInt() ?? 0;
    _authorProfile = widget.post['profiles'] as Map<String, dynamic>?;
    _incrementViews();
    _loadComments();
    _checkLikeStatus();
    _checkBookmarkStatus();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 增加浏览次数
  Future<void> _incrementViews() async {
    try {
      final postId = widget.post['id'] as String;
      await _supabase
          .from('posts')
          .update({'views_count': _viewsCount + 1})
          .eq('id', postId);
    } catch (e) {
      debugPrint('增加浏览数失败: $e');
    }
  }

  /// 检查点赞状态
  Future<void> _checkLikeStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final postId = widget.post['id'] as String;
      final result = await _supabase
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();
      if (result != null) {
        setState(() => _isLiked = true);
      }
    } catch (e) {
      debugPrint('检查点赞状态失败: $e');
    }
  }

  /// 检查收藏状态
  Future<void> _checkBookmarkStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final postId = widget.post['id'] as String;
      final result = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();
      if (result != null) {
        setState(() => _isBookmarked = true);
      }
    } catch (e) {
      debugPrint('检查收藏状态失败: $e');
    }
  }

  /// 检查关注状态
  Future<void> _checkFollowStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final authorId = widget.post['user_id'] as String?;
      if (authorId == null || authorId == user.id) return;
      final result = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', authorId)
          .eq('status', 'active')
          .maybeSingle();
      if (result != null) {
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      debugPrint('检查关注状态失败: $e');
    }
  }

  /// 加载评论列表
  Future<void> _loadComments() async {
    try {
      final postId = widget.post['id'] as String;
      final response = await _supabase
          .from('comments')
          .select('*, profiles:user_id(nickname, username, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _comments = response != null
            ? List<Map<String, dynamic>>.from(response)
            : [];
        _loadingComments = false;
      });
    } catch (e) {
      debugPrint('加载评论失败: $e');
      setState(() => _loadingComments = false);
    }
  }

  /// 发送评论
  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _sendingComment = true);

    try {
      final postId = widget.post['id'] as String;
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'content': content,
      });

      // 更新评论计数
      await _supabase
          .from('posts')
          .update({'comments_count': _commentCount + 1})
          .eq('id', postId);

      _commentController.clear();
      setState(() {
        _commentCount += 1;
        _sendingComment = false;
      });
      _loadComments();
    } catch (e) {
      debugPrint('发送评论失败: $e');
      setState(() => _sendingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// 切换点赞
  Future<void> _toggleLike() async {
    try {
      final postId = widget.post['id'] as String;
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      if (_isLiked) {
        await _supabase.from('likes').delete().match({
          'user_id': user.id,
          'post_id': postId,
        });
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 9999999);
        });
      } else {
        await _supabase.from('likes').insert({
          'user_id': user.id,
          'post_id': postId,
        });
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      debugPrint('点赞操作失败: $e');
    }
  }

  /// 切换收藏
  Future<void> _toggleBookmark() async {
    try {
      final postId = widget.post['id'] as String;
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      if (_isBookmarked) {
        await _supabase.from('favorites').delete().match({
          'user_id': user.id,
          'post_id': postId,
        });
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'post_id': postId,
        });
      }

      setState(() => _isBookmarked = !_isBookmarked);
    } catch (e) {
      debugPrint('收藏操作失败: $e');
    }
  }

  /// 切换关注
  Future<void> _toggleFollow() async {
    try {
      final authorId = widget.post['user_id'] as String?;
      final user = _supabase.auth.currentUser;
      if (user == null || authorId == null) return;

      if (_isFollowing) {
        await _supabase.from('follows').delete().match({
          'follower_id': user.id,
          'following_id': authorId,
        });
      } else {
        await _supabase.from('follows').insert({
          'follower_id': user.id,
          'following_id': authorId,
          'status': 'active',
        });
      }

      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      debugPrint('关注操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _authorProfile;
    final nickname = _resolveNickname(profile);
    final avatarUrl = profile?['avatar_url'] as String?;
    final faithTag = profile?['faith_tag'] as String?;
    final title = widget.post['title'] as String? ?? '';
    final content = widget.post['content'] as String? ?? '';
    final coverImage = widget.post['cover_image'] as String?;
    final createdAt = widget.post['created_at'] as String?;
    final tags = _extractTags(widget.post);
    final isOwnPost = _supabase.auth.currentUser?.id == widget.post['user_id'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ====== 顶部导航栏 ======
          _buildAppBar(nickname, avatarUrl, faithTag, isOwnPost),

          // ====== 可滚动内容区 ======
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 标题
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 封面图
                  if (coverImage != null && coverImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCoverImage(coverImage),
                    ),

                  const SizedBox(height: 16),

                  // 正文内容
                  if (content.isNotEmpty)
                    Text(
                      content,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),

                  // 标签
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 数据统计行
                  const SizedBox(height: 20),
                  _buildStatsRow(),

                  // 分割线
                  const SizedBox(height: 16),
                  Container(height: 0.5, color: AppColors.borderColor),
                  const SizedBox(height: 16),

                  // 评论标题
                  Text(
                    '评论 ($_commentCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 评论列表
                  if (_loadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.rainbowEnd,
                        ),
                      ),
                    )
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        '暂无评论，来说两句吧~',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  else
                    ..._comments.map((c) => _buildCommentItem(c)),

                  const SizedBox(height: 100), // 底部留白
                ],
              ),
            ),
          ),

          // ====== 底部固定操作栏 ======
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildAppBar(String nickname, String? avatarUrl, String? faithTag, bool isOwnPost) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 返回按钮
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),

            // 作者头像
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inputBg,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(Icons.person, size: 16, color: Colors.white54)
                  : null,
            ),

            const SizedBox(width: 10),

            // 昵称 + 信仰标签
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (faithTag != null && faithTag.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.rainbowStart, AppColors.rainbowEnd],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            faithTag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _formatDate(widget.post['created_at'] as String?),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // 关注按钮（非自己的帖子时显示）
            if (!isOwnPost)
              GestureDetector(
                onTap: _toggleFollow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: _isFollowing
                        ? null
                        : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,colors: AppColors.rainbowColors),
                    color: _isFollowing ? Colors.white.withOpacity(0.08) : null,
                    border: _isFollowing
                        ? Border.all(color: Colors.white.withOpacity(0.15))
                        : null,
                  ),
                  child: Text(
                    _isFollowing ? '已关注' : '关注',
                    style: TextStyle(
                      color: _isFollowing ? AppColors.textSecondary : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 数据统计行
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(Icons.visibility_outlined, _viewsCount, AppColors.textMuted),
        const SizedBox(width: 16),
        _buildStatItem(Icons.chat_bubble_outline, _commentCount, AppColors.textMuted),
        const SizedBox(width: 16),
        _buildStatItem(Icons.local_fire_department, _computeHotValue(), AppColors.rainbowEnd),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          _formatCount(value),
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  int _computeHotValue() {
    final views = (widget.post['views_count'] as num?)?.toInt() ?? 0;
    final heat = (widget.post['heat_count'] as num?)?.toInt() ?? 0;
    final comments = (widget.post['comments_count'] as num?)?.toInt() ?? 0;
    final shares = (widget.post['shares_count'] as num?)?.toInt() ?? 0;
    final favorites = (widget.post['favorites_count'] as num?)?.toInt() ?? 0;
    return (views * 0.5 + heat * 5 + comments * 2 + shares * 3 + favorites * 2).toInt();
  }

  /// 底部操作栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 评论输入框
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderColor, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: '说点什么...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: _sendingComment ? null : _sendComment,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _sendingComment
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.rainbowEnd,
                                    ),
                                  )
                                : ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: AppColors.rainbowColors,
                                    ).createShader(bounds),
                                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 互动按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(_likeCount),
                  color: _isLiked ? AppColors.accentRed : AppColors.textMuted,
                  onTap: _toggleLike,
                ),
                _buildBottomAction(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(_commentCount),
                  color: AppColors.textMuted,
                  onTap: () {
                    // 滚动到评论区
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
                _buildBottomAction(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: '收藏',
                  color: _isBookmarked ? AppColors.rainbowEnd : AppColors.textMuted,
                  onTap: _toggleBookmark,
                ),
                _buildBottomAction(
                  icon: Icons.share_outlined,
                  label: '分享',
                  color: AppColors.textMuted,
                  onTap: () {
                    // TODO: 调用系统分享
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 评论项
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final nickname = profile?['nickname'] ?? profile?['username'] ?? '匿名';
    final avatarUrl = profile?['avatar_url'] as String?;
    final content = comment['content'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.inputBg,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, size: 14, color: Colors.white54)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 封面图
  Widget _buildCoverImage(String coverImage) {
    if (coverImage.startsWith('data:image/')) {
      try {
        final base64Data = coverImage.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, width: double.infinity, fit: BoxFit.cover);
      } catch (e) {
        return const SizedBox.shrink();
      }
    } else if (coverImage.startsWith('http://') || coverImage.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: coverImage,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: AppColors.inputBg,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rainbowEnd),
          ),
        ),
        errorWidget: (context, url, error) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  // ====== 工具方法 ======

  String _resolveNickname(Map<String, dynamic>? profile) {
    final raw = profile?['nickname'] ?? profile?['username'] ?? '';
    if (raw.toString().startsWith('member_') ||
        (raw.toString().contains('-') && raw.toString().length > 20)) {
      return '匿名';
    }
    return raw.toString().isEmpty ? '匿名' : raw.toString();
  }

  List<String> _extractTags(Map<String, dynamic> post) {
    return (post['tags'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .where((t) =>
                !t.startsWith('__') &&
                !t.startsWith('member_') &&
                !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(t) &&
                t.isNotEmpty)
            .toList() ??
        [];
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 30) return '${diff.inDays}天前';
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatCount(int count) {
    if (count > 999999) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count > 999) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
