import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'test_helper.dart';

/// Home Page Golden Test - Mock version aligned with web Home.tsx
/// Layout: header (hamburger + search), channel tabs (推荐/关注), hot ranking,
/// 2-column post grid, bottom nav

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Home page golden', (WidgetTester tester) async {
    await setupGoldenSurface(tester);
    await tester.pumpWidget(wrapForGoldenTest(_buildHome()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/page_home.png'),
    );
  });
}

Widget _buildHome() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // -- Sticky Header --
      Container(
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SafeArea(
          bottom: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Row 1: hamburger + search bar
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu, color: AppColors.textPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Icon(Icons.search, color: AppColors.iconColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('搜索笔记、信仰问题...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13))),
                  SizedBox(width: 8),
                ]),
              )),
            ]),
            const SizedBox(height: 12),
            // Channel Tabs
            Row(children: [
              _channelTab('推荐', true),
              _channelTab('关注', false),
            ]),
          ]),
        ),
      ),

      // -- Hot Ranking Section --
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.hoverBgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title row with flame icon
            Row(children: [
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: AppColors.auroraGradient),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: AppColors.bgColor),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department, color: AppColors.auroraRed, size: 12),
                    const SizedBox(width: 2),
                    const Text('热门', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              const Text('热门排行', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              _hotTab('本日', true),
              const SizedBox(width: 4),
              _hotTab('本周', false),
              const SizedBox(width: 4),
              _hotTab('本月', false),
            ]),
            const SizedBox(height: 10),
            // Top 3 hot posts
            _hotItem(1, '论信仰与科学的关系：两者并非对立', '3.2W'),
            const SizedBox(height: 6),
            _hotItem(2, '圣经创世记与现代宇宙学的对话', '2.8W'),
            const SizedBox(height: 6),
            _hotItem(3, '佛教禅修入门：如何开始你的冥想之旅', '1.9W'),
            const SizedBox(height: 6),
            _hotItem(4, '伊斯兰教的五大功课详解', '1.5W'),
            const SizedBox(height: 6),
            _hotItem(5, '道教养生之道的现代解读', '1.2W'),
          ]),
        ),
      ),

      // -- Post Grid (2 columns) --
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _postCard(
              title: '读《心经》有感',
              cover: Icons.menu_book,
              author: '慧明',
              faithTag: '佛教',
              likes: 128,
              comments: 32,
            )),
            const SizedBox(width: 12),
            Expanded(child: _postCard(
              title: '祷告的力量：我的见证',
              cover: Icons.church,
              author: '恩典',
              faithTag: '基督教',
              likes: 96,
              comments: 18,
            )),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _postCard(
              title: '古兰经中的科学奇迹',
              cover: Icons.mosque,
              author: '阿里',
              faithTag: '伊斯兰教',
              likes: 87,
              comments: 24,
            )),
            const SizedBox(width: 12),
            Expanded(child: _postCard(
              title: '道德经与现代生活哲学',
              cover: Icons.auto_stories,
              author: '清风',
              faithTag: '道教',
              likes: 75,
              comments: 15,
            )),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _postCard(
              title: '印度教的轮回与解脱',
              cover: Icons.wb_sunny,
              author: '拉吉',
              faithTag: '印度教',
              likes: 63,
              comments: 11,
            )),
            const SizedBox(width: 12),
            Expanded(child: _postCard(
              title: '犹太教安息日的意义',
              cover: Icons.star,
              author: '大卫',
              faithTag: '犹太教',
              likes: 52,
              comments: 9,
            )),
          ]),
        ]),
      )),
    ]),
    // -- Bottom Nav --
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: SafeArea(
        top: false,
        child: Row(children: [
          _navItem(Icons.home, '首页', true),
          _navItem(Icons.menu_book, '学习', false),
          _navItem(Icons.add_circle_outline, '发布', false),
          _navItem(Icons.chat_bubble_outline, '消息', false),
          _navItem(Icons.person_outline, '我的', false),
        ]),
      ),
    ),
  );
}

Widget _channelTab(String label, bool active) {
  return Padding(
    padding: const EdgeInsets.only(right: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(
        color: active ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 15,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      )),
      const SizedBox(height: 6),
      Container(
        height: 2,
        width: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: active ? AppColors.auroraGradient : null,
          color: active ? null : Colors.transparent,
        ),
      ),
    ]),
  );
}

Widget _hotTab(String label, bool active) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: active ? AppColors.auroraGradientWithOpacity(0.3) : null,
      color: active ? null : AppColors.hoverBg,
    ),
    child: Text(label, style: TextStyle(
      color: active ? AppColors.textPrimary : AppColors.textSecondary,
      fontSize: 11,
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
    )),
  );
}

Widget _hotItem(int rank, String title, String hotValue) {
  return Row(children: [
    Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: rank <= 3 ? AppColors.auroraGradientWithOpacity(0.4) : null,
        color: rank > 3 ? AppColors.hoverBg : null,
      ),
      child: Center(child: Text('$rank', style: TextStyle(
        color: rank <= 3 ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 11, fontWeight: FontWeight.bold,
      ))),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
    const SizedBox(width: 8),
    Text(hotValue, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
  ]);
}

Widget _postCard({
  required String title,
  required IconData cover,
  required String author,
  required String faithTag,
  required int likes,
  required int comments,
}) {
  return GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Cover area
      Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.hoverBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(child: Icon(cover, color: AppColors.textMuted, size: 32)),
      ),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraCyan, AppColors.auroraBlue])),
            child: Center(child: Text(author[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(author, style: TextStyle(color: AppColors.textWeak, fontSize: 11), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(4)),
            child: Text(faithTag, style: const TextStyle(color: Colors.white, fontSize: 9)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.favorite_border, color: AppColors.iconColorWeak, size: 14),
          const SizedBox(width: 2),
          Text('$likes', style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
          const SizedBox(width: 12),
          Icon(Icons.chat_bubble_outline, color: AppColors.iconColorWeak, size: 14),
          const SizedBox(width: 2),
          Text('$comments', style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
        ]),
      ])),
    ]),
  );
}

Widget _navItem(IconData icon, String label, bool active) {
  return Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: active ? AppColors.textPrimary : AppColors.textSecondary, size: 22),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
        color: active ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 10,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      )),
    ]),
  );
}
