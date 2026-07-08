import 'package:flutter/material.dart';

/// OpenFaith 设计系统 - 颜色常量
/// 从网页版 rainbow.ts 提取，保证 Flutter 与网页版视觉一致
class AppColors {
  AppColors._();

  // ===== 背景色 =====
  static const Color bgColor = Color(0xFF050816);
  static const Color background = bgColor; // 兼容旧引用
  static const Color cardBg = Color(0x0AFFFFFF);      // 4% white
  static const Color cardBgHover = Color(0x14FFFFFF);  // 8% white
  static const Color scaffoldBg = Color(0xFF050816);

  // ===== 边框色 =====
  static const Color borderDefault = Color(0x14FFFFFF); // 8% white
  static const Color border = borderDefault;             // 兼容
  static const Color borderColor = Color(0x14FFFFFF);    // 8% white（对齐网页版 --border-color）
  static const Color borderWeak = Color(0x0FFFFFFF);    // 6% white
  static const Color divider = Color(0x14FFFFFF);

  // ===== 文字色 =====
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0x80FFFFFF); // 50% white
  static const Color textTertiary = Color(0x40FFFFFF);  // 25% white
  static const Color textHint = Color(0x40FFFFFF);
  static const Color textMuted = Color(0x59FFFFFF);     // 兼容旧引用

  // ===== 七彩 Aurora 色（网页版 AURORA_COLORS） =====
  static const Color auroraRed = Color(0xFFFF4D6D);
  static const Color auroraOrange = Color(0xFFFF9F1C);
  static const Color auroraYellow = Color(0xFFFFD60A);
  static const Color auroraGreen = Color(0xFF70E000);
  static const Color auroraCyan = Color(0xFF00E5FF);
  static const Color auroraBlue = Color(0xFF3A86FF);
  static const Color auroraPurple = Color(0xFF9D4EDD);

  // 短名兼容
  static const Color red = auroraRed;
  static const Color orange = auroraOrange;
  static const Color yellow = auroraYellow;
  static const Color green = auroraGreen;
  static const Color cyan = auroraCyan;
  static const Color blue = auroraBlue;
  static const Color purple = auroraPurple;

  /// 七彩颜色列表
  static const List<Color> auroraColors = [
    auroraRed,
    auroraOrange,
    auroraYellow,
    auroraGreen,
    auroraCyan,
    auroraBlue,
    auroraPurple,
  ];

  /// 兼容旧字段名
  static const List<Color> rainbowColors = auroraColors;

  /// 七彩线性渐变（135度 = begin:topLeft, end:bottomRight）
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: auroraColors,
  );

  /// 指定透明度的七彩渐变
  static LinearGradient auroraGradientWithOpacity(double opacity) {
    final o = opacity.clamp(0.0, 1.0);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: auroraColors.map((c) => c.withOpacity(o)).toList(),
    );
  }

  /// 指定透明度的颜色列表
  static List<Color> auroraColorsWithOpacity(double opacity) {
    return auroraColors.map((c) => c.withOpacity(opacity)).toList();
  }

  // ===== 功能色 =====
  static const Color error = Color(0xFFFF4D6D);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFD60A);
  static const Color info = Color(0xFF00E5FF);
  static const Color accentRed = Color(0xFFFF4D6D);

  // ===== 遮罩/背景 =====
  static const Color overlay = Color(0x80000000);        // 50% black
  static const Color navBg = Color(0xF7050816);          // 97% opacity of bgColor
  static const Color inputBg = Color(0x0AFFFFFF);        // 4% white

  // ===== 彩虹起止色（兼容旧引用） =====
  static const Color rainbowStart = auroraRed;
  static const Color rainbowEnd = auroraPurple;
  static const Color rainbowMid = auroraGreen;

  // ===== 消息气泡 =====
  static const Color myMessage = Color(0xFF1A1F36);
  static const Color otherMessage = Color(0xFF161B22);
}
