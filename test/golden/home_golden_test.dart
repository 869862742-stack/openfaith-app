import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';

void main() {
  testWidgets('Home page golden', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(child: Text('Home')),
    )));
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_home.png'));
  });
}
