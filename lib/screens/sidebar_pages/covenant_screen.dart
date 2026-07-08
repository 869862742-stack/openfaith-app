import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// 信仰公约页 - 对齐网页版 Covenant.tsx
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('信仰公约', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部介绍卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 盾牌图标 - 七彩渐变边框
                      Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: AppColors.rainbowColors,
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: AppColors.background,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OpenFaith 信仰公约', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('尊重 · 包容 · 和平', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '我们致力于创建一个尊重、包容、和平的全球信仰交流社区，让每一位探索者都能在这里找到心灵的归属。',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 公约条目
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 序号 - 七彩渐变边框
                    Container(
                      width: 32, height: 32,
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: AppColors.rainbowColors,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: AppColors.background,
                        ),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(item['content']!, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
                      ],
                    )),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // 底部签署区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: AppColors.rainbowColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppColors.background,
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF70E000), size: 32),
                    SizedBox(height: 8),
                    Text('我已阅读并同意遵守以上公约', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('使用 OpenFaith 即表示您同意遵守以上公约条款', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
