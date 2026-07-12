import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Learn Extended 2 Golden Tests
/// Covers: religion_detail, room_list

// --- Common Helpers ---
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

// --- Religion Detail Page --- (aligned with web ReligionDetail.tsx)
Widget _buildReligionDetail() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // -- Aurora gradient header with stats --
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.auroraRed.withOpacity(0.3),
              AppColors.auroraOrange.withOpacity(0.2),
              AppColors.auroraBlue.withOpacity(0.2),
              AppColors.auroraPurple.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('基督教', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.share, color: Color(0xB3FFFFFF), size: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.chat_bubble, color: Color(0xB3FFFFFF), size: 16),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // Quick stats: type + followers
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                Expanded(child: _statCard('宗教类型', '亚伯拉罕宗教')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('全球信徒', '约24亿')),
              ]),
            ),
          ]),
        ),
      ),

      // -- Content --
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Basic Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardTitle(Icons.public, '基本信息'),
              const SizedBox(height: 12),
              _infoRow(Icons.location_on, '起源地区', '中东地区（以色列/巴勒斯坦）'),
              const SizedBox(height: 12),
              _infoRow(Icons.access_time, '起源时间', '公元1世纪'),
              const SizedBox(height: 12),
              _infoRow(Icons.public, '分布地区', '欧洲、美洲、大洋洲、非洲南部'),
            ]),
          ),
          const SizedBox(height: 16),

          // Core Belief card with gradient left border
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(
                width: 4,
                color: AppColors.auroraBlue,
              )),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('核心信仰', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              const Text('信仰上帝（天父）为万物的创造者，信仰耶稣基督为上帝的儿子、救世主。相信耶稣基督的降生、受难、复活和升天，为全人类的罪做了赎罪祭，使信他的人获得永生。', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 16),

          // Introduction card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardTitle(Icons.menu_book, '简介'),
              const SizedBox(height: 12),
              const Text('基督教是世界上最大的宗教之一，以耶稣基督的教导为核心。主要分为天主教、东正教和新教三大分支。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 16),

          // Related Books card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardTitle(Icons.menu_book, '相关藏书'),
              const SizedBox(height: 12),
              _relatedBook('圣经研读指南', '基督教核心经典的系统解读与注释'),
              const SizedBox(height: 12),
              _relatedBook('基督教要义', '加尔文的系统神学巨著'),
              const SizedBox(height: 12),
              _relatedBook('圣经历史背景', '深入了解圣经时代的历史文化'),
            ]),
          ),
          const SizedBox(height: 24),
        ]),
      )),
    ]),
  );
}

Widget _statCard(String label, String value) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: AppColors.auroraGradient,
    ),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgColor,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: const Color(0x99FFFFFF), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

Widget _cardTitle(IconData icon, String title) {
  return Row(children: [
    Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: AppColors.auroraGradient),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.5), color: AppColors.cardBg),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
  ]);
}

Widget _infoRow(IconData icon, String label, String value) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
    ])),
  ]);
}

Widget _relatedBook(String title, String desc) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: const Color(0x4DFFFFFF), width: 3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
    ]),
  );
}

// --- Room List Page --- (aligned with web RoomList.tsx)
Widget _buildRoomList() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: SafeArea(child: Column(children: [
      _buildGlassHeader('共修房间'),
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          Expanded(child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Row(children: [
              SizedBox(width: 12),
              Icon(Icons.search, color: AppColors.textPlaceholder, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('搜索房间名或房间ID...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
              SizedBox(width: 12),
            ]),
          )),
          const SizedBox(width: 8),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.auroraGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text('创建', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
        _buildRoomListItem('晨间冥想', '12856', '安静冥想，感受内心的平静', 5, Icons.self_improvement, '雨声', Icons.cloud),
        const SizedBox(height: 12),
        _buildRoomListItem('圣经研读', '34521', '一起研读圣经创世记', 12, Icons.menu_book, '钢琴', Icons.piano),
        const SizedBox(height: 12),
        _buildRoomListItem('静默祷告', '78903', '在静默中与神对话', 3, Icons.church, null, null),
        const SizedBox(height: 12),
        _buildRoomListItem('佛法共修', '45672', '金刚经共读与讨论', 8, Icons.self_improvement, '森林', Icons.forest),
        const SizedBox(height: 12),
        _buildRoomListItem('古兰经学习', '56104', '古兰经基础学习小组', 6, Icons.school, '海浪', Icons.water),
        const SizedBox(height: 12),
        _buildRoomListItem('道德经研读', '91235', '道德经逐章精读', 4, Icons.auto_stories, '风声', Icons.air),
      ]))),
    ])),
  );
}

Widget _buildRoomListItem(String name, String code, String desc, int users, IconData icon, String? sound, IconData? soundIcon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.auroraPurple.withOpacity(0.1),
        ),
        child: Icon(icon, color: AppColors.auroraPurple, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text('ID: $code', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.people, color: AppColors.textWeak, size: 14),
          const SizedBox(width: 4),
          Text('$users人在', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          if (sound != null && soundIcon != null) ...[
            const SizedBox(width: 12),
            Icon(soundIcon, color: AppColors.textWeak, size: 14),
            const SizedBox(width: 4),
            Text(sound, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ],
        ]),
      ])),
    ]),
  );
}
