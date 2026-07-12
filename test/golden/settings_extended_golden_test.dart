import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';


/// Settings Extended Pages Golden Tests
/// Covers: settings_profile, settings_font, settings_language, settings_preferences, settings_about, settings_privacy

// ─── Common Header ───
Widget _buildHeader(String title, {bool showBack = true}) {
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
          if (showBack) ...[
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
          ],
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

// ─── Glass Header (centered title) ───
Widget _buildGlassHeader(String title) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: SafeArea(
      bottom: false,
      child: Center(
        child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

// ─── Settings List Card ───
Widget _buildSettingsCard(IconData icon, String title, {bool destructive = false, String? subtitle, bool showArrow = true}) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: destructive ? AppColors.error : Colors.white, fontSize: 15)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
              ],
            ],
          ),
        ),
        if (showArrow) const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
      ],
    ),
  );
}

// ─── Toggle Card ───
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
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
        Switch(value: enabled, onChanged: (_) {}, activeColor: AppColors.auroraBlue),
      ],
    ),
  );
}

// ─── Search Bar ───
Widget _buildSearchBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.inputBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.search, color: AppColors.textPlaceholder, size: 20),
        SizedBox(width: 8),
        Expanded(child: Text('搜索...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
      ],
    ),
  );
}

// ─── Input Field ───
Widget _buildInput(String hint, IconData icon, {bool obscure = false}) {
  return TextField(
    obscureText: obscure,
    enabled: false,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─── Post Card ───
Widget _buildPostCard({
  required String authorName,
  required String avatarLetter,
  required List<Color> avatarGradient,
  required String faithTag,
  required String timeAgo,
  required String content,
  required int likes,
  required int comments,
  required int shares,
}) {
  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: avatarGradient)),
                child: Center(child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                        child: Text(faithTag, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Text(timeAgo, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            _actionIcon(Icons.favorite_border, '$likes'),
            const SizedBox(width: 24),
            _actionIcon(Icons.chat_bubble_outline, '$comments'),
            const SizedBox(width: 24),
            _actionIcon(Icons.share_outlined, '$shares'),
          ]),
        ],
      ),
    ),
  );
}

Widget _actionIcon(IconData icon, String count) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: AppColors.iconColorWeak, size: 18),
    const SizedBox(width: 4),
    Text(count, style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
  ]);
}

// ─── Tab Bar ───
Widget _buildTabBar(List<String> tabs, int activeIndex) {
  return Container(
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5))),
    child: Row(
      children: List.generate(tabs.length, (i) {
        final isActive = i == activeIndex;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(border: isActive ? Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2)) : null),
            child: Center(child: Text(tabs[i], style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 15, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400))),
          ),
        );
      }),
    ),
  );
}

// ─── Bottom Nav ───
Widget _buildBottomNav(int activeIndex) {
  final items = [
    [Icons.home_outlined, Icons.home, '首页'],
    [Icons.explore_outlined, Icons.explore, '学习'],
    [null, null, null], // publish button
    [Icons.notifications_outlined, Icons.notifications, '消息'],
    [Icons.person_outline, Icons.person, '我的'],
  ];
  return Container(
    decoration: BoxDecoration(color: AppColors.navBg, border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5))),
    child: SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(top: 2, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          if (item[0] == null) {
            return Transform.translate(offset: const Offset(0, -8), child: Container(
              width: 40, height: 40, padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
              child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgSecondarySolid), child: const Center(child: Icon(Icons.add, color: Colors.white, size: 20))),
            ));
          }
          final idx = items.indexOf(item);
          final isActive = idx == activeIndex;
          return ConstrainedBox(constraints: const BoxConstraints(minWidth: 50), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(isActive ? item[1] as IconData : item[0] as IconData, size: 20, color: isActive ? Colors.white : AppColors.iconColorWeak),
              const SizedBox(height: 2),
              Text(item[2] as String, style: TextStyle(fontSize: 10, color: isActive ? AppColors.textPrimary : AppColors.iconColorWeak)),
            ]),
          ));
        }).toList(),
      ),
    )),
  );
}

// ─── Empty State ───
Widget _buildEmptyState(String title, String subtitle) {
  return Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
    Icon(Icons.inbox_outlined, color: AppColors.textWeak, size: 48),
    const SizedBox(height: 16),
    Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
  ])));
}


void main() {
  group('Settings Extended Golden Tests', () {

    testWidgets('Settings main page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettings()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings.png'));
    });

    testWidgets('Settings - Profile edit', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsProfile()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_profile.png'));
    });

    testWidgets('Settings - Account security', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsAccount()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_account.png'));
    });

    testWidgets('Settings - Notification', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsNotification()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_notification.png'));
    });

    testWidgets('Settings - Font/Display', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsFont()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_font.png'));
    });

    testWidgets('Settings - Language', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsLanguage()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_language.png'));
    });

    testWidgets('Settings - Content preferences', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsPreferences()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_preferences.png'));
    });

    testWidgets('Settings - About', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsAbout()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_about.png'));
    });

    testWidgets('Settings - Privacy', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSettingsPrivacy()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_privacy.png'));
    });
  });
}

Widget _buildSettings() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('设置'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildSettingsCard(Icons.person_outline, '账号安全', subtitle: '密码、登录设备'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.text_fields_outlined, '显示设置', subtitle: '字体大小'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.notifications_outlined, '通知设置'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.language, '语言设置', subtitle: '简体中文'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.article_outlined, '内容偏好'),
        const SizedBox(height: 24),
        Container(height: 0.5, color: AppColors.borderColor),
        const SizedBox(height: 24),
        _buildSettingsCard(Icons.people_outline, '切换账号'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.logout, '退出登录', destructive: true),
      ])),
    ]),
  );
}

Widget _buildSettingsProfile() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('个人资料'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Center(child: Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraBlue, AppColors.auroraPurple])), child: const Center(child: Text('信', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))))),
        const SizedBox(height: 8),
        const Text('点击更换头像', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        const SizedBox(height: 24),
        _buildSettingsCard(Icons.person, '昵称', subtitle: '信仰 seekers'),
        const SizedBox(height: 8),
        _buildSettingsCard(Icons.alternate_email, '用户名', subtitle: '@faith_seeker'),
        const SizedBox(height: 8),
        _buildSettingsCard(Icons.article, '个人简介', subtitle: '在信仰的道路上不断探索与前行'),
        const SizedBox(height: 8),
        _buildSettingsCard(Icons.tag, '信仰标签', subtitle: '基督教'),
        const SizedBox(height: 8),
        _buildSettingsCard(Icons.cake, '生日', subtitle: '未设置'),
        const SizedBox(height: 8),
        _buildSettingsCard(Icons.location_city, '地区', subtitle: '未设置'),
      ]))),
    ]),
  );
}

Widget _buildSettingsAccount() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('账号安全'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Security banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.hoverBg, AppColors.hoverBgLight],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ShaderMask(shaderCallback: (r) => AppColors.auroraGradient.createShader(r),
                child: const Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 20)),
              const SizedBox(width: 8),
              Text('安全保护已开启', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                foreground: Paint()..shader = AppColors.auroraGradient.createShader(const Rect.fromLTWH(0,0,200,70)))),
            ]),
            const SizedBox(height: 8),
            Text('您的账号正在受到 OpenFaith 加密盾的实时保护。建议定期修改密码并保持手机/邮箱可用。',
              style: const TextStyle(fontSize: 12, color: Color.fromRGBO(255,255,255,0.6))),
          ]),
        ),
        const SizedBox(height: 24),
        // Account info card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 22), SizedBox(width: 8), Text('账号信息', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 16),
          _buildInfoRow('邮箱', 'user@example.com'),
          const SizedBox(height: 12),
          _buildInfoRow('注册时间', '2024-06-15'),
          const SizedBox(height: 12),
          _buildInfoRow('账号状态', '正常', valueColor: AppColors.success),
        ])),
        const SizedBox(height: 16),
        // Password change card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('通过邮箱重置密码', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          _buildInput('请输入新密码（至少6位）', Icons.lock_outline, obscure: true),
          const SizedBox(height: 12),
          _buildInput('请再次输入新密码', Icons.lock_outline, obscure: true),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
            child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('发送重置链接', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))))),
        ])),
        const SizedBox(height: 16),
        // Email verification card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)), child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.verified, color: AppColors.success, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('邮箱已验证', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            const Text('您的邮箱已成功验证', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
        ])),
        const SizedBox(height: 16),
        // Phone binding card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)), child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.phone_android_outlined, color: AppColors.textSecondary, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('绑定手机', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            const Text('绑定手机号以增强账号安全', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          TextButton(onPressed: () {}, child: const Text('绑定', style: TextStyle(color: AppColors.auroraBlue))),
        ])),
      ])),
    ]),
  );
}

Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
  return Row(children: [
    Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
    Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontSize: 14))),
  ]);
}

Widget _buildSettingsNotification() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('通知设置'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [
        // Notification permission banner - warm background matching web
        Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color.fromRGBO(255, 197, 15, 0.12),
            border: Border.all(color: const Color.fromRGBO(255, 197, 15, 0.3), width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.notifications_active, color: Color.fromRGBO(255, 197, 15, 0.8), size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('开启通知权限', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('允许发送通知以接收消息提醒', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ])),
            TextButton(onPressed: () {}, child: const Text('去开启', style: TextStyle(color: Color.fromRGBO(255, 197, 15, 1.0), fontWeight: FontWeight.w600))),
          ])),
        // Section 1: 消息通知 (2 toggles)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('消息通知', style: TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w500))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.chat_bubble_outline, title: '新消息通知', desc: '接收新消息通知', action: _buildNotifToggle(enabled: true)),
            Container(height: 1, color: AppColors.borderColor),
            _buildNotifSettingItem(icon: Icons.phone_android, title: '语音和视频通话通知', desc: '接收语音/视频通话提醒', action: _buildNotifToggle(enabled: true)),
          ]),
        ])),
        // Section 2: 通知显示 (1 toggle)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('通知显示', style: TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w500))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.visibility_outlined, title: '通知显示内容', desc: '在通知中显示消息详情', action: _buildNotifToggle(enabled: true)),
          ]),
        ])),
        // Section 3: 声音与震动 (2 toggles)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('声音与震动', style: TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w500))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.volume_up, title: '消息提示音', desc: '开启提示音', action: _buildNotifToggle(enabled: true)),
            Container(height: 1, color: AppColors.borderColor),
            _buildNotifSettingItem(icon: Icons.vibration, title: '通话铃声', desc: '开启通话铃声', action: _buildNotifToggle(enabled: true)),
          ]),
        ])),
        // Section 4: 提示音与铃声 (3 clickable items)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('提示音与铃声', style: TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w500))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.music_note, title: '消息提示音', desc: '默认提示音', action: const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20)),
            Container(height: 1, color: AppColors.borderColor),
            _buildNotifSettingItem(icon: Icons.music_note, title: '来电铃声', desc: '柔和铃声', action: const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20)),
            Container(height: 1, color: AppColors.borderColor),
            _buildNotifSettingItem(icon: Icons.music_note, title: '呼叫铃声', desc: '经典铃声', action: const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20)),
          ]),
        ])),
        const SizedBox(height: 32),
      ]))),
    ]),
  );
}

Widget _buildNotifSectionCard({required List<Widget> children}) {
  return Container(margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
    clipBehavior: Clip.antiAlias, child: Column(children: children));
}

Widget _buildNotifSettingItem({required IconData icon, required String title, String? desc, required Widget action}) {
  return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.hoverBg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.textPrimary, size: 16)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      if (desc != null) Text(desc, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ])),
    action,
  ]));
}

Widget _buildNotifToggle({required bool enabled}) {
  return enabled
    ? Container(width: 48, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: AppColors.auroraGradient),
        padding: const EdgeInsets.all(1),
        child: Container(width: 46, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: AppColors.bgColor),
          padding: const EdgeInsets.all(2),
          child: Align(alignment: Alignment.centerRight,
            child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.textPrimary,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0,1))])))))
    : Container(width: 48, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.borderColor,
        border: Border.all(color: AppColors.borderSubtle, width: 1)),
        padding: const EdgeInsets.all(2),
        child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.textPlaceholder,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0,1))])));
}

Widget _buildSettingsFont() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('显示设置'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('字体大小', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildFontOption('小', '12px / 14px', false),
        const SizedBox(height: 8),
        _buildFontOption('标准', '14px / 16px', true),
        const SizedBox(height: 8),
        _buildFontOption('大', '16px / 18px', false),
        const SizedBox(height: 32),
        const Text('预览', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('标题文字示例', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('这是正文内容的预览效果。字体大小设置后，所有页面的文字都会相应调整。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        ]))),
      ]))),
    ]),
  );
}

Widget _buildFontOption(String label, String desc, bool selected) {
  return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.auroraBlue : AppColors.borderColor, width: selected ? 1.5 : 0.5)), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      const SizedBox(height: 2),
      Text(desc, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ])),
    if (selected) const Icon(Icons.check_circle, color: AppColors.auroraBlue, size: 22),
  ]));
}

Widget _buildSettingsLanguage() {
  final langs = [
    ['🇨🇳', '简体中文', '简体中文', 'zh', true],
    ['🇨🇳', '繁體中文', '繁體中文', 'zh-TW', false],
    ['🇺🇸', '英文', 'English', 'en', false],
    ['🇯🇵', '日本語', '日本語', 'ja', false],
    ['🇰🇷', '한국어', '한국어', 'ko', false],
    ['🇪🇸', 'Español', 'Español', 'es', false],
    ['🇫🇷', 'Français', 'Français', 'fr', false],
    ['🇩🇪', 'Deutsch', 'Deutsch', 'de', false],
    ['🇧🇷', 'Português', 'Português', 'pt', false],
    ['🇷🇺', 'Русский', 'Русский', 'ru', false],
    ['🇸🇦', 'العربية', 'العربية', 'ar', false],
    ['🇮🇳', 'हिन्दी', 'हिन्दी', 'hi', false],
  ];
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('语言设置'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Current language card
        Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
          child: const Row(children: [
            Icon(Icons.language, color: AppColors.textPrimary, size: 16),
            SizedBox(width: 8),
            Text('当前语言', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ])),
        // Language list
        ...langs.map((l) {
          final isSelected = l[4] as bool;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: isSelected
            ? Container(padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.bgColor),
                  child: _buildLangRow(l)))
            : Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.hoverBgLight, border: Border.all(color: AppColors.borderColor)),
                child: _buildLangRow(l)));
        }),
        const SizedBox(height: 24),
        // Hint text
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
          child: Center(child: Text('语言切换后立即生效', style: TextStyle(color: AppColors.textWeak, fontSize: 12)))),
        const SizedBox(height: 16),
      ])),
    ]),
  );
}

Widget _buildLangRow(List<dynamic> l) {
  final isSelected = l[4] as bool;
  return Row(children: [
    Text(l[0] as String, style: const TextStyle(fontSize: 20)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l[2] as String, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      Text(l[1] as String, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ])),
    if (isSelected) const Icon(Icons.check, color: AppColors.textPrimary, size: 20),
  ]);
}

Widget _buildSettingsPreferences() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('内容偏好'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('感兴趣的标签', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('选择你感兴趣的内容标签，我们将为你推荐相关内容', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _tagChip('祈祷', true), _tagChip('读经', true), _tagChip('赞美', false), _tagChip('布道', false),
          _tagChip('神学', true), _tagChip('教会生活', false), _tagChip('圣经研究', true), _tagChip('教会历史', false),
          _tagChip('心理健康', false), _tagChip('情绪管理', false), _tagChip('自我成长', true),
        ]),
        const SizedBox(height: 32),
        const Text('屏蔽的标签', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [_tagChip('广告', true, isBlock: true)]),
      ]))),
    ]),
  );
}

Widget _tagChip(String label, bool selected, {bool isBlock = false}) {
  return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(
    gradient: selected && !isBlock ? AppColors.auroraGradientWithOpacity(0.3) : null,
    color: selected && !isBlock ? null : isBlock ? AppColors.error.withOpacity(0.15) : AppColors.inputBg,
    borderRadius: BorderRadius.circular(16),
    border: selected ? null : Border.all(color: isBlock ? AppColors.error.withOpacity(0.3) : AppColors.borderColor, width: 0.5),
  ), child: Text(label, style: TextStyle(color: selected && !isBlock ? Colors.white : isBlock ? AppColors.error : AppColors.textSecondary, fontSize: 13)));
}

Widget _buildSettingsAbout() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('关于'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        const SizedBox(height: 32),
        Center(child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(18)), child: const Center(child: Text('OF', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))))),
        const SizedBox(height: 16),
        const Text('OpenFaith', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Version 1.0.0 (Build 7)', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        const SizedBox(height: 32),
        _buildSettingsCard(Icons.article_outlined, '用户协议'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.privacy_tip_outlined, '隐私政策'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.gavel_outlined, '社区公约'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.update, '检查更新'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.star_outline, '给我们评分'),
        const SizedBox(height: 32),
        const Text('🌈 信仰无界，心灵相通', style: TextStyle(color: AppColors.textWeak, fontSize: 13), textAlign: TextAlign.center),
      ]))),
    ]),
  );
}

Widget _buildSettingsPrivacy() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('隐私设置'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildToggleCard('允许陌生人查看我的主页', true),
        const SizedBox(height: 4),
        _buildToggleCard('允许搜索到我的账号', true),
        const SizedBox(height: 4),
        _buildToggleCard('显示在线状态', false),
        const SizedBox(height: 4),
        _buildToggleCard('显示阅读记录', true),
        const SizedBox(height: 24),
        _buildSettingsCard(Icons.block, '黑名单管理'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.report_outlined, '举报记录'),
        const SizedBox(height: 4),
        _buildSettingsCard(Icons.delete_outline, '清除缓存'),
      ])),
    ]),
  );
}
