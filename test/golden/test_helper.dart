import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openfaith_app/i18n/app_localizations.dart';
import 'package:openfaith_app/theme/app_theme.dart';

/// Standard iPhone 14 screen size for golden tests
const kGoldenSize = Size(393, 852);

bool _initialized = false;

/// Initialize test dependencies (Supabase, SharedPreferences)
/// Call this in setUpAll()
Future<void> initTestDependencies() async {
  if (_initialized) return;

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  // Initialize Supabase with real project config
  // Uses try-catch in case it's already initialized in this isolate
  try {
    await Supabase.initialize(
      url: 'https://rdhwmeittgdosmkxtpak.supabase.co',
      publishableKey: 'sb_publishable_Sch6yDRuc1N0w7M61-U29A_ZP0J-9xe',
    );
  } catch (_) {
    // Already initialized - ignore
  }

  _initialized = true;
}

/// Wrap a page widget for golden testing with 393×852 constraint
Widget wrapForGoldenTest(Widget child, {Locale locale = const Locale('zh')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
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
