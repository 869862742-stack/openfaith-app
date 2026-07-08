import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import 'user_profile_screen.dart';

/// 群聊详情页 - 对齐网页版 GroupChatDetail.tsx
class GroupChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const GroupChatDetailScreen({super.key, required this.groupData});

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen> {
  final _supabase = Supabase.instance.client;

  String? _groupId;
  String? _groupTitle;
  String? _groupContent;
  List<String> _groupTags = [];
  String? _creatorId;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _groupPosts = [];
  bool _isMember = false;
  bool _loading = true;
  bool _loadingMembers = true;
  bool _loadingPosts = true;
  String? _currentUserId;  static const List<Color> _rainbowColors = [


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
    _currentUserId = _supabase.auth.currentUser?.id;
    _parseGroupData();
    _loadMembers();
    _loadGroupPosts();
  }

  void _parseGroupData() {
    final g = widget.groupData;
    setState(() {
      _groupId = g['id'] as String?;
      _groupTitle = g['title'] as String? ?? '群聊';
      _groupContent = g['content'] as String?;
      _groupTags = (g['tags'] as List?)?.cast<String>() ?? [];
      _creatorId = g['user_id'] as String?;
      _isMember = true;
      _loading = false;
    });
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

      final profiles = await _supabase.from('profiles')
        .select('id,user_id,username,nickname,avatar_url')
        .inFilter('user_id', memberTags);
      setState(() {
        _members = List<Map<String, dynamic>>.from(profiles);
        _loadingMembers = false;
      });
    } catch (_) {
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadGroupPosts() async {
    if (_groupId == null) return;
    setState(() => _loadingPosts = true);
    try {
      final res = await _supabase.from('posts')
        .select('id,title,content,tags,user_id,heat_count,status,created_at')
        .order('created_at', ascending: false)
        .limit(100);
      final all = List<Map<String, dynamic>>.from(res);
      final filtered = all.where((p) {
        final tags = (p['tags'] as List?)?.cast<String>() ?? [];
        return tags.contains('__group_chat__') &&
            _groupId != null &&
            tags.contains('group_$_groupId');
      }).toList();
      setState(() {
        _groupPosts = filtered;
        _loadingPosts = false;
      });
    } catch (_) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _toggleMembership() async {
    if (_currentUserId == null || _groupId == null) return;
    final memberTag = 'member_$_currentUserId';

    if (_isMember) {
      try {
        final res = await _supabase.from('posts')
          .select('id,tags')
          .eq('id', _groupId!);
        if (res.isNotEmpty) {
          final tags = (res[0]['tags'] as List?)?.cast<String>() ?? [];
          tags.remove(memberTag);
          await _supabase.from('posts')
            .update({'tags': tags})
            .eq('id', _groupId!);
        }
        setState(() => _isMember = false);
        _loadMembers();
      } catch (_) {}
    } else {
      try {
        final res = await _supabase.from('posts')
          .select('id,tags')
          .eq('id', _groupId!);
        if (res.isNotEmpty) {
          final tags = (res[0]['tags'] as List?)?.cast<String>() ?? [];
          if (!tags.contains(memberTag)) tags.add(memberTag);
          await _supabase.from('posts')
            .update({'tags': tags})
            .eq('id', _groupId!);
        }
        setState(() => _isMember = true);
        _loadMembers();
      } catch (_) {}
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

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _groupTitle ?? '群聊',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF8B949E)),
            onPressed: () => _showGroupOptions(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildGroupHeader(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildSectionTitle('成员 (${_members.length})', Icons.people),
            const SizedBox(height: 8),
            _buildMembersList(),
            const SizedBox(height: 20),
            _buildSectionTitle('群聊内容', Icons.article),
            const SizedBox(height: 8),
            _buildGroupPostsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3A86FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups,
                  color: Color(0xFF3A86FF), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_groupTitle ?? '群聊',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text('${_members.length} 位成员',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      )),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isMember
                    ? const Color(0xFF4CAF50).withOpacity(0.15)
                    : const Color(0xFFFF9F1C).withOpacity(0.15),
              ),
              child: Text(
                _isMember ? '已加入' : '未加入',
                style: TextStyle(
                  color: _isMember
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9F1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ]),
          if (_groupContent != null && _groupContent!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_groupContent!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                )),
          ],
          if (_groupTags
              .where((t) =>
                  !t.startsWith('__') &&
                  !t.startsWith('member_') &&
                  !t.startsWith('group_'))
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _groupTags
                  .where((t) =>
                      !t.startsWith('__') &&
                      !t.startsWith('member_') &&
                      !t.startsWith('group_'))
                  .take(5)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: _rainbowBordered(
          radius: 12,
          child: GestureDetector(
            onTap: _toggleMembership,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: _isMember
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.exit_to_app,
                          color: Colors.white.withOpacity(0.8), size: 18),
                      const SizedBox(width: 6),
                      Text('退出群聊',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ])
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('加入群聊',
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
    ]);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          )),
    ]);
  }

  Widget _buildMembersList() {
    if (_loadingMembers) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.rainbowEnd),
        ),
      );
    }
    if (_members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('暂无成员信息',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        ...List.generate(_members.length, (i) {
          final m = _members[i];
          final name = m['nickname'] as String? ??
              m['username'] as String? ??
              '未命名用户';
          final uid = m['user_id'] as String? ?? m['id'] as String?;
          final avatarUrl = m['avatar_url'] as String?;
          return Container(
            decoration: BoxDecoration(
              border: i < _members.length - 1
                  ? Border(
                      bottom: BorderSide(
                          color: Colors.white.withOpacity(0.04)))
                  : null,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF484F58),
                              size: 18))
                      : const Icon(Icons.person,
                          color: Color(0xFF484F58), size: 18),
                ),
              ),
              title: Text(name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              trailing: Icon(Icons.chevron_right,
                  size: 18, color: Colors.white.withOpacity(0.3)),
              onTap: uid != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: uid),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildGroupPostsList() {
    if (_loadingPosts) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.rainbowEnd),
        ),
      );
    }
    if (_groupPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(children: [
            Icon(Icons.article,
                size: 36, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 8),
            Text('暂无群聊内容',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 13)),
          ]),
        ),
      );
    }
    return Column(
      children: _groupPosts.map((post) => _buildPostItem(post)).toList(),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    final title = post['title'] as String? ?? '';
    final content = post['content'] as String? ?? '';
    final heatCount = post['heat_count'] as int? ?? 0;
    final createdAt = post['created_at'] as String? ?? '';

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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(_groupTitle ?? '群聊',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${_members.length} 位成员',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.copy,
              label: '复制群聊信息',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _buildOptionItem(
              icon: Icons.share,
              label: '分享群聊',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            if (_isMember)
              _buildOptionItem(
                icon: Icons.exit_to_app,
                label: '退出群聊',
                color: const Color(0xFFEF4444),
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
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color ?? Colors.white.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: color ?? Colors.white.withOpacity(0.8),
                fontSize: 14,
              )),
        ]),
      ),
    );
  }
}
