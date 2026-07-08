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

  // 七彩渐变
  static const _auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD)],
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

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050816),
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, '首页'),
              _buildNavItem(1, Icons.explore_outlined, Icons.explore, '学习'),
              _buildPublishButton(),
              _buildNavItem(2, Icons.notifications_outlined, Icons.notifications, '消息', showBadge: true),
              _buildNavItem(3, Icons.person_outline, Icons.person, '我的'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: _showPublishMenu,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(1.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: _auroraGradient,
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF050816),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF4D6D), Color(0xFF00E5FF), Color(0xFF9D4EDD)],
              ).createShader(bounds),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {bool showBadge = false}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                isSelected
                    ? ShaderMask(
                        shaderCallback: (bounds) => _auroraGradient.createShader(bounds),
                        child: Icon(activeIcon, color: Colors.white, size: 24),
                      )
                    : Icon(icon, size: 24, color: Colors.white.withOpacity(0.5)),
                if (showBadge && _unreadCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublishMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '发布内容',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _publishOption(Icons.article_outlined, '笔记', () => _navigateToPublish('note')),
                _publishOption(Icons.videocam_outlined, '视频', () => _navigateToPublish('video')),
                _publishOption(Icons.meeting_room_outlined, '房间', () => _navigateToPublish('room')),
                _publishOption(Icons.event_outlined, '计划', () => _navigateToPublish('plan')),
                _publishOption(Icons.file_copy_outlined, '草稿', () => _navigateToPublish('drafts')),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _publishOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.rainbowEnd, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _navigateToPublish(String type) {
    Navigator.pop(context);
    switch (type) {
      case 'note':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        break;
      case 'video':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishVideoScreen()));
        break;
      case 'room':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
        break;
      case 'plan':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishPlanScreen()));
        break;
      case 'drafts':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DraftsScreen(
              onEditDraft: (draft) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreatePostScreen(editDraft: draft)),
                );
              },
            ),
          ),
        );
        break;
    }
  }
}