import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'test_helper.dart';

/// Learn Page Golden Test - Mock version aligned with web Learn.tsx
/// Replaces real LearnScreen (which needs Supabase) with a static mock

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
      // ── Header: Search + Tabs ──
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
                Expanded(child: Text('搜索宗教、经典、节日...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
                SizedBox(width: 12),
              ]),
            ),
          ),
          // Main tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _learnTab(Icons.menu_book, '百科', true),
              const SizedBox(width: 8),
              _learnTab(Icons.library_books, '藏经阁', false),
              const SizedBox(width: 8),
              _learnTab(Icons.calendar_today, '日历', false),
            ]),
          ),
          const SizedBox(height: 8),
        ]),
      ),

      // ── Encyclopedia Tab Content ──
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Section title
          const Text('世界主要宗教', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Religion cards grid (2 columns)
          Row(children: [
            Expanded(child: _religionCard(Icons.church, '基督教', '24亿信徒', AppColors.auroraBlue)),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.mosque, '伊斯兰教', '19亿信徒', AppColors.auroraGreen)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.self_improvement, '佛教', '5亿信徒', AppColors.auroraOrange)),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.star, '印度教', '12亿信徒', AppColors.auroraRed)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.menu_book, '犹太教', '1500万信徒', AppColors.auroraYellow)),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.auto_stories, '道教', '1200万信徒', AppColors.auroraCyan)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _religionCard(Icons.wb_sunny, '锡克教', '3000万信徒', AppColors.auroraPurple)),
            const SizedBox(width: 12),
            Expanded(child: _religionCard(Icons.public, '巴哈伊教', '800万信徒', AppColors.auroraGreen)),
          ]),

          const SizedBox(height: 24),
          // Section title for popular books
          const Text('热门经典', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Book cards
          _bookCard('圣经', '基督教', '基督教的核心经典，包含旧约和新约两大部分'),
          const SizedBox(height: 8),
          _bookCard('古兰经', '伊斯兰教', '伊斯兰教的根本经典，穆斯林信仰的最高权威'),
          const SizedBox(height: 8),
          _bookCard('金刚经', '佛教', '大乘佛教重要经典，阐述般若空性思想'),
        ]),
      )),

      // ── Contribution Footer ──
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppColors.auroraGradientWithOpacity(0.5),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.5),
                color: AppColors.bgColor,
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble, color: AppColors.textPrimary, size: 14),
                SizedBox(width: 4),
                Text('参与共建', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ),

      // ── Bottom Nav ──
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

Widget _religionCard(IconData icon, String name, String scale, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.hoverBgLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderDefault),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 10),
      Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(scale, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ]),
  );
}

Widget _bookCard(String title, String religion, String desc) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.hoverBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Icon(Icons.auto_stories, color: AppColors.textPrimary, size: 20)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('$religion · $desc', style: const TextStyle(color: AppColors.textWeak, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 18),
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
