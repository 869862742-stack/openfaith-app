import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Sidebar Pages Golden Tests
/// Covers: history, downloads, covenant, scan, support, gongjing, privacy, terms, vip

// ─── Common Helpers ───
Widget _buildSliverHeader(String title, {bool showBack = true}) {
  return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
    ),
    child: SafeArea(
      bottom: false,
      child: Row(children: [
        if (showBack) ...[
          const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 4),
        ],
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

Widget _buildGlassHeader(String title) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: SafeArea(
      bottom: false,
      child: Row(children: [
        const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Center(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 36),
      ]),
    ),
  );
}

Widget _buildSettingsCard(IconData icon, String title, {String? subtitle, bool showArrow = true}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.textSecondary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 12))],
      ])),
      if (showArrow) const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
    ]),
  );
}

void main() {
  group('Sidebar Pages Golden Tests', () {
    testWidgets('history page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildHistory()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_history.png'));
    });

    testWidgets('downloads page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildDownloads()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_downloads.png'));
    });

    testWidgets('covenant page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildCovenant()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_covenant.png'));
    });

    testWidgets('scan page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildScan()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_scan.png'));
    });

    testWidgets('support page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSupport()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_support.png'));
    });

    testWidgets('gongjing page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildGongjing()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_gongjing.png'));
    });

    testWidgets('privacy page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildPrivacy()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_privacy.png'));
    });

    testWidgets('terms page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildTerms()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_terms.png'));
    });

    testWidgets('vip page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildVip()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_vip.png'));
    });
  });
}

// ─── History Page ───
Widget _buildHistory() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Header: back + title on left, "关闭记录" on right
      Container(
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
            const Text('浏览记录', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('关闭记录', style: TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Clear history button with rainbow border
        Container(padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
          child: Container(
            width: double.infinity, height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: AppColors.bgColor),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text('清空浏览记录', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _buildHistoryItem('今天读了一段很有启发的经文', '张三', '2小时前', '基督教'),
        const SizedBox(height: 8),
        _buildHistoryItem('禅修日记第30天', '李明', '昨天', '佛教'),
        const SizedBox(height: 8),
        _buildHistoryItem('今天的祷告让我感受到了真主的慈悯', '王芳', '2天前', '伊斯兰教'),
        const SizedBox(height: 8),
        _buildHistoryItem('道德经研读笔记：上善若水', '陈伟', '3天前', '道教'),
        const SizedBox(height: 8),
        _buildHistoryItem('圣经研读心得分享', '赵六', '5天前', '基督教'),
      ]))),
    ]),
  );
}

Widget _buildHistoryItem(String title, String author, String time, String tag) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      // Cover thumbnail (48x48 rounded-lg)
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.04),
        ),
        child: const Center(child: Text('📖', style: TextStyle(fontSize: 18))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title + tag on same line
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(tag, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        // Author + time
        Row(children: [
          Text(author, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(color: AppColors.textWeak.withOpacity(0.5), fontSize: 12)),
        ]),
      ])),
    ]),
  );
}

// ─── Downloads Page ───
Widget _buildDownloads() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildSliverHeader('下载管理'),
      // Stats bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
        ),
        child: Row(children: [
          _buildStat('0', '已下载书籍'),
          Container(width: 1, height: 24, color: AppColors.borderDefault),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
          _buildStat('0', '笔记资源'),
          Container(width: 1, height: 24, color: AppColors.borderDefault),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
          _buildStat('0 MB', '占用空间'),
        ]),
      ),
      // Tab bar
      Container(
        decoration: BoxDecoration(color: AppColors.cardBg, border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1))),
        child: Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2))), child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, size: 16), SizedBox(width: 8), Text('离线书籍', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))])))),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.description, size: 16, color: AppColors.textWeak), const SizedBox(width: 8), Text('笔记资源', style: TextStyle(color: AppColors.textWeak, fontSize: 14))])))),
        ]),
      ),
      Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
        Icon(Icons.download_outlined, color: AppColors.textWeak, size: 48),
        const SizedBox(height: 16),
        Text('暂无下载内容', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('浏览书籍时可以离线保存', style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
      ])))),
    ]),
  );
}

Widget _buildStat(String value, String label) {
  return Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
  ]);
}

// ─── Covenant Page ───
Widget _buildCovenant() {
  const items = [
    {'title': '平等与尊重', 'content': '每一个灵魂都值得被听见。我们尊重所有信仰传统、灵性探索及无神论立场。'},
    {'title': '和平与理性', 'content': '分享您的见解而非强加您的观点。我们鼓励建设性的对话。'},
    {'title': '真实与纯净', 'content': '严禁传播邪教思想、极端主义信息、暴力违禁内容或商业欺诈。'},
    {'title': '安全与边界', 'content': '尊重他人的数字足迹。严禁泄露他人真实身份信息。'},
    {'title': '共筑安心家园', 'content': '平台将根据违规情节的轻重，对违反公约的行为采取相应管理措施。'},
  ];
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildSliverHeader('信仰公约'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Intro card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.5), color: AppColors.background),
                  child: const Center(child: Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OpenFaith 信仰公约', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('尊重 · 包容 · 和平', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 12),
            const Text('我们致力于创建一个尊重、包容、和平的全球信仰交流社区。', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 24),
        ...List.generate(items.length, (i) {
          final item = items[i];
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32, height: 32,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.5), color: AppColors.background),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['title']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item['content']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ])),
            ]),
          ));
        }),
        const SizedBox(height: 24),
        Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check, color: AppColors.textPrimary, size: 16),
            SizedBox(width: 8),
            Text('共同维护社区环境', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ]),
        )),
      ]))),
    ]),
  );
}

// ─── Scan Page ───
Widget _buildScan() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildSliverHeader('扫一扫'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('扫描二维码', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('使用相机扫描二维码或从相册选择图片', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            _buildGradientBtn(icon: Icons.camera_alt_outlined, label: '打开相机扫描'),
            const SizedBox(height: 12),
            _buildGradientBtn(icon: Icons.image_outlined, label: '从相册选择'),
          ]),
        ),
        const SizedBox(height: 32),
        const Center(child: Text('扫描二维码可以快速添加好友或加入群聊', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      ]))),
    ]),
  );
}

Widget _buildGradientBtn({required IconData icon, required String label}) {
  return Container(
    width: double.infinity, height: 48,
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.5), color: AppColors.background),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ─── Support Page ───
Widget _buildSupport() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('欢迎联系'),
      // Tab bar
      Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 0.5))),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(16)), child: const Text('我的工单', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
          const SizedBox(width: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Text('新建工单', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
        ]),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildTicketCard('功能建议：增加夜间模式', '已回复', '3天前'),
        const SizedBox(height: 12),
        _buildTicketCard('Bug反馈：页面加载缓慢', '处理中', '5天前'),
      ]))),
    ]),
  );
}

Widget _buildTicketCard(String title, String status, String time) {
  Color statusColor;
  switch (status) {
    case '已回复':
      statusColor = AppColors.auroraGreen;
      break;
    case '处理中':
      statusColor = AppColors.auroraOrange;
      break;
    default:
      statusColor = AppColors.textWeak;
  }
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 11))),
      ]),
      const SizedBox(height: 8),
      Text(time, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
    ]),
  );
}

// ─── Gongjing Page ───
Widget _buildGongjing() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Header
      Container(
        decoration: BoxDecoration(color: AppColors.headerBg, border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5))),
        child: SafeArea(bottom: false, child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
            const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary, size: 20),
            const Spacer(),
            const Text('共境', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            const Spacer(),
            const SizedBox(width: 36),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Row(children: [
            _buildGongjingTab('静默同行', true),
            const SizedBox(width: 8),
            _buildGongjingTab('世界呼吸', false),
            const SizedBox(width: 8),
            _buildGongjingTab('树洞回声', false),
            const SizedBox(width: 8),
            _buildGongjingTab('无界圆桌', false),
          ])),
        ])),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 24, 16, 32), child: Column(children: [
        // Room cards
        _buildGongjingRoomCard('晨间冥想', '5人正在静默共修', Icons.self_improvement),
        const SizedBox(height: 12),
        _buildGongjingRoomCard('圣经研读', '12人正在共修', Icons.menu_book),
        const SizedBox(height: 12),
        _buildGongjingRoomCard('静默祷告', '3人正在共修', Icons.church),
      ]))),
    ]),
  );
}

Widget _buildGongjingTab(String label, bool active) {
  return Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: active ? AppColors.auroraBlue.withOpacity(0.15) : null,
      borderRadius: BorderRadius.circular(20),
      border: active ? null : Border.all(color: AppColors.borderDefault),
    ),
    child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 12))),
  ));
}

Widget _buildGongjingRoomCard(String name, String info, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradientWithOpacity(0.3)), child: Icon(icon, color: Colors.white, size: 24)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(info, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ])),
    ]),
  );
}

// ─── Privacy Page ─── (aligned with PrivacyPolicyScreen source)
Widget _buildPrivacy() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Custom header: back | title | EN toggle
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            const Text('← 返回', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 14)),
            const Spacer(),
            const Text('隐私政策', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.hoverBg, borderRadius: BorderRadius.circular(8)),
              child: const Text('EN', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 12)),
            ),
          ]),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('最后更新：2026年6月7日', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12)),
        const SizedBox(height: 24),
        const Text('1. 概述', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('OpenFaith（以下简称"我们"）深知个人信息对您的重要性，我们将按照法律法规的规定，保护您的个人信息及隐私安全。本隐私政策适用于 OpenFaith 移动应用及网站（openfaithhub.com）提供的所有服务。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 8),
        const Text('我们制定本隐私政策旨在帮助您了解：我们如何收集、使用、存储和保护您的个人信息；您如何管理您的个人信息。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 24),
        const Text('2. 我们收集的信息', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('2.1 您主动提供的信息', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildPrivacyBullet('注册信息：邮箱地址、昵称、身份标签'),
        _buildPrivacyBullet('内容信息：您发布的笔记、评论、问答等用户生成内容'),
        _buildPrivacyBullet('社交信息：关注关系、好友请求、私信内容'),
        const SizedBox(height: 16),
        const Text('2.2 自动收集的信息', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildPrivacyBullet('设备信息：设备型号、操作系统版本'),
        _buildPrivacyBullet('使用数据：访问页面、功能使用频率、阅读时长'),
        _buildPrivacyBullet('Cookie 及类似技术：用于维护登录状态、偏好设置'),
        const SizedBox(height: 24),
        const Text('3. 我们如何使用信息', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildPrivacyBullet('提供、维护和改进我们的服务'),
        _buildPrivacyBullet('个性化推荐内容（基于您的身份标签和阅读偏好）'),
        _buildPrivacyBullet('处理交易和管理VIP会员权益'),
        _buildPrivacyBullet('发送服务通知（系统消息、互动提醒）'),
        const SizedBox(height: 24),
        const Text('4. 信息共享', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('我们不会出售您的个人信息。仅在以下情况下我们可能共享您的信息：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 8),
        _buildPrivacyBullet('获得您的明确同意后'),
        _buildPrivacyBullet('与我们的服务提供商共享（云托管、支付处理）'),
        _buildPrivacyBullet('遵守法律义务或法律程序'),
        const SizedBox(height: 32),
      ]))),
    ]),
  );
}

Widget _buildPrivacyBullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6))),
    ]),
  );
}

// ─── Terms Page ─── (aligned with TermsOfServiceScreen source)
Widget _buildTerms() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      // Custom header: back | title | EN toggle
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.headerBg,
          border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            const Text('← 返回', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 14)),
            const Spacer(),
            const Text('服务条款', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.hoverBg, borderRadius: BorderRadius.circular(8)),
              child: const Text('EN', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 12)),
            ),
          ]),
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('最后更新：2026年6月7日', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12)),
        const SizedBox(height: 24),
        const Text('1. 接受条款', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('欢迎使用 OpenFaith！使用本应用及网站（openfaithhub.com）即表示您同意遵守本服务条款。如果您不同意这些条款，请勿使用我们的服务。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 24),
        const Text('2. 服务描述', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('OpenFaith 是一个宗教经典阅读与信仰交流平台，提供以下核心服务：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 8),
        _buildTermsBullet('多宗教经典书籍的在线阅读'),
        _buildTermsBullet('信仰社区互动（笔记、评论、问答）'),
        _buildTermsBullet('静默陪伴与共境功能'),
        _buildTermsBullet('VIP会员增值服务'),
        const SizedBox(height: 24),
        const Text('3. 用户资格', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildTermsBullet('您必须年满13周岁方可使用本服务'),
        _buildTermsBullet('您提供的注册信息必须真实、准确'),
        _buildTermsBullet('每人仅限注册一个账号'),
        _buildTermsBullet('不得使用他人身份注册或使用服务'),
        const SizedBox(height: 24),
        const Text('4. 用户行为规范', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('您在使用本服务时，不得：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 8),
        _buildTermsBullet('发布违法、淫秽、诽谤、仇恨、暴力或歧视性内容'),
        _buildTermsBullet('冒充他人或虚构身份'),
        _buildTermsBullet('骚扰、威胁或恐吓其他用户'),
        _buildTermsBullet('传播垃圾信息或恶意软件'),
        const SizedBox(height: 32),
      ]))),
    ]),
  );
}

Widget _buildTermsBullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6))),
    ]),
  );
}

// ─── VIP Page ─── (aligned with VipScreen source)
Widget _buildVip() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('会员中心'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), child: Column(children: [
        // Hero: crown icon with rainbow border + title + subtitle
        Container(
          width: 64, height: 64,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: AppColors.auroraGradientWithOpacity(0.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38.5),
              color: AppColors.bgColor,
            ),
            child: const Center(child: Icon(Icons.workspace_premium, color: AppColors.textPrimary, size: 40)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('解锁专属权益', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('升级VIP，畅享信仰之旅', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
        const SizedBox(height: 24),
        // 我的特权卡片 section
        Align(alignment: Alignment.centerLeft, child: Text('我的特权卡片', style: TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2))),
        const SizedBox(height: 12),
        Row(children: List.generate(5, (i) {
          final icons = [Icons.visibility, Icons.push_pin, Icons.volume_up, Icons.send, Icons.chat_bubble_outline];
          final labels = ['加热卡', '置顶卡', '回响卡', '同行卡', '答疑卡'];
          return Expanded(child: Container(
            margin: EdgeInsets.only(left: i > 0 ? 4 : 0, right: i < 4 ? 4 : 0),
            child: Container(
              padding: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradientWithOpacity(0.5)),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11.5), color: AppColors.bgColor),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  Icon(icons[i], color: AppColors.textPrimary, size: 16),
                  const SizedBox(height: 4),
                  Text('${i + 1}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(labels[i], style: TextStyle(color: AppColors.textWeak, fontSize: 10)),
                ]),
              ),
            ),
          ));
        })),
        const SizedBox(height: 8),
        Text('每月赠送1张，超月未用自动过期', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        // VIP 专属权益 section (3-col grid, show first 2 rows = 6 items)
        Align(alignment: Alignment.centerLeft, child: Text('VIP 专属权益', style: TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2))),
        const SizedBox(height: 12),
        ..._buildVipGridRow([
          {'icon': Icons.visibility, 'label': '加热卡', 'color': AppColors.auroraCyan},
          {'icon': Icons.push_pin, 'label': '置顶卡', 'color': AppColors.auroraBlue},
          {'icon': Icons.volume_up, 'label': '回响卡', 'color': AppColors.auroraPurple},
        ]),
        const SizedBox(height: 10),
        ..._buildVipGridRow([
          {'icon': Icons.send, 'label': '同行卡', 'color': AppColors.auroraOrange},
          {'icon': Icons.chat_bubble_outline, 'label': '答疑卡', 'color': AppColors.auroraGreen},
          {'icon': Icons.workspace_premium, 'label': '专属标识', 'color': AppColors.auroraPurple},
        ]),
        const SizedBox(height: 10),
        ..._buildVipGridRow([
          {'icon': Icons.bolt, 'label': '经验加速', 'color': AppColors.auroraRed},
          {'icon': Icons.headphones, 'label': '优先客服', 'color': AppColors.auroraRed},
          {'icon': Icons.star, 'label': '热点翻倍', 'color': AppColors.auroraOrange},
        ]),
        const SizedBox(height: 10),
        ..._buildVipGridRow([
          {'icon': Icons.groups, 'label': '圆桌主持', 'color': AppColors.auroraGreen},
          {'icon': Icons.person_add, 'label': '静默同行', 'color': AppColors.auroraCyan},
          {'icon': Icons.translate, 'label': 'AI翻译', 'color': AppColors.auroraYellow},
        ]),
        const SizedBox(height: 20),
        // 开通即享 section
        Container(
          padding: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.auroraGradientWithOpacity(0.5)),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.5), color: AppColors.bgColor),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.card_giftcard, color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 8),
                const Text('开通即享', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                '1张加热卡', '1张置顶卡', '1张回响卡', '1张同行卡', '1张答疑卡', '+500经验',
              ].map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check, color: AppColors.auroraGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(g, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              )).toList()),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        // Bottom CTA button
        Container(
          padding: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.auroraGradientWithOpacity(0.5)),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.5), color: AppColors.bgColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.workspace_premium, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              const Text('开通 VIP 会员', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.textPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('¥99', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text('一次性付费 · 永久享受', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 16),
      ]))),
    ]),
  );
}

List<Widget> _buildVipGridRow(List<Map<String, dynamic>> items) {
  return [
    Row(children: List.generate(3, (col) {
      final item = items[col];
      final icon = item['icon'] as IconData;
      final label = item['label'] as String;
      final color = item['color'] as Color;
      return Expanded(child: Container(
        margin: EdgeInsets.only(left: col > 0 ? 10 : 0, right: col < 2 ? 10 : 0),
        child: Container(
          padding: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradientWithOpacity(0.5)),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11.5), color: AppColors.bgColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ]),
          ),
        ),
      ));
    })),
  ];
}
