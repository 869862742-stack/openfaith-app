import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/messages/private_chat_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Chat page golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForGoldenTest(
        const PrivateChatScreen(
          otherUserId: 'test-user-001',
          otherUserName: '张弟兄',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('goldens/page_chat.png'),
    );
  });
}
