import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Publish Note Golden Test
/// Mock matches web PublishNote.tsx default state layout exactly:
/// Header(发布笔记, 存草稿, aurora发布), 3-col image grid(add button),
/// title(22px bold, filled input), content(16px, filled textarea),
/// tags(+添加标签), 加热卡 toggle

void main() {
  testWidgets('Publish note page golden', (WidgetTester tester) async {
    await setupGoldenSurface(tester);
    await tester.pumpWidget(wrapForGoldenTest(_buildPublishNoteMock()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_publish_note.png'),
    );
  });
}

Widget _buildPublishNoteMock() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(
      children: [
        // ─── Header ───
        // Matches web: back arrow, "发布笔记" centered, 存草稿 ghost button, 发布 aurora button
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
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                ),
                const Expanded(
                  child: Text(
                    '发布笔记',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 存草稿 ghost button with icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_outlined, size: 14, color: AppColors.textPrimary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text('存草稿', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 发布 aurora button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.auroraGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('发布', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        // ─── Body ───
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片 section - 3-column grid with add button
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 1, // just the add button in default state
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.textWeak.withOpacity(0.4), width: 1.5),
                        color: AppColors.inputBg.withOpacity(0.3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 28, color: AppColors.textWeak.withOpacity(0.6)),
                          const SizedBox(height: 2),
                          Text('添加图片', style: TextStyle(color: AppColors.textWeak.withOpacity(0.6), fontSize: 10)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // 标题 input - large 22px bold, filled bg
                TextField(
                  enabled: false,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '添加标题会有更多赞哦~',
                    hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 22, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                // 内容 textarea - 16px, filled bg
                TextField(
                  enabled: false,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
                  decoration: InputDecoration(
                    hintText: '分享你的信仰故事...',
                    hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 16),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                  ),
                  maxLines: 8,
                  minLines: 6,
                ),
                const SizedBox(height: 20),
                // 话题标签 section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('话题标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // + 添加标签 button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: const Text('+ 添加标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 加热卡 section (always visible in default state)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: AppColors.auroraCyan, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('加热卡', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('让更多人看到你的笔记', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                              ],
                            ),
                          ),
                          // Toggle switch (off state)
                          Container(
                            width: 40,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 2,
                                  top: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // VIP hint text
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('开通VIP每月赠送1张免费加热卡', style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
