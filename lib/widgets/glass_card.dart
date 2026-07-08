import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'rainbow_border.dart';

/// 玻璃卡片 - 带七彩渐变边框的容器
///
/// 外层彩虹边框，内部暗色背景，支持点击回调。
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.opacity = 0.5,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: RainbowBorder(
          borderRadius: borderRadius,
          borderWidth: borderWidth,
          opacity: opacity,
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              color: AppColors.cardBg,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
