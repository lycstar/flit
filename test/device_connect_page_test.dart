import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/device/device_connect_page.dart';
import 'package:flit/features/settings/appearance_preferences.dart';

import 'support/app_scope.dart';
import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final processes = <FakeProcess>[];
  final commands = <String?>[];
  late Future<Map<String, Object>> Function() readDevices;
  late AppearancePreferences prefs;
  var reads = 0;
  var available = true;

  Map<String, Object> deviceList(String lines) => {
    'exitCode': 0,
    'output': 'List of devices attached\n$lines',
  };

  setUp(() async {
    processes.clear();
    commands.clear();
    reads = 0;
    available = true;
    prefs = AppearancePreferences()
      ..adbHost = '127.0.0.1'
      ..adbPaired = false;
    readDevices = () async => deviceList('');
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      // home 留空让偏好不落盘; prefix 不存在让工作台 shell 安静待命
      if (call.method == 'bootstrapStatus') {
        return {'home': '', 'prefix': '/does-not-exist'};
      }
      if (call.method == 'exec') {
        final command = (call.arguments as Map)['cmd'];
        if (command.toString().endsWith('command -v adb')) {
          return {
            'exitCode': available ? 0 : 1,
            'output': available ? '/prefix/bin/adb' : '',
          };
        }
        if (command.toString().endsWith('adb devices -l')) {
          reads++;
          return readDevices();
        }
      }
      return false;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('flit/device'), (
      call,
    ) async {
      // 电池优化已忽略: 电池提示卡不出现, 页面布局保持紧凑
      if (call.method == 'isIgnoringBatteryOptimizations') return true;
      // NSD 发现返回空: 自动连接的发现环节立即结束(视为无线调试未开)
      if (call.method == 'discoverAdb') return const <Map<String, Object>>[];
      return null;
    });
    await prefs.load();
  });

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  Finder button(String text) => find.widgetWithText(FilledButton, text);

  Future<void> settle(WidgetTester tester) async {
    // Preferences are shared with code outside the widget test's fake clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    // 页面加入 Shizuku 式步骤卡后变长: 拉高视口让全部区块一次建出,
    // 避免懒加载列表把区块 2 留在视口外导致 finder 找不到字段
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      testApp(
        services: testServices(
          preferences: prefs,
          launcher:
              ({
                required command,
                required workingDirectory,
                required rows,
                required columns,
              }) async {
                commands.add(command);
                final process = FakeProcess();
                processes.add(process);
                return process;
              },
        ),
        home: const DeviceConnectPage(autoConnectOnOpen: false),
      ),
    );
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final f = field(label);
    for (
      var i = 0;
      i < 10 &&
          tester.any(find.descendant(of: find.byType(ListView), matching: f));
      i++
    ) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -150));
      await tester.pump();
    }
    await tester.ensureVisible(f);
    await tester.enterText(f, text);
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(button(label));
    await tester.tap(button(label));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('rejects out-of-range ports and accepts the upper boundary', (
    tester,
  ) async {
    await open(tester);
    for (final port in ['0', '99999']) {
      await enter(tester, '连接端口', port);
      await press(tester, '连接');
      expect(commands, isEmpty);
    }
    await tester.ensureVisible(field('连接端口'));
    await enter(tester, '连接端口', '65535');
    await press(tester, '连接');
    expect(commands, ["adb connect '127.0.0.1:65535'"]);
    await close(tester);
    // UI 关闭 = 硬杀立即释放(不再先发 Ctrl+C 等优雅退出)
    expect(processes.single.exited.isCompleted, true);
  });

  testWidgets(
    'pair retry preserves the code; connect waits for the requested device to come online',
    (tester) async {
      await open(tester);
      await tester.ensureVisible(field('设备地址'));
      await enter(tester, '设备地址', '192.168.1.8');
      await tester.ensureVisible(field('配对端口'));
      await enter(tester, '配对端口', '123');
      await tester.ensureVisible(field('配对码（6 位）'));
      await enter(tester, '配对码（6 位）', '123456');
      await press(tester, '配对');
      expect(commands.single, "adb pair '192.168.1.8:123' '123456'");
      expect(tester.widget<FilledButton>(button('连接')).onPressed, isNull);
      await processes.first.finish(1);
      await settle(tester);
      expect(
        tester.widget<TextField>(field('配对码（6 位）')).controller!.text,
        '123456',
      );
      expect(find.text('有配对记录'), findsNothing);
      await press(tester, '配对');
      processes.last.emit(
        'Successfully paired to 192.168.1.8:123 [guid=example]\r\n',
      );
      await processes.last.finish();
      await settle(tester);
      // 配对成功会自动触发连接: 等它的探测进程出现并跑完(无缓存端口且
      // NSD 不可用 → 以"未发现端口"收场), busy 释放后连接按钮才可用
      for (var i = 0; i < 20 && processes.length < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      await processes.last.finish();
      await settle(tester);
      expect(find.text('有配对记录'), findsOneWidget);
      expect(tester.widget<TextField>(field('配对码（6 位）')).controller!.text, '');
      expect(tester.widget<FilledButton>(button('连接')).onPressed, isNotNull);
      await tester.ensureVisible(field('设备地址'));
      await enter(tester, '设备地址', '192.168.1.9');
      await tester.pump();
      expect(find.text('有配对记录'), findsNothing);
      await tester.ensureVisible(field('设备地址'));
      await enter(tester, '设备地址', '127.0.0.1');
      final pending = Completer<Map<String, Object>>();
      readDevices = () => pending.future;
      await tester.ensureVisible(field('连接端口'));
      await enter(tester, '连接端口', '32100');
      await press(tester, '连接');
      await processes.last.finish();
      await tester.pump();
      expect(tester.widget<FilledButton>(button('连接')).onPressed, isNull);
      expect(tester.widget<FilledButton>(button('配对')).onPressed, isNull);
      expect(tester.widget<TextField>(field('设备地址')).enabled, false);
      expect(commands, hasLength(4)); // pair · 自动连接的探测 · pair · connect
      expect(commands.last, "adb connect '127.0.0.1:32100'");
      pending.complete(
        deviceList(
          '127.0.0.1:32100 offline\n192.168.1.8:12345 device model:Other\n',
        ),
      );
      await settle(tester);
      expect(find.textContaining('✓ 已连接'), findsNothing);
      readDevices = () async =>
          deviceList('127.0.0.1:32100 device model:Phone\n');
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(find.textContaining('✓ 已连接 127.0.0.1:32100'), findsOneWidget);
      expect(tester.widget<FilledButton>(button('连接')).onPressed, isNotNull);
      await close(tester);
    },
  );

  testWidgets('zero connect exit code does not count as an online device', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(field('连接端口'));
    await enter(tester, '连接端口', '32100');
    await press(tester, '连接');
    await processes.single.finish();
    await settle(tester);
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.textContaining('✓ 已连接'), findsNothing);
    expect(find.textContaining('设备尚未上线'), findsOneWidget);
    expect(tester.widget<FilledButton>(button('连接')).onPressed, isNotNull);
    await close(tester);
  });

  testWidgets(
    'device-read failure is distinct from missing adb and recovers on resume',
    (tester) async {
      readDevices = () async => {
        'exitCode': 1,
        'output': 'cannot connect to daemon',
      };
      await open(tester);
      expect(find.text('读取设备失败，请查看终端输出'), findsOneWidget);
      expect(find.textContaining('未找到 ADB'), findsNothing);
      readDevices = () async =>
          deviceList('127.0.0.1:32100 device model:Phone\n');
      final before = reads;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(reads, greaterThan(before));
      expect(find.text('本机 · Phone'), findsOneWidget);
      readDevices = () async => deviceList('');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(find.text('本机 · Phone'), findsNothing);
      await close(tester);
    },
  );

  testWidgets(
    'failed status verification reports the read error, not the port',
    (tester) async {
      await open(tester);
      readDevices = () async =>
          throw PlatformException(code: 'exec', message: 'native failure');
      await tester.ensureVisible(field('连接端口'));
      await enter(tester, '连接端口', '32100');
      await press(tester, '连接');
      await processes.single.finish();
      await settle(tester);
      expect(find.textContaining('✗ 无法确认连接状态：读取设备失败'), findsOneWidget);
      expect(find.textContaining('核对无线调试的连接端口'), findsNothing);
      // 区块 2 在懒加载列表视口外: 滚到区块 2 再断言按钮状态
      await tester.ensureVisible(field('连接端口'));
      await tester.pump();
      expect(tester.widget<FilledButton>(button('连接')).onPressed, isNotNull);
      await close(tester);
    },
  );

  testWidgets(
    'missing adb is shown without treating it as an empty device list',
    (tester) async {
      available = false;
      await open(tester);
      expect(find.textContaining('未找到 ADB'), findsOneWidget);
      expect(reads, 0);
      await close(tester);
    },
  );
}
