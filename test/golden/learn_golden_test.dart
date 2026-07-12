import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Learn Page Golden Test - Mock version aligned with web Learn.tsx
/// Layout: header (search + 3 tabs), encyclopedia tab (2-col religion grid), bottom nav

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Learn page golden', (WidgetTester tester) async {
    await setupGoldenSurface(tester);
    await tester.pumpWidget(wrapForGoldenTest(_buildLearn()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/page_learning.png'),
    );
  });
}

Widget _buildLearn() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: SafeArea(child: Column(children: [
      // -- Header: Search + Tabs --
      Container(
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: Column(children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                SizedBox(width: 12),
                Icon(Icons.search, color: AppColors.iconColorWeak, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('搜索宗教...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
                SizedBox(width: 12),
              ]),
            ),
          ),
          // Main tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _learnTab(Icons.menu_book, '百科', true),
              const SizedBox(width: 8),
              _learnTab(Icons.library_books, '藏经阁', false),
              const SizedBox(width: 8),
              _learnTab(Icons.calendar_today, '日历', false),
            ]),
          ),
        ]),
      ),

      // -- Encyclopedia Tab Content: 2-col religion grid --
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: _religionCard(Icons.church, '基督教', '约24亿信徒')),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.mosque, '伊斯兰教', '约19亿信徒')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.self_improvement, '佛教', '约5亿信徒')),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.star, '印度教', '约12亿信徒')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.menu_book, '犹太教', '约1500万信徒')),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.auto_stories, '道教', '约1200万信徒')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.wb_sunny, '锡克教', '约3000万信徒')),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.public, '巴哈伊教', '约800万信徒')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.favorite, '耆那教', '约400万信徒')),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.nature, '神道教', '约400万信徒')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.local_fire_department, '琐罗亚斯德教', '约20万信徒')),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.landscape, '万物有灵论', '约2亿信徒')),
          ]),
        ]),
      )),

      // -- Bottom Nav --
      Container(
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        child: SafeArea(
          top: false,
          child: Row(children: [
            _navItem(Icons.home, '首页', false),
            _navItem(Icons.menu_book, '学习', true),
            _navItem(Icons.add_circle_outline, '发布', false),
            _navItem(Icons.chat_bubble_outline, '消息', false),
            _navItem(Icons.person_outline, '我的', false),
          ]),
        ),
      ),
    ])),
  );
}

Widget _learnTab(IconData icon, String label, bool active) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: active ? AppColors.auroraGradient : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? AppColors.bgColor : Colors.transparent,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: active ? AppColors.textPrimary : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          )),
        ]),
      ),
    ),
  );
}

Widget _religionCard(IconData icon, String name, String scale) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1AFFFFFF)), // rgba(255,255,255,0.1)
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.auroraCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.auroraCyan, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 6),
      Text(scale, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
