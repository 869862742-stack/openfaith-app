import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/screens/home/create_post_screen.dart';
import 'package:openfaith_app/screens/gongjing/silent_room_screen.dart';
import 'package:openfaith_app/screens/messages/private_chat_screen.dart';
import 'package:openfaith_app/screens/profile/widgets/edit_profile_dialog.dart';
import 'package:openfaith_app/screens/profile/widgets/followers_list_dialog.dart';
import 'test_helper.dart';

/// Deep Screens Golden Tests
/// Covers 5 actual widget deep pages that import real screen implementations:
/// create_post, silent_room, private_chat_deep, edit_profile_dialog, followers_dialog

void main() {
  setUpAll(() async {
    await initTestDependencies();
  });

  group('Deep Screens Golden Tests', () {

    // ──── 1. Create Post Screen ────
    testWidgets('page_create_post renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(
        const Scaffold(
          body: CreatePostScreen(),
        ),
      ));
      // Let the widget initialize (it may have loading states)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_create_post.png'));
    });

    // ──── 2. Silent Room Screen ────
    testWidgets('page_silent_room renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(
        const SilentRoomScreen(roomId: 'test-room-001'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_silent_room.png'));
    });

    // ──── 3. Private Chat Deep Screen ────
    testWidgets('page_private_chat_deep renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(
        const PrivateChatScreen(
          otherUserId: 'test-user-002',
          otherUserName: '夜行者',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_private_chat_deep.png'));
    });

    // ──── 4. Edit Profile Dialog ────
    testWidgets('page_edit_profile_dialog renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(
        _buildEditProfileDialogWrapper(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_edit_profile_dialog.png'));
    });

    // ──── 5. Followers Dialog ────
    testWidgets('page_followers_dialog renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(
        _buildFollowersDialogWrapper(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_followers_dialog.png'));
    });
  });
}

// ─── Wrapper: EditProfileDialog in Scaffold ───
Widget _buildEditProfileDialogWrapper() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Center(
      child: EditProfileDialog(
        profile: {
          'username': 'OpenFaith',
          'bio': '信仰之旅',
          'avatar_url': null,
        },
        onSaveSuccess: () {},
      ),
    ),
  );
}

// ─── Wrapper: FollowersListDialog in Scaffold ───
Widget _buildFollowersDialogWrapper() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Center(
      child: FollowersListDialog(
        userId: 'test-user-001',
        isFollowers: true,
      ),
    ),
  );
}
