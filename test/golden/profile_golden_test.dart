import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Profile Page Golden Test - Mock version aligned with web Profile.tsx
/// Layout: starry background, avatar with rainbow border, name + faith tag,
/// ID + QR + edit, stats row, level bar, bio card, tabs, notes grid, bottom nav

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Profile page golden', (WidgetTester tester) async {
    await setupGoldenSurface(tester);
    await tester.pumpWidget(wrapForGoldenTest(_buildProfile()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/page_profile.png'),
    );
  });
}

Widget _buildProfile() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // -- Background with starry dots + hamburger + share --
      Container(
        height: 192,
        decoration: const BoxDecoration(color: Color(0xFF050816)),
        child: Stack(children: [
          // Starry dots
          Positioned.fill(child: CustomPaint(painter: _StarryPainter())),
          // Top buttons
          SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.hoverBg, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.hoverBg, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.share, color: Colors.white, size: 20),
              ),
            ]),
          )),
        ]),
      ),

      // -- Overlapping content --
      Expanded(child: SingleChildScrollView(
        child: Column(children: [
          // Avatar with rainbow border
          Container(
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.auroraGradient,
            ),
            child: Container(
              width: 92, height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgSecondary,
              ),
              child: const Center(child: Icon(Icons.person, color: Colors.white, size: 40)),
            ),
          ),

          const SizedBox(height: 12),

          // Username + faith tag
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('OpenFaith', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.hoverBgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('基督教', style: TextStyle(color: Color(0xCCCCCCCC), fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ID + QR + Edit
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('ID: 10001', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.qr_code_2, color: AppColors.textSecondary, size: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            ),
          ]),

          const SizedBox(height: 16),

          // Stats row: followers, following, heat, hot points
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              _statItem(Icons.people, '128', '粉丝'),
              _statItem(Icons.people_outline, '56', '关注'),
              _statItem(Icons.local_fire_department, '2.3W', '热度'),
              _statItem(Icons.bolt, '1580', '热点'),
            ]),
          ),

          const SizedBox(height: 12),

          // Level pill + exp bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.hoverBgLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('LV.3 思辨者', style: TextStyle(color: Color(0xCCCCCCCC), fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96, height: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(color: AppColors.bgSecondary, child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  )),
                ),
              ),
              const SizedBox(width: 4),
              Text('65%', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),

          const SizedBox(height: 16),

          // Bio card with rainbow border
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradientWithOpacity(0.5),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.5),
                  color: AppColors.bgColor,
                ),
                child: const Text('信仰是一场内心的旅程，愿在这里与大家共同成长，探索生命的意义与价值。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tabs: 笔记 / 计划 / 收藏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _profileTab('笔记', true),
              const SizedBox(width: 8),
              _profileTab('计划', false),
              const SizedBox(width: 8),
              _profileTab('收藏', false),
            ]),
          ),

          const SizedBox(height: 12),

          // Notes grid (2 columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _noteCard(Icons.menu_book, '读《心经》有感')),
                const SizedBox(width: 12),
                Expanded(child: _noteCard(Icons.church, '祷告的力量')),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _noteCard(Icons.mosque, '古兰经中的科学')),
                const SizedBox(width: 12),
                Expanded(child: _noteCard(Icons.auto_stories, '道德经感悟')),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _noteCard(Icons.star, '信仰与理性')),
                const SizedBox(width: 12),
                Expanded(child: _noteCard(Icons.wb_sunny, '冥想日记')),
              ]),
            ]),
          ),

          const SizedBox(height: 80), // space for bottom nav
        ]),
      )),
    ]),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: SafeArea(
        top: false,
        child: Row(children: [
          _navItem(Icons.home, '首页', false),
          _navItem(Icons.menu_book, '学习', false),
          _navItem(Icons.add_circle_outline, '发布', false),
          _navItem(Icons.chat_bubble_outline, '消息', false),
          _navItem(Icons.person, '我的', true),
        ]),
      ),
    ),
  );
}

Widget _statItem(IconData icon, String value, String label) {
  return Expanded(child: Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: const Color(0x99FFFFFF), size: 16),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]));
}

Widget _profileTab(String label, bool active) {
  if (active) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: AppColors.auroraGradient),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppColors.bgColor),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x33FFFFFF)),
    ),
    child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
  );
}

Widget _noteCard(IconData icon, String title) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(
      aspectRatio: 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Icon(icon, color: AppColors.textMuted, size: 32)),
      ),
    ),
    const SizedBox(height: 6),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  ]);
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

/// Simple starry dots painter for profile background
class _StarryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dots = [
      _Dot(0.10, 0.30, 1.5, const Color(0xCCFFFFFF)),
      _Dot(0.40, 0.60, 1.0, const Color(0xB3C8DCFF)),
      _Dot(0.70, 0.20, 2.0, const Color(0xE6FFFFFF)),
      _Dot(0.85, 0.70, 1.0, const Color(0xB3B4C8FF)),
      _Dot(0.25, 0.80, 1.2, const Color(0x99FFFFFF)),
      _Dot(0.55, 0.45, 1.0, const Color(0xCCFFD60A)),
      _Dot(0.90, 0.40, 1.5, const Color(0xB3FFFFFF)),
      _Dot(0.15, 0.55, 1.0, const Color(0x99B4C8FF)),
    ];
    for (final d in dots) {
      final paint = Paint()..color = d.color;
      canvas.drawCircle(Offset(size.width * d.x, size.height * d.y), d.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Dot {
  final double x, y, r;
  final Color color;
  _Dot(this.x, this.y, this.r, this.color);
}
