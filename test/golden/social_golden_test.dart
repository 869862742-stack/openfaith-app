import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';


/// Social Pages Golden Tests
/// Covers: add_friend, add_group, contact

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
  group('Social Pages Golden Tests', () {

    testWidgets('Add friend page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildAddFriend()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_add_friend.png'));
    });

    testWidgets('Add group page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildAddGroup()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_add_group.png'));
    });

    testWidgets('Contact page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildContact()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_contact.png'));
    });
  });
}

Widget _buildAddFriend() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('添加好友'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSearchBar(),
        const SizedBox(height: 24),
        // Search results
        const Text('推荐用户', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _userItem('赵六', '基督教', '一起共修过', 'Z', [AppColors.auroraRed, AppColors.auroraOrange], '添加'),
        const SizedBox(height: 8),
        _userItem('钱七', '佛教', '2位共同好友', 'Q', [AppColors.auroraBlue, AppColors.auroraPurple], '添加'),
        const SizedBox(height: 8),
        _userItem('孙八', '伊斯兰教', '同在一个群组', 'S', [AppColors.auroraGreen, AppColors.auroraCyan], '已添加'),
      ]))),
    ]),
  );
}

Widget _userItem(String name, String faith, String info, String letter, List<Color> gradient, String action) {
  return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor, width: 0.5)), child: Row(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)), child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 15)),
      const SizedBox(height: 2),
      Text('$faith · $info', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(
      gradient: action == '添加' ? AppColors.auroraGradient : null,
      color: action != '添加' ? AppColors.inputBg : null,
      borderRadius: BorderRadius.circular(16),
    ), child: Text(action, style: TextStyle(color: action == '添加' ? Colors.white : AppColors.textSecondary, fontSize: 12))),
  ]));
}

Widget _buildAddGroup() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('创建群组'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('群组名称', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildInput('输入群组名称', Icons.group_outlined),
        const SizedBox(height: 20),
        const Text('群组描述', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(height: 80, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)), child: const Text('描述你的群组...')),
        const SizedBox(height: 20),
        const Text('群组标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['基督教', '伊斯兰教', '佛教', '印度教', '道教'].map((t) {
          final s = t == '基督教';
          return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: s ? AppColors.auroraGradientWithOpacity(0.3) : null, color: s ? null : AppColors.inputBg, borderRadius: BorderRadius.circular(14), border: s ? null : Border.all(color: AppColors.borderColor, width: 0.5)), child: Text(t, style: TextStyle(color: s ? Colors.white : AppColors.textSecondary, fontSize: 12)));
        }).toList()),
        const SizedBox(height: 24),
        const Text('邀请好友', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _friendCheckbox('张三', 'Z', [AppColors.auroraRed, AppColors.auroraOrange], true),
        const SizedBox(height: 8),
        _friendCheckbox('李明', 'L', [AppColors.auroraBlue, AppColors.auroraPurple], false),
      ]))),
    ]),
  );
}

Widget _friendCheckbox(String name, String letter, List<Color> gradient, bool checked) {
  return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: checked ? AppColors.auroraBlue : AppColors.borderColor, width: checked ? 1.5 : 0.5)), child: Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)), child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))),
    const SizedBox(width: 12),
    Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14))),
    Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, color: checked ? AppColors.auroraBlue : AppColors.textWeak, size: 22),
  ]));
}

Widget _buildContact() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('联系人'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        // Friend requests section
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor, width: 0.5)), child: Row(children: [
          Stack(children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.auroraRed, AppColors.auroraOrange])), child: const Center(child: Text('赵', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
            Positioned(right: -2, top: -2, child: Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error), child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))))),
          ]),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('好友请求', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text('2条新请求', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
        ])),
        const SizedBox(height: 16),
        const Text('好友列表', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _contactItem('张三', '在线', 'Z', [AppColors.auroraRed, AppColors.auroraOrange]),
        const SizedBox(height: 8),
        _contactItem('李明', '3小时前', 'L', [AppColors.auroraBlue, AppColors.auroraPurple]),
        const SizedBox(height: 8),
        _contactItem('王芳', '昨天', 'W', [AppColors.auroraGreen, AppColors.auroraCyan]),
        const SizedBox(height: 8),
        _contactItem('陈伟', '在线', 'C', [AppColors.auroraYellow, AppColors.auroraGreen]),
      ]))),
    ]),
  );
}

Widget _contactItem(String name, String status, String letter, List<Color> gradient) {
  return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor, width: 0.5)), child: Row(children: [
    Stack(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)), child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
      if (status == '在线') Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success, border: Border.all(color: AppColors.bgColor, width: 2)))),
    ]),
    const SizedBox(width: 12),
    Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 15))),
    Text(status, style: TextStyle(color: status == '在线' ? AppColors.success : AppColors.textWeak, fontSize: 12)),
  ]));
}
