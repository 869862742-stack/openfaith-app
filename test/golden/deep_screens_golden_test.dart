import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Deep Screens Golden Tests (Mock UI versions)
/// Covers actual screen deep pages using mock UI to avoid network calls

void main() {
  group('Deep Screens Golden Tests', () {
    testWidgets('page_create_post renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildCreatePost()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_create_post.png'));
    });

    testWidgets('page_silent_room renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSilentRoom()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_silent_room.png'));
    });

    testWidgets('page_private_chat_deep renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildPrivateChat()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_private_chat_deep.png'));
    });

    testWidgets('page_followers_dialog renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildFollowersDialog()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_followers_dialog.png'));
    });
  });
}

// ─── Create Post Page ───
Widget _buildCreatePost() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    appBar: AppBar(
      backgroundColor: AppColors.bgColor,
      elevation: 0,
      leading: const Icon(Icons.close, color: Colors.white),
      title: const Text('发布帖子', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: AppColors.auroraBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('发布', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: '帖子标题（可选）',
                hintStyle: TextStyle(color: AppColors.textWeak, fontSize: 16),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Content field
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: const TextField(
              maxLines: null,
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: '分享你的想法...\n\n支持文字、经文引用、图片等内容',
                hintStyle: TextStyle(color: AppColors.textWeak, fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tags
          Wrap(
            spacing: 8,
            children: [
              _buildTag('信仰感悟', true),
              _buildTag('灵修', false),
              _buildTag('祷告', false),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, color: AppColors.textWeak, size: 16),
                  const SizedBox(width: 4),
                  Text('添加标签', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(children: [
            _buildActionButton(Icons.image_outlined, '图片'),
            const SizedBox(width: 12),
            _buildActionButton(Icons.videocam_outlined, '视频'),
            const SizedBox(width: 12),
            _buildActionButton(Icons.menu_book_outlined, '经文引用'),
            const SizedBox(width: 12),
            _buildActionButton(Icons.location_on_outlined, '位置'),
          ]),
        ],
      ),
    ),
  );
}

Widget _buildTag(String label, bool selected) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: selected ? AppColors.auroraBlue.withOpacity(0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected ? AppColors.auroraBlue : AppColors.borderColor,
        width: 0.5,
      ),
    ),
    child: Text(label, style: TextStyle(
      color: selected ? AppColors.auroraBlue : AppColors.textWeak,
      fontSize: 13,
    )),
  );
}

Widget _buildActionButton(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textWeak, size: 18),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
    ]),
  );
}

// ─── Silent Room Page ───
Widget _buildSilentRoom() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    appBar: AppBar(
      backgroundColor: AppColors.bgColor,
      elevation: 0,
      leading: const Icon(Icons.arrow_back_ios, color: Colors.white),
      title: const Text('静修房间', style: TextStyle(color: Colors.white, fontSize: 17)),
    ),
    body: Column(children: [
      // Timer area
      Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.auroraGradient,
            ),
            child: const Center(
              child: Text('25:00', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Text('专注静修中', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('放下手机，静心祷告', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
        ]),
      ),
      // Participants
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: Row(children: [
          Icon(Icons.people, color: AppColors.textWeak, size: 18),
          const SizedBox(width: 8),
          Text('12人正在一起静修', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
        ]),
      ),
      // Chat input
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '写下你的感悟...',
                hintStyle: TextStyle(color: AppColors.textWeak),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ]),
      )),
    ]),
  );
}

// ─── Private Chat (Deep) ───
Widget _buildPrivateChat() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    appBar: AppBar(
      backgroundColor: AppColors.bgColor,
      elevation: 0,
      leading: const Icon(Icons.arrow_back_ios, color: Colors.white),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('夜行者', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Text('在线', style: TextStyle(color: AppColors.auroraGreen, fontSize: 11)),
      ]),
      actions: [
        IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white), onPressed: () {}),
      ],
    ),
    body: Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        reverse: true,
        child: Column(children: [
          _chatBubble('你好！最近灵修怎么样？', false),
          const SizedBox(height: 12),
          _chatBubble('挺好的，每天坚持读经祷告。你呢？', true),
          const SizedBox(height: 12),
          _chatBubble('我也在坚持，最近在读诗篇，很有感触。', false),
          const SizedBox(height: 12),
          _chatBubble('诗篇确实很美，一起加油！', true),
        ]),
      )),
      // Input bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(top: false, child: Row(children: [
          Icon(Icons.add_circle_outline, color: AppColors.textWeak, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(hintText: '输入消息...', hintStyle: TextStyle(color: AppColors.textWeak), border: InputBorder.none, isDense: true),
            ),
          )),
          const SizedBox(width: 8),
          Icon(Icons.send, color: AppColors.auroraBlue, size: 24),
        ])),
      ),
    ]),
  );
}

Widget _chatBubble(String text, bool isSent) {
  return Align(
    alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSent ? AppColors.auroraBlue : AppColors.cardBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isSent ? 16 : 4),
          bottomRight: Radius.circular(isSent ? 4 : 16),
        ),
      ),
      child: Text(text, style: TextStyle(color: isSent ? Colors.white : AppColors.textPrimary, fontSize: 15, height: 1.4)),
    ),
  );
}

// ─── Followers Dialog (Mock) ───
Widget _buildFollowersDialog() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    appBar: AppBar(
      backgroundColor: AppColors.bgColor,
      elevation: 0,
      leading: const Icon(Icons.close, color: Colors.white),
      title: const Text('粉丝', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
    ),
    body: Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.search, color: AppColors.textWeak, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('搜索用户...', style: TextStyle(color: AppColors.textWeak, fontSize: 15))),
          ]),
        ),
      ),
      // User list
      Expanded(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _followerItem('恩典之路', '走在信仰的道路上', true),
          _followerItem('光之子', '愿光照亮前行路', false),
          _followerItem('祈祷者', '每日祷告，内心平安', true),
          _followerItem('磐石', '信仰如磐石般坚定', false),
          _followerItem('活水', '饮于生命活水', true),
        ],
      )),
    ]),
  );
}

Widget _followerItem(String name, String bio, bool isFollowing) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple]),
        ),
        child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(bio, style: TextStyle(color: AppColors.textWeak, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFollowing ? AppColors.borderColor : AppColors.auroraBlue,
            width: 0.5,
          ),
        ),
        child: Text(
          isFollowing ? '已关注' : '关注',
          style: TextStyle(color: isFollowing ? AppColors.textWeak : AppColors.auroraBlue, fontSize: 13),
        ),
      ),
    ]),
  );
}
