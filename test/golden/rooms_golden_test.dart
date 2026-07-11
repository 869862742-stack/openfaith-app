import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';


/// Rooms Page Golden Tests
/// Covers: rooms, silent_room, create_room

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
  group('Rooms Golden Tests', () {

    testWidgets('Room list page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildRoomList()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_rooms.png'));
    });

    testWidgets('Silent room page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSilentRoom()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_silent_room.png'));
    });

    testWidgets('Create room page', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildCreateRoom()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_create_room.png'));
    });
  });
}

Widget _buildRoomList() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('共修房间'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        _roomItem('晨间冥想', '5人正在共修', '冥想 · 治愈', true),
        const SizedBox(height: 8),
        _roomItem('圣经研读', '12人正在共修', '读书 · 基督教', true),
        const SizedBox(height: 8),
        _roomItem('静默祷告', '3人正在共修', '祈祷', true),
        const SizedBox(height: 8),
        _roomItem('深夜禅修', '2人正在共修', '冥想 · 佛教', false),
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 48, decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('创建新房间', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)))),
      ]))),
    ]),
  );
}

Widget _roomItem(String name, String status, String tags, bool active) {
  return GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradientWithOpacity(0.3)), child: Icon(active ? Icons.self_improvement : Icons.nightlight_round, color: Colors.white, size: 24)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 2),
      Text(tags, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
    ])),
    if (active) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(16)), child: const Text('加入', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
  ])));
}

Widget _buildSilentRoom() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Stack(children: [
      // Starfield background placeholder
      Container(color: AppColors.bgColor),
      // Content
      Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(color: AppColors.headerBg.withOpacity(0.8), border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5))),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(bottom: false, child: Row(children: [
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('晨间冥想', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Text('5人在线', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
            ])),
            const Icon(Icons.music_note, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 22),
          ])),
        ),
        // Participants avatars
        Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...[AppColors.auroraRed, AppColors.auroraBlue, AppColors.auroraGreen, AppColors.auroraOrange, AppColors.auroraPurple].map((c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c, c.withOpacity(0.6)])), child: Center(child: Text('X', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)))))),
        ])),
        // Timer
        const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('25:00', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4)),
          SizedBox(height: 8),
          Text('专注冥想中', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ]))),
        // Bottom controls
        Container(padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.inputBg, shape: BoxShape.circle), child: const Icon(Icons.mic_off, color: AppColors.textSecondary)), const SizedBox(height: 4), const Text('静音', style: TextStyle(color: AppColors.textWeak, fontSize: 10))]),
          Column(children: [Container(width: 56, height: 56, decoration: BoxDecoration(gradient: AppColors.auroraGradient, shape: BoxShape.circle), child: const Icon(Icons.pause, color: Colors.white, size: 28)), const SizedBox(height: 4), const Text('暂停', style: TextStyle(color: AppColors.textWeak, fontSize: 10))]),
          Column(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.inputBg, shape: BoxShape.circle), child: const Icon(Icons.exit_to_app, color: AppColors.error)), const SizedBox(height: 4), const Text('离开', style: TextStyle(color: AppColors.textWeak, fontSize: 10))]),
        ])),
      ]),
    ]),
  );
}

Widget _buildCreateRoom() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildHeader('创建房间'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('房间名称', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildInput('输入房间名称', Icons.meeting_room_outlined),
        const SizedBox(height: 20),
        const Text('房间描述', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(height: 100, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)), child: const Text('描述你的房间...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
        const SizedBox(height: 20),
        const Text('标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['冥想', '音乐', '治愈', '读书', '祈祷', '学习', '工作'].map((t) {
          final s = t == '冥想';
          return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: s ? AppColors.auroraGradientWithOpacity(0.3) : null, color: s ? null : AppColors.inputBg, borderRadius: BorderRadius.circular(16), border: s ? null : Border.all(color: AppColors.borderColor, width: 0.5)), child: Text(t, style: TextStyle(color: s ? Colors.white : AppColors.textSecondary, fontSize: 13)));
        }).toList()),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor, width: 0.5)), child: Row(children: [
          const Expanded(child: Text('公开房间', style: TextStyle(color: Colors.white, fontSize: 15))),
          Switch(value: true, onChanged: (_) {}, activeColor: AppColors.auroraBlue),
        ])),
        const SizedBox(height: 32),
        Container(width: double.infinity, height: 48, decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('创建房间', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)))),
      ]))),
    ]),
  );
}
