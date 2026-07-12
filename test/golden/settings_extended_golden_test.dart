import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/profile/display_settings_screen.dart';
import 'package:openfaith_app/screens/profile/language_settings_screen.dart';
import 'package:openfaith_app/screens/profile/content_preferences_screen.dart';
import 'package:openfaith_app/screens/profile/notification_settings_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  group('Settings Extended Pages Golden Tests', () {
    testWidgets('Display settings page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const DisplaySettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings_font.png'),
      );
    });

    testWidgets('Language settings page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const LanguageSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings_language.png'),
      );
    });

    testWidgets('Content preferences page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const ContentPreferencesScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings_preferences.png'),
      );
    });

    testWidgets('Notification settings extended page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const NotificationSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_settings_notification_ext.png'),
      );
    });
  });
}
