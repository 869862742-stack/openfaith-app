import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 极光图标按钮 - 选中时七彩渐变，未选中时半透明白
/// 对应网页版 BottomNav 的 NavIcon 效果
class AuroraIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final double size;
  final String? label;
  final int? badgeCount;

  const AuroraIconButton({
    super.key,
    required this.icon,
    required this.isActive,
    this.onTap,
    this.size = 24.0,
    this.label,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 图标
                isActive
                    ? ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.auroraGradient.createShader(rect),
                        child: Icon(icon, color: Colors.white, size: size),
                      )
                    : Icon(icon, color: AppColors.textSecondary, size: size),

                // 角标
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.auroraRed, Color(0xFFFF6B6B)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount! > 99 ? '99+' : '${badgeCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 圆形渐变边框头像容器
class AuroraAvatar extends StatelessWidget {
  final Widget child;
  final double size;
  final double borderWidth;

  const AuroraAvatar({
    super.key,
    required this.child,
    this.size = 48.0,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 外层渐变
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.auroraGradientWithOpacity(0.6),
      ),
      child: Container(
        // 内层实色
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgColor,
        ),
        padding: EdgeInsets.all(2),
        child: SizedBox(
          width: size - borderWidth * 2 - 4,
          height: size - borderWidth * 2 - 4,
          child: child,
        ),
      ),
    );
  }
}
