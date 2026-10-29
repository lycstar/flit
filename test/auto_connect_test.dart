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

  setUp(() async {
    prefs.adbConnectPort = '';
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
    String initialDevices = '',
    String onlinePort = '',
    String connectOutput = '',
    List<DiscoveredAdb> discovered = const [],
  }) async {
    final commands = <String>[];
    var connectedPort = '';
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
                  connectedPort.isNotEmpty && connectedPort == onlinePort;
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
              process.emit(connectOutput);
            }
            unawaited(process.finish(0));
            return process;
          },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/device'),
      (call) async => [
        for (final d in discovered) {'host': d.host, 'port': d.port},
      ],
    );
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
}
