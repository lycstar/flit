import 'package:flit_device/flit_device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(FlitDevice.channel, null));

  testWidgets(
    'native deadline result is not discarded by simultaneous Dart timeout',
    (tester) async {
      messenger.setMockMethodCallHandler(FlitDevice.channel, (call) async {
        await Future<void>.delayed(const Duration(milliseconds: 6100));
        return [
          {'host': '127.0.0.1', 'port': 43210},
        ];
      });
      List<DiscoveredAdb>? found;
      final future = FlitDevice.discoverAdb().then((value) => found = value);
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(found, isNull);
      await tester.pump(const Duration(milliseconds: 100));
      await future;
      expect(found!.single.port, '43210');
    },
  );

  test(
    'NSD platform failure is reported instead of pretending no device exists',
    () async {
      messenger.setMockMethodCallHandler(
        FlitDevice.channel,
        (_) async =>
            throw PlatformException(code: 'discovery_failed', message: 'NSD 3'),
      );
      await expectLater(
        FlitDevice.discoverAdb(),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  test('invalid ports from the native bridge are rejected', () async {
    messenger.setMockMethodCallHandler(
      FlitDevice.channel,
      (_) async => [
        {'host': '127.0.0.1', 'port': 0},
        {'host': '127.0.0.1', 'port': 65536},
        {'host': '127.0.0.1', 'port': 'abc'},
        {'host': '127.0.0.1', 'port': 43210},
      ],
    );
    expect((await FlitDevice.discoverAdb()).map((e) => e.port), ['43210']);
  });
}
