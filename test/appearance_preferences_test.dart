import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/settings/appearance_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'appearance changes preserve saved device and pairing preferences',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'flit-preferences-',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
        call,
      ) async {
        if (call.method == 'bootstrapStatus') return {'home': home.path};
        return null;
      });
      final preferences = AppearancePreferences();
      final reloaded = AppearancePreferences();
      try {
        await preferences.update(
          adbHost: '192.168.1.8',
          adbPaired: true,
          runDevice: '192.168.1.8:32100',
        );
        await preferences.update(editor: 16, theme: 'light');
        final data = jsonDecode(
          await File('${home.path}/.flit/appearance.json').readAsString(),
        );
        expect(data['adbHost'], '192.168.1.8');
        expect(data['adbPaired'], true);
        expect(data['runDevice'], '192.168.1.8:32100');
        await reloaded.load();
        expect(reloaded.editorSize, 16);
        expect(reloaded.adbHost, '192.168.1.8');
        expect(reloaded.adbPaired, true);
        expect(reloaded.runDevice, '192.168.1.8:32100');
        await reloaded.update(adbPaired: false, runDevice: '');
        expect(
          jsonDecode(
            await File('${home.path}/.flit/appearance.json').readAsString(),
          )['adbPaired'],
          false,
        );
      } finally {
        preferences.dispose();
        reloaded.dispose();
        messenger.setMockMethodCallHandler(
          const MethodChannel('flit/env'),
          null,
        );
        await home.delete(recursive: true);
      }
    },
  );
}
