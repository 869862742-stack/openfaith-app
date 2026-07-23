import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'services/call_service.dart';
import 'webview/webview_shell.dart';

const supabaseUrl = 'https://rdhwmeittgdosmkxtpak.supabase.co';
const supabaseAnonKey = 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Shorebird 增量更新已通过 shorebird.yaml 的 auto_update: true 自动处理
  // 无需手动检查，启动时会自动下载并应用补丁

  // Supabase 初始化（为原生通话模块准备）
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  // Sentry 错误监控
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN_HERE';
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 1.0 : 0.5;
    },
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => CallService(),
      child: const OpenFaithApp(),
    ),
  );
}

class OpenFaithApp extends StatelessWidget {
  const OpenFaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenFaith',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050816),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          surface: Color(0xFF050816),
        ),
      ),
      home: const WebViewShell(),
    );
  }
}
