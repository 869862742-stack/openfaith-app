import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Learn page golden', (WidgetTester tester) async {
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
                child: const Text('学习', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              // Tab bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTab('书籍', true),
                    const SizedBox(width: 16),
                    _buildTab('日历', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Book list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBookCard('圣经', '旧约+新约', '66卷', '📖'),
                    const SizedBox(height: 12),
                    _buildBookCard('荒漠甘泉', '每日灵修', '365篇', '🌅'),
                    const SizedBox(height: 12),
                    _buildBookCard('天路历程', '经典文学', '12章', '🛤️'),
                    const SizedBox(height: 12),
                    _buildBookCard('祈祷手册', '祷告指南', '30篇', '🙏'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_learning.png'));
  });
}

Widget _buildTab(String label, bool active) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: active ? Colors.white : Colors.transparent, width: 2)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.white : AppColors.textSecondary,
        fontSize: 14,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

Widget _buildBookCard(String title, String author, String pages, String emoji) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(author, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text('$pages', style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
      ],
    ),
  );
}
