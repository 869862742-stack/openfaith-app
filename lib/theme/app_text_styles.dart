import 'package:flutter/material.dart';
import 'app_colors.dart';

/// OpenFaith 设计系统 - 文本样式
///
/// 基于白色系文字色，尺寸与网页版一致。
class AppTextStyles {
  AppTextStyles._();

  // ── 字号常量 ──────────────────────────────────────────
  static const double _captionSize = 12;
  static const double _bodySize = 14;
  static const double _titleSize = 16;
  static const double _headlineSize = 20;
  static const double _displaySize = 24;

  // ── 样式 ──────────────────────────────────────────────

  static const TextStyle caption = TextStyle(
    fontSize: _captionSize,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle body = TextStyle(
    fontSize: _bodySize,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: _bodySize,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle title = TextStyle(
    fontSize: _titleSize,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headline = TextStyle(
    fontSize: _headlineSize,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle display = TextStyle(
    fontSize: _displaySize,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle button = TextStyle(
    fontSize: _bodySize,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
  );

  // ── 便捷方法 ──────────────────────────────────────────

  /// 获取指定颜色的 body 样式
  static TextStyle bodyWithColor(Color color) => body.copyWith(color: color);

  /// 获取带颜色的 caption
  static TextStyle captionWithColor(Color color) => caption.copyWith(color: color);
}
