import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Home page golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
        home: Scaffold(
          backgroundColor: AppColors.bgColor,
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('搜索帖子...', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTab('推荐', true),
                    const SizedBox(width: 16),
                    _buildTab('关注', false),
                    const SizedBox(width: 16),
                    _buildTab('标签', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Post list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPostCard('信仰 seekers', '2小时前', '今天的灵修分享', '基督徒生活', '🙏'),
                    const SizedBox(height: 12),
                    _buildPostCard('恩典之路', '5小时前', '读经心得', '圣经学习', ''),
                    const SizedBox(height: 12),
                    _buildPostCard('赞美之声', '1天前', '诗歌推荐', '敬拜赞美', '🎵'),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.navBg,
              border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, '首页', true),
                _buildNavItem(Icons.explore, '发现', false),
                _buildNavItem(Icons.add_circle, '发布', false),
                _buildNavItem(Icons.chat_bubble, '消息', false),
                _buildNavItem(Icons.person, '我的', false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_home.png'));
  });
}

Widget _buildTab(String label, bool active) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: active ? Colors.white : Colors.transparent, width: 2)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.white : AppColors.textSecondary,
        fontSize: 14,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

Widget _buildPostCard(String author, String time, String title, String tag, String emoji) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.auroraGradient,
              ),
              child: const Center(child: Text('X', style: TextStyle(color: Colors.white, fontSize: 14))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(time, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
                ],
              ),
            ),
            Text(emoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(tag, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ),
      ],
    ),
  );
}

Widget _buildNavItem(IconData icon, String label, bool active) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: active ? Colors.white : AppColors.textSecondary, size: 22),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textWeak, fontSize: 10)),
    ],
  );
}
