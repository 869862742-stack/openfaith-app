import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

/// 共境页面 - 对齐网页版 Gongjing.tsx
/// 包含四大功能入口：静默同行、世界呼吸时刻、树洞回声、无界圆桌
class GongjingScreen extends StatefulWidget {
  const GongjingScreen({super.key});
  @override
  State<GongjingScreen> createState() => _GongjingScreenState();
}

class _GongjingScreenState extends State<GongjingScreen> {
  final _supabase = Supabase.instance.client;
  int _onlineCount = 0;

  // 四大模块定义
  static const _modules = <Map<String, dynamic>>[
    {
      'id': 'silent_walk',
      'title': '静默同行',
      'subtitle': '与陌生人无声相伴，在沉默中找到安宁',
      'icon_code': 'nights_stay',
      'color': Color(0xFF3A86FF),
      'desc': '选择你的状态（安静中/阅读中/反思中/冥想中/祈祷时），系统自动匹配一位同行者。无需交谈，只是安静地在一起。',
    },
    {
      'id': 'breathing',
      'title': '世界呼吸时刻',
      'subtitle': '全球同步冥想，与万千灵魂共鸣',
      'icon_code': 'air',
      'color': Color(0xFF70E000),
      'desc': '定时全球冥想活动，所有参与者同步进行呼吸练习，感受跨越时空的连接。',
    },
    {
      'id': 'echo',
      'title': '树洞回声',
      'subtitle': '匿名倾诉，温柔回应',
      'icon_code': 'chat_bubble_outline',
      'color': Color(0xFF9D4EDD),
      'desc': '匿名分享你的内心世界，用温暖的表情回应他人。不需要名字，只需要共鸣。',
    },
    {
      'id': 'roundtable',
      'title': '无界圆桌',
      'subtitle': '跨越信仰的平等对话',
      'icon_code': 'groups',
      'color': Color(0xFF00E5FF),
      'desc': '不同信仰背景的人围坐一堂，平等探讨信仰话题。每位发言者都有相同的展示空间。',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchOnline();
  }

  Future<void> _fetchOnline() async {
    try {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      final res = await _supabase.from('profiles').select('id').gte('last_online_at', fiveMinAgo);
      if (res != null) setState(() => _onlineCount = res.length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('共境', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF70E000))),
                const SizedBox(width: 4),
                Text('$_onlineCount 在线', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部介绍
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
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,colors: AppColors.rainbowColors),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: AppColors.background,
                        ),
                        child: const Icon(Icons.explore, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('共境', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('在静谧中寻找连接', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    '共境是 OpenFaith 的冥想与灵性空间。在这里，你可以与陌生人安静同行、参与全球冥想、匿名倾诉内心，或加入跨信仰的圆桌对话。',
                    style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('共境功能', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // 四大模块卡片
            ..._modules.map((m) => _buildModuleCard(m)),
            const SizedBox(height: 20),
            // 底部说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    '共境空间注重安静与尊重。无需言语，只需在场。',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> m) {
    final iconCode = m['icon_code'] as String;
    final color = m['color'] as Color;
    final iconMap = {
      'nights_stay': Icons.nights_stay,
      'air': Icons.air,
      'chat_bubble_outline': Icons.chat_bubble_outline,
      'groups': Icons.groups,
    };
    final icon = iconMap[iconCode] ?? Icons.explore;
    return GestureDetector(
      onTap: () => _openModule(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,colors: AppColors.rainbowColors),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.background,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(m['subtitle'] as String, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
                  ])),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(m['desc'] as String, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }

  void _openModule(Map<String, dynamic> m) {
    final id = m['id'] as String;
    final title = m['title'] as String;
    
    switch (id) {
      case 'silent_walk':
        _showSilentWalkDialog();
        break;
      case 'breathing':
        _showBreathingDialog();
        break;
      case 'echo':
        _showEchoDialog();
        break;
      case 'roundtable':
        _showRoundtableDialog();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title 功能开发中...'), backgroundColor: AppColors.cardBg, behavior: SnackBarBehavior.floating),
        );
    }
  }

  void _showSilentWalkDialog() {
    String? selectedStatus;
    final statuses = ['安静中', '阅读中', '反思中', '冥想中', '祈祷时'];
    final statusIcons = [Icons.nightlight, Icons.menu_book, Icons.favorite, Icons.psychology, Icons.self_improvement];
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) =>
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('静默同行', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('选择你当前的状态，系统将为你匹配同行者', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ...statuses.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final selected = selectedStatus == s;
            return GestureDetector(
              onTap: () => setDialogState(() => selectedStatus = s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF3A86FF).withOpacity(0.15) : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? const Color(0xFF3A86FF) : Colors.white.withOpacity(0.08)),
                ),
                child: Row(children: [
                  Icon(statusIcons[i], color: selected ? const Color(0xFF3A86FF) : AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Text(s, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 14)),
                ]),
              ),
            );
          }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: selectedStatus != null ? () {
              Navigator.pop(ctx);
              _startSilentWalk(selectedStatus!);
            } : null,
            child: const Text('开始同行', style: TextStyle(color: Color(0xFF3A86FF))),
          ),
        ],
      ),
    ));
  }

  void _startSilentWalk(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在以「$status」状态寻找同行者...'),
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showBreathingDialog() {
    showDialog(context: context, builder: (ctx) =>
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('世界呼吸时刻', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.air, color: Color(0xFF70E000), size: 48),
          const SizedBox(height: 12),
          const Text('下一次全球冥想时间', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('每日 21:00 (UTC+8)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('届时全球参与者将同步进行呼吸练习，感受跨越时空的连接与平静。', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了', style: TextStyle(color: Color(0xFF70E000)))),
        ],
      ),
    );
  }

  void _showEchoDialog() {
    showDialog(context: context, builder: (ctx) =>
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('树洞回声', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_outline, color: Color(0xFF9D4EDD), size: 48),
          const SizedBox(height: 12),
          const Text('匿名倾诉你的内心世界', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('在这里，你可以卸下所有身份，用最真实的声音说话。他人可以用温暖的表情回应你。', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
          const SizedBox(height: 16),
          // 反应表情
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _reactionEmoji('🤍', 'Resonated'),
            const SizedBox(width: 16),
            _reactionEmoji('🌿', 'I Understand'),
            const SizedBox(width: 16),
            _reactionEmoji('✨', 'With You'),
            const SizedBox(width: 16),
            _reactionEmoji('🌙', 'Quiet Support'),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('返回', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('树洞回声功能开发中...'), backgroundColor: AppColors.cardBg, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('进入', style: TextStyle(color: Color(0xFF9D4EDD))),
          ),
        ],
      ),
    );
  }

  Widget _reactionEmoji(String emoji, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]);
  }

  void _showRoundtableDialog() {
    showDialog(context: context, builder: (ctx) =>
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('无界圆桌', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.groups, color: Color(0xFF00E5FF), size: 48),
          const SizedBox(height: 12),
          const Text('跨越信仰的平等对话', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('不同信仰背景的人围坐一堂，平等探讨信仰话题。每位发言者都有相同的展示空间，没有等级之分。', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('VIP会员可无等级要求主持圆桌', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('返回', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('无界圆桌功能开发中...'), backgroundColor: AppColors.cardBg, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('进入', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }
}
