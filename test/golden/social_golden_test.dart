import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/messages/add_friend_screen.dart';
import 'package:openfaith_app/screens/messages/add_group_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  group('Social Pages Golden Tests', () {
    testWidgets('Add friend page golden', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const AddFriendScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_add_friend.png'),
      );
    });

    testWidgets('Add group page golden', (WidgetTester tester) async {
      await tester.pumpWidget(wrapForGoldenTest(const AddGroupScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await expectLater(
        find.byType(SizedBox).first,
        matchesGoldenFile('goldens/page_add_group.png'),
      );
    });
  });
}
