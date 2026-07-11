import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Post detail golden', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(child: Center(child: Text('帖子详情', style: TextStyle(color: Colors.white, fontSize: 24)))),
    )));
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_post_detail.png'));
  });
}
