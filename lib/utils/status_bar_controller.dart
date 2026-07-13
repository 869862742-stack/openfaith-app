import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 状态栏控制器 - 统一管理状态栏样式和颜色
class StatusBarHelper {
  /// 设置亮色状态栏（深色背景时用）
  static void setLight({Color? statusBarColor}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  /// 设置暗色状态栏（浅色背景时用）
  static void setDark({Color? statusBarColor}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  /// 隐藏状态栏
  static void hide() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 显示状态栏
  static void show() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// 恢复默认（透明+亮色图标，适合深色主题APP）
  static void reset() {
    setLight();
  }
}
