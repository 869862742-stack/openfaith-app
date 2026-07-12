import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Rooms Page Golden Test - Mock version aligned with web RoomList.tsx
/// Layout: search bar + create button, room list items with icon, name, ID, description, user count, sound

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Room list page golden', (WidgetTester tester) async {
    await setupGoldenSurface(tester);
    await tester.pumpWidget(wrapForGoldenTest(_buildRoomList()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/page_rooms.png'),
    );
  });
}

Widget _buildRoomList() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: SafeArea(child: Column(children: [
      // -- Search bar + Create button --
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

      // -- Room list --
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _roomItem('晨间冥想', '12856', '安静冥想，感受内心的平静', 5, Icons.self_improvement, '雨声', Icons.cloud),
          const SizedBox(height: 12),
          _roomItem('圣经研读', '34521', '一起研读圣经创世记', 12, Icons.menu_book, '钢琴', Icons.piano),
          const SizedBox(height: 12),
          _roomItem('静默祷告', '78903', '在静默中与神对话', 3, Icons.church, null, null),
          const SizedBox(height: 12),
          _roomItem('佛法共修', '45672', '金刚经共读与讨论', 8, Icons.self_improvement, '森林', Icons.forest),
          const SizedBox(height: 12),
          _roomItem('古兰经学习', '56104', '古兰经基础学习小组', 6, Icons.school, '海浪', Icons.water),
          const SizedBox(height: 12),
          _roomItem('道德经研读', '91235', '道德经逐章精读', 4, Icons.auto_stories, '风声', Icons.air),
          const SizedBox(height: 12),
          _roomItem('禅修静心', '67890', '每日禅修打卡', 2, Icons.self_improvement, '自定义', Icons.music_note),
          const SizedBox(height: 24),
        ]),
      )),
    ])),
  );
}

Widget _roomItem(String name, String code, String desc, int users, IconData icon, String? sound, IconData? soundIcon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Room icon
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF9D4EDD).withOpacity(0.1),
        ),
        child: Icon(icon, color: AppColors.auroraPurple, size: 24),
      ),
      const SizedBox(width: 12),
      // Content
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Name + Room code
        Row(children: [
          Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text('ID: $code', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 4),
        // Description
        Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        // User count + sound
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
