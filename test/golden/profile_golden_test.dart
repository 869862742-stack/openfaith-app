import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';


/// Profile Page Golden Test
/// Covers: profile, user_profile

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
  group('Profile Page Golden Tests', () {
    testWidgets('Profile page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildProfile()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_profile.png'));
    });

    testWidgets('User profile page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildUserProfile()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_user_profile.png'));
    });
  });
}

Widget _buildProfile() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: SingleChildScrollView(child: Column(children: [
      // Profile header
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.bgColor, AppColors.bgColor.withOpacity(0.8)]),
        ),
        child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          // Top row
          Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(16)), child: const Text('编辑资料', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 20)),
          ]),
          const SizedBox(height: 24),
          // Avatar
          Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraBlue, AppColors.auroraPurple])), child: const Center(child: Text('信', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 16),
          const Text('信仰 seekers', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(10)), child: const Text('基督教', style: TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(height: 8),
          const Text('Lv.5 融通者', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          const Text('在信仰的道路上不断探索与前行。热爱阅读圣经，喜欢分享感悟。', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('128', '帖子'),
            _statItem('1.2k', '粉丝'),
            _statItem('256', '关注'),
            _statItem('5.6k', '热度'),
          ]),
        ]))),
      ),
      // Tab bar
      _buildTabBar(['笔记', '计划', '珍藏'], 0),
      // Posts grid
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildPostCard(authorName: '信仰 seekers', avatarLetter: '信', avatarGradient: [AppColors.auroraBlue, AppColors.auroraPurple], faithTag: '基督教', timeAgo: '2天前', content: '今天的灵修很有收获，分享诗篇23篇的感悟。', likes: 45, comments: 12, shares: 3),
        const SizedBox(height: 12),
        _buildPostCard(authorName: '信仰 seekers', avatarLetter: '信', avatarGradient: [AppColors.auroraBlue, AppColors.auroraPurple], faithTag: '基督教', timeAgo: '5天前', content: '参加了一次很棒的线上共修活动，感受到了信仰的力量。', likes: 78, comments: 23, shares: 8),
      ])),
    ])),
    bottomNavigationBar: _buildBottomNav(4),
  );
}

Widget _statItem(String value, String label) {
  return Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}

Widget _buildUserProfile() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: SingleChildScrollView(child: Column(children: [
      _buildHeader('用户主页'),
      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Container(width: 72, height: 72, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraRed, AppColors.auroraOrange])), child: const Center(child: Text('张', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 12),
        const Text('张三', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(10)), child: const Text('基督教', style: TextStyle(color: Colors.white, fontSize: 12))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(20)), child: const Text('关注', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderColor, width: 0.5)), child: const Text('发消息', style: TextStyle(color: Colors.white, fontSize: 14))),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statItem('128', '帖子'),
          _statItem('1.2k', '粉丝'),
          _statItem('256', '关注'),
        ]),
        const SizedBox(height: 16),
        const Text('热爱信仰，热爱生活。每日灵修，分享感悟。', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
      ])),
      _buildTabBar(['笔记', '珍藏'], 0),
      Padding(padding: const EdgeInsets.all(16), child: _buildPostCard(authorName: '张三', avatarLetter: 'Z', avatarGradient: [AppColors.auroraRed, AppColors.auroraOrange], faithTag: '基督教', timeAgo: '1天前', content: '今天的灵修很有收获。', likes: 42, comments: 8, shares: 3)),
    ])),
  );
}
