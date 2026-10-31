import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/settings/appearance_preferences.dart';
import 'package:flit/services/adb_connection_method.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'appearance changes preserve saved device and pairing preferences',
    () async {
      final home = await Directory.systemTemp.createTemp('flit-preferences-');
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
          adbConnectionMethod: AdbConnectionMethod.usb,
          adbPairingRevision: 12345,
          runDevice: '192.168.1.8:32100',
        );
        await preferences.update(
          editor: 16,
          theme: 'light',
          terminal: 22,
          terminalFont: 'monospace',
          terminalLineHeight: 1.6,
        );
        final data = jsonDecode(
          await File('${home.path}/.flit/appearance.json').readAsString(),
        );
        expect(data['adbHost'], '192.168.1.8');
        expect(data['adbPaired'], true);
        expect(data['adbConnectionMethod'], 'usb');
        expect(data['adbPairingRevision'], 12345);
        expect(data['runDevice'], '192.168.1.8:32100');
        await reloaded.load();
        expect(reloaded.editorSize, 16);
        expect(reloaded.terminalSize, 22);
        expect(reloaded.terminalFont, 'monospace');
        expect(reloaded.terminalLineHeight, 1.6);
        expect(reloaded.adbHost, '192.168.1.8');
        expect(reloaded.adbPaired, true);
        expect(reloaded.adbConnectionMethod, AdbConnectionMethod.usb);
        expect(reloaded.adbPairingRevision, 12345);
        expect(reloaded.runDevice, '192.168.1.8:32100');
        await reloaded.update(
          adbPaired: false,
          runDevice: '',
          terminal: 100,
          terminalLineHeight: .1,
          terminalFont: 'unavailable',
        );
        expect(reloaded.terminalSize, AppearancePreferences.terminalMaxSize);
        expect(reloaded.terminalLineHeight, 1);
        expect(reloaded.terminalFont, 'JetBrainsMono');
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
