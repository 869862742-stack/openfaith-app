import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Deep Pages Golden Tests
/// Covers 20 deep/nested pages with mock UI:
/// edit_profile, followers_list, following_list, level_info, search_results,
/// post_likes, tree_hole, roundtable, moderator_application, sound_selector,
/// qr_code, tags_selection, share_note, share_scripture, create_room,
/// book_detail, user_profile, profile_qrcode, chat_attach_menu, publish_with_tags

// ─── Common Helpers ───

Widget _buildPageHeader(String title, {Widget? trailing}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: SafeArea(
      bottom: false,
      child: Row(children: [
        const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Center(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 36),
      ]),
    ),
  );
}

Widget _buildGlassHeader(String title) => _buildPageHeader(title);

Widget _buildUserListItem(String name, String subtitle, bool showFollowBtn, {bool isFollowed = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.auroraBlue, AppColors.auroraPurple],
          ),
        ),
        child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        if (subtitle.isNotEmpty) const SizedBox(height: 2),
        if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: AppColors.textWeak, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      if (showFollowBtn) Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isFollowed ? AppColors.inputBg : AppColors.auroraBlue,
          border: isFollowed ? Border.all(color: AppColors.borderColor) : null,
        ),
        child: Text(isFollowed ? '已关注' : '关注', style: TextStyle(color: isFollowed ? AppColors.textSecondary : Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}

Widget _buildSearchField() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        Icon(Icons.search, color: AppColors.textWeak, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('搜索...', style: TextStyle(color: AppColors.textWeak, fontSize: 14))),
      ]),
    ),
  );
}

/// Rainbow border wrapper
Widget _rainbowBorder({required Widget child, double radius = 12}) {
  return Container(
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(colors: [
        Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
        Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
      ]),
    ),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(radius - 1),
      ),
      child: child,
    ),
  );
}

void main() {
    setUpAll(() async {
      await initTestDependencies();
    });
  group('Deep Pages Golden Tests', () {
    // ──── 1. Edit Profile ────
    testWidgets('page_edit_profile renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildEditProfile()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_edit_profile.png'));
    });

    // ──── 2. Followers List ────
    testWidgets('page_followers_list renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildFollowersList()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_followers_list.png'));
    });

    // ──── 3. Following List ────
    testWidgets('page_following_list renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildFollowingList()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_following_list.png'));
    });

    // ──── 4. Level Info ────
    testWidgets('page_level_info renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildLevelInfo()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_level_info.png'));
    });

    // ──── 5. Search Results ────
    testWidgets('page_search_results renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSearchResults()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_search_results.png'));
    });

    // ──── 6. Post Likes ────
    testWidgets('page_post_likes renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildPostLikes()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_post_likes.png'));
    });

    // ──── 7. Tree Hole ────
    testWidgets('page_tree_hole renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildTreeHole()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_tree_hole.png'));
    });

    // ──── 8. Roundtable ────
    testWidgets('page_roundtable renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildRoundtable()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_roundtable.png'));
    });

    // ──── 9. Moderator Application ────
    testWidgets('page_moderator_application renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildModeratorApplication()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_moderator_application.png'));
    });

    // ──── 10. Sound Selector ────
    testWidgets('page_sound_selector renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSoundSelector()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_sound_selector.png'));
    });

    // ──── 11. QR Code ────
    testWidgets('page_qr_code renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildQrCode()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_qr_code.png'));
    });

    // ──── 12. Tags Selection ────
    testWidgets('page_tags_selection renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildTagsSelection()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_tags_selection.png'));
    });

    // ──── 13. Share Note ────
    testWidgets('page_share_note renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildShareNote()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_share_note.png'));
    });

    // ──── 14. Share Scripture ────
    testWidgets('page_share_scripture renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildShareScripture()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_share_scripture.png'));
    });

    // ──── 15. Create Room (mock) ────
    testWidgets('page_create_room renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildCreateRoom()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_create_room.png'));
    });

    // ──── 16. Book Detail (mock) ────
    testWidgets('page_book_detail renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildBookDetail()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_book_detail.png'));
    });

    // ──── 17. User Profile (mock) ────
    testWidgets('page_user_profile renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildUserProfile()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_user_profile.png'));
    });

    // ──── 18. Profile QR Code ────
    testWidgets('page_profile_qrcode renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildProfileQrCode()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_profile_qrcode.png'));
    });

    // ──── 19. Chat Attach Menu ────
    testWidgets('page_chat_attach_menu renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildChatAttachMenu()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_chat_attach_menu.png'));
    });

    // ──── 20. Publish with Tags ────
    testWidgets('page_publish_with_tags renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildPublishWithTags()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_publish_with_tags.png'));
    });
  });
}

// ════════════════════════════════════════════════════
// Page Builders (Mock UI)
// ════════════════════════════════════════════════════

// ─── 1. Edit Profile ───
Widget _buildEditProfile() {
  // Avatar color picker colors matching the web version
  const List<Color> avatarColors = [
    Color(0xFFFF4D6D), // red
    Color(0xFFFF9F1C), // orange
    Color(0xFFFFD60A), // yellow
    Color(0xFF70E000), // green
    Color(0xFF00E5FF), // cyan
    Color(0xFF3A86FF), // blue (selected)
    Color(0xFF9D4EDD), // purple
  ];

  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Stack(children: [
      // Starfield-like background (decorative dots to simulate stars)
      Positioned.fill(
        child: CustomPaint(
          painter: _EditProfileStarPainter(),
        ),
      ),
      // Semi-transparent overlay (modal backdrop)
      Positioned.fill(
        child: Container(color: Colors.black.withOpacity(0.55)),
      ),
      // Modal dialog
      Center(
        child: Container(
          width: 353,
          constraints: const BoxConstraints(maxHeight: 720),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Modal header: title + close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(children: [
                const Text('编辑资料', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  child: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                  onTap: () {},
                ),
              ]),
            ),
            Divider(height: 1, color: AppColors.borderColor),
            // Scrollable modal content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(children: [
                  // Avatar with selection ring
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF3A86FF), Color(0xFF9D4EDD)],
                      ),
                      border: Border.all(color: AppColors.auroraBlue, width: 2.5),
                    ),
                    child: const Center(child: Text('O', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 14),
                  // Color picker: 7 colored circles
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (int i = 0; i < avatarColors.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarColors[i],
                            border: i == 5 // blue selected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  // "使用自定义头像" text button
                  GestureDetector(
                    child: const Text('使用自定义头像', style: TextStyle(color: AppColors.auroraBlue, fontSize: 13)),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  // Background image section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('更换背景', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderColor, width: 0.5),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          ),
                        ),
                        child: Icon(Icons.image_outlined, color: AppColors.textWeak, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('点击更换背景图片', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
                      const SizedBox(width: 8),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  // Nickname field
                  _buildFieldRow('昵称', 'OpenFaith'),
                  const SizedBox(height: 16),
                  // Bio / 个性签名 field with character count
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('个性签名', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                      const Spacer(),
                      Text('100/100', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(minHeight: 80),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderColor, width: 0.5),
                      ),
                      child: const Text('信仰之旅，探索内心的平静', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // 身份/信仰标签 dropdown
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('身份/信仰标签', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderColor, width: 0.5),
                      ),
                      child: Row(children: [
                        const Expanded(child: Text('基督教', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                        Icon(Icons.expand_more, color: AppColors.textWeak, size: 20),
                      ]),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ]),
  );
}

/// Simple star painter for the edit profile modal backdrop
class _EditProfileStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final rng = List<int>.generate(40, (i) => (i * 7 + 13) % 97);
    for (int i = 0; i < rng.length; i++) {
      final x = (rng[i] * 3.97) % size.width;
      final y = (rng[i] * 8.73) % size.height;
      final r = 0.5 + (rng[i] % 3) * 0.5;
      paint.color = Colors.white.withOpacity(0.2 + (rng[i] % 5) * 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _buildFieldRow(String label, String value, {bool multiLine = false, Widget? trailing}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
    const SizedBox(height: 8),
    Container(
      width: double.infinity,
      padding: EdgeInsets.all(multiLine ? 12 : 10),
      constraints: multiLine ? BoxConstraints(minHeight: 80) : null,
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
      ),
      child: Row(children: [
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
        if (trailing != null) trailing,
      ]),
    ),
  ]);
}

// ─── 2. Followers List ───
Widget _buildFollowersList() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('粉丝'),
      _buildSearchField(),
      const SizedBox(height: 8),
      Expanded(child: ListView(children: [
        _buildUserListItem('夜行者', '寻求内心平静', true),
        _buildUserListItem('星辰', '禅修爱好者', true, isFollowed: true),
        _buildUserListItem('光之旅人', '佛教修行者', true),
        _buildUserListItem('静水流深', '经文研究者', true),
      ])),
    ]),
  );
}

// ─── 3. Following List ───
Widget _buildFollowingList() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('关注'),
      _buildSearchField(),
      const SizedBox(height: 8),
      Expanded(child: ListView(children: [
        _buildUserListItem('明月禅师', '禅修导师', true, isFollowed: true),
        _buildUserListItem('信仰之声', '基督教牧师', true, isFollowed: true),
        _buildUserListItem('道法自然', '道教修行者', true, isFollowed: true),
      ])),
    ]),
  );
}

// ─── 4. Level Info ───
Widget _buildLevelInfo() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('等级信息'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // User profile context header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(children: [
            Row(children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF70E000), Color(0xFF00E5FF)]),
                ),
                child: const Center(child: Text('O', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('OpenFaith', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: AppColors.auroraGradientWithOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('管理员', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('ID: OF_20260607', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 12),
            // User stats
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildLevelStat('1.2k', '粉丝'),
              _buildLevelStat('256', '关注'),
              _buildLevelStat('8476', '热值'),
              _buildLevelStat('12', '热点'),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        // Level badge with progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD60A), Color(0xFFFF9F1C)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('LV.3 思耕者', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
              const Spacer(),
              Text('22%', style: TextStyle(color: AppColors.auroraOrange, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.22,
                backgroundColor: AppColors.inputBg,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9F1C)),
                minHeight: 6,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        // Current level privileges
        Align(alignment: Alignment.centerLeft, child: const Text('当前等级特权', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        _buildPrivilegeItem(Icons.chat_bubble, '1 个群聊'),
        const SizedBox(height: 8),
        _buildPrivilegeItem(Icons.visibility, '曝光 2 小时', subtitle: '任选 1 篇'),
        const SizedBox(height: 16),
        // Next level unlock
        Align(alignment: Alignment.centerLeft, child: const Text('升到 LV.4 笃行者 解锁', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        _buildPrivilegeItem(Icons.chat_bubble, '2 个群聊', badge: '+可创建 2 个群聊'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('还需 15524 经验升级', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
            const SizedBox(height: 8),
            Text('9476 / 25000', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 20),
        // VIP privileges
        Align(alignment: Alignment.centerLeft, child: const Text('VIP 专属特权', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildVipPrivilege(Icons.trending_up, '经验 ×2'),
            _buildVipPrivilege(Icons.person_outline, '动态头像'),
            _buildVipPrivilege(Icons.palette, '自定义主题'),
            _buildVipPrivilege(Icons.download, '离线下载'),
            _buildVipPrivilege(Icons.visibility, '曝光特权'),
            _buildVipPrivilege(Icons.push_pin, '置顶卡'),
          ],
        ),
        const SizedBox(height: 16),
      ]))),
      // Bottom tab bar
      Container(
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.auroraBlue, width: 2))),
              child: const Center(child: Text('笔记', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
            )),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(child: Text('计划', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            )),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(child: Text('珍藏', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            )),
          ]),
        ),
      ),
    ]),
  );
}

Widget _buildLevelStat(String value, String label) {
  return Column(children: [
    Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
  ]);
}

Widget _buildPrivilegeItem(IconData icon, String title, {String? subtitle, String? badge}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.auroraOrange, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(subtitle, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ],
        ]),
        if (badge != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: AppColors.auroraGradientWithOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge, style: TextStyle(color: AppColors.auroraOrange, fontSize: 11)),
          ),
        ],
      ])),
    ]),
  );
}

Widget _buildVipPrivilege(IconData icon, String title) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.auroraOrange.withOpacity(0.2), width: 0.5),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.auroraOrange, size: 24),
      const SizedBox(height: 8),
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}

Widget _buildBenefitItem(String title, String desc, bool unlocked) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: unlocked ? AppColors.auroraBlue.withOpacity(0.2) : AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Icon(unlocked ? Icons.check_circle : Icons.lock_outline, color: unlocked ? AppColors.auroraGreen : AppColors.textWeak, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: unlocked ? AppColors.textPrimary : AppColors.textWeak, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ])),
    ]),
  );
}

// ─── 5. Search Results ───
Widget _buildSearchResults() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Search bar with keyword
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Icon(Icons.search, color: AppColors.textWeak, size: 18),
                const SizedBox(width: 8),
                const Text('信仰', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                const Spacer(),
                Icon(Icons.close, color: AppColors.textWeak, size: 16),
              ]),
            )),
          ]),
        ),
      ),
      // Tabs
      Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5))),
        child: Row(children: [
          _buildSearchTab('全部', true),
          _buildSearchTab('用户', false),
          _buildSearchTab('帖子', false),
          _buildSearchTab('共境', false),
        ]),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildSearchResultCard('用户', '信仰之声', '基督教牧师，分享灵性感悟'),
        const SizedBox(height: 12),
        _buildSearchResultCard('帖子', '我的信仰感悟', '今天读了一段很有启发的经文...'),
        const SizedBox(height: 12),
        _buildSearchResultCard('共境', '信仰交流群', '探讨各宗教信仰的核心教义'),
        const SizedBox(height: 12),
        _buildSearchResultCard('帖子', '信仰的力量', '信仰是内心的灯塔，指引我们前行...'),
      ])),
    ]),
  );
}

Widget _buildSearchTab(String label, bool active) {
  return Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(border: active ? Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2)) : null),
    child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
  ));
}

Widget _buildSearchResultCard(String type, String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.inputBg,
        ),
        child: Icon(
          type == '用户' ? Icons.person : type == '帖子' ? Icons.article : Icons.meeting_room,
          color: AppColors.auroraBlue, size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: AppColors.textWeak, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

// ─── 6. Post Likes ───
Widget _buildPostLikes() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('点赞'),
      const SizedBox(height: 8),
      Expanded(child: ListView(children: [
        _buildUserListItem('夜行者', '2小时前', false),
        _buildUserListItem('星辰', '3小时前', false),
        _buildUserListItem('光之旅人', '昨天', false),
        _buildUserListItem('静水流深', '昨天', false),
        _buildUserListItem('信仰之声', '2天前', false),
      ])),
    ]),
  );
}

// ─── 7. Tree Hole ───
Widget _buildTreeHole() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('树洞'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildTreeHoleCard('有时候真的很累，想找个地方倾诉。', '匿名用户', '2小时前', 3),
        const SizedBox(height: 12),
        _buildTreeHoleCard('感恩今天遇到的一位好心人，愿世间充满善意。', '匿名用户', '5小时前', 7),
        const SizedBox(height: 12),
        _buildTreeHoleCard('祈祷家人平安健康，这是我最大的心愿。', '匿名用户', '昨天', 12),
      ])),
    ]),
  );
}

Widget _buildTreeHoleCard(String content, String author, String time, int echoCount) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.6)),
      const SizedBox(height: 12),
      Row(children: [
        Icon(Icons.person_outline, color: AppColors.textWeak, size: 14),
        const SizedBox(width: 4),
        Text(author, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        const SizedBox(width: 16),
        Icon(Icons.access_time, color: AppColors.textWeak, size: 14),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        const Spacer(),
        Icon(Icons.volume_up_outlined, color: AppColors.textWeak, size: 14),
        const SizedBox(width: 4),
        Text('$echoCount', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ]),
    ]),
  );
}

// ─── 8. Roundtable ───
Widget _buildRoundtable() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('圆桌'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildRoundtableCard('信仰与科学能否共存？', '探讨现代科学与传统信仰的关系', 28, '进行中'),
        const SizedBox(height: 12),
        _buildRoundtableCard('禅修的入门体验', '分享你的禅修心得与感悟', 15, '进行中'),
        const SizedBox(height: 12),
        _buildRoundtableCard('读经打卡挑战', '每日阅读一段经典经文', 42, '进行中'),
      ])),
    ]),
  );
}

Widget _buildRoundtableCard(String title, String desc, int participants, String status) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.auroraBlue.withOpacity(0.2), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.auroraBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status, style: const TextStyle(color: AppColors.auroraBlue, fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 8),
      Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(height: 12),
      Row(children: [
        Icon(Icons.people_outline, color: AppColors.textWeak, size: 16),
        const SizedBox(width: 4),
        Text('$participants 人参与', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ]),
    ]),
  );
}

// ─── 9. Moderator Application ───
Widget _buildModeratorApplication() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('版主申请'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Room selection
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('选择共境', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: Row(children: [
              const Expanded(child: Text('信仰交流群', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        // Application reason
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('申请理由', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: const Text('我热爱这个社区，希望能够为社区的和谐发展贡献自己的力量。我有丰富的社区管理经验...', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
          ),
        ]),
        const SizedBox(height: 20),
        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline, color: AppColors.auroraBlue, size: 16),
              const SizedBox(width: 8),
              const Text('申请须知', style: TextStyle(color: AppColors.auroraBlue, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 8),
            Text('· 申请提交后将在 48 小时内审核\n· 需要达到 Lv.3 以上\n· 近 30 天无违规记录', style: TextStyle(color: AppColors.textWeak, fontSize: 12, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
          ),
          child: const Center(child: Text('提交申请', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        ),
      ]))),
    ]),
  );
}

// ─── 10. Sound Selector ───
Widget _buildSoundSelector() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('铃声选择'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Section: System sounds
        Align(alignment: Alignment.centerLeft, child: Text('系统铃声', style: TextStyle(color: AppColors.textWeak, fontSize: 13))),
        const SizedBox(height: 12),
        _buildSoundItem('晨钟', '清脆的钟声，适合晨间冥想', true),
        _buildSoundItem('溪流', '潺潺溪水声', false),
        _buildSoundItem('鸟鸣', '清晨的鸟叫声', false),
        _buildSoundItem('雨声', '淅淅沥沥的雨声', false),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerLeft, child: Text('自定义铃声', style: TextStyle(color: AppColors.textWeak, fontSize: 13))),
        const SizedBox(height: 12),
        _buildSoundItem('我的冥想曲', '自定义上传', false),
        _buildSoundItem('般若波罗蜜', '自定义上传', false),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.upload_outlined, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            const Text('上传自定义铃声', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
      ])),
    ]),
  );
}

Widget _buildSoundItem(String name, String desc, bool selected) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: selected ? AppColors.auroraBlue : AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.auroraBlue : AppColors.inputBg,
        ),
        child: Icon(selected ? Icons.play_arrow : Icons.music_note, color: selected ? Colors.white : AppColors.textWeak, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(color: selected ? AppColors.auroraBlue : AppColors.textPrimary, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ])),
      if (selected) Icon(Icons.check_circle, color: AppColors.auroraBlue, size: 20),
    ]),
  );
}

// ─── 11. QR Code ───
Widget _buildQrCode() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('我的二维码'),
      Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // User info
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A86FF), Color(0xFF9D4EDD)]),
          ),
          child: const Center(child: Text('O', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 12),
        const Text('OpenFaith', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('信仰之旅', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        const SizedBox(height: 28),
        // QR code placeholder (simulated grid)
        _rainbowBorder(
          radius: 16,
          child: Container(
            width: 200, height: 200,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.qr_code_2, color: Colors.black, size: 100),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Share button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.share, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text('分享二维码', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]))),
    ]),
  );
}

// ─── 12. Tags Selection ───
Widget _buildTagsSelection() {
  final tags = ['基督教', '伊斯兰教', '犹太教', '佛教', '印度教', '道教', '锡克教', '巴哈伊教', '摩门教', '神道教', '耆那教', '宗教研究者', '经文爱好者', '寻求者'];
  final selected = {'基督教', '佛教'};
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('选择信仰标签'),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('已选择 2 个标签', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
      ),
      const SizedBox(height: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tags.map((tag) {
            final isSel = selected.contains(tag);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSel ? AppColors.auroraBlue.withOpacity(0.15) : AppColors.inputBg,
                border: Border.all(color: isSel ? AppColors.auroraBlue : AppColors.borderColor, width: 0.5),
              ),
              child: Text(tag, style: TextStyle(color: isSel ? AppColors.auroraBlue : AppColors.textSecondary, fontSize: 14, fontWeight: isSel ? FontWeight.w500 : FontWeight.w400)),
            );
          }).toList(),
        ),
      )),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
          ),
          child: const Center(child: Text('确认选择', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        ),
      ),
      const SizedBox(height: 16),
    ]),
  );
}

// ─── 13. Share Note ───
Widget _buildShareNote() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('分享笔记'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Note preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('我的信仰感悟', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('今天读了一段很有启发的经文，分享给大家思考。信仰的力量在于内心的平静与坚定。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Text('— OpenFaith', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerLeft, child: const Text('分享到', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
        const SizedBox(height: 16),
        // Share targets
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildShareTarget(Icons.chat_bubble, '私信', AppColors.auroraBlue),
          _buildShareTarget(Icons.people, '群聊', AppColors.auroraGreen),
          _buildShareTarget(Icons.content_copy, '复制链接', AppColors.auroraOrange),
          _buildShareTarget(Icons.share, '更多', AppColors.auroraPurple),
        ]),
      ]))),
    ]),
  );
}

Widget _buildShareTarget(IconData icon, String label, Color color) {
  return Column(children: [
    Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Icon(icon, color: color, size: 24),
    ),
    const SizedBox(height: 8),
    Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}

// ─── 14. Share Scripture ───
Widget _buildShareScripture() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('分享经文'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Scripture content
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.auroraBlue.withOpacity(0.1), AppColors.auroraPurple.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.auroraBlue.withOpacity(0.2), width: 0.5),
          ),
          child: Column(children: [
            const Icon(Icons.format_quote, color: AppColors.auroraBlue, size: 32),
            const SizedBox(height: 12),
            const Text('"你们是世上的光。城造在山上，是不能隐藏的。"', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500, height: 1.6, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            Text('— 马太福音 5:14', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 28),
        Align(alignment: Alignment.centerLeft, child: const Text('分享方式', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
        const SizedBox(height: 16),
        // Share options
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildShareTarget(Icons.chat_bubble, '私信', AppColors.auroraBlue),
          _buildShareTarget(Icons.people, '群聊', AppColors.auroraGreen),
          _buildShareTarget(Icons.content_copy, '复制链接', AppColors.auroraOrange),
          _buildShareTarget(Icons.image, '生成图片', AppColors.auroraPurple),
        ]),
      ]))),
    ]),
  );
}

// ─── 15. Create Room (mock) ───
Widget _buildCreateRoom() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('创建共境'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Room name
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('共境名称', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.auroraBlue.withOpacity(0.5), width: 1),
            ),
            child: const Row(children: [
              Expanded(child: Text('晨间冥想', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              Icon(Icons.clear, color: AppColors.textWeak, size: 16),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        // Description
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('描述', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, height: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: const Text('每日清晨一起冥想，感受内心的宁静', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
          ),
        ]),
        const SizedBox(height: 16),
        // Tags
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('标签', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _buildTagChip('冥想', true),
            _buildTagChip('治愈', true),
            _buildTagChip('祈祷', false),
            _buildTagChip('读书', false),
            _buildTagChip('运动', false),
          ]),
        ]),
        const SizedBox(height: 16),
        // Public / Private toggle
        Row(children: [
          Icon(Icons.public, color: AppColors.auroraBlue, size: 20),
          const SizedBox(width: 8),
          const Text('公开', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            width: 44, height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.auroraBlue,
            ),
            child: Align(alignment: Alignment.centerRight, child: Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), margin: const EdgeInsets.only(right: 2))),
          ),
        ]),
        const SizedBox(height: 24),
        // Create button
        Container(
          width: double.infinity, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
          ),
          child: const Center(child: Text('创建共境', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        ),
      ]))),
    ]),
  );
}

Widget _buildTagChip(String label, bool selected) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: selected ? AppColors.auroraBlue.withOpacity(0.15) : AppColors.inputBg,
      border: Border.all(color: selected ? AppColors.auroraBlue : AppColors.borderColor, width: 0.5),
    ),
    child: Text(label, style: TextStyle(color: selected ? AppColors.auroraBlue : AppColors.textSecondary, fontSize: 13)),
  );
}

// ─── 16. Book Detail (mock) ───
Widget _buildBookDetail() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('书籍详情'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Book cover area
        Container(
          width: 120, height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.auroraBlue.withOpacity(0.3), AppColors.auroraPurple.withOpacity(0.3)],
            ),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: const Center(child: Icon(Icons.menu_book, color: AppColors.textSecondary, size: 48)),
        ),
        const SizedBox(height: 16),
        const Text('道德经', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('道教经典', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        const SizedBox(height: 12),
        // Description
        Text('《道德经》是春秋时期老子所著，为中国古代哲学的经典之作。全书分上下两篇，共八十一章，论述了"道"与"德"的深刻含义。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 20),
        // Chapter list header
        Align(alignment: Alignment.centerLeft, child: const Text('章节目录', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        _buildChapterItem(1, '道可道，非常道', true),
        _buildChapterItem(2, '天下皆知美之为美', false),
        _buildChapterItem(3, '不尚贤，使民不争', false),
        _buildChapterItem(4, '道冲，而用之或不盈', false),
      ]))),
    ]),
  );
}

Widget _buildChapterItem(int number, String title, bool active) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: active ? AppColors.auroraBlue.withOpacity(0.1) : AppColors.cardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: active ? AppColors.auroraBlue.withOpacity(0.3) : AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.auroraBlue : AppColors.inputBg,
        ),
        child: Center(child: Text('$number', style: TextStyle(color: active ? Colors.white : AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text('第${number}章 $title', style: TextStyle(color: active ? AppColors.auroraBlue : AppColors.textPrimary, fontSize: 14, fontWeight: active ? FontWeight.w500 : FontWeight.w400))),
      Icon(Icons.chevron_right, color: AppColors.textWeak, size: 18),
    ]),
  );
}

// ─── 17. User Profile (mock) ───
Widget _buildUserProfile() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Custom header for user profile
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.auroraBlue,
              ),
              child: const Text('关注', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 22),
          ]),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Avatar + info
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF9F1C), Color(0xFFFF4D6D)]),
          ),
          child: const Center(child: Text('夜', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 12),
        const Text('夜行者', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('寻求内心平静，探索信仰真谛', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        const SizedBox(height: 12),
        // Stats
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildProfileStat('328', '帖子'),
          const SizedBox(width: 24),
          _buildProfileStat('1.2k', '粉丝'),
          const SizedBox(width: 24),
          _buildProfileStat('256', '关注'),
        ]),
        const SizedBox(height: 20),
        // Tab bar
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5))),
          child: Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2))),
              child: const Center(child: Text('帖子', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
            )),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(child: Text('收藏', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        // Sample posts
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('禅修日记第30天', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('内心越来越平静，感受到了从未有过的安宁...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              Text('昨天', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
              const Spacer(),
              Icon(Icons.favorite_border, color: AppColors.iconColorWeak, size: 16),
              const SizedBox(width: 4),
              const Text('128', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ]),
          ]),
        ),
      ]))),
    ]),
  );
}

Widget _buildProfileStat(String value, String label) {
  return Column(children: [
    Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
  ]);
}

// ─── 18. Profile QR Code ───
Widget _buildProfileQrCode() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('个人名片'),
      Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.cardBg, AppColors.bgSecondary],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(children: [
            // User avatar
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF70E000), Color(0xFF00E5FF)]),
              ),
              child: const Center(child: Text('O', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            const Text('OpenFaith', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('信仰之旅，探索内心的平静', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            const SizedBox(height: 20),
            // QR placeholder
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.qr_code_2, color: Colors.black, size: 80)),
            ),
            const SizedBox(height: 16),
            Text('扫码查看我的主页', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 24),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.share, color: AppColors.auroraBlue, size: 16),
          const SizedBox(width: 6),
          const Text('分享名片', style: TextStyle(color: AppColors.auroraBlue, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]))),
    ]),
  );
}

// ─── 19. Chat Attach Menu ───
Widget _buildChatAttachMenu() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Chat header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF3A86FF), Color(0xFF9D4EDD)]),
              ),
              child: const Center(child: Text('夜', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
            const Text('夜行者', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      // Some chat messages
      Expanded(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Other's message
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.otherMessage,
                borderRadius: BorderRadius.circular(12).copyWith(topLeft: Radius.zero),
              ),
              child: const Text('你好，今天过得怎么样？', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
          // My message
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.myMessage,
                borderRadius: BorderRadius.circular(12).copyWith(topRight: Radius.zero),
              ),
              child: const Text('很好，谢谢！愿平安与你同在。', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ),
          ),
          const Spacer(),
          // Attach menu expanded at bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildAttachItem(Icons.image, '图片', AppColors.auroraBlue),
                _buildAttachItem(Icons.camera_alt, '拍照', AppColors.auroraGreen),
                _buildAttachItem(Icons.videocam, '视频', AppColors.auroraOrange),
                _buildAttachItem(Icons.insert_drive_file, '文件', AppColors.auroraPurple),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildAttachItem(Icons.location_on, '位置', AppColors.auroraRed),
                _buildAttachItem(Icons.bookmark, '收藏', AppColors.auroraCyan),
                _buildAttachItem(Icons.link, '链接', AppColors.auroraYellow),
                _buildAttachItem(Icons.more_horiz, '更多', AppColors.textWeak),
              ]),
            ]),
          ),
        ]),
      )),
    ]),
  );
}

Widget _buildAttachItem(IconData icon, String label, Color color) {
  return Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
    const SizedBox(height: 6),
    Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  ]);
}

// ─── 20. Publish with Tags ───
Widget _buildPublishWithTags() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('发布笔记'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Title field
        Container(
          width: double.infinity, height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: const Row(children: [
            Expanded(child: Text('我的信仰感悟', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
          ]),
        ),
        const SizedBox(height: 12),
        // Content field
        Container(
          width: double.infinity, height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: const Text('今天读了一段很有启发的经文，分享给大家思考...', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
        ),
        const SizedBox(height: 16),
        // Tags selection expanded
        Align(alignment: Alignment.centerLeft, child: const Text('选择信仰标签', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTagChip('基督教', true),
            _buildTagChip('伊斯兰教', false),
            _buildTagChip('佛教', true),
            _buildTagChip('道教', false),
            _buildTagChip('印度教', false),
            _buildTagChip('锡克教', false),
            _buildTagChip('寻求者', false),
          ],
        ),
        const SizedBox(height: 20),
        // Selected tags
        Align(alignment: Alignment.centerLeft, child: Text('已选择：基督教、佛教', style: TextStyle(color: AppColors.textWeak, fontSize: 12))),
        const SizedBox(height: 16),
        // Publish button
        Container(
          width: double.infinity, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
          ),
          child: const Center(child: Text('发布', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        ),
      ]))),
    ]),
  );
}
