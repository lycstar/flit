import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/device/device_connection.dart';
import 'package:flit/features/settings/appearance_preferences.dart';
import 'package:flit/services/adb_ops.dart';
import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late DeviceConnection connection;
  late FakeProcess process;
  var statuses = '';
  Future<Map<String, Object>> Function()? pendingRead;

  setUp(() {
    statuses = '';
    pendingRead = null;
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      if (call.method == 'bootstrapStatus') return {'home': '', 'prefix': ''};
      if (call.method == 'exec') {
        final cmd = (call.arguments as Map)['cmd'];
        if (cmd.toString().endsWith('command -v adb')) {
          return {'exitCode': 0, 'output': '/prefix/bin/adb'};
        }
        if (cmd.toString().endsWith('adb devices -l')) {
          return pendingRead != null
              ? pendingRead!()
              : {
                  'exitCode': 0,
                  'output': 'List of devices attached\n$statuses',
                };
        }
      }
      return false;
    });
    connection = DeviceConnection(
      preferences: AppearancePreferences(),
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async {
            process = FakeProcess();
            return process;
          },
    );
  });
  tearDown(() => connection.dispose());

  Future<void> finish(String output, [int code = 0]) async {
    await Future<void>.delayed(Duration.zero);
    process.emit(output);
    await process.finish(code);
  }

  test('device list retains auth states but run targets stay online only', () {
    const output =
        'List of devices attached\n127.0.0.1:1 unauthorized\n127.0.0.1:2 offline\nusb device model:Phone\n';
    expect(AdbOps.parseStatuses(output).map((d) => d.state), [
      'unauthorized',
      'offline',
      'device',
    ]);
    expect(AdbOps.parseDevices(output), [('usb', 'Phone')]);
  });

  test(
    'normalizes ports and IPv6; rejects URLs and host:port in host field',
    () {
      expect(DeviceConnection.endpoint('', '032100'), '127.0.0.1:32100');
      expect(DeviceConnection.endpoint('::1', '32100'), '[::1]:32100');
      expect(DeviceConnection.endpoint('[::1]', '32100'), '[::1]:32100');
      for (final host in [
        'https://192.168.1.2',
        '192.168.1.2:32100',
        'a b',
        '-bad',
      ]) {
        expect(
          () => DeviceConnection.endpoint(host, '1'),
          throwsFormatException,
        );
      }
    },
  );

  test('zero exit without pairing confirmation is failure', () async {
    final result = connection.pair('127.0.0.1', '31000', '123456');
    await finish('Failed: Wrong password or connection was dropped.');
    expect(await result, false);
    expect(connection.messageIsError, true);
    expect(connection.busy, false);
  });

  test('unauthorized devices are visible and stop connect polling', () async {
    statuses = '127.0.0.1:32100 unauthorized\n';
    final result = connection.connect('127.0.0.1', '32100');
    await finish('failed to authenticate to 127.0.0.1:32100');
    expect(await result, false);
    expect(connection.devices.single.label, '未授权');
    expect(connection.message, contains('设备未授权'));
  });

  test(
    'failed authentication without a transport has an authentication message',
    () async {
      final result = connection.connect('127.0.0.1', '32100');
      await finish('failed to authenticate to 127.0.0.1:32100');
      expect(await result, false);
      expect(connection.message, contains('ADB 认证失败'));
    },
  );

  test(
    'refused connections are not reported as successful or network timeout',
    () async {
      final result = connection.connect('127.0.0.1', '32100');
      await finish("cannot connect to 127.0.0.1:32100: Connection refused");
      expect(await result, false);
      expect(connection.message, contains('连接被拒绝'));
    },
  );

  test(
    'pending refresh cannot overwrite a newer connection snapshot',
    () async {
      final old = Completer<Map<String, Object>>();
      pendingRead = () => old.future;
      final refresh = connection.refresh();
      await Future<void>.delayed(Duration.zero);
      pendingRead = null;
      statuses = '127.0.0.1:32100 device model:Phone\n';
      final result = connection.connect('127.0.0.1', '32100');
      await finish('connected to 127.0.0.1:32100');
      expect(await result, true);
      old.complete({'exitCode': 0, 'output': 'List of devices attached\n'});
      await refresh;
      expect(connection.devices.single.online, true);
    },
  );

  test(
    'process startup failure is not misreported as network timeout',
    () async {
      connection.dispose();
      connection = DeviceConnection(
        preferences: AppearancePreferences(),
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async {
              throw StateError('missing bash');
            },
      );
      expect(await connection.connect('127.0.0.1', '32100'), false);
      expect(connection.message, contains('ADB 启动失败'));
      expect(connection.message, isNot(contains('连接超时')));
      expect(connection.busy, false);
    },
  );

  test('malformed adb output is a read error, not an empty list', () async {
    pendingRead = () async => {'exitCode': 0, 'output': 'daemon failure'};
    await connection.refresh();
    expect(connection.readError, isNotNull);
    expect(connection.missing, false);
  });

  test(
    'one action at a time; disconnect targets only selected serial',
    () async {
      connection.dispose();
      connection = DeviceConnection(
        preferences: AppearancePreferences(),
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async {
              expect(command, "adb disconnect '127.0.0.1:32100'");
              process = FakeProcess();
              return process;
            },
      );
      final result = connection.disconnect('127.0.0.1:32100');
      expect(await connection.connect('127.0.0.1', '32000'), false);
      await finish('disconnected 127.0.0.1:32100');
      expect(await result, true);
      expect(connection.message, contains('配对授权仍保留'));
    },
  );
}
