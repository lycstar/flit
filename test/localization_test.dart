import 'dart:convert';
import 'dart:io';

import 'package:flit/app.dart';
import 'package:flit/core/app_scope.dart';
import 'package:flit/features/settings/appearance_preferences.dart';
import 'package:flit/features/settings/settings_page.dart';
import 'package:flit/l10n/app_localizations.dart';
import 'package:flit/l10n/app_localizations_zh.dart';
import 'package:flit/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory home;
  final nativeLanguages = <String>[];

  setUp(() async {
    home = await Directory.systemTemp.createTemp('flit-language-');
    nativeLanguages.clear();
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      if (call.method == 'bootstrapStatus') {
        return {
          'home': home.path,
          'prefix': '/does-not-exist',
          'bootstrapped': false,
        };
      }
      return {'exitCode': 0, 'output': ''};
    });
    messenger.setMockMethodCallHandler(const MethodChannel('flit/device'), (
      call,
    ) async {
      if (call.method == 'setLanguage') {
        nativeLanguages.add((call.arguments as Map)['language'] as String);
      }
      if (call.method == 'isIgnoringBatteryOptimizations') return true;
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 1,
    );
  });

  tearDown(() async {
    strings = AppLocalizationsZh();
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/device'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
    await home.delete(recursive: true);
  });

  test(
    'language resolution follows supported system locales and explicit overrides',
    () {
      expect(
        resolveAppLocale('system', [const Locale('zh', 'TW')]),
        const Locale('zh'),
      );
      expect(
        resolveAppLocale('system', [const Locale('en', 'GB')]),
        const Locale('en'),
      );
      expect(
        resolveAppLocale('system', [const Locale('ja')]),
        const Locale('en'),
      );
      expect(resolveAppLocale('system', []), const Locale('en'));
      expect(resolveAppLocale('zh', [const Locale('en')]), const Locale('zh'));
      expect(resolveAppLocale('en', [const Locale('zh')]), const Locale('en'));
    },
  );

  test('both catalogs contain the same messages and preserve placeholders', () {
    final zh =
        jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync()) as Map;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    expect(en.keys.toSet(), zh.keys.toSet());
    for (final key in zh.keys.where((key) => !key.startsWith('@'))) {
      final placeholders = RegExp(r'\{p\d+\}');
      expect(
        placeholders
            .allMatches(en[key] as String)
            .map((m) => m.group(0))
            .toSet(),
        placeholders
            .allMatches(zh[key] as String)
            .map((m) => m.group(0))
            .toSet(),
        reason: key,
      );
      expect((en[key] as String).isNotEmpty, true, reason: key);
    }
  });

  test(
    'language is persisted separately from device and editor settings',
    () async {
      final preferences = AppearancePreferences();
      expect(preferences.language, 'system');
      await preferences.update(
        adbHost: '127.0.0.1',
        adbConnectPort: '5555',
        editor: 18,
      );
      await preferences.setLanguage('en');
      final reloaded = AppearancePreferences();
      await reloaded.load();
      expect(reloaded.language, 'en');
      expect(reloaded.adbConnectPort, '5555');
      expect(reloaded.editorSize, 18);
      await reloaded.setLanguage('invalid');
      expect(reloaded.language, 'system');
      expect(nativeLanguages, containsAllInOrder(['en', 'en', 'system']));
      preferences.dispose();
      reloaded.dispose();
    },
  );

  testWidgets(
    'switch languages on an existing route without replacing services',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final preferences = AppearancePreferences()..backgroundNoticeShown = true;
      await tester.runAsync(preferences.load);
      final services = testServices(preferences: preferences);
      await tester.pumpWidget(
        AppScope(services: services, child: const FlitApp()),
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Follow System'), findsOneWidget);
      final settings = tester.state(find.byType(SettingsPage));
      final shell = services.workbenchShell;

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.items!.map((item) => item.value), ['system', 'zh', 'en']);
      await tester.runAsync(() async {
        dropdown.onChanged!('zh');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('跟随系统'), findsNothing);
      expect(tester.state(find.byType(SettingsPage)), same(settings));
      expect(services.workbenchShell, same(shell));
      expect(
        MaterialLocalizations.of(
          tester.element(find.text('设置')),
        ).copyButtonLabel,
        '复制',
      );

      await tester.runAsync(() => preferences.setLanguage('system'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('跟随系统'), findsOneWidget);
      expect(
        AppLocalizations.of(tester.element(find.text('设置')))!.localeName,
        'zh',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await shell.close();
    },
  );
}
