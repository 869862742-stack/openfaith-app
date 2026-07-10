import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CovenantScreen extends StatelessWidget {
  const CovenantScreen({super.key});

  static const _items = [
    {'title': '平等与尊重', 'content': '每一个灵魂都值得被听见。我们尊重所有信仰传统、灵性探索及无神论立场。严禁任何形式的歧视、仇恨言论或宗教排他性攻击。'},
    {'title': '和平与理性', 'content': '分享您的见解而非强加您的观点。我们鼓励建设性的对话，反对任何形式的网络暴力、恶意抹黑或挑衅行为。'},
    {'title': '真实与纯净', 'content': '严禁传播邪教思想、极端主义信息、暴力违禁内容或商业欺诈。OpenFaith 是心灵成长的净土，拒绝任何噪音。'},
    {'title': '安全与边界', 'content': '尊重他人的数字足迹。严禁泄露他人真实身份信息，保持适当的社交距离，构建安全的连接。'},
    {'title': '共筑安心家园', 'content': '为守护这片净土，平台将根据违规情节的轻重，对违反公约的行为采取相应管理措施，包括但不限于内容删除、功能限制、暂停或终止账号使用。'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(onBack: () => Navigator.pop(context)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top intro card
                  _buildIntroCard(),
                  const SizedBox(height: 24),
                  // Covenant items
                  ...List.generate(_items.length, (i) {
                    final item = _items[i];
                    return _buildCovenantItem(i + 1, item['title']!, item['content']!);
                  }),
                  const SizedBox(height: 24),
                  // Bottom tag
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBgLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, color: AppColors.textPrimary, size: 16),
                          SizedBox(width: 8),
                          Text('共同维护社区环境', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Shield icon with rainbow gradient border
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.auroraColors,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.5),
                    color: AppColors.background,
                  ),
                  child: const Center(child: Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OpenFaith 信仰公约', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('尊重 · 包容 · 和平', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '我们致力于创建一个尊重、包容、和平的全球信仰交流社区，让每一位探索者都能在这里找到心灵的归属。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCovenantItem(int index, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hoverBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number with rainbow gradient border
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.auroraColors,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.5),
                color: AppColors.background,
              ),
              child: Center(
                child: Text('$index', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onBack;

  _SliverAppBarDelegate({required this.onBack});

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.headerBg,
            border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              const Text('信仰公约', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
