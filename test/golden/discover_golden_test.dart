import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';


/// Discover Page Golden Test
/// Covers: discover

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
  group('Discover Page Golden Tests', () {
    testWidgets('Discover page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildDiscover()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_discover.png'));
    });
  });
}

Widget _buildDiscover() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('发现'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSearchBar(),
        const SizedBox(height: 24),
        const Text('分类浏览', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, children: [
          _categoryCard('圣经研读', Icons.menu_book, AppColors.auroraPurple),
          _categoryCard('祷告指南', Icons.self_improvement, AppColors.auroraGreen),
          _categoryCard('灵修日记', Icons.edit_note, AppColors.auroraOrange),
          _categoryCard('教会动态', Icons.church, AppColors.auroraBlue),
          _categoryCard('诗歌赞美', Icons.music_note, AppColors.auroraRed),
          _categoryCard('团契生活', Icons.groups, AppColors.auroraYellow),
        ]),
        const SizedBox(height: 24),
        const Text('热门话题', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _topicCard('每日灵修：诗篇23篇', '今天默想耶和华是我的牧者...', 128, 32),
        const SizedBox(height: 8),
        _topicCard('新约圣经读书计划', '一起读完使徒行传，每日打卡分享', 86, 15),
        const SizedBox(height: 8),
        _topicCard('祷告墙', '为彼此代祷，见证神的恩典', 234, 67),
        const SizedBox(height: 8),
        _topicCard('信仰问答', '关于信仰的疑问，在这里找到答案', 156, 43),
      ]))),
    ]),
  );
}

Widget _categoryCard(String name, IconData icon, Color color) {
  return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
    const SizedBox(height: 8),
    Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
  ])));
}

Widget _topicCard(String title, String desc, int participants, int posts) {
  return GlassCard(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
    const SizedBox(height: 10),
    Row(children: [
      Icon(Icons.people, color: AppColors.auroraBlue, size: 14),
      const SizedBox(width: 4),
      Text('$participants 参与', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
      const SizedBox(width: 16),
      Icon(Icons.article, color: AppColors.auroraOrange, size: 14),
      const SizedBox(width: 4),
      Text('$posts 帖子', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ]),
  ])));
}
