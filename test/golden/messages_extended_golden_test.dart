import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

/// Messages Extended Golden Tests
/// Covers: group_chat_detail, private_chat

// ─── Common Helpers ───
Widget _buildChatHeader(String title, {String? subtitle}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: SafeArea(
      bottom: false,
      child: Row(children: [
        const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: AppColors.textWeak, fontSize: 12))],
        ])),
        const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 22),
      ]),
    ),
  );
}

void main() {
  group('Messages Extended Golden Tests', () {
    testWidgets('group_chat_detail page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildGroupChatDetail()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_group_chat_detail.png'));
    });

    testWidgets('private_chat page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildPrivateChat()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_private_chat.png'));
    });
  });
}

// ─── Group Chat Detail Page ───
Widget _buildGroupChatDetail() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildChatHeader('信仰交流群', subtitle: '12人'),
      Expanded(child: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildReceivedMessage('大家好！欢迎加入信仰交流群。', '张三', '14:30'),
          const SizedBox(height: 16),
          _buildReceivedMessage('今天想和大家分享一段经文感悟。', '张三', '14:31'),
          const SizedBox(height: 16),
          _buildSentMessage('感谢分享！我也有一些心得想交流。', '14:32'),
          const SizedBox(height: 16),
          _buildReceivedMessage('信仰的力量在于内心的平静与坚定，让我们一起成长。', '李明', '14:35'),
          const SizedBox(height: 16),
          _buildSentMessage('说得好！共勉之。', '14:36'),
        ]),
      )),
      // Input bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navBg,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Icon(Icons.add_circle_outline, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(20)),
              child: const Text('输入消息...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14)),
            )),
            const SizedBox(width: 8),
            Icon(Icons.emoji_emotions_outlined, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppColors.auroraGradient, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ]),
        ),
      ),
    ]),
  );
}

// ─── Private Chat Page ───
Widget _buildPrivateChat() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildChatHeader('王芳'),
      Expanded(child: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildReceivedMessage('你好！看到你在社区分享的感悟，很有共鸣。', '14:20'),
          const SizedBox(height: 16),
          _buildSentMessage('谢谢！很高兴能引起共鸣。你平时也读经吗？', '14:22'),
          const SizedBox(height: 16),
          _buildReceivedMessage('是的，每天早晨都会读一段。最近在读诗篇，很有感触。', '14:25'),
          const SizedBox(height: 16),
          _buildSentMessage('诗篇确实很美。推荐你 also 看看箴言，也很有智慧。', '14:27'),
          const SizedBox(height: 16),
          _buildReceivedMessage('好的，谢谢推荐！有空一起交流。', '14:30'),
        ]),
      )),
      // Input bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navBg,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Icon(Icons.add_circle_outline, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(20)),
              child: const Text('输入消息...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14)),
            )),
            const SizedBox(width: 8),
            Icon(Icons.emoji_emotions_outlined, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppColors.auroraGradient, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ]),
        ),
      ),
    ]),
  );
}

Widget _buildReceivedMessage(String text, String senderOrTime, String time, {bool showSender = true}) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraGreen, AppColors.auroraCyan])),
      child: Center(child: Text(senderOrTime[0], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
    ),
    const SizedBox(width: 8),
    Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showSender) ...[Text(senderOrTime, style: TextStyle(color: AppColors.textWeak, fontSize: 11)), const SizedBox(height: 4)],
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor, width: 0.5)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
      ),
      const SizedBox(height: 4),
      Text(showSender ? time : senderOrTime, style: TextStyle(color: AppColors.textWeak, fontSize: 10)),
    ])),
  ]);
}

Widget _buildSentMessage(String text, String time) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
    Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
      ),
      const SizedBox(height: 4),
      Text(time, style: TextStyle(color: AppColors.textWeak, fontSize: 10)),
    ])),
    const SizedBox(width: 8),
    Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraBlue, AppColors.auroraPurple])),
      child: const Center(child: Text('我', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
    ),
  ]);
}
