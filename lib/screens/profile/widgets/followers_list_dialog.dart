import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';

/// 粉丝/关注列表弹窗
class FollowersListDialog extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true=粉丝列表, false=关注列表

  const FollowersListDialog({
    super.key,
    required this.userId,
    this.isFollowers = true,
  });

  @override
  State<FollowersListDialog> createState() => _FollowersListDialogState();
}

class _FollowersListDialogState extends State<FollowersListDialog> {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
        _filterList();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterList() {
    if (_searchQuery.isEmpty) {
      _filteredList = List.from(_list);
    } else {
      _filteredList = _list.where((item) {
        final name = (item['nickname'] ?? '').toString().toLowerCase();
        final username = (item['username'] ?? '').toString().toLowerCase();
        final tag = (item['faith_tag'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) ||
            username.contains(_searchQuery) ||
            tag.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 查询 follows 表
      final column = widget.isFollowers ? 'follower_id' : 'following_id';
      final filterColumn = widget.isFollowers ? 'following_id' : 'follower_id';
      final followsRes = await _supabase
          .from('follows')
          .select('$column, created_at')
          .eq(filterColumn, widget.userId)
          .order('created_at', ascending: false);

      if (followsRes.isEmpty) {
        if (mounted) setState(() { _list = []; _filteredList = []; _loading = false; });
        return;
      }

      final ids = followsRes.map((f) => f[column] as String).toList();
      if (ids.isEmpty) {
        if (mounted) setState(() { _list = []; _filteredList = []; _loading = false; });
        return;
      }

      // 获取用户资料
      final profilesRes = await _supabase
          .from('profiles')
          .select('user_id, username, nickname, avatar_url, faith_tag')
          .inFilter('user_id', ids);

      final profilesMap = <String, Map<String, dynamic>>{};
      for (final p in profilesRes) {
        profilesMap[p['user_id'] as String] = Map<String, dynamic>.from(p as Map);
      }

      final merged = followsRes.map((f) {
        final uid = f[column] as String;
        final profile = profilesMap[uid] ?? {};
        return {
          'user_id': uid,
          'username': profile['username'] ?? '',
          'nickname': profile['nickname'] ?? profile['username'] ?? '用户',
          'avatar_url': profile['avatar_url'] ?? '',
          'faith_tag': profile['faith_tag'] ?? '',
          'followed_at': f['created_at'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _list = merged;
          _filteredList = List.from(merged);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[FollowersList] Error: $e');
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _handleUnfollow(String targetUserId) async {
    try {
      await _supabase.from('follows').delete().eq('follower_id', widget.userId).eq('following_id', targetUserId);
      setState(() {
        _list.removeWhere((item) => item['user_id'] == targetUserId);
        _filterList();
      });
    } catch (e) {
      debugPrint('[Unfollow] Error: $e');
    }
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}W';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFollowers ? '粉丝' : '关注';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  Text('$title (${_formatCount(_list.length)})',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                  ),
                ]),
              ),
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '搜索...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // 列表
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.auroraPurple))
                    : _filteredList.isEmpty
                        ? Center(child: Text(_searchQuery.isNotEmpty ? '无匹配结果' : '暂无$title',
                            style: const TextStyle(color: AppColors.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _filteredList[index];
                              return _buildUserTile(item);
                            },
                          ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> item) {
    final avatarUrl = item['avatar_url'] as String? ?? '';
    final nickname = item['nickname'] as String? ?? '用户';
    final faithTag = item['faith_tag'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        // 头像
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.borderColor,
          backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.auroraColors).createShader(bounds),
                  child: const Text('OF',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                )
              : null,
        ),
        const SizedBox(width: 12),
        // 信息
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nickname,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (faithTag.isNotEmpty)
              Text(faithTag,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        // 取消关注按钮（仅关注列表显示）
        if (!widget.isFollowers)
          GestureDetector(
            onTap: () => _handleUnfollow(item['user_id'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_remove, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('取消关注', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
          ),
      ]),
    );
  }
}
