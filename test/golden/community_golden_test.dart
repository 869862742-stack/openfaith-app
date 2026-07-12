import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/sidebar_pages/covenant_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Community covenant page golden', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForGoldenTest(const CovenantScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('goldens/page_community_rules.png'),
    );
  });
}
