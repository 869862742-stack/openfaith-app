import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/publish/publish_note_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Publish note page golden', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForGoldenTest(const PublishNoteScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('goldens/page_publish_note.png'),
    );
  });
}
