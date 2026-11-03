import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/projects/workbench_page.dart';
import 'services/auto_proxy.dart';
import 'features/settings/appearance_preferences.dart';
import 'l10n/app_localizations.dart';
import 'l10n/strings.dart';

class FlitApp extends StatefulWidget {
  const FlitApp({super.key});

  @override
  State<FlitApp> createState() => _FlitAppState();
}

class _FlitAppState extends State<FlitApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回前台重探一次系统代理(覆盖无回调路径), 有变化自动应用
    if (state == AppLifecycleState.resumed) {
      context.read<AutoProxy>().load();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppearancePreferences>().language;
    final locale = resolveAppLocale(
      language,
      WidgetsBinding.instance.platformDispatcher.locales,
    );
    strings = lookupAppLocalizations(locale);
    return MaterialApp(
      title: 'Flit',
      locale: language == 'system' ? null : locale,
      localeListResolutionCallback: (locales, supported) =>
          resolveAppLocale(language, locales ?? const []),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [context.read<RouteObserver<PageRoute<dynamic>>>()],
      theme: flitTheme(),
      home: const WorkbenchPage(),
    );
  }
}
