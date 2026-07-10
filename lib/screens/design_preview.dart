import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/glass_card.dart';
import '../widgets/aurora_button.dart';
import '../widgets/aurora_icon_button.dart';
import '../widgets/rainbow_border.dart';

/// 设计系统预览页面
class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Design System'),
        backgroundColor: AppColors.bgColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 标题 =====
            ShaderMask(
              shaderCallback: (rect) => AppColors.auroraGradient.createShader(rect),
              child: const Text(
                'OpenFaith Design System',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== 颜色展示 =====
            _sectionTitle('Aurora Colors'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.auroraColors.map((color) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== 渐变展示 =====
            _sectionTitle('Aurora Gradient'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradient,
              ),
              child: const Center(
                child: Text(
                  'Aurora Gradient 135deg',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== RainbowBorder 变体 =====
            _sectionTitle('RainbowBorder'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // opacity 0.3
                RainbowBorder(
                  borderWidth: 1,
                  borderRadius: 12,
                  opacity: 0.3,
                  padding: const EdgeInsets.all(12),
                  child: const Text('opacity 0.3', style: TextStyle(color: Colors.white)),
                ),
                // opacity 0.5
                RainbowBorder(
                  borderWidth: 1,
                  borderRadius: 12,
                  opacity: 0.5,
                  padding: const EdgeInsets.all(12),
                  child: const Text('opacity 0.5', style: TextStyle(color: Colors.white)),
                ),
                // opacity 0.7
                RainbowBorder(
                  borderWidth: 2,
                  borderRadius: 12,
                  opacity: 0.7,
                  padding: const EdgeInsets.all(12),
                  child: const Text('opacity 0.7', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== GlassCard =====
            _sectionTitle('GlassCard'),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Title',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This is a glass card with rainbow border.\nBackground: #050816 with aurora gradient border.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.favorite_border, color: AppColors.auroraRed, size: 16),
                      const SizedBox(width: 4),
                      Text('128', style: AppTextStyles.caption),
                      const SizedBox(width: AppSpacing.lg),
                      Icon(Icons.comment_outlined, color: AppColors.auroraCyan, size: 16),
                      const SizedBox(width: 4),
                      Text('42', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              borderRadius: 16,
              opacity: 0.2,
              child: const Text(
                'Larger border radius card (16px)',
                style: AppTextStyles.body,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== AuroraButton =====
            _sectionTitle('AuroraButton'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AuroraButton(
                  text: 'Outlined Button',
                  onPressed: () {},
                ),
                AuroraButton(
                  text: 'With Icon',
                  icon: Icons.add,
                  onPressed: () {},
                ),
                AuroraButtonFilled(
                  text: 'Filled Button',
                  onPressed: () {},
                ),
                AuroraButtonFilled(
                  text: 'Send',
                  icon: Icons.send,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== AuroraIconButton =====
            _sectionTitle('AuroraIconButton'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AuroraIconButton(
                  icon: Icons.home,
                  isActive: true,
                  label: '首页',
                  onTap: () {},
                ),
                AuroraIconButton(
                  icon: Icons.explore,
                  isActive: false,
                  label: '学习',
                  onTap: () {},
                ),
                AuroraIconButton(
                  icon: Icons.notifications,
                  isActive: false,
                  label: '消息',
                  badgeCount: 5,
                  onTap: () {},
                ),
                AuroraIconButton(
                  icon: Icons.person,
                  isActive: true,
                  label: '我的',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== Typography =====
            _sectionTitle('Typography'),
            const SizedBox(height: AppSpacing.sm),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display 24px Bold', style: AppTextStyles.display),
                SizedBox(height: 4),
                Text('Headline 20px Semibold', style: AppTextStyles.headline),
                SizedBox(height: 4),
                Text('Title 16px Semibold', style: AppTextStyles.title),
                SizedBox(height: 4),
                Text('Body 14px Regular', style: AppTextStyles.body),
                SizedBox(height: 4),
                Text('Caption 12px Secondary', style: AppTextStyles.caption),
                SizedBox(height: 4),
                Text('Overline 10px', style: AppTextStyles.overline),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== Input =====
            _sectionTitle('Input'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ===== Spacing =====
            _sectionTitle('Spacing Scale'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: [
                _spacingChip('xs: 4', 4),
                _spacingChip('sm: 8', 8),
                _spacingChip('md: 12', 12),
                _spacingChip('lg: 16', 16),
                _spacingChip('xl: 20', 20),
                _spacingChip('xxl: 24', 24),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (rect) => AppColors.auroraGradient.createShader(rect),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _spacingChip(String label, double width) {
    return Container(
      width: width,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.auroraBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.auroraBlue.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
