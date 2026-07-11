import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Post detail page golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
        home: Scaffold(
          backgroundColor: AppColors.bgColor,
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('帖子详情', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                    const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.auroraGradient,
                            ),
                            child: const Center(child: Text('X', style: TextStyle(color: Colors.white, fontSize: 16))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('信仰 seekers', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                Text('2小时前', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.auroraBlue, width: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('关注', style: TextStyle(color: AppColors.auroraBlue, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Post title
                      const Text('今天的灵修分享', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // Post content
                      Text(' Christians are called to love one another as Christ loved us. This is the foundation of our community.  Christians are called to love one another as Christ loved us. This is the foundation of our community.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
                      const SizedBox(height: 16),
                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTag('灵修'),
                          _buildTag('信仰生活'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAction(Icons.favorite_border, '点赞', '128'),
                          _buildAction(Icons.chat_bubble_outline, '评论', '32'),
                          _buildAction(Icons.share, '分享', ''),
                          _buildAction(Icons.bookmark_border, '收藏', ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_post_detail.png'));
  });
}

Widget _buildTag(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.inputBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  );
}

Widget _buildAction(IconData icon, String label, String count) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.textSecondary, size: 22),
      const SizedBox(height: 4),
      Text(count.isNotEmpty ? count : label, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
    ],
  );
}
