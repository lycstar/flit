import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_zh.dart';

AppLocalizations strings = AppLocalizationsZh();

extension LocalizedContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this) ?? _fallbackStrings;
}

AppLocalizations get _fallbackStrings => strings;

Locale resolveAppLocale(String language, List<Locale> systemLocales) {
  if (language == 'zh' || language == 'en') return Locale(language);
  for (final locale in systemLocales) {
    if (locale.languageCode == 'zh' || locale.languageCode == 'en') {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('en');
}
