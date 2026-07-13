import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 七彩渐变边框组件
///
/// 核心实现原理（对应网页版 padding 嵌套法）：
/// - 外层 Container：渐变背景 + 圆角
/// - Padding：控制边框宽度（默认 1px）
/// - 内层 Container：实色 #050816 背景 + 圆角（减去边框宽度）
/// - 内部放置 child
class RainbowBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  const RainbowBorder({
    super.key,
    required this.child,
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.opacity = 0.5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(borderRadius),

        border: Border.all(color: AppColors.rainbowEnd, width: 1),

      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            color: AppColors.bgColor, // 实色 #050816，铁律
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
