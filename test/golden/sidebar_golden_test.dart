import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';

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
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildHistory()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_history.png'));
    });

    testWidgets('downloads page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildDownloads()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_downloads.png'));
    });

    testWidgets('covenant page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildCovenant()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_covenant.png'));
    });

    testWidgets('scan page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildScan()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_scan.png'));
    });

    testWidgets('support page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildSupport()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_support.png'));
    });

    testWidgets('gongjing page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildGongjing()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_gongjing.png'));
    });

    testWidgets('privacy page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildPrivacy()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_privacy.png'));
    });

    testWidgets('terms page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildTerms()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_terms.png'));
    });

    testWidgets('vip page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor), home: _buildVip()));
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
      _buildSliverHeader('浏览记录', showBack: true),
      // Toggle bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
        ),
        child: Row(children: [
          Icon(Icons.fiber_manual_record, color: AppColors.auroraGreen, size: 10),
          const SizedBox(width: 8),
          Text('记录浏览', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text('清空记录', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.auroraBlue, AppColors.auroraPurple])),
        child: Center(child: Text(author[0], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(6)), child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10))),
          const SizedBox(width: 8),
          Text('$author · $time', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        ]),
      ])),
      Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
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

// ─── Privacy Page ───
Widget _buildPrivacy() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildSliverHeader('隐私政策'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDefault)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.5), color: AppColors.background),
                  child: const Center(child: Icon(Icons.privacy_tip_outlined, color: AppColors.textPrimary, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OpenFaith 隐私政策', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('最后更新：2026年1月1日', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
              ])),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        _buildPrivacySection('1. 信息收集', '我们收集您在注册、使用过程中提供的个人信息，包括用户名、邮箱、信仰偏好等。我们不会收集与信仰服务无关的个人信息。'),
        const SizedBox(height: 16),
        _buildPrivacySection('2. 信息使用', '您的信息仅用于提供和改善我们的服务，包括个性化推荐、社区互动等功能。我们不会将您的信息出售给第三方。'),
        const SizedBox(height: 16),
        _buildPrivacySection('3. 信息保护', '我们采用行业标准的安全措施保护您的个人信息，包括数据加密、安全存储等。'),
        const SizedBox(height: 16),
        _buildPrivacySection('4. 信息共享', '除法律法规要求外，我们不会与任何第三方共享您的个人信息。'),
      ]))),
    ]),
  );
}

Widget _buildPrivacySection(String title, String content) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
    ]),
  );
}

// ─── Terms Page ───
Widget _buildTerms() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildSliverHeader('服务条款'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDefault)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.5), color: AppColors.background),
                  child: const Center(child: Icon(Icons.description_outlined, color: AppColors.textPrimary, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OpenFaith 服务条款', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('最后更新：2026年1月1日', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
              ])),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        _buildTermsSection('1. 服务说明', 'OpenFaith 是一个全球信仰交流平台，旨在连接不同信仰背景的探索者，提供学习、交流和成长的空间。'),
        const SizedBox(height: 16),
        _buildTermsSection('2. 用户责任', '用户应遵守社区公约，尊重其他信仰传统，不传播虚假信息，不从事违法活动。'),
        const SizedBox(height: 16),
        _buildTermsSection('3. 内容规范', '用户发布的内容应合法合规，不得包含仇恨言论、暴力内容或商业广告。'),
        const SizedBox(height: 16),
        _buildTermsSection('4. 免责声明', '平台上的内容代表用户个人观点，不构成专业信仰指导。'),
      ]))),
    ]),
  );
}

Widget _buildTermsSection(String title, String content) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.hoverBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDefault)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
    ]),
  );
}

// ─── VIP Page ───
Widget _buildVip() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Column(children: [
      _buildGlassHeader('会员中心'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // VIP banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradientWithOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.auroraBlue.withOpacity(0.3)),
          ),
          child: Column(children: [
            Container(
              width: 64, height: 64,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgColor),
                child: const Center(child: Icon(Icons.workspace_premium, color: AppColors.auroraYellow, size: 32)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('OpenFaith VIP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('解锁更多专属功能与特权', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity, height: 44,
              decoration: BoxDecoration(gradient: AppColors.auroraGradient, borderRadius: BorderRadius.circular(22)),
              child: const Center(child: Text('开通 VIP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        // Benefits
        _buildVipBenefit(Icons.star, '专属标识', '显示独特的 VIP 标识'),
        const SizedBox(height: 12),
        _buildVipBenefit(Icons.flash_on, '加热卡', '每月赠送加热卡，提升曝光'),
        const SizedBox(height: 12),
        _buildVipBenefit(Icons.block, '无广告', '享受无广告的纯净体验'),
        const SizedBox(height: 12),
        _buildVipBenefit(Icons.support_agent, '优先支持', '优先获得客服支持'),
      ]))),
    ]),
  );
}

Widget _buildVipBenefit(IconData icon, String title, String desc) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.auroraBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.auroraBlue, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ])),
      const Icon(Icons.check_circle, color: AppColors.auroraGreen, size: 20),
    ]),
  );
}
