import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/animated_starfield.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/create_post_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/publish/publish_plan_screen.dart';
import '../screens/publish/publish_video_screen.dart';
import '../screens/publish/drafts_screen.dart';
import '../screens/gongjing/create_room_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  /// 七彩渐变 — 对齐网页版 AURORA_GRADIENT (135deg)
  static const _auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.auroraColors,
  );

  /// 未读徽章渐变 — 对齐网页版 linear-gradient(135deg, #FF4D6D, #FF6B6B)
  static const _badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4D6D), Color(0xFFFF6B6B)],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedStarfield(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  // ─────────────── 底部导航栏 ───────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        // 网页版: rgba(5,8,22,0.97) → AppColors.navBg (0xF7050816)
        color: AppColors.navBg,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // 网页版: px-2 pb-1.5 pt-0.5 → horizontal:8, bottom:6, top:2
          padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(
            top: 2,
            bottom: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, '首页'),
              _buildNavItem(1, Icons.explore_outlined, Icons.explore, '学习'),
              _buildPublishButton(),
              _buildNavItem(
                2,
                Icons.notifications_outlined,
                Icons.notifications,
                '消息',
                showBadge: true,
              ),
              _buildNavItem(3, Icons.person_outline, Icons.person, '我的'),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── 普通 Nav Item ───────────────

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool showBadge = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        // 网页版: min-w-[50px]
        constraints: const BoxConstraints(minWidth: 50),
        child: Container(
          // 网页版: py-0.5 px-2
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标区 — 网页版: display:inline-flex 包裹
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── 图标 ──
                  _buildNavIcon(isSelected, activeIcon, icon),

                  // ── 未读徽章 ──
                  if (showBadge && _unreadCount > 0)
                    Positioned(
                      // 网页版: top-2px right-8px
                      top: -2,
                      right: -8,
                      child: Container(
                        // 网页版: minWidth 16, height 16, padding 0 4px, radius 8
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: _badgeGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── 文字 ── 网页版: text-[10px] mt-0.5
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.iconColorWeak,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建导航图标 — 选中时用 ShaderMask 实现七彩效果
  Widget _buildNavIcon(bool isSelected, IconData activeIcon, IconData icon) {
    // 网页版: icon 20px, strokeWidth 2
    const double iconSize = 20;

    if (isSelected) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: ShaderMask(
          shaderCallback: (bounds) => _auroraGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Icon(activeIcon, color: Colors.white, size: iconSize),
        ),
      );
    }

    return Icon(icon, size: iconSize, color: AppColors.iconColorWeak);
  }

  // ─────────────── Publish (+) 按钮 ───────────────

  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: _showPublishMenu,
      // 网页版: relative -mt-2
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Container(
          // 网页版: w-10 h-10 = 40x40
          width: 40,
          height: 40,
          // 网页版: padding 1.5px
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: _auroraGradient,
          ),
          child: Container(
            // 网页版: 内圈 background #0A0E1F
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0A0E1F),
            ),
            child: Center(
              // 网页版: w-5 h-5 = 20x20, 颜色白色
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────── 发布菜单（底部弹出） ───────────────

  void _showPublishMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // 网页版: 背景遮罩 bg-black/50
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) => Container(
        // 网页版: rounded-t-2xl p-6, background rgba(10,14,31,0.98)
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFA0A0E1F), // rgba(10,14,31,0.98)
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 网页版: text-lg font-semibold mb-4 text-center text-white
            const Text(
              '发布',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // 网页版: grid grid-cols-2 gap-4 → 2列网格
            _buildPublishGrid(),

            // 网页版: w-full mt-4 py-3, color rgba(255,255,255,0.5)
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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

  /// 发布选项 2×2 网格
  Widget _buildPublishGrid() {
    final options = <_PublishOption>[
      _PublishOption(
        icon: Icons.edit_outlined,
        label: '笔记',
        onTap: () => _navigateToPublish('note'),
      ),
      _PublishOption(
        icon: Icons.brightness_2_outlined,
        label: '房间',
        onTap: () => _navigateToPublish('room'),
      ),
      _PublishOption(
        icon: Icons.menu_book_outlined,
        label: '计划',
        onTap: () => _navigateToPublish('plan'),
      ),
      _PublishOption(
        icon: Icons.file_copy_outlined,
        label: '草稿',
        onTap: () => _navigateToPublish('drafts'),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPublishGridItem(options[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildPublishGridItem(options[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPublishGridItem(options[2])),
            const SizedBox(width: 16),
            Expanded(child: _buildPublishGridItem(options[3])),
          ],
        ),
      ],
    );
  }

  /// 单个发布选项 — 对齐网页版圆形图标容器
  Widget _buildPublishGridItem(_PublishOption option) {
    return GestureDetector(
      onTap: option.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 网页版: flex flex-col items-center p-4 rounded-xl
        // background: rgba(255,255,255,0.05)
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 网页版: w-12 h-12 rounded-full, padding 2px, aurora border, inner #0A0E1F
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: _auroraGradient,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0A0E1F),
                ),
                // 网页版: 图标 w-6 h-6 = 24x24, text-color
                child: Center(
                  child: Icon(
                    option.icon,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 网页版: text-sm text-white
            Text(
              option.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── 导航逻辑 ───────────────

  void _navigateToPublish(String type) {
    Navigator.pop(context);
    switch (type) {
      case 'note':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
        break;
      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PublishVideoScreen()),
        );
        break;
      case 'room':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
        );
        break;
      case 'plan':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PublishPlanScreen()),
        );
        break;
      case 'drafts':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DraftsScreen(
              onEditDraft: (draft) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(editDraft: draft),
                  ),
                );
              },
            ),
          ),
        );
        break;
    }
  }
}

/// 发布菜单选项数据
class _PublishOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PublishOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
