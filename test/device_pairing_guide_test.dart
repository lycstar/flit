import 'dart:async';

import 'package:flit/features/device/device_pairing_guide_page.dart';
import 'package:flit_device/flit_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  var notifications = true;
  var supported = true;
  var fail = false;
  Future<Map<String, Object>> Function()? read;

  setUp(() {
    calls.clear();
    notifications = true;
    supported = true;
    fail = false;
    read = null;
    messenger.setMockMethodCallHandler(FlitDevice.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'pairingReadiness') {
        if (fail) throw PlatformException(code: 'unavailable');
        if (read != null) return read!();
        return {'supported': supported, 'notificationsEnabled': notifications};
      }
      return true;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(FlitDevice.channel, null));

  Future<void> open(WidgetTester tester, {bool allowStart = true}) async {
    await tester.pumpWidget(
      MaterialApp(home: DevicePairingGuidePage(allowStart: allowStart)),
    );
    await tester.pumpAndSettle();
  }

  FilledButton start(WidgetTester tester) =>
      tester.widget(find.widgetWithText(FilledButton, '开始配对'));

  testWidgets(
    'reading the offline guide checks readiness without starting a service',
    (tester) async {
      await open(tester);
      expect(calls, ['pairingReadiness']);
      expect(find.text('配对通知已开启'), findsOneWidget);
      expect(find.textContaining('原生样式'), findsOneWidget);
      expect(start(tester).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
      expect(calls, ['pairingReadiness']);
    },
  );

  testWidgets(
    'disabled notification or channel blocks start and resumes after settings',
    (tester) async {
      notifications = false;
      await open(tester);
      expect(find.text('请先允许 Flit 通知'), findsOneWidget);
      expect(start(tester).onPressed, isNull);
      await tester.tap(find.text('通知设置'));
      await tester.pumpAndSettle();
      expect(calls, contains('openNotificationSettings'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      notifications = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('配对通知已开启'), findsOneWidget);
      expect(start(tester).onPressed, isNotNull);
      expect(calls, isNot(contains('startPairing')));
    },
  );

  testWidgets('unsupported Android and busy device page cannot start pairing', (
    tester,
  ) async {
    supported = false;
    await open(tester);
    expect(find.textContaining('可返回使用电脑 USB 激活'), findsOneWidget);
    expect(start(tester).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    supported = true;
    await open(tester, allowStart: false);
    expect(start(tester).onPressed, isNull);
    expect(calls, isNot(contains('startPairing')));
  });

  testWidgets('failed readiness remains unknown and can be retried', (
    tester,
  ) async {
    fail = true;
    await open(tester);
    expect(find.text('通知状态未知'), findsOneWidget);
    expect(start(tester).onPressed, isNull);
    fail = false;
    await tester.tap(find.text('重新检查'));
    await tester.pumpAndSettle();
    expect(start(tester).onPressed, isNotNull);
  });

  testWidgets(
    'late readiness cannot override a newer resume or a disposed page',
    (tester) async {
      final pending = Completer<Map<String, Object>>();
      read = () => pending.future;
      await tester.pumpWidget(
        const MaterialApp(home: DevicePairingGuidePage()),
      );
      await tester.pump();
      read = null;
      notifications = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNull);
      pending.complete({'supported': true, 'notificationsEnabled': true});
      await tester.pumpAndSettle();
      expect(find.text('请先允许 Flit 通知'), findsOneWidget);
      final disposedRead = Completer<Map<String, Object>>();
      read = () => disposedRead.future;
      await tester.tap(find.text('重新检查'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      disposedRead.complete({'supported': true, 'notificationsEnabled': true});
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
