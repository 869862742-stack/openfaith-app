// 向后兼容：七彩组件已迁移到 widgets/ 目录
// RainbowBorder -> widgets/rainbow_border.dart
// RainbowBorderContainer -> widgets/glass_card.dart (GlassCard)
export '../widgets/rainbow_border.dart';
import '../widgets/glass_card.dart';
export '../widgets/glass_card.dart';

// 旧类名兼容
import 'package:flutter/material.dart';
import '../widgets/rainbow_border.dart';

/// @deprecated 使用 GlassCard 代替
class RainbowBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const RainbowBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: borderRadius,
      padding: padding,
      child: child,
    );
  }
}
