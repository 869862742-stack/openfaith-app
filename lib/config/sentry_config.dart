import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry 错误监控配置
class SentryConfig {
  /// Sentry DSN - 请替换为真实的 DSN
  static const String dsn = 'YOUR_SENTRY_DSN_HERE';

  /// 环境标识
  static String get environment => kReleaseMode ? 'production' : 'development';

  /// 采样率配置
  /// production 环境全量上报，development 环境半量上报
  static double get tracesSampleRate => kReleaseMode ? 1.0 : 0.5;

  /// 初始化 Sentry
  static Future<void> initSentry() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = environment;
        options.tracesSampleRate = tracesSampleRate;
        options.enableAutoSessionTracking = true;
        options.attachStacktrace = true;
        
        // 开发环境降低上报频率
        if (kReleaseMode) {
          options.sampleRate = 1.0;
        } else {
          options.sampleRate = 0.5;
        }
        
        // 不发送个人身份信息
        options.shouldSendDefaultPii = false;
      },
    );
  }
}
