import 'package:flutter/material.dart';
import 'strings_zh.dart';
import 'strings_en.dart';

/// App localization delegate
/// Supports Chinese (zh) and English (en)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  /// Localized strings map
  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': zhStrings,
    'en': enStrings,
  };

  /// Translate key to localized string
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['zh']?[key] ??
        key;
  }

  /// Shorthand accessor
  String tr(String key) => translate(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(
      _AppLocalizationsDelegate old) =>
      false;
}

/// Extension for convenient access: context.tr('key')
extension AppLocalizationsExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).translate(key);
}
