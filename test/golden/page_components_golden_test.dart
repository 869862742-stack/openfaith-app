import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/theme/app_spacing.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';
import 'package:openfaith_app/widgets/aurora_icon_button.dart';
import 'package:openfaith_app/widgets/religion_icon.dart';
import 'package:openfaith_app/widgets/glass_card.dart';

void main() {
  group('Page Component Golden Tests', () {
    
    testWidgets('AuroraButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuroraButton(
                    text: '登录',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  AuroraButton(
                    text: '注册账号',
                    icon: Icons.person_add,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  AuroraButtonFilled(
                    text: '提交',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_aurora_button.png'));
    });

    testWidgets('AuroraIconButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuroraIconButton(
                    icon: Icons.home_outlined,
                    isActive: true,
                    label: '首页',
                  ),
                  const SizedBox(width: 24),
                  AuroraIconButton(
                    icon: Icons.explore_outlined,
                    isActive: false,
                    label: '学习',
                  ),
                  const SizedBox(width: 24),
                  AuroraIconButton(
                    icon: Icons.notifications_outlined,
                    isActive: false,
                    label: '消息',
                    badgeCount: 5,
                  ),
                  const SizedBox(width: 24),
                  AuroraIconButton(
                    icon: Icons.person_outline,
                    isActive: false,
                    label: '我的',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_aurora_icon_button.png'));
    });

    testWidgets('AuroraAvatar renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuroraAvatar(
                    size: 48,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.auroraRed, AppColors.auroraOrange],
                        ),
                      ),
                      child: const Center(
                        child: Text('U', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AuroraAvatar(
                    size: 64,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.auroraBlue, AppColors.auroraPurple],
                        ),
                      ),
                      child: const Center(
                        child: Text('A', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_aurora_avatar.png'));
    });

    testWidgets('ReligionIconWidget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildReligionIconItem('基督教'),
                  _buildReligionIconItem('伊斯兰教'),
                  _buildReligionIconItem('佛教'),
                  _buildReligionIconItem('犹太教'),
                  _buildReligionIconItem('印度教'),
                  _buildReligionIconItem('道教'),
                  _buildReligionIconItem('锡克教'),
                  _buildReligionIconItem('巴哈伊教'),
                  _buildReligionIconItem('神道教'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_religion_icons.png'));
    });

    testWidgets('Post card mockup renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: SizedBox(
                width: 360,
                child: _buildPostCard(
                  authorName: '张三',
                  authorAvatar: 'Z',
                  avatarGradient: [AppColors.auroraRed, AppColors.auroraOrange],
                  faithTag: '基督教',
                  timeAgo: '2小时前',
                  content: '今天读了一段很有启发的经文，分享给大家思考。信仰的力量在于内心的平静与坚定。',
                  likeCount: 42,
                  commentCount: 8,
                  shareCount: 3,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_post_card.png'));
    });

    testWidgets('Profile header mockup renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: SizedBox(
                width: 360,
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            AuroraAvatar(
                              size: 64,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppColors.auroraBlue, AppColors.auroraPurple],
                                  ),
                                ),
                                child: const Center(
                                  child: Text('李', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '李四',
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.auroraGradientWithOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '基督教',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Lv.5 融通者',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('128', '帖子'),
                            _buildStatItem('1.2k', '粉丝'),
                            _buildStatItem('256', '关注'),
                            _buildStatItem('5.6k', '热度'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_profile_header.png'));
    });

    testWidgets('Search bar renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: SizedBox(
                width: 360,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.textPlaceholder, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '搜索帖子、用户、标签...',
                          style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_search_bar.png'));
    });

    testWidgets('Tab bar renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: SizedBox(
                width: 360,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem('推荐', true),
                      _buildTabItem('关注', false),
                      _buildTabItem('标签', false),
                      _buildTabItem('共修', false),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_tab_bar.png'));
    });

    testWidgets('Settings list renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: SizedBox(
                width: 360,
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSettingsItem(Icons.person, '个人资料', '编辑头像、昵称等'),
                      const SizedBox(height: 4),
                      _buildSettingsItem(Icons.security, '账号安全', '密码、登录设备'),
                      const SizedBox(height: 4),
                      _buildSettingsItem(Icons.notifications, '通知设置', '推送、消息提醒'),
                      const SizedBox(height: 4),
                      _buildSettingsItem(Icons.palette, '显示设置', '主题、字体大小'),
                      const SizedBox(height: 4),
                      _buildSettingsItem(Icons.language, '语言', '简体中文'),
                      const SizedBox(height: 4),
                      _buildSettingsItem(Icons.info, '关于', '版本 1.0.0'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_settings_list.png'));
    });
  });
}

Widget _buildReligionIconItem(String name) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ReligionIconWidget(name: name, size: 32),
      const SizedBox(height: 4),
      Text(
        name.length > 4 ? '${name.substring(0, 4)}..' : name,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    ],
  );
}

Widget _buildPostCard({
  required String authorName,
  required String authorAvatar,
  required List<Color> avatarGradient,
  required String faithTag,
  required String timeAgo,
  required String content,
  required int likeCount,
  required int commentCount,
  required int shareCount,
}) {
  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AuroraAvatar(
                size: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: avatarGradient,
                    ),
                  ),
                  child: Center(
                    child: Text(authorAvatar, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: AppColors.auroraGradientWithOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(faithTag, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Text(timeAgo, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionItem(Icons.favorite_border, '$likeCount'),
              const SizedBox(width: 24),
              _buildActionItem(Icons.chat_bubble_outline, '$commentCount'),
              const SizedBox(width: 24),
              _buildActionItem(Icons.share_outlined, '$shareCount'),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildActionItem(IconData icon, String count) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.iconColorWeak, size: 18),
      const SizedBox(width: 4),
      Text(count, style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
    ],
  );
}

Widget _buildStatItem(String value, String label) {
  return Column(
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ],
  );
}

Widget _buildTabItem(String label, bool isActive) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isActive
            ? Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2))
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
      ],
    ),
  );
}
