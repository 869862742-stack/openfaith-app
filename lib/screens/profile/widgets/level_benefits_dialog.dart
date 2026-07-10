import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// 等级名称映射（10级）
const Map<int, String> kLevelNames = {
  1: '探索者', 2: '追寻者', 3: '思辨者', 4: '笃行者', 5: '融通者',
  6: '守望者', 7: '觉悟者', 8: '至诚者', 9: '明达者', 10: '光明者',
};

/// 等级阈值配置
const List<int> kLevelThresholds = [
  0, 1000, 5000, 25000, 125000, 250000, 500000, 1000000, 2000000, 5000000,
];

/// 等级权益配置
const Map<int, Map<String, dynamic>> kLevelBenefits = {
  1: {'groups': 0, 'monthly_hot': 0, 'exposure_hours': 0, 'features': ['基础功能']},
  2: {'groups': 1, 'monthly_hot': 0, 'exposure_hours': 0, 'features': ['可创建1个群聊']},
  3: {'groups': 1, 'monthly_hot': 0, 'exposure_hours': 2, 'features': ['曝光2小时（任选1篇）']},
  4: {'groups': 2, 'monthly_hot': 0, 'exposure_hours': 0, 'features': ['可创建2个群聊']},
  5: {'groups': 2, 'monthly_hot': 100, 'exposure_hours': 0, 'features': ['每月1日获得100热点']},
  6: {'groups': 3, 'monthly_hot': 0, 'exposure_hours': 0, 'features': ['编辑资料无限制']},
  7: {'groups': 3, 'monthly_hot': 200, 'exposure_hours': 0, 'features': ['每月1日获得200热点']},
  8: {'groups': 4, 'monthly_hot': 0, 'exposure_hours': 24, 'features': ['曝光24小时（任选1篇）']},
  9: {'groups': 5, 'monthly_hot': 300, 'exposure_hours': 0, 'features': ['每月1日获得300热点']},
  10: {'groups': 999, 'monthly_hot': 0, 'exposure_hours': 0, 'features': ['全部功能不受限制', '永久会员权益']},
};

/// 根据经验值计算等级
int calculateLevel(int experience) {
  for (int i = kLevelThresholds.length - 1; i >= 0; i--) {
    if (experience >= kLevelThresholds[i]) {
      return i + 1;
    }
  }
  return 1;
}

/// 计算升级进度百分比
double calculateLevelProgress(int experience, int level) {
  if (level >= 10) return 100.0;
  final currentThreshold = kLevelThresholds[level - 1];
  final nextThreshold = kLevelThresholds[level];
  final expInLevel = experience - currentThreshold;
  final expNeeded = nextThreshold - currentThreshold;
  if (expNeeded <= 0) return 100.0;
  return (expInLevel / expNeeded * 100).clamp(0.0, 100.0);
}

/// 等级权益弹窗
class LevelBenefitsDialog extends StatelessWidget {
  final int currentLevel;
  final int experience;
  final bool isVip;

  const LevelBenefitsDialog({
    super.key,
    required this.currentLevel,
    required this.experience,
    this.isVip = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = calculateLevelProgress(experience, currentLevel);
    final nextThreshold = currentLevel < 10
        ? kLevelThresholds[currentLevel]
        : kLevelThresholds[9];
    final expNeeded = nextThreshold - experience;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.auroraRed, AppColors.auroraPurple]),
                        ),
                        child: Text('LV.$currentLevel',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Text(kLevelNames[currentLevel] ?? '探索者',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                      ),
                    ],
                  ),
                ),
                // 内容
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 当前等级权益
                        Text('当前等级特权',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        _buildBenefitRow(currentLevel),
                        const SizedBox(height: 16),
                        // 升级进度
                        if (currentLevel < 10) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('还需 ${_formatExp(expNeeded)} 经验升级',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    Text('$experience / $nextThreshold',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: AppColors.borderColor,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.auroraBlue),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('升到 LV.${currentLevel + 1} ${kLevelNames[currentLevel + 1] ?? ""} 解锁',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          _buildNextLevelBenefitRow(currentLevel + 1),
                        ],
                        // VIP 专属特权
                        if (isVip) ...[
                          const SizedBox(height: 16),
                          Container(height: 0.5, color: AppColors.borderColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Icon(Icons.workspace_premium, color: AppColors.textMuted, size: 16),
                            const SizedBox(width: 6),
                            Text('VIP 专属特权', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 10),
                          _buildVipBenefits(),
                        ],
                        // 全部等级列表
                        const SizedBox(height: 20),
                        Container(height: 0.5, color: AppColors.borderColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('全部等级', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        ...List.generate(10, (i) {
                          final lvl = i + 1;
                          final isCurrent = lvl == currentLevel;
                          final isPassed = lvl < currentLevel;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.auroraRed.withOpacity(0.1) : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrent ? Border.all(color: AppColors.auroraRed.withOpacity(0.3)) : null,
                            ),
                            child: Row(children: [
                              Container(
                                width: 20, height: 20, alignment: Alignment.center,
                                child: isPassed
                                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                                    : Text('$lvl', style: TextStyle(
                                        color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                                        fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                              ),
                              const SizedBox(width: 10),
                              Text(kLevelNames[lvl] ?? '', style: TextStyle(
                                  color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 13, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal)),
                              const Spacer(),
                              Text('${kLevelThresholds[i]}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ]),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(int level) {
    final benefit = kLevelBenefits[level] ?? {};
    final groups = benefit['groups'] as int? ?? 0;
    final monthlyHot = benefit['monthly_hot'] as int? ?? 0;
    final exposureHours = benefit['exposure_hours'] as int? ?? 0;
    final features = (benefit['features'] as List?)?.cast<String>() ?? [];
    return Wrap(spacing: 12, runSpacing: 8, children: [
      _benefitChip(Icons.group, '${groups == 999 ? "∞" : groups} 个群聊'),
      if (monthlyHot > 0) _benefitChip(Icons.bolt, '每月+$monthlyHot 热点'),
      if (exposureHours > 0) _benefitChip(Icons.visibility, '曝光${exposureHours}小时'),
      ...features.map((f) => _benefitChip(Icons.star, f)),
    ]);
  }

  Widget _buildNextLevelBenefitRow(int level) {
    final benefit = kLevelBenefits[level] ?? {};
    final features = (benefit['features'] as List?)?.cast<String>() ?? [];
    return Wrap(spacing: 8, runSpacing: 6, children: features.map((f) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.auroraRed.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text('+ $f', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    )).toList());
  }

  Widget _buildVipBenefits() {
    final items = [
      [Icons.bolt, '经验 ×2'],
      [Icons.star, '动态头像'],
      [Icons.palette, '自定义主题'],
      [Icons.download, '离线下载'],
      [Icons.visibility, '曝光特权'],
      [Icons.arrow_upward, '置顶卡'],
    ];
    return Wrap(spacing: 16, runSpacing: 10, children: items.map((item) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item[0] as IconData, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(item[1] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    )).toList());
  }

  Widget _benefitChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  String _formatExp(int exp) {
    if (exp >= 1000000) return '${(exp / 1000000).toStringAsFixed(1)}M';
    if (exp >= 1000) return '${(exp / 1000).toStringAsFixed(1)}K';
    return '$exp';
  }
}
