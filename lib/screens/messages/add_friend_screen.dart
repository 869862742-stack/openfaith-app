import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _greetingController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _error;
  Map<String, dynamic>? _greetingTarget;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    try {
      final client = Supabase.instance.client;
      final resp = await client
          .from('profiles')
          .select('id, username, email, avatar_url')
          .or('username.ilike.%$query%,email.ilike.%$query%')
          .limit(20);
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        final filtered =
            (resp as List).where((u) => u['id'] != currentUser.id).toList();
        if (mounted) {
          setState(() => _results = filtered.cast<Map<String, dynamic>>());
        }
      } else {
        if (mounted) {
          setState(() => _results = resp.cast<Map<String, dynamic>>());
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _searching = false);
  }

  void _openGreeting(Map<String, dynamic> user) {
    _greetingTarget = user;
    _greetingController.text = '你好，希望能添加你为好友';
    showDialog(
      context: context,
      builder: (_) => _GreetingDialog(
        user: user,
        controller: _greetingController,
        onSend: () => _sendFriendRequest(
          user['id'],
          user['username'] ?? 'user',
          _greetingController.text,
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(
    String userId,
    String username,
    String message,
  ) async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      await client.from('friend_requests').insert({
        'from_user_id': currentUser.id,
        'to_user_id': userId,
        'status': 'pending',
        'message': message,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已向 $username 发送好友请求'),
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    }
  }

  // ===== UI Helpers =====

  Widget _glassHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            border: Border(
              bottom: BorderSide(color: AppColors.borderDefault, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                '添加好友',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(13),

          border: Border.all(color: AppColors.rainbowEnd, width: 1),

        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.bgColor,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: '搜索昵称、ID...',
                      hintStyle: const TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _search(),
                    onTapOutside: (event) => _searchFocusNode.unfocus(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _gradientButton(
          onPressed: _searching ? null : _search,
          child: _searching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : const Text(
                  '搜索',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final username = user['username'] ?? '未命名用户';
    final userId = (user['id'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.inputBg,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? Icon(Icons.person, color: AppColors.iconColorWeak, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userId.isNotEmpty)
                  Text(
                    'ID: ${userId.length > 8 ? '${userId.substring(0, 8)}...' : userId}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 添加按钮
          GestureDetector(
            onTap: () => _openGreeting(user),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: AppColors.rainbowEnd, width: 1),

              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add, size: 12, color: AppColors.textPrimary),
                  const SizedBox(width: 4),
                  const Text(
                    '添加',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            _glassHeader(),
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(16),
              child: _searchBar(),
            ),
            // 错误提示
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            // 结果列表
            Expanded(
              child: _searching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.auroraBlue,
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 48,
                                color: AppColors.iconColorWeak,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? '搜索用户名或邮箱添加好友'
                                    : '未找到匹配的用户',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _userCard(_results[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 打招呼弹窗 =====
class _GreetingDialog extends StatelessWidget {
  final Map<String, dynamic> user;
  final TextEditingController controller;
  final VoidCallback onSend;

  const _GreetingDialog({
    required this.user,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username'] ?? '未命名用户';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题行
            Row(
              children: [
                const Text(
                  '添加好友',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 目标用户信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.inputBg,
                    backgroundImage: user['avatar_url'] != null
                        ? NetworkImage(user['avatar_url'])
                        : null,
                    child: user['avatar_url'] == null
                        ? Icon(Icons.person,
                            color: AppColors.iconColorWeak, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '发送好友请求并打招呼',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 打招呼消息
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '打招呼消息',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '说点什么打个招呼吧...',
                  hintStyle: const TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 发送按钮
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(

                  borderRadius: BorderRadius.circular(13),

                  border: Border.all(color: AppColors.rainbowEnd, width: 1),

                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.bgColor,
                  ),
                  child: const Center(
                    child: Text(
                      '发送好友请求',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
