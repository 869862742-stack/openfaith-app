import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';
import 'test_helper.dart';


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
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettings()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings.png'));
    });

    testWidgets('Settings - Profile edit', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsProfile()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_profile.png'));
    });

    testWidgets('Settings - Account security', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsAccount()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_account.png'));
    });

    testWidgets('Settings - Notification', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsNotification()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_notification.png'));
    });

    testWidgets('Settings - Font/Display', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsFont()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_font.png'));
    });

    testWidgets('Settings - Language', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsLanguage()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_language.png'));
    });

    testWidgets('Settings - Content preferences', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsPreferences()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_preferences.png'));
    });

    testWidgets('Settings - About', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsAbout()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_about.png'));
    });

    testWidgets('Settings - Privacy', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSettingsPrivacy()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_settings_privacy.png'));
    });
  });
}

Widget _buildSettingsFlatItem(IconData icon, String title, {bool destructive = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Icon(icon, color: destructive ? AppColors.error : AppColors.textSecondary, size: 20),
      const SizedBox(width: 16),
      Expanded(child: Text(title, style: TextStyle(color: destructive ? AppColors.error : Colors.white, fontSize: 14))),
    ]),
  );
}

Widget _buildSettings() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('设置'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        Column(children: [
          _buildSettingsFlatItem(Icons.person_outline, '账号安全'),
          const SizedBox(height: 4),
          _buildSettingsFlatItem(Icons.text_fields_outlined, '显示设置'),
          const SizedBox(height: 4),
          _buildSettingsFlatItem(Icons.notifications_outlined, '通知设置'),
          const SizedBox(height: 4),
          _buildSettingsFlatItem(Icons.language, '语言设置'),
          const SizedBox(height: 4),
          _buildSettingsFlatItem(Icons.article_outlined, '内容偏好'),
        ]),
        const SizedBox(height: 24),
        Container(height: 0.5, color: AppColors.borderColor),
        const SizedBox(height: 24),
        Column(children: [
          _buildSettingsFlatItem(Icons.people_outline, '切换账号'),
          const SizedBox(height: 4),
          _buildSettingsFlatItem(Icons.logout, '退出登录', destructive: true),
        ]),
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

// ═══════════════════════════════════════════════════════════════
// 1. SETTINGS ACCOUNT - matches AccountSecurity.tsx
// ═══════════════════════════════════════════════════════════════

Widget _buildAccountMenuItem(IconData icon, String label, String value, {bool destructive = false}) {
  // Web: flex items-center gap-4 p-4 rounded-xl
  // Normal: bg=rgba(255,255,255,0.04) border=rgba(255,255,255,0.08)
  // Delete: bg=var(--card-bg) border=var(--border-color)
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: destructive ? AppColors.cardBg : const Color(0x0AFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 1),
    ),
    child: Row(children: [
      Icon(icon, color: destructive ? AppColors.error : Colors.white, size: 20),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: destructive ? AppColors.error : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        if (value.isNotEmpty) Text(value, style: TextStyle(color: destructive ? const Color(0x66FFFFFF) : Colors.white, fontSize: 12)),
      ])),
      Icon(Icons.chevron_right, color: destructive ? const Color(0x66FFFFFF) : AppColors.textSecondary, size: 20),
    ]),
  );
}

Widget _buildSettingsAccount() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('账号与安全'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Security banner - web: rounded-2xl p-4 mb-6
        // bg=linear-gradient(135deg, rgba(255,255,255,0.08), rgba(255,255,255,0.04))
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x14FFFFFF), Color(0x0AFFFFFF)],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.shield, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              ShaderMask(shaderCallback: (r) => AppColors.auroraGradient.createShader(r),
                child: const Text('安全保护已开启', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text('您的账号正在受到 OpenFaith 加密盾的实时保护。建议定期修改密码并保持手机/邮箱可用。',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ]),
        ),
        // Menu items - web: space-y-3 (12px gap)
        _buildAccountMenuItem(Icons.smartphone, '手机号', '未绑定'),
        const SizedBox(height: 12),
        _buildAccountMenuItem(Icons.mail, '邮箱号', 'user@example.com'),
        const SizedBox(height: 12),
        _buildAccountMenuItem(Icons.lock, '登录密码', '已设置'),
        const SizedBox(height: 12),
        // Delete account - uses same style but red
        _buildAccountMenuItem(Icons.delete_outline, '注销账号', '', destructive: true),
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

// ═══════════════════════════════════════════════════════════════
// 4. SETTINGS NOTIFICATION - matches NotificationSettings.tsx
// ═══════════════════════════════════════════════════════════════

Widget _buildSettingsNotification() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Header: px-4 py-3 bg=rgba(5,8,22,0.92) border-bottom=rgba(255,255,255,0.08)
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20)),
            const SizedBox(width: 4),
            const Text('通知设置', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [
        // Notification permission banner - rainbow gradient border
        Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), padding: const EdgeInsets.all(0.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.auroraGradient,
          ),
          child: Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromRGBO(5, 8, 22, 0.95),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.notifications, color: Color(0xFFFF9F1C), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('开启通知权限', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('开启后才能收到来电和消息提醒，即使不在聊天页面也不会错过', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ])),
            ])),
        ),
        // Section 1: 消息通知 (2 toggles)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child: Text('消息通知', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.chat_bubble, title: '新消息通知', desc: '收到新消息时提醒', action: _buildNotifToggle(enabled: true)),
            Container(height: 1, color: const Color(0x0FFFFFFF)),
            _buildNotifSettingItem(icon: Icons.call, title: '语音和视频通话通知', desc: '收到通话邀请时响铃提醒', action: _buildNotifToggle(enabled: true)),
          ]),
        ])),
        // Section 2: 通知显示 (1 toggle)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child: Text('通知显示', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.visibility, title: '通知显示内容', desc: '显示发送者和消息内容', action: _buildNotifToggle(enabled: true)),
          ]),
        ])),
        // Section 3: 声音与震动 (3 toggles)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child: Text('声音与震动', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.volume_up, title: '消息提示音', desc: '收到新消息时播放提示音', action: _buildNotifToggle(enabled: true)),
            Container(height: 1, color: const Color(0x0FFFFFFF)),
            _buildNotifSettingItem(icon: Icons.music_note, title: '通话铃声', desc: '收到通话邀请时播放铃声', action: _buildNotifToggle(enabled: true)),
            Container(height: 1, color: const Color(0x0FFFFFFF)),
            _buildNotifSettingItem(icon: Icons.smartphone, title: '聊天界面内提示音', desc: '在聊天页面收到新消息时播放', action: _buildNotifToggle(enabled: true)),
          ]),
        ])),
        // Section 4: 提示音与铃声 (3 clickable items with chevron)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child: Text('提示音与铃声', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6))),
          _buildNotifSectionCard(children: [
            _buildNotifSettingItem(icon: Icons.chat_bubble, title: '消息提示音', desc: '默认提示音', action: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)),
            Container(height: 1, color: const Color(0x0FFFFFFF)),
            _buildNotifSettingItem(icon: Icons.call, title: '来电铃声', desc: '柔和铃声', action: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)),
            Container(height: 1, color: const Color(0x0FFFFFFF)),
            _buildNotifSettingItem(icon: Icons.call, title: '呼叫铃声', desc: '经典铃声', action: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)),
          ]),
        ])),
        const SizedBox(height: 24),
      ]))),
    ]),
  );
}

Widget _buildNotifSectionCard({required List<Widget> children}) {
  return Container(margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),  // web: rgba(255,255,255,0.04)
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x0FFFFFFF), width: 1),  // web: rgba(255,255,255,0.06)
    ),
    clipBehavior: Clip.antiAlias, child: Column(children: children));
}

Widget _buildNotifSettingItem({required IconData icon, required String title, String? desc, required Widget action}) {
  // Web: flex items-center gap-3 py-3 px-4
  return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 16)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      if (desc != null) ...[const SizedBox(height: 2), Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))],
    ])),
    action,
  ]));
}

Widget _buildNotifToggle({required bool enabled}) {
  // Web style: ToggleSwitch w-12 h-7 (48×28) rounded-full
  // Enabled: 1px rainbow gradient border + dark bg(#050816) + white circular knob(20px) right (translateX 22px)
  // Disabled: bg=rgba(255,255,255,0.15) + border=rgba(255,255,255,0.1) + dimmed knob left
  if (enabled) {
    return Container(width: 48, height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.auroraGradient,
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: const Color(0xFF050816),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(width: 20, height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0,1))]))),
        ),
      ),
    );
  }
  return Container(width: 48, height: 28,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withOpacity(0.15),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(width: 20, height: 20,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.4),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0,1))]))),
  );
}

// ═══════════════════════════════════════════════════════════════
// 3. SETTINGS FONT/DISPLAY - matches DisplaySettings.tsx
// ═══════════════════════════════════════════════════════════════

Widget _buildSettingsFont() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('显示设置'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section title: text-sm font-bold mb-3
        const Text('字体大小', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // 3 horizontal buttons - web: flex gap-3 (12px)
        Row(children: [
          Expanded(child: _buildFontSizeButton('小', '12px / 14px', false)),
          const SizedBox(width: 12),
          Expanded(child: _buildFontSizeButton('标准', '14px / 16px', true)),
          const SizedBox(width: 12),
          Expanded(child: _buildFontSizeButton('大', '16px / 18px', false)),
        ]),
        const SizedBox(height: 32),
        // Preview section - web: rainbow gradient border container, rounded-xl, p-4
        Container(
          padding: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.auroraGradientWithOpacity(0.6),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: AppColors.bgColor,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Preview header with Type icon
              Row(children: [
                const Icon(Icons.text_fields, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('预览', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 12),
              // Inner preview card: bg=rgba(255,255,255,0.04), border=rgba(255,255,255,0.08), rounded-xl, p-4
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('标题文字示例', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('这是正文内容的预览效果。字体大小设置后，所有页面的文字都会相应调整。',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5)),
                  const SizedBox(height: 12),
                  // Action buttons: "确认" with rainbow border + "取消" subtle
                  Row(children: [
                    // 确认 button - rainbow gradient border pill
                    Container(
                      padding: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppColors.auroraGradient,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: AppColors.bgColor,
                        ),
                        child: const Text('确认', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 取消 button - subtle pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0x0DFFFFFF),
                        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
                      ),
                      child: Text('取消', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ]))),
    ]),
  );
}

Widget _buildFontSizeButton(String label, String desc, bool selected) {
  // Web: flex-1 py-3 px-2 rounded-xl, centered content
  // Selected: rainbow gradient border (RAINBOW_STYLES.clipBorder1_5px)
  // Not selected: bg=rgba(255,255,255,0.04), border=rgba(255,255,255,0.08)
  if (selected) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.auroraGradient,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.bgColor,
        ),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ]),
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x14FFFFFF), width: 1),
    ),
    child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// 5. SETTINGS LANGUAGE - matches LanguageSettings.tsx
// ═══════════════════════════════════════════════════════════════

Widget _buildSettingsLanguage() {
  final langs = [
    ['🇨🇳', '简体中文', '简体中文', 'zh-CN', true],
    ['🇺🇸', 'English', 'English', 'en-US', false],
    ['🇫🇷', 'Français', 'Français', 'fr-FR', false],
    ['🇪🇸', 'Español', 'Español', 'es-ES', false],
    ['🇷🇺', 'Русский', 'Русский', 'ru-RU', false],
    ['🇸🇦', 'العربية', 'العربية', 'ar-EG', false],
  ];
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('语言设置'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Current language card - web: rounded-xl p-4 mb-4 bg=rgba(255,255,255,0.04) border=rgba(255,255,255,0.08)
        Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x14FFFFFF), width: 1),
          ),
          child: Row(children: [
            const Icon(Icons.language, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text('当前语言: ', style: TextStyle(color: Colors.white, fontSize: 14)),
            const Text('简体中文', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
        // Language list - web: space-y-2 (8px gap)
        ...langs.map((l) {
          final isSelected = l[4] as bool;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: isSelected
            // Selected: 2px rainbow gradient border, inner bgColor
            ? Container(padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
                child: Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.bgColor),
                  child: _buildLangRow(l)))
            // Not selected: bg=rgba(255,255,255,0.04), border=rgba(255,255,255,0.08)
            : Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x0AFFFFFF),
                  border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                ),
                child: _buildLangRow(l)));
        }),
        const SizedBox(height: 24),
        // Hint text - web: mt-6 p-4 rounded-xl bg=rgba(255,255,255,0.03) border=rgba(255,255,255,0.06)
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x0FFFFFFF), width: 1),
          ),
          child: Center(child: Text('语言切换后立即生效', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)))),
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
      Text(l[2] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      Text(l[1] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
    ])),
    if (isSelected) const Icon(Icons.check, color: Colors.white, size: 20),
  ]);
}

// ═══════════════════════════════════════════════════════════════
// 2. SETTINGS PREFERENCES - matches ContentPreferences.tsx
// ═══════════════════════════════════════════════════════════════

Widget _buildSettingsPreferences() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('内容偏好'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Section 1: 偏好标签 - rainbow gradient border container
        _buildPrefSection(
          title: '偏好标签',
          desc: '我们会为您优先推荐您感兴趣的学习内容',
          tags: const ['基督教', '佛教'],
          showEmpty: false,
          hasGradientAddButton: true,
          addLabel: '添加偏好',
        ),
        const SizedBox(height: 16),
        // Section 2: 屏蔽标签 - rainbow gradient border container
        _buildPrefSection(
          title: '屏蔽标签',
          desc: '被屏蔽的标签内容将不会出现在您的推荐中',
          tags: const [],
          showEmpty: true,
          hasGradientAddButton: false,
          addLabel: '添加屏蔽',
        ),
      ]))),
    ]),
  );
}

Widget _buildPrefSection({
  required String title,
  required String desc,
  required List<String> tags,
  required bool showEmpty,
  required bool hasGradientAddButton,
  required String addLabel,
}) {
  // Web: rounded-xl p-4, rainbow gradient border (0.5px), bg=transparent (we use bgColor for Flutter)
  return Container(
    padding: const EdgeInsets.all(0.5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: AppColors.auroraGradientWithOpacity(0.5),
    ),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: AppColors.bgColor,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header with colored indicator bar
        Row(children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.auroraGradientWithOpacity(0.5),
          )),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 12),
        // Tags
        if (tags.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: tags.map((tag) => _buildPrefTagChip(tag)).toList()),
        // Empty placeholder for blocked tags
        if (showEmpty && tags.isEmpty) Container(
          height: 64, width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1, style: BorderStyle.solid),
          ),
          child: Center(child: Text('暂无屏蔽标签', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))),
        ),
        if (showEmpty && tags.isEmpty) const SizedBox(height: 12),
        // Add button
        if (hasGradientAddButton)
          // "添加偏好" - rainbow gradient border button
          Container(
            width: double.infinity, height: 40,
            padding: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.auroraGradientWithOpacity(0.6),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: AppColors.bgColor,
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(addLabel, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ])),
            ),
          )
        else
          // "添加屏蔽" - subtle border button
          Container(
            width: double.infinity, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
            ),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit, color: Colors.white.withOpacity(0.7), size: 16),
              const SizedBox(width: 8),
              Text(addLabel, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
            ])),
          ),
      ]),
    ),
  );
}

Widget _buildPrefTagChip(String label) {
  // Web: px-3 py-1.5 text-xs rounded-full
  // bg=rgba(255,255,255,0.06), color=#FFFFFF, border=0.5px solid rgba(255,255,255,0.2)
  // With X remove button
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x0FFFFFFF),  // rgba(255,255,255,0.06)
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),  // rgba(255,255,255,0.2)
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      const SizedBox(width: 4),
      Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 12),
    ]),
  );
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
