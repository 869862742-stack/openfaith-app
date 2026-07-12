import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';

/// Learn Extended 2 Golden Tests
/// Covers: religion_detail, room_list

// ─── Common Helpers ───
Widget _buildGlassHeader(String title) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: SafeArea(
      bottom: false,
      child: Row(children: [
        const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Center(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 36),
      ]),
    ),
  );
}

void main() {
  group('Learn Extended 2 Golden Tests', () {
    testWidgets('religion_detail page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildReligionDetail()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_religion_detail.png'));
    });

    testWidgets('room_list page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildRoomList()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_room_list.png'));
    });
  });
}

// ─── Religion Detail Page ───
Widget _buildReligionDetail() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('基督教'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradientWithOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
              ),
              child: const Center(child: Icon(Icons.church, color: Colors.white, size: 32)),
            ),
            const SizedBox(height: 12),
            const Text('基督教', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('全球约24亿信徒', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            const Text('基督教是世界最大的宗教之一，以耶稣基督为核心，信仰上帝（天父）创造和救赎的爱。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5, shadows: []), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 24),
        // Section: Key texts
        _buildDetailSection('核心经典', [
          _buildBookChip('圣经'),
          _buildBookChip('旧约'),
          _buildBookChip('新约'),
        ]),
        const SizedBox(height: 20),
        // Section: Practices
        _buildDetailSection('主要宗派', [
          _buildBookChip('天主教'),
          _buildBookChip('新教'),
          _buildBookChip('东正教'),
        ]),
        const SizedBox(height: 20),
        // Section: Books
        _buildDetailSection('推荐书籍', [
          _buildBookCard('圣经研读指南', '张牧师', 4.8),
          const SizedBox(height: 8),
          _buildBookCard('基督教要义', '加尔文', 4.9),
        ]),
        const SizedBox(height: 24),
        // Follow button
        Container(
          width: double.infinity, height: 48,
          decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(24)),
          child: const Center(child: Text('+ 关注', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        ),
      ]))),
    ]),
  );
}

Widget _buildDetailSection(String title, List<Widget> children) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 12),
    ...children,
  ]);
}

Widget _buildBookChip(String label) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.auroraGradientWithOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ),
  );
}

Widget _buildBookCard(String title, String author, double rating) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: AppColors.auroraGradientWithOpacity(0.3),
        ),
        child: const Icon(Icons.menu_book, color: Colors.white, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(author, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ])),
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star, color: AppColors.auroraYellow, size: 16),
        const SizedBox(width: 4),
        Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    ]),
  );
}

// ─── Room List Page ───
Widget _buildRoomList() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('共修房间'),
      // Search bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.search, color: AppColors.textPlaceholder, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('搜索房间...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
          ]),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
        _buildRoomListItem('晨间冥想', '5人在线', '冥想', Icons.self_improvement),
        const SizedBox(height: 8),
        _buildRoomListItem('圣经研读', '12人在线', '读书', Icons.menu_book),
        const SizedBox(height: 8),
        _buildRoomListItem('静默祷告', '3人在线', '祈祷', Icons.church),
        const SizedBox(height: 8),
        _buildRoomListItem('佛法共修', '8人在线', '禅修', Icons.self_improvement),
        const SizedBox(height: 8),
        _buildRoomListItem('古兰经学习', '6人在线', '学习', Icons.school),
        const SizedBox(height: 8),
        _buildRoomListItem('道德经研读', '4人在线', '读书', Icons.auto_stories),
      ]))),
    ]),
  );
}

Widget _buildRoomListItem(String name, String info, String tag, IconData icon) {
  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradientWithOpacity(0.3)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(info, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(12)),
          child: const Text('加入', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
    ),
  );
}
