import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'test_helper.dart';

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
    setUpAll(() async {
      await initTestDependencies();
    });
  group('Learn Extended 2 Golden Tests', () {
    testWidgets('religion_detail page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildReligionDetail()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_religion_detail.png'));
    });

    testWidgets('room_list page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildRoomList()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_room_list.png'));
    });
  });
}

// ─── Religion Detail Page ───
Widget _buildReligionDetail() {
  // Web版是"基督教（新教）"详情页面，包含基本信息、核心信仰、简介等
  // 修改mock UI结构使其更接近web版
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('基督教（新教）'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Two info cards with rainbow border
        Row(children: [
          Expanded(child: _buildRainbowCard('宗教类型', '一神教', Icons.public)),
          const SizedBox(width: 8),
          Expanded(child: _buildRainbowCard('全球信徒', '约9亿', Icons.people)),
        ]),
        const SizedBox(height: 16),
        // Basic info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('基本信息', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, '起源地区', '欧洲德国、瑞士、英国等地'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, '起源时间', '16世纪（1517年马丁·路德发表《九十五条论纲》）'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.map, '分布地区', '北欧五国、德国、瑞士、英国、美国、加拿大、澳大利亚'),
          ]),
        ),
        const SizedBox(height: 16),
        // Core beliefs card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradientWithOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('核心信仰', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('因信称义、信徒皆祭司、圣经为信仰最高权威，强调个人直接与上帝相通，简化圣事礼仪', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 16),
        // Introduction card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('简介', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('新教是基督教三大主流分支之一，于16世纪欧洲宗教改革运动中脱离罗马天主教而形成。新教不承认罗马教宗的权威，主张《圣经》为信仰的唯一最高准则，强调信徒个人可直接与上帝沟通而无须神职中介。', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5)),
          ]),
        ),
      ]))),
    ]),
  );
}

Widget _buildRainbowCard(String label, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: AppColors.auroraGradient,
    ),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.5),
        color: AppColors.bgColor,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.textSecondary, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
      ])),
    ],
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
