import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';

void main() {
  group('Auth Pages Golden Tests', () {
    
    testWidgets('Register page form renders correctly', (WidgetTester tester) async {
      final emailCtrl = TextEditingController();
      final nicknameCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final confirmCtrl = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                borderRadius: 24,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          '创建账号',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          '开启你的信仰之旅',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLabel('邮箱'),
                      const SizedBox(height: 8),
                      _buildInput(emailCtrl, '请输入邮箱', Icons.email_outlined),
                      const SizedBox(height: 20),
                      _buildLabel('昵称'),
                      const SizedBox(height: 8),
                      _buildInput(nicknameCtrl, '请输入昵称', Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildLabel('密码'),
                      const SizedBox(height: 8),
                      _buildInput(passwordCtrl, '至少8位', Icons.lock_outline, obscure: true),
                      const SizedBox(height: 20),
                      _buildLabel('确认密码'),
                      const SizedBox(height: 8),
                      _buildInput(confirmCtrl, '再次输入密码', Icons.lock_outline, obscure: true),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.auroraGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('注册', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_register.png'));
    });

    testWidgets('Settings page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBg,
                    border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                        const SizedBox(width: 12),
                        const Text('设置', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSettingsCard(Icons.person_outline, '账号安全'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.text_fields_outlined, '显示设置'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.notifications_outlined, '通知设置'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.language, '语言设置'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.article_outlined, '内容偏好'),
                      const SizedBox(height: 24),
                      Container(height: 0.5, color: AppColors.borderColor),
                      const SizedBox(height: 24),
                      _buildSettingsCard(Icons.people_outline, '切换账号'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.logout, '退出登录', destructive: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings.png'));
    });

    testWidgets('Account security page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Column(
              children: [
                _buildHeader('账号安全'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSettingsCard(Icons.lock_outline, '修改密码'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.phone_android, '绑定手机'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.email_outlined, '绑定邮箱'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.devices, '登录设备'),
                      const SizedBox(height: 4),
                      _buildSettingsCard(Icons.security, '两步验证'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_account.png'));
    });

    testWidgets('Notification settings page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Column(
              children: [
                _buildHeader('通知设置'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildToggleCard('推送通知', true),
                      const SizedBox(height: 4),
                      _buildToggleCard('消息通知', true),
                      const SizedBox(height: 4),
                      _buildToggleCard('评论通知', true),
                      const SizedBox(height: 4),
                      _buildToggleCard('点赞通知', false),
                      const SizedBox(height: 4),
                      _buildToggleCard('关注通知', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_notification.png'));
    });
  });
}

Widget _buildLabel(String text) {
  return Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));
}

Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

Widget _buildSettingsCard(IconData icon, String title, {bool destructive = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(
      children: [
        Icon(icon, color: destructive ? AppColors.error : AppColors.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: destructive ? AppColors.error : Colors.white, fontSize: 15),
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
      ],
    ),
  );
}

Widget _buildHeader(String title) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

Widget _buildToggleCard(String title, bool enabled) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ),
        Switch(
          value: enabled,
          onChanged: (_) {},
          activeColor: AppColors.auroraBlue,
        ),
      ],
    ),
  );
}
