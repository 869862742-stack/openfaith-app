import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openfaith_app/i18n/app_localizations.dart';
import 'package:openfaith_app/theme/app_theme.dart';

/// Standard iPhone 14 screen size for golden tests
const kGoldenSize = Size(393, 852);

bool _initialized = false;

/// Mock platform channels that are not available in test environment
void _mockPlatformChannels() {
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  // Mock app_links MethodChannel (v2.x uses /messages suffix)
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.app_links/messages'),
    (MethodCall call) async {
      if (call.method == 'getInitialLink') return null;
      if (call.method == 'getInitialLinkString') return null;
      return null;
    },
  );

  // Also mock legacy channel name in case older version is used
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.app_links'),
    (MethodCall call) async => null,
  );

  // Mock app_links EventChannel
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.app_links/events'),
    (MethodCall call) async {
      if (call.method == 'listen') return null;
      if (call.method == 'cancel') return null;
      return null;
    },
  );
}

/// Load Chinese font from assets for proper CJK rendering in tests
Future<void> _loadChineseFont() async {
  try {
    final fontData = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
    final fontLoader = FontLoader('NotoSansSC');
    fontLoader.addFont(Future.value(fontData));
    await fontLoader.load();
    debugPrint('[TestHelper] NotoSansSC font loaded successfully');
  } catch (e) {
    debugPrint('[TestHelper] Failed to load NotoSansSC font: $e');
  }
}

/// Helper to copy a TextStyle with a different fontFamily
TextStyle _withFont(TextStyle? style, String fontFamily) {
  return (style ?? const TextStyle()).copyWith(fontFamily: fontFamily);
}

/// Initialize test dependencies (Supabase, SharedPreferences, plugin mocks, fonts)
Future<void> initTestDependencies() async {
  if (_initialized) return;

  _mockPlatformChannels();
  await _loadChineseFont();

  SharedPreferences.setMockInitialValues({});

  try {
    await Supabase.initialize(
      url: 'https://rdhwmeittgdosmkxtpak.supabase.co',
      publishableKey: 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe',
    );
  } catch (_) {}

  _initialized = true;
}

/// Wrap a page widget for golden testing with 393×852 constraint
/// Uses NotoSansSC font family for proper CJK rendering
Widget wrapForGoldenTest(Widget child, {Locale locale = const Locale('zh')}) {
  final baseTheme = AppTheme.darkTheme;

  // Override font family to use NotoSansSC for CJK text rendering in tests
  const String font = 'NotoSansSC';
  final tt = baseTheme.textTheme;
  final testTheme = baseTheme.copyWith(
    textTheme: tt.copyWith(
      displayLarge: _withFont(tt.displayLarge, font),
      headlineMedium: _withFont(tt.headlineMedium, font),
      titleLarge: _withFont(tt.titleLarge, font),
      titleMedium: _withFont(tt.titleMedium, font),
      bodyLarge: _withFont(tt.bodyLarge, font),
      bodyMedium: _withFont(tt.bodyMedium, font),
      bodySmall: _withFont(tt.bodySmall, font),
      labelLarge: _withFont(tt.labelLarge, font),
    ),
    appBarTheme: baseTheme.appBarTheme.copyWith(
      titleTextStyle: _withFont(baseTheme.appBarTheme.titleTextStyle, font),
    ),
    bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
      selectedLabelStyle: _withFont(baseTheme.bottomNavigationBarTheme.selectedLabelStyle, font),
      unselectedLabelStyle: _withFont(baseTheme.bottomNavigationBarTheme.unselectedLabelStyle, font),
    ),
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      hintStyle: _withFont(baseTheme.inputDecorationTheme.hintStyle, font),
    ),
    dialogTheme: baseTheme.dialogTheme.copyWith(
      titleTextStyle: _withFont(baseTheme.dialogTheme.titleTextStyle, font),
      contentTextStyle: _withFont(baseTheme.dialogTheme.contentTextStyle, font),
    ),
    snackBarTheme: baseTheme.snackBarTheme.copyWith(
      contentTextStyle: _withFont(baseTheme.snackBarTheme.contentTextStyle, font),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      labelStyle: _withFont(baseTheme.chipTheme.labelStyle, font),
    ),
  );

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: testTheme,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: SizedBox(
      width: kGoldenSize.width,
      height: kGoldenSize.height,
      child: ClipRect(child: child),
    ),
  );
}
