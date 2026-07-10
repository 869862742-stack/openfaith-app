import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/api_cache.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import '../../utils/emoji_icons.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String? highlightCommentId;

  const PostDetailScreen({super.key, required this.post, this.highlightCommentId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _pageController = PageController();

  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _sendingComment = false;

  // ══════ 评论高亮 ══════
  String? _highlightedCommentId;
  bool _isHighlighting = false;

  // ══════ EXP 动画 ══════
  AnimationController? _expAnimController;
  Animation<Offset>? _expSlideAnimation;
  Animation<double>? _expFadeAnimation;
  OverlayEntry? _expOverlayEntry;

  void _showExpAnimation(int amount) {
    _expOverlayEntry?.remove();
    _expAnimController?.dispose();

    _expAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _expSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _expAnimController!,
      curve: Curves.easeOut,
    ));
    _expFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _expAnimController!,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _expOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.12,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedBuilder(
            animation: _expAnimController!,
            builder: (context, child) {
              return Opacity(
                opacity: _expFadeAnimation!.value,
                child: FractionalTranslation(
                  translation: _expSlideAnimation!.value,
                  child: Text(
                    '+$amount EXP',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_expOverlayEntry!);
    _expAnimController!.forward().then((_) {
      _expOverlayEntry?.remove();
      _expOverlayEntry = null;
    });
  }

  int _likeCount = 0;
  int _commentCount = 0;
  int _viewsCount = 0;
  int _heatCount = 0;
  int _currentPageImage = 0;

  Map<String, dynamic>? _authorProfile;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.post['likes_count'] as num?)?.toInt() ?? 0;
    _commentCount = (widget.post['comments_count'] as num?)?.toInt() ?? 0;
    _viewsCount = (widget.post['views_count'] as num?)?.toInt() ?? 0;
    _heatCount = (widget.post['heat_count'] as num?)?.toInt() ?? 0;
    _authorProfile = widget.post['profiles'] as Map<String, dynamic>?;
    _images = _extractImages(widget.post);
    _incrementViews();
    _loadCommentsAndHighlight();
    _checkLikeStatus();
    _checkBookmarkStatus();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _expAnimController?.dispose();
    _expOverlayEntry?.remove();
    super.dispose();
  }

  List<String> _extractImages(Map<String, dynamic> post) {
    final imgs = post['images'];
    if (imgs is List && imgs.isNotEmpty) {
      return imgs.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final cover = post['cover_image'] as String?;
    if (cover != null && cover.isNotEmpty) return [cover];
    return [];
  }

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
        if (!mounted) return;
        setState(() => _isLiked = true);
      }
    } catch (e) {
      debugPrint('检查点赞状态失败: $e');
    }
  }

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
        if (!mounted) return;
        setState(() => _isBookmarked = true);
      }
    } catch (e) {
      debugPrint('收藏状态失败: $e');
    }
  }

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
        if (!mounted) return;
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      debugPrint('关注状态失败: $e');
    }
  }

  /// 加载评论并处理高亮定位
  Future<void> _loadCommentsAndHighlight() async {
    await _loadComments();
    if (widget.highlightCommentId != null && widget.highlightCommentId!.isNotEmpty && _comments.isNotEmpty) {
      final idx = _comments.indexWhere((c) => c['id'] == widget.highlightCommentId);
      if (idx != -1) {
        // 延迟一帧确保布局完成
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _highlightedCommentId = widget.highlightCommentId;
            _isHighlighting = true;
          });
          // 滚动到评论位置（估算位置）
          // 评论列表从帖子内容下方开始，每个评论约 100px 高度
          final estimatedOffset = 400.0 + idx * 100.0;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
          // 2秒后停止高亮动画
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() {
              _isHighlighting = false;
            });
            // 渐隐后再清除 ID
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              setState(() {
                _highlightedCommentId = null;
              });
            });
          });
        });
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final postId = widget.post['id'] as String;
      final response = await _supabase
          .from('comments')
          .select('*, profiles:user_id(nickname, username, avatar_url, faith_tag)')
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .limit(50);

      if (!mounted) return;
      setState(() {
        _comments = response != null
            ? List<Map<String, dynamic>>.from(response)
            : [];
        _loadingComments = false;
      });
    } catch (e) {
      debugPrint('加载评论失败: $e');
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

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

      await _supabase
          .from('posts')
          .update({'comments_count': _commentCount + 1})
          .eq('id', postId);
      // Invalidate home posts cache (comment count changed)
      ApiCache.instance.invalidate('home:posts:0');

      _commentController.clear();
      if (!mounted) return;
      setState(() {
        _commentCount += 1;
        _sendingComment = false;
      });
      _loadComments();

      // 增加经验值 +2
      try {
        await _supabase.rpc('increment_experience', params: {
          'target_user_id': user.id,
          'exp_amount': 2,
        });
      } catch (e) { debugPrint('增加经验值失败: $e'); }

      if (mounted) {
        _showExpAnimation(2);
      }
    } catch (e) {
      debugPrint('发送评论失败: $e');
      if (!mounted) return;
      setState(() => _sendingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

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
        if (!mounted) return;
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 9999999);
        });
      } else {
        await _supabase.from('likes').insert({
          'user_id': user.id,
          'post_id': postId,
        });
        // Invalidate home posts cache (like count changed)
        ApiCache.instance.invalidate('home:posts:0');
        if (!mounted) return;
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      debugPrint('点赞操作失败: $e');
    }
  }

  Future<void> _toggleHeat() async {
    try {
      final postId = widget.post['id'] as String;
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. 读取当前用户的热点余额
      final profileRes = await _supabase
          .from('profiles')
          .select('hot_points')
          .eq('user_id', user.id)
          .maybeSingle();

      final hotPoints = (profileRes?['hot_points'] as num?)?.toInt() ?? 0;

      // 2. 余额不足提示
      if (hotPoints <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('热点不足，请等待每日赠送或升级VIP'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 3. 扣减 1 个热点
      await _supabase
          .from('profiles')
          .update({'hot_points': hotPoints - 1})
          .eq('user_id', user.id);

      // 4. 帖子热度 +1
      await _supabase
          .from('posts')
          .update({'heat_count': _heatCount + 1})
          .eq('id', postId);

      // 5. 更新本地状态并提示
      if (!mounted) return;
      setState(() => _heatCount += 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加热成功，剩余热点: ${hotPoints - 1}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('加热操作失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加热失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 分享帖子：复制链接 + 更新分享计数
  Future<void> _sharePost() async {
    try {
      final postId = widget.post['id'] as String;
      final title = widget.post['title'] as String? ?? 'OpenFaith 帖子';
      
      // 构造分享文本
      final shareText = '【OpenFaith】$title\nhttps://openfaith.app/post/$postId';
      
      // 复制链接到剪贴板
      await Clipboard.setData(ClipboardData(text: shareText));
      
      // 更新 posts 表的 shares_count
      final currentShares = (widget.post['shares_count'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('posts')
          .update({'shares_count': currentShares + 1})
          .eq('id', postId);
      
      // 同步更新本地 widget.post 的 shares_count
      widget.post['shares_count'] = currentShares + 1;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('链接已复制，快去分享吧！'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('分享操作失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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

      if (!mounted) return;
      setState(() => _isBookmarked = !_isBookmarked);
    } catch (e) {
      debugPrint('收藏操作失败: $e');
    }
  }

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

      if (!mounted) return;
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      debugPrint('关注操作失败: $e');
    }
  }

  void _scrollToComments() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
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
    final createdAt = widget.post['created_at'] as String?;
    final tags = _extractTags(widget.post);
    final isOwnPost = _supabase.auth.currentUser?.id == widget.post['user_id'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ====== 毛玻璃顶部导航栏 ======
          _buildHeader(nickname, avatarUrl, faithTag, isOwnPost),

          // ====== 可滚动内容区 ======
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片轮播
                  if (_images.isNotEmpty) _buildImageCarousel(),

                  // 帖子详情区
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 作者信息行
                        _buildAuthorRow(nickname, avatarUrl, faithTag, isOwnPost),

                        const SizedBox(height: 12),

                        // 标题
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),

                        const SizedBox(height: 8),

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
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: AppColors.textWeak,
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

                        // 分割线 + 评论标题
                        const SizedBox(height: 16),
                        Container(height: 0.5, color: AppColors.borderSubtle),
                        const SizedBox(height: 16),

                        // 评论标题
                        Text(
                          '评论 ($_commentCount)',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
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
                                color: AppColors.auroraBlue,
                              ),
                            ),
                          )
                        else if (_comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                '暂无评论，快来抢沙发',
                                style: TextStyle(color: AppColors.textWeak, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._comments.map((c) => _buildCommentItem(c)),

                        const SizedBox(height: 120), // 底部留白给固定栏
                      ],
                    ),
                  ),
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

  /// 毛玻璃 Header
  Widget _buildHeader(String nickname, String? avatarUrl, String? faithTag, bool isOwnPost) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            border: Border(
              bottom: BorderSide(color: AppColors.borderDefault, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // 返回按钮
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
                  ),
                ),
                const Spacer(),
                // 分享按钮
                GestureDetector(
                  onTap: () {
                    _sharePost();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                // 更多按钮 (含举报)
                GestureDetector(
                  onTap: _showMoreMenu,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_horiz, color: AppColors.textPrimary, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// 显示更多菜单 (分享/举报)
  void _showMoreMenu() {
    final isOwnPost = _supabase.auth.currentUser?.id == widget.post['user_id'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderActive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Share action
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 22),
                title: const Text('分享', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _sharePost();
                },
              ),
              // Copy link
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.textPrimary, size: 22),
                title: const Text('复制链接', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  final postId = widget.post['id'] as String;
                  final link = 'https://openfaithhub.com/post/$postId';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('链接已复制'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // Report (only for non-own posts)
              if (!isOwnPost)
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.auroraRed, size: 22),
                  title: const Text('举报', style: TextStyle(color: AppColors.auroraRed, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog();
                  },
                ),
              const SizedBox(height: 8),
              // Cancel
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Center(
                    child: Text('取消', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示举报弹窗
  void _showReportDialog() {
    String selectedReason = '垃圾广告';
    final reasons = ['垃圾广告', '违规内容', '不实信息', '骚扰或欺凌', '其他'];
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderDefault, width: 0.5),
          ),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.auroraRed.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_outlined, color: AppColors.auroraRed, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '举报帖子',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '请选择举报原因',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => GestureDetector(
                  onTap: () => setDialogState(() => selectedReason = reason),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedReason == reason
                          ? AppColors.auroraRed.withOpacity(0.12)
                          : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedReason == reason
                            ? AppColors.auroraRed.withOpacity(0.4)
                            : AppColors.borderDefault,
                        width: selectedReason == reason ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == reason ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selectedReason == reason ? AppColors.auroraRed : AppColors.textWeak,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          reason,
                          style: TextStyle(
                            color: selectedReason == reason ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: selectedReason == reason ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                // Additional description
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDefault, width: 0.5),
                  ),
                  child: TextField(
                    controller: reasonController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '补充说明（可选）',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDefault, width: 0.5),
                          ),
                          child: const Center(
                            child: Text('取消', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _submitReport(selectedReason, reasonController.text.trim());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.auroraRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('提交举报', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 提交举报
  Future<void> _submitReport(String reason, String description) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final postId = widget.post['id'] as String;
      await _supabase.from('reports').insert({
        'reporter_id': user.id,
        'post_id': postId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('举报已提交，感谢您的反馈'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('提交举报失败: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('举报提交失败: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 图片轮播（支持滑动切换 + 圆点指示器）
  Widget _buildImageCarousel() {
    if (_images.length == 1) {
      return _buildSingleImage(_images[0]);
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) => setState(() => _currentPageImage = index),
            itemBuilder: (context, index) {
              return _buildSingleImage(_images[index]);
            },
          ),
        ),
        // 圆点指示器
        if (_images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (index) {
                final isActive = index == _currentPageImage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.textPrimary : AppColors.textPlaceholder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    final transformationController = TransformationController();
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: GestureDetector(
        onDoubleTap: () {
          final currentScale = transformationController.value.getMaxScaleOnAxis();
          if (currentScale > 1.0) {
            // Zoom out - animate back to original
            final resetMatrix = Matrix4.identity();
            _animateZoom(transformationController, resetMatrix);
          } else {
            // Zoom in to center at 2x
            final zoomMatrix = Matrix4.identity()..scale(2.0);
            _animateZoom(transformationController, zoomMatrix);
          }
        },
        child: InteractiveViewer(
          transformationController: transformationController,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(20),
          child: _buildCoverImageWidget(imageUrl, height: 300),
        ),
      ),
    );
  }

  void _animateZoom(TransformationController controller, Matrix4 target) {
    controller.value = target;
  }

  /// 作者信息行（头像 + 昵称 + 信仰标签 + 关注/编辑按钮）
  Widget _buildAuthorRow(String nickname, String? avatarUrl, String? faithTag, bool isOwnPost) {
    return Row(
      children: [
        // 头像
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.inputBg,
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? const Icon(Icons.person, size: 18, color: AppColors.iconColorWeak)
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
                        color: AppColors.textPrimary,
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
                        gradient: AppColors.auroraGradientWithOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        faithTag,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
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
                style: const TextStyle(color: AppColors.textWeak, fontSize: 11),
              ),
            ],
          ),
        ),

        // 关注 / 编辑+删除按钮
        if (!isOwnPost)
          GestureDetector(
            onTap: _toggleFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: _isFollowing ? null : AppColors.auroraGradient,
                color: _isFollowing ? AppColors.hoverBg : null,
                border: _isFollowing
                    ? Border.all(color: AppColors.borderActive)
                    : null,
              ),
              child: Text(
                _isFollowing ? '已关注' : '+ 关注',
                style: TextStyle(
                  color: _isFollowing ? AppColors.textWeak : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderActive),
                ),
                child: const Text(
                  '编辑',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 数据统计行
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(Icons.visibility_outlined, _viewsCount, AppColors.textWeak),
        const SizedBox(width: 12),
        _buildStatChip(Icons.chat_bubble_outline, _commentCount, AppColors.textWeak),
        const SizedBox(width: 12),
        _buildStatChip(Icons.local_fire_department, _computeHotValue(), AppColors.auroraOrange),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            _formatCount(value),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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

  /// 底部固定操作栏
  Widget _buildBottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            border: Border(
              top: BorderSide(color: AppColors.borderDefault, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 评论输入框
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: '说点什么...',
                            hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
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
                                    color: AppColors.auroraBlue,
                                  ),
                                )
                              : ShaderMask(
                                  shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                                  child: const Icon(Icons.send, color: AppColors.textPrimary, size: 18),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 表情快捷栏
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojiIcons.length > 12 ? 12 : emojiIcons.length,
                    itemBuilder: (ctx, i) {
                      final emoji = emojiIcons[i];
                      return GestureDetector(
                        onTap: () => _sendEmojiReaction(emoji),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(emoji.icon, size: 16, color: emoji.color),
                              const SizedBox(width: 2),
                              Text(emoji.label, style: TextStyle(color: emoji.color, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // 互动按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      label: _formatCount(_likeCount),
                      color: _isLiked ? AppColors.auroraRed : AppColors.textWeak,
                      onTap: _toggleLike,
                    ),
                    _buildBottomAction(
                      icon: Icons.chat_bubble_outline,
                      label: _formatCount(_commentCount),
                      color: AppColors.textWeak,
                      onTap: _scrollToComments,
                    ),
                    _buildBottomAction(
                      icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      label: '收藏',
                      color: _isBookmarked ? AppColors.auroraYellow : AppColors.textWeak,
                      onTap: _toggleBookmark,
                    ),
                    _buildBottomAction(
                      icon: Icons.local_fire_department,
                      label: _formatCount(_heatCount),
                      color: AppColors.auroraOrange,
                      onTap: _toggleHeat,
                    ),
                    _buildBottomAction(
                      icon: Icons.share_outlined,
                      label: '分享',
                      color: AppColors.textWeak,
                      onTap: _sharePost,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 发送表情快捷反应
  void _sendEmojiReaction(EmojiIconItem emoji) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('comments').insert({
        'post_id': widget.post['id'],
        'user_id': user.id,
        'content': emoji.icon.codePoint.toRadixString(16),
      });
      if (!mounted) return;
      setState(() => _commentCount++);
      await _loadComments();
    } catch (e) {
      debugPrint('发送表情反应失败: $e');
    }
  }

  /// 评论项
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final nickname = profile?['nickname'] ?? profile?['username'] ?? '匿名';
    final avatarUrl = profile?['avatar_url'] as String?;
    final content = comment['content'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;
    final commentFaithTag = profile?['faith_tag'] as String?;
    final isAuthor = widget.post['user_id'] == comment['user_id'];

    final isHighlighted = _highlightedCommentId == comment['id'];

    Widget commentCard = Padding(
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
                ? const Icon(Icons.person, size: 14, color: AppColors.iconColorWeak)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 昵称行
                Row(
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 作者标识 or 信仰标签
                    if (isAuthor)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '作者',
                          style: TextStyle(color: AppColors.textWeak, fontSize: 9),
                        ),
                      )
                    else if (commentFaithTag != null && commentFaithTag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          commentFaithTag,
                          style: const TextStyle(color: AppColors.textWeak, fontSize: 9),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 评论内容
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                // 回复按钮
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    _commentController.text = '@$nickname ';
                    _commentController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _commentController.text.length),
                    );
                  },
                  child: const Text(
                    '回复',
                    style: TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // 如果该评论需要高亮，添加七彩渐变边框动画
    if (isHighlighted && _isHighlighting) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.rainbowColors,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.auroraBlue.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: commentCard,
        ),
      );
    }

    return commentCard;
  }

  /// 封面图 Widget（支持 base64 和 URL）
  Widget _buildCoverImageWidget(String coverImage, {double? height}) {
    if (coverImage.startsWith('data:image/')) {
      try {
        final base64Data = coverImage.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    } else if (coverImage.startsWith('http://') || coverImage.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: coverImage,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height ?? 200,
          color: AppColors.inputBg,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.auroraBlue),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: height ?? 200,
          color: AppColors.inputBg,
          child: const Icon(Icons.broken_image, color: AppColors.textPlaceholder, size: 40),
        ),
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

  String _formatCount(int count) => formatCount(count);
}
