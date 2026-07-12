import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/screens/home/post_detail_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDependencies();
  });

  testWidgets('Post detail page golden', (WidgetTester tester) async {
    final mockPost = <String, dynamic>{
      'id': 'test-post-001',
      'title': '今天的灵修分享',
      'content': 'Christians are called to love one another as Christ loved us. This is the foundation of our community.',
      'user_id': 'test-user-001',
      'created_at': DateTime.now().toIso8601String(),
      'tags': ['灵修', '信仰生活'],
      'like_count': 128,
      'comment_count': 32,
      'share_count': 16,
      'username': '信仰 seekers',
      'avatar_url': null,
      'faith_tag': '基督教',
    };

    await tester.pumpWidget(
      wrapForGoldenTest(PostDetailScreen(post: mockPost)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('goldens/page_post_detail.png'),
    );
  });
}
