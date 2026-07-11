import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

void main() {
  testWidgets('Messages page golden', (WidgetTester tester) async {
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
                child: const Text('消息', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              // Tab bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTab('私信', true),
                    const SizedBox(width: 16),
                    _buildTab('群聊', false),
                    const SizedBox(width: 16),
                    _buildTab('共修', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Message list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMessageItem('张弟兄', '平安！今天的灵修分享很好', '2分钟前', true),
                    const SizedBox(height: 12),
                    _buildMessageItem('李姊妹', '谢谢你的代祷', '1小时前', false),
                    const SizedBox(height: 12),
                    _buildMessageItem('王牧师', '周日的讲道主题是恩典', '3小时前', true),
                    const SizedBox(height: 12),
                    _buildMessageItem('赵弟兄', '一起加油', '昨天', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_messages.png'));
  });
}

Widget _buildTab(String label, bool active) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: active ? Colors.white : Colors.transparent, width: 2)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.white : AppColors.textSecondary,
        fontSize: 14,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

Widget _buildMessageItem(String name, String lastMessage, String time, bool unread) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.auroraGradient,
          ),
          child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(lastMessage, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
            if (unread) const SizedBox(height: 4),
            if (unread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3A86FF), shape: BoxShape.circle)),
          ],
        ),
      ],
    ),
  );
}
