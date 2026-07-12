import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Publish Extended Golden Tests
/// Covers: publish_video, publish_plan, drafts
/// Updated to closely match web source: PublishVideo.tsx, PublishPlan.tsx, DraftsScreen.dart

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
            const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(child: Center(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))),
          if (trailing != null) trailing else const SizedBox(width: 36),
        ],
      ),
    ),
  );
}

Widget _buildSectionLabel(InlineSpan labelSpan) {
  return Text.rich(labelSpan, style: TextStyle(color: AppColors.textWeak, fontSize: 13));
}

// Helper for label with optional aurora asterisk
InlineSpan _labelWithRequired(String text, {bool required = false}) {
  if (required) {
    return TextSpan(
      children: [
        TextSpan(text: text, style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        TextSpan(text: ' *', style: TextStyle(color: AppColors.auroraCyan, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
  return TextSpan(text: text, style: TextStyle(color: AppColors.textWeak, fontSize: 13));
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


// Tag selector row (used in video & plan)
Widget _buildTagSelector() {
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: AppColors.hoverBg,
      border: Border.all(color: AppColors.borderDefault),
    ),
    child: Row(children: [
      Expanded(child: Text('选择标签', style: TextStyle(color: AppColors.textWeak, fontSize: 14))),
      ShaderMask(
        shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
        child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

// Custom toggle switch matching web design
Widget _buildWebToggle({required bool value, required Color activeColor}) {
  return Container(
    width: 48,
    height: 24,
    decoration: BoxDecoration(
      color: value ? activeColor : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        Positioned(
          left: value ? 26 : 2,
          top: 2,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ],
    ),
  );
}

void main() {
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
// Matches PublishVideo.tsx: header(发布视频笔记, 存草稿, aurora发布),
// video upload(16:9 dashed), cover upload(16:9 dashed),
// title *(aurora asterisk), 简介, 话题标签
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
        // 视频 * (aurora asterisk)
        _buildSectionLabel(_labelWithRequired('视频', required: true)),
        const SizedBox(height: 8),
        // Video upload - 16:9 aspect ratio, dashed border
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault, style: BorderStyle.solid, width: 1.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.videocam, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              const Text('点击上传视频', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text('最大50MB', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // 视频封面（可选）
        _buildSectionLabel(_labelWithRequired('视频封面（可选）')),
        const SizedBox(height: 8),
        // Cover upload - 16:9 aspect ratio
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
        // 标题 * (aurora asterisk)
        _buildSectionLabel(_labelWithRequired('标题', required: true)),
        const SizedBox(height: 8),
        _buildInputField('填写视频标题...'),
        const SizedBox(height: 16),
        // 简介
        _buildSectionLabel(_labelWithRequired('简介')),
        const SizedBox(height: 8),
        _buildInputField('介绍一下你的视频...', maxLines: 4),
        const SizedBox(height: 16),
        // 话题标签
        _buildSectionLabel(_labelWithRequired('话题标签')),
        const SizedBox(height: 8),
        _buildTagSelector(),
      ]))),
    ]),
  );
}

// ─── Publish Plan Page ───
// Matches PublishPlan.tsx: header(发起计划, plain white 发起 button),
// Order: 计划名称, 日期, 开始时间/结束时间(grid-cols-2), 话题标签, 计划描述,
// 开启打卡功能 toggle, 允许他人参与 toggle
Widget _buildPublishPlan() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Header - bg matches bgColor, no backdrop-blur, plain white button
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Center(child: Text('发起计划', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(16)),
                child: const Text('发起', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 计划名称
        _buildSectionLabel(_labelWithRequired('计划名称')),
        const SizedBox(height: 8),
        _buildInputField('例如：每日晨间冥想30分钟'),
        const SizedBox(height: 16),
        // 日期
        _buildSectionLabel(_labelWithRequired('日期')),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.hoverBg,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.4), size: 16),
            const SizedBox(width: 12),
            const Text('2026-07-12', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 16),
        // 开始时间 / 结束时间 (grid-cols-2)
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionLabel(_labelWithRequired('开始时间')),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.hoverBg,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(children: [
                Icon(Icons.access_time, color: Colors.white.withOpacity(0.4), size: 16),
                const SizedBox(width: 8),
                const Text('09:00', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ]),
            ),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionLabel(_labelWithRequired('结束时间')),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.hoverBg,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(children: [
                Icon(Icons.access_time, color: Colors.white.withOpacity(0.4), size: 16),
                const SizedBox(width: 8),
                const Text('10:00', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ]),
            ),
          ])),
        ]),
        const SizedBox(height: 16),
        // 话题标签
        _buildSectionLabel(_labelWithRequired('话题标签')),
        const SizedBox(height: 8),
        _buildTagSelector(),
        const SizedBox(height: 16),
        // 计划描述 (4 rows textarea)
        _buildSectionLabel(_labelWithRequired('计划描述')),
        const SizedBox(height: 8),
        _buildInputField('描述你的计划目标、内容安排...', maxLines: 4),
        const SizedBox(height: 16),
        // 开启打卡功能 toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
              child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('开启打卡功能', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
            _buildWebToggle(value: true, activeColor: AppColors.auroraCyan),
          ]),
        ),
        const SizedBox(height: 12),
        // 允许他人参与 toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
              child: const Icon(Icons.people_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('允许他人参与', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
            _buildWebToggle(value: true, activeColor: AppColors.auroraCyan),
          ]),
        ),
      ]))),
    ]),
  );
}

// ─── Drafts Page ───
// Matches real DraftsScreen.dart: header(草稿箱, back arrow),
// RainbowBorder cards with bgColor, title, content preview, tags, "更新于" time
Widget _buildDrafts() {
  final now = DateTime.now();
  final drafts = [
    {'title': '我的信仰感悟', 'content': '今天读了一段很有启发的经文，分享给大家思考。信仰的力量在于内心的平静与坚定，无论在什么环境下都能给人力量。', 'tags': ['基督教', '感悟'], 'updatedAt': now.subtract(const Duration(hours: 2))},
    {'title': '禅修日记', 'content': '第30天的禅修记录。内心越来越平静，感受到了从未有过的安宁与喜悦。每天坚持打坐，身体和心灵都在发生变化。', 'tags': ['佛教', '禅修'], 'updatedAt': now.subtract(const Duration(days: 1))},
    {'title': '无标题', 'content': '今天的祷告让我感受到了真主的慈悯。感恩一切...', 'tags': ['伊斯兰教'], 'updatedAt': now.subtract(const Duration(days: 3))},
  ];

  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Header matches real DraftsScreen - bgColor, not headerBg
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Center(child: Text('草稿箱', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Column(children: [
        for (int i = 0; i < drafts.length; i++) ...[
          _buildDraftCard(
            title: drafts[i]['title'] as String,
            content: drafts[i]['content'] as String,
            tags: drafts[i]['tags'] as List<String>,
            updatedAt: drafts[i]['updatedAt'] as DateTime,
          ),
          if (i < drafts.length - 1) const SizedBox(height: 12),
        ],
      ]))),
    ]),
  );
}

Widget _buildDraftCard({required String title, required String content, required List<String> tags, required DateTime updatedAt}) {
  String formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  // RainbowBorder simulation - outer gradient border, inner bgColor fill
  return Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: AppColors.auroraGradient,
    ),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(14.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title + delete icon
        Row(children: [
          Expanded(child: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
          Icon(Icons.delete_outline, size: 20, color: AppColors.iconColorWeak),
        ]),
        const SizedBox(height: 8),
        // Content preview
        Text(content, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
        // Tags
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: tags.take(5).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.hoverBgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(tag, style: TextStyle(color: AppColors.iconColorWeak, fontSize: 11)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 10),
        // Updated time
        Text('更新于 ${formatTime(updatedAt)}', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 11)),
      ]),
    ),
  );
}
