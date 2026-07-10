import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';

/// Sidebar overlay component (对齐网页版 Sidebar.tsx)
/// 从左侧滑入，宽272px，半透明遮罩层，暗黑背景 #0D1117
class Sidebar extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(String menuItemId)? onMenuItemTap;

  const Sidebar({
    super.key,
    required this.onClose,
    this.onMenuItemTap,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isAdmin = false;
  Map<String, dynamic>? _currentUser;
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
    _checkAdmin();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['role'] == 'admin') {
        setState(() => _isAdmin = true);
      }
    } catch (e) {
      debugPrint('[Sidebar] Admin check error: $e');
    }
  }

  /// P1-8: 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('profiles')
          .select('nickname, username, avatar_url, faith_tag, is_vip')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        setState(() => _currentUser = Map<String, dynamic>.from(res as Map));
      }
    } catch (e) {
      debugPrint('[Sidebar] Load user error: $e');
    }
  }

  void _close() {
    _slideController.reverse().then((_) {
      if (mounted) widget.onClose();
    });
  }

  void _handleMenuTap(String id) {
    if (id == 'logout') {
      _handleLogout();
      return;
    }
    // Close sidebar first, then notify parent
    _close();
    // Defer callback to after animation
    Future.delayed(const Duration(milliseconds: 320), () {
      widget.onMenuItemTap?.call(id);
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('退出登录', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('确定要退出登录吗？',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(
        id: 'history',
        icon: Icons.schedule,
        label: '浏览记录',
        color: AppColors.textSecondary,
      ),
      _MenuItem(
        id: 'download',
        icon: Icons.download_outlined,
        label: '我的下载',
        color: AppColors.textSecondary,
      ),
      _MenuItem(
        id: 'covenant',
        icon: Icons.article_outlined,
        label: '信仰公约',
        color: AppColors.textSecondary,
      ),
      _MenuItem(
        id: 'scan',
        icon: Icons.qr_code_scanner,
        label: '扫一扫',
        color: AppColors.textSecondary,
      ),
      _MenuItem(
        id: 'support',
        icon: Icons.headphones,
        label: '欢迎联系',
        color: AppColors.textSecondary,
      ),
      _MenuItem(
        id: 'vip',
        icon: Icons.workspace_premium,
        label: '订阅会员',
        color: const Color(0xFFFFD60A),
        highlight: true,
      ),
      if (_isAdmin)
        _MenuItem(
          id: 'admin',
          icon: Icons.shield,
          label: '管理后台',
          color: AppColors.textSecondary,
        ),
      _MenuItem(
        id: 'settings',
        icon: Icons.settings,
        label: '设置',
        color: AppColors.textSecondary,
      ),
    ];

    return Stack(
      children: [
        // Semi-transparent overlay (tap to close)
        GestureDetector(
          onTap: _close,
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
        // Sidebar panel
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 272,
              height: double.infinity,
              child: Material(
                color: const Color(0xFF0A0E1A), // 实色深色背景（对齐网页版 --card-bg）
                elevation: 8,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header: logo + close button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: AppColors.rainbowColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'OpenFaith',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _close,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: AppColors.borderColor),
                                ),
                                child: const Icon(Icons.close,
                                    color: AppColors.textSecondary, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // P1-8: 用户信息区域
                      if (_currentUser != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            children: [
                              // 头像（七彩渐变边框）
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: AppColors.rainbowColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.background,
                                  ),
                                  child: ClipOval(
                                    child: (_currentUser!['avatar_url'] != null &&
                                            (_currentUser!['avatar_url'] as String).isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: _currentUser!['avatar_url'],
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20),
                                            errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20),
                                          )
                                        : const Icon(Icons.person, color: AppColors.textPlaceholder, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 昵称 + VIP + 信仰标签
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _currentUser!['nickname'] ?? _currentUser!['username'] ?? '用户',
                                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_currentUser!['is_vip'] == true) ...[
                                          const SizedBox(width: 4),
                                          const Text('👑', style: TextStyle(fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                    if (_currentUser!['faith_tag'] != null &&
                                        (_currentUser!['faith_tag'] as String).isNotEmpty)
                                      Text(
                                        _currentUser!['faith_tag'] as String,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child:
                            Divider(color: AppColors.borderColor, height: 1),
                      ),
                      // Menu items
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              ...menuItems.map((item) =>
                                  _buildMenuItemWidget(item)),
                            ],
                          ),
                        ),
                      ),
                      // Bottom: logout
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () => _handleMenuTap('logout'),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                const Icon(Icons.logout,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 16),
                                const Text(
                                  '退出登录',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item) {
    // VIP 项：七彩渐变边框（铁律）
    if (item.highlight) {
      return GestureDetector(
        onTap: () => _handleMenuTap(item.id),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.rainbowColors,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.rainbowColors,
                  ).createShader(bounds),
                  child: Icon(item.icon, color: AppColors.textPrimary, size: 20),
                ),
                const SizedBox(width: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.rainbowColors,
                  ).createShader(bounds),
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    // 普通项：按下有反馈
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleMenuTap(item.id),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.borderColor,
        highlightColor: AppColors.borderSubtle,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.borderSubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: item.color, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final bool highlight;

  _MenuItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    this.highlight = false,
  });
}
