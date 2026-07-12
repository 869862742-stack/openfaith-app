import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Publish Extended Golden Tests
/// Covers: publish_video, publish_plan, drafts

// ─── Common Helpers ───
Widget _buildGlassHeader(String title, {bool showBack = true, Widget? trailing}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          if (showBack) ...[
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(child: Center(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))),
          if (trailing != null) trailing else const SizedBox(width: 36),
        ],
      ),
    ),
  );
}

Widget _buildSectionLabel(String text) {
  return Text(text, style: TextStyle(color: AppColors.textWeak, fontSize: 13));
}

Widget _buildInputField(String hint, {int maxLines = 1}) {
  return TextField(
    enabled: false,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
      filled: true,
      fillColor: AppColors.hoverBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
    ),
  );
}

void main() {
    setUpAll(() async {
      await initTestDependencies();
    });
  group('Publish Extended Golden Tests', () {
    testWidgets('publish_video page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildPublishVideo()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_publish_video.png'));
    });

    testWidgets('publish_plan page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildPublishPlan()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_publish_plan.png'));
    });

    testWidgets('drafts page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildDrafts()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_drafts.png'));
    });
  });
}

// ─── Publish Video Page ───
Widget _buildPublishVideo() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('发布视频笔记', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('存草稿', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(16)),
          child: const Text('发布', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionLabel('视频 *'),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault, style: BorderStyle.solid, width: 1.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.video_library, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            const Text('点击上传视频', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            Text('最大50MB', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('视频封面（可选）'),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault, style: BorderStyle.solid, width: 1.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate, size: 32, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              const Text('点击上传封面', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('标题'),
        const SizedBox(height: 8),
        _buildInputField('填写视频标题...'),
        const SizedBox(height: 16),
        _buildSectionLabel('简介'),
        const SizedBox(height: 8),
        _buildInputField('介绍一下你的视频...', maxLines: 4),
        const SizedBox(height: 16),
        _buildSectionLabel('话题标签'),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
          child: Row(children: [
            Expanded(child: Text('选择标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
              child: const Text('+', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ),
          ]),
        ),
      ]))),
    ]),
  );
}

// ─── Publish Plan Page ───
Widget _buildPublishPlan() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('发起计划', trailing: const Text('发起', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionLabel('计划名称'),
        const SizedBox(height: 8),
        _buildInputField('例如：每日晨间冥想30分钟'),
        const SizedBox(height: 16),
        _buildSectionLabel('日期'),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
          child: Row(children: [
            Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text('2026-07-13', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
          ]),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('时间段'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
            child: Row(children: [
              Icon(Icons.access_time, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text('09:00', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ]),
          )),
          const SizedBox(width: 8),
          Expanded(child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
            child: Row(children: [
              Icon(Icons.access_time, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text('10:00', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ]),
          )),
        ]),
        const SizedBox(height: 16),
        _buildSectionLabel('计划描述'),
        const SizedBox(height: 8),
        _buildInputField('描述你的计划...', maxLines: 3),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor, width: 0.5)),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: AppColors.auroraBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text('每日打卡提醒', style: const TextStyle(color: Colors.white, fontSize: 15))),
            Switch(value: true, onChanged: (_) {}, activeColor: AppColors.auroraBlue),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor, width: 0.5)),
          child: Row(children: [
            Icon(Icons.public, color: AppColors.auroraGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text('公开计划', style: const TextStyle(color: Colors.white, fontSize: 15))),
            Switch(value: true, onChanged: (_) {}, activeColor: AppColors.auroraBlue),
          ]),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('话题标签'),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
          child: Row(children: [
            Expanded(child: Text('选择标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
              child: const Text('+', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ),
          ]),
        ),
      ]))),
    ]),
  );
}

// ─── Drafts Page ───
Widget _buildDrafts() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('草稿箱'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildDraftCard(
          title: '我的信仰感悟',
          content: '今天读了一段很有启发的经文，分享给大家思考。信仰的力量在于内心的平静与坚定...',
          tags: ['基督教', '感悟'],
          time: '2小时前',
        ),
        const SizedBox(height: 12),
        _buildDraftCard(
          title: '禅修日记',
          content: '第30天的禅修记录。内心越来越平静，感受到了从未有过的安宁...',
          tags: ['佛教', '禅修'],
          time: '昨天',
        ),
        const SizedBox(height: 12),
        _buildDraftCard(
          title: '',
          content: '今天的祷告让我感受到了真主的慈悯。感恩一切...',
          tags: ['伊斯兰教'],
          time: '3天前',
        ),
      ]))),
    ]),
  );
}

Widget _buildDraftCard({required String title, required String content, required List<String> tags, required String time}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(
          title.isNotEmpty ? title : content,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        Text(time, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ]),
      if (title.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
      if (tags.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 4, children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(10)),
          child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        )).toList()),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Icon(Icons.edit_outlined, color: AppColors.auroraBlue, size: 16),
        const SizedBox(width: 4),
        Text('继续编辑', style: TextStyle(color: AppColors.auroraBlue, fontSize: 13)),
        const Spacer(),
        Icon(Icons.delete_outline, color: AppColors.textWeak, size: 16),
        const SizedBox(width: 4),
        Text('删除', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
      ]),
    ]),
  );
}
