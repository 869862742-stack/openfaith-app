import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/learn/learn_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Learn page golden', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForGoldenTest(const LearnScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('goldens/page_learning.png'),
    );
  });
}
