import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Profile Extended Golden Tests
/// Covers: switch_account, heating_records, my_posts

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
  group('Profile Extended Golden Tests', () {
    testWidgets('switch_account page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSwitchAccount()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_switch_account.png'));
    });

    testWidgets('heating_records page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildHeatingRecords()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_heating_records.png'));
    });

    testWidgets('my_posts page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildMyPosts()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_my_posts.png'));
    });
  });
}

// ─── Switch Account Page ─── (aligned with SwitchAccountScreen source)
Widget _buildSwitchAccount() {
  return Scaffold(
    backgroundColor: const Color(0xFF0E0E22),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0E0E22),
      elevation: 0,
      leading: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      title: const Text('切换账号', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
    ),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('当前及已关联账号', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
      const SizedBox(height: 12),
      // Current account card with rainbow border
      Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [
            Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
            Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
          ]),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A86FF), Color(0xFF9D4EDD)]),
                ),
                child: const Center(child: Text('O', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
              Positioned(
                bottom: -2, right: -2,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF70E000), Color(0xFF00E5FF)]),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('OpenFaith', style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0x0DFFFFFF),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text('user@openfaithhub.com', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ])),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      // Add account button (outlined style)
      CustomPaint(
        painter: _DashedBorderPainter(
          borderRadius: 12,
          color: const Color(0xFFCBD5E1),
          strokeWidth: 2,
          dashLength: 6,
          gapLength: 4,
        ),
        child: Container(
          width: double.infinity, height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFEF2F2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person_add_outlined, color: AppColors.textWeak, size: 20),
            const SizedBox(width: 8),
            Text('添加新账号', style: TextStyle(color: AppColors.textWeak, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      // Security notice card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: AppColors.auroraBlue, size: 16),
            const SizedBox(width: 8),
            Text('账号安全提示', style: TextStyle(color: AppColors.auroraBlue, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text('切换账号功能方便您在多个身份间快速跳转。请确保所有关联账号均为本人使用，以保护您的灵性成长数据与个人隐私。',
              style: TextStyle(color: AppColors.textWeak, fontSize: 12, height: 1.5)),
        ]),
      ),
    ])),
  );
}

// ─── Heating Records Page ───
Widget _buildHeatingRecords() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('加热记录'),
      // Stats
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
        ),
        child: Row(children: [
          _buildHeatingStat('3', '已加热'),
          Container(width: 1, height: 32, color: AppColors.borderDefault),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20)),
          _buildHeatingStat('5', '剩余加热卡'),
          Container(width: 1, height: 32, color: AppColors.borderDefault),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20)),
          _buildHeatingStat('128', '总曝光'),
        ]),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildHeatingRecordCard('我的信仰感悟', '2026-07-10 14:30', '42次曝光', '进行中'),
        const SizedBox(height: 12),
        _buildHeatingRecordCard('禅修日记分享', '2026-07-08 09:15', '56次曝光', '已结束'),
        const SizedBox(height: 12),
        _buildHeatingRecordCard('道德经研读笔记', '2026-07-05 18:20', '30次曝光', '已结束'),
      ]))),
    ]),
  );
}

Widget _buildHeatingStat(String value, String label) {
  return Expanded(child: Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
  ]));
}

Widget _buildHeatingRecordCard(String title, String time, String views, String status) {
  final isActive = status == '进行中';
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isActive ? AppColors.auroraBlue.withOpacity(0.3) : AppColors.borderColor, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.auroraBlue.withOpacity(0.15) : AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status, style: TextStyle(color: isActive ? AppColors.auroraBlue : AppColors.textWeak, fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Icon(Icons.access_time, color: AppColors.textWeak, size: 14),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        const SizedBox(width: 16),
        Icon(Icons.visibility_outlined, color: AppColors.textWeak, size: 14),
        const SizedBox(width: 4),
        Text(views, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ]),
    ]),
  );
}

// ─── My Posts Page ───
Widget _buildMyPosts() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('我的帖子'),
      // Tab bar
      Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5))),
        child: Row(children: [
          _buildMyPostsTab('全部', true),
          _buildMyPostsTab('笔记', false),
          _buildMyPostsTab('视频', false),
          _buildMyPostsTab('计划', false),
        ]),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildMyPostCard(
          title: '我的信仰感悟',
          content: '今天读了一段很有启发的经文，分享给大家思考。信仰的力量在于内心的平静与坚定。',
          time: '2小时前',
          likes: 42,
          comments: 8,
        ),
        const SizedBox(height: 12),
        _buildMyPostCard(
          title: '禅修日记第30天',
          content: '内心越来越平静，感受到了从未有过的安宁。禅修真的能改变一个人的内心世界。',
          time: '昨天',
          likes: 128,
          comments: 23,
        ),
        const SizedBox(height: 12),
        _buildMyPostCard(
          title: '',
          content: '今天的祷告让我感受到了真主的慈悯。感恩一切。',
          time: '3天前',
          likes: 67,
          comments: 12,
        ),
      ]))),
    ]),
  );
}

Widget _buildMyPostsTab(String label, bool active) {
  return Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(border: active ? Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2)) : null),
    child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
  ));
}

Widget _buildMyPostCard({required String title, required String content, required String time, required int likes, required int comments}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
      ],
      Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 12),
      Row(children: [
        Text(time, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        const Spacer(),
        Icon(Icons.favorite_border, color: AppColors.iconColorWeak, size: 16),
        const SizedBox(width: 4),
        Text('$likes', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
        const SizedBox(width: 16),
        Icon(Icons.chat_bubble_outline, color: AppColors.iconColorWeak, size: 16),
        const SizedBox(width: 4),
        Text('$comments', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ]),
    ]),
  );
}


// ─── Dashed Border Painter ───
class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final extract = metric.extractPath(distance, end);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
  }
}
