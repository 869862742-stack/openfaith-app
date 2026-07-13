import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 极光渐变按钮
class AuroraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double borderRadius;
  final double borderWidth;
  final double opacity;

  const AuroraButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.borderRadius = 12.0,
    this.borderWidth = 1.0,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        // 外层：渐变边框
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(borderRadius),

          border: Border.all(color: AppColors.rainbowEnd, width: 1),

        ),
        child: Container(
          // 内层：实色 #050816
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                ShaderMask(
                  shaderCallback: (rect) => AppColors.auroraGradient.createShader(rect),
                  child: Icon(icon, color: AppColors.textPrimary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              ShaderMask(
                shaderCallback: (rect) => AppColors.auroraGradient.createShader(rect),
                child: Text(
                  text,
                  style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 填充式极光按钮（实色渐变背景）
class AuroraButtonFilled extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double borderRadius;

  const AuroraButtonFilled({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(borderRadius),

          border: Border.all(color: AppColors.rainbowEnd, width: 1),

        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              text,
              style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
