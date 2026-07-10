import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import '../../theme/app_colors.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String _currentFilter = 'all';

  String? get _userId {
    final session = _supabase.auth.currentSession;
    return session?.user.id;
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      PostgrestFilterBuilder query = _supabase
          .from('posts')
          .select('*, profiles:user_id(nickname, avatar_url)')
          .eq('user_id', userId);

      if (_currentFilter == 'published') {
        query = query.eq('status', 'published');
      } else if (_currentFilter == 'draft') {
        query = query.eq('status', 'draft');
      }

      final response = await query.order('created_at', ascending: false).limit(50);

      if (response != null) {
        if (!mounted) return;
        setState(() {
          _posts = List<Map<String, dynamic>>.from(response as List);
        });
      }
    } catch (e) {
      debugPrint('Load posts error: $e');
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除帖子', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('确定要删除这篇帖子吗？此操作不可撤销。',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('posts').delete().eq('id', postId);
        _loadPosts();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('帖子已删除'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).paddingTop + 12,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.borderDefault, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const Expanded(
                  child: Text(
                    '我的帖子',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          // Filter tabs
          _buildFilterTabs(),
          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.auroraPurple))
                : _posts.isEmpty
                    ? _buildEmptyView()
                    : RefreshIndicator(
                        color: AppColors.auroraPurple,
                        onRefresh: _loadPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) =>
                              _buildPostCard(_posts[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('已发布', 'published'),
          const SizedBox(width: 8),
          _buildFilterChip('草稿', 'draft'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _currentFilter = value);
        _loadPosts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? AppColors.auroraGradient
              : null,
          color: isSelected ? null : AppColors.cardBg,
          border:
              isSelected ? null : Border.all(color: AppColors.borderColor),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final title = post['title'] as String? ?? '';
    final content = post['content'] as String? ?? '';
    final coverImage = post['cover_image'] as String?;
    final likeCount = (post['like_count'] as num?)?.toInt() ?? 0;
    final commentCount = (post['comment_count'] as num?)?.toInt() ?? 0;
    final status = post['status'] as String? ?? 'published';
    final createdAt = post['created_at'] as String?;
    final religionName = post['religion_name'] as String?;

    final formattedDate = _formatDate(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title.isEmpty ? '无标题' : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (status == 'draft')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.warning.withOpacity(0.15),
                        ),
                        child: const Text('草稿',
                            style: TextStyle(
                                color: AppColors.warning, fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (content.isNotEmpty)
                  Text(content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5)),
                if (religionName != null && religionName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.auroraPurple.withOpacity(0.1),
                      border: Border.all(
                          color: AppColors.auroraPurple.withOpacity(0.3)),
                    ),
                    child: Text(religionName,
                        style: const TextStyle(
                            color: AppColors.auroraPurple, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          if (coverImage != null && coverImage.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              placeholder: (_, __) => Container(
                height: 180,
                color: AppColors.bgColor,
                child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.textMuted)),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Text(formattedDate,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const Spacer(),
                _buildActionChip(
                  Icons.favorite_outline,
                  _formatCount(likeCount),
                  AppColors.auroraRed,
                ),
                const SizedBox(width: 12),
                _buildActionChip(
                  Icons.comment_outlined,
                  _formatCount(commentCount),
                  AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textMuted, size: 20),
                  color: AppColors.cardBg,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost(post['id'] as String);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text('编辑',
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text('删除',
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.article_outlined,
                color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('暂无帖子',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('开始分享你的信仰故事吧',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('发布帖子'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.auroraPurple,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}周前';
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
