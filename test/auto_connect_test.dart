import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/device/device_connection.dart';
import 'package:flit/features/settings/appearance_preferences.dart';
import 'package:flit/features/terminal/console_session.dart';
import 'package:flit_device/flit_device.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final prefs = AppearancePreferences();
  var discoveries = 0;

  setUp(() async {
    discoveries = 0;
    prefs.adbConnectPort = '';
    prefs.adbHost = '127.0.0.1';
    prefs.adbPaired = false;
    // 无家目录: 偏好保持内存值, 不落盘
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      if (call.method == 'bootstrapStatus') return {'home': '', 'prefix': ''};
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/device'),
      null,
    );
  });

  /// 驱动 autoConnectAdb: devices 输出按"是否已 connect 过"变化, NSD 由 mock 供给
  Future<(AdbAutoResult, List<String>)> runAuto({
    String initialDevices = 'List of devices attached\n',
    String onlinePort = '',
    String connectOutput = '',
    List<DiscoveredAdb> discovered = const [],
    int onlineDelay = 0,
    bool discoveryFails = false,
  }) async {
    final commands = <String>[];
    var connectedPort = '';
    var verificationReads = 0;
    final console = ConsoleSession(
      title: '自动连接',
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async {
            final cmd = command ?? '';
            commands.add(cmd);
            final process = FakeProcess();
            if (cmd.contains('adb devices')) {
              // 连错端口(已下线的旧端口)不会让设备上线
              final online =
                  connectedPort.isNotEmpty &&
                  connectedPort == onlinePort &&
                  verificationReads++ >= onlineDelay;
              process.emit(
                online
                    ? 'List of devices attached\n127.0.0.1:$onlinePort\tdevice\n'
                    : initialDevices,
              );
            }
            final connect = RegExp(
              r'adb connect 127\.0\.0\.1:(\d+)',
            ).firstMatch(cmd);
            if (connect != null) {
              connectedPort = connect.group(1)!;
              process.emit(
                connectOutput.isNotEmpty
                    ? connectOutput
                    : connectedPort == onlinePort
                    ? 'connected to 127.0.0.1:$connectedPort'
                    : 'cannot connect: Connection refused',
              );
            }
            unawaited(process.finish(0));
            return process;
          },
    );
    messenger.setMockMethodCallHandler(const MethodChannel('flit/device'), (
      call,
    ) async {
      discoveries++;
      if (discoveryFails) {
        throw PlatformException(code: 'nsd', message: 'NSD failed');
      }
      return [
        for (final d in discovered) {'host': d.host, 'port': d.port},
      ];
    });
    final result = await autoConnectAdb(console: console, preferences: prefs);
    await console.close();
    return (result, commands);
  }

  test(
    'last successful port is tried first and persisted on success',
    () async {
      prefs.adbConnectPort = '43721';
      final (result, commands) = await runAuto(
        onlinePort: '43721',
        connectOutput: 'connected to 127.0.0.1:43721\n',
      );
      expect(result, AdbAutoResult.connected);
      expect(commands, [
        'adb devices',
        'adb connect 127.0.0.1:43721',
        'adb devices',
      ]);
      expect(discoveries, 0);
      expect(prefs.adbConnectPort, '43721');
      expect(prefs.adbPaired, true);
    },
  );

  test('failed authentication reports needsPairing', () async {
    prefs.adbConnectPort = '43721';
    final (result, commands) = await runAuto(
      connectOutput: 'failed to authenticate to 127.0.0.1:43721',
      onlinePort: '43721',
    );
    expect(result, AdbAutoResult.needsPairing);
    expect(commands, hasLength(2)); // 停止尝试, 不再探测
  });

  test('nothing advertised means wireless debugging is off', () async {
    final (result, commands) = await runAuto();
    expect(result, AdbAutoResult.unavailable);
    expect(commands, ['adb devices']);
    expect(prefs.adbPaired, false);
  });

  test('discovered port is used when the last port no longer works', () async {
    prefs.adbConnectPort = '11111';
    final (result, commands) = await runAuto(
      discovered: [const DiscoveredAdb(host: '192.168.1.8', port: '43721')],
      onlinePort: '43721',
    );
    expect(result, AdbAutoResult.connected);
    expect(commands, [
      'adb devices',
      'adb connect 127.0.0.1:11111', // 旧端口先试, 失败
      'adb devices',
      'adb connect 127.0.0.1:43721', // NSD 发现的新端口
      'adb devices',
    ]);
    expect(prefs.adbConnectPort, '43721');
  });
  test(
    'other LAN and USB devices never count as a successful local connection',
    () async {
      final (result, _) = await runAuto(
        initialDevices:
            'List of devices attached\n192.168.1.8:43210\tdevice\nusb123\tdevice\n',
      );
      expect(result, AdbAutoResult.unavailable);
      expect(discoveries, 1);
    },
  );

  test('remote cached port is not reused on localhost', () async {
    prefs.adbHost = '192.168.1.8';
    prefs.adbConnectPort = '43210';
    final (result, commands) = await runAuto();
    expect(result, AdbAutoResult.unavailable);
    expect(commands, ['adb devices']);
  });

  test(
    'connection waits for exact target online and handles space-separated adb output',
    () async {
      final (result, _) = await runAuto(
        discovered: [const DiscoveredAdb(host: '127.0.0.1', port: '43210')],
        onlinePort: '43210',
        onlineDelay: 1,
        initialDevices: 'List of devices attached\n192.168.1.8:43210 device\n',
      );
      expect(result, AdbAutoResult.connected);
    },
  );

  test('advertised but refused is not misreported as needs pairing', () async {
    final (result, _) = await runAuto(
      discovered: [const DiscoveredAdb(host: '127.0.0.1', port: '43210')],
    );
    expect(result, AdbAutoResult.failed);
  });

  test('NSD failure is distinct from no advertisements', () async {
    final (result, _) = await runAuto(discoveryFails: true);
    expect(result, AdbAutoResult.failed);
  });

  test(
    'closing console during discovery prevents subsequent connect commands',
    () async {
      final pending = Completer<List<Map<String, Object>>>();
      final entered = Completer<void>();
      messenger.setMockMethodCallHandler(const MethodChannel('flit/device'), (
        call,
      ) {
        entered.complete();
        return pending.future;
      });
      final commands = <String>[];
      final console = ConsoleSession(
        title: 'scan',
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async {
              commands.add(command!);
              final process = FakeProcess()..emit('List of devices attached\n');
              unawaited(process.finish());
              return process;
            },
      );
      final result = autoConnectAdb(console: console, preferences: prefs);
      await entered.future;
      await console.close();
      pending.complete([
        {'host': '127.0.0.1', 'port': 43210},
      ]);
      expect(await result, AdbAutoResult.unavailable);
      expect(commands, ['adb devices']);
    },
  );
}
