import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Community page golden', (WidgetTester tester) async {
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
                child: const Text('社区公约', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRuleItem('1. 彼此相爱', '耶稣赐给你们一条新命令，乃是叫你们彼此相爱'),
                    const SizedBox(height: 12),
                    _buildRuleItem('2. 不可论断', '你们不要论断人，免得你们被论断'),
                    const SizedBox(height: 12),
                    _buildRuleItem('3. 互相代祷', '你们要彼此认罪，互相代求'),
                    const SizedBox(height: 12),
                    _buildRuleItem('4. 和睦同居', '看哪，弟兄和睦同居，是何等地善，何等地美'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_community_rules.png'));
  });
}

Widget _buildRuleItem(String title, String content) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
      ],
    ),
  );
}
