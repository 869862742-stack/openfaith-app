import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Chat page golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
        home: Scaffold(
          backgroundColor: AppColors.bgColor,
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.auroraGradient,
                      ),
                      child: const Center(child: Text('X', style: TextStyle(color: Colors.white, fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('张弟兄', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('在线', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),
              // Chat messages
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMessage('平安！今天的灵修分享很好', false, '10:30'),
                    const SizedBox(height: 16),
                    _buildMessage('谢谢你的鼓励，一起加油！', true, '10:32'),
                    const SizedBox(height: 16),
                    _buildMessage('周日的讲道主题是恩典', false, '10:35'),
                  ],
                ),
              ),
              // Input bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('输入消息...', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.auroraGradient,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_chat.png'));
  });
}

Widget _buildMessage(String text, bool isMe, String time) {
  return Row(
    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (!isMe) Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.auroraGradient,
        ),
        child: const Center(child: Text('X', style: TextStyle(color: Colors.white, fontSize: 14))),
      ),
      if (!isMe) const SizedBox(width: 8),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? AppColors.auroraBlue.withOpacity(0.3) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
      if (isMe) const SizedBox(width: 8),
      Text(time, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
    ],
  );
}
