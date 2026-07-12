import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/auth/login_screen.dart';
import 'package:openfaith_app/screens/auth/register_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  group('Auth Extended Golden Tests', () {
    testWidgets('Login page extended view', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const LoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_login_extended.png'),
      );
    });

    testWidgets('Register page extended view', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const RegisterScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_register_extended.png'),
      );
    });
  });
}
