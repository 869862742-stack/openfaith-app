import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/auth/login_screen.dart';
import 'package:openfaith_app/screens/auth/register_screen.dart';
import 'package:openfaith_app/screens/profile/settings_screen.dart';
import 'package:openfaith_app/screens/profile/account_security_screen.dart';
import 'package:openfaith_app/screens/profile/notification_settings_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  group('Auth Pages Golden Tests', () {
    testWidgets('Login page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const LoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_login.png'),
      );
    });

    testWidgets('Register page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const RegisterScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_register.png'),
      );
    });

    testWidgets('Settings page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings.png'),
      );
    });

    testWidgets('Account security page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const AccountSecurityScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings_account.png'),
      );
    });

    testWidgets('Notification settings page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const NotificationSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings_notification.png'),
      );
    });
  });
}
