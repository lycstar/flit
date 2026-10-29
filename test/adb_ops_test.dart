import 'package:flutter_test/flutter_test.dart';
import 'package:flit/services/adb_ops.dart';

void main() {
  group('AdbOps.parseDevices', () {
    test('常规输出: 本机回环 + 局域网设备', () {
      final devices = AdbOps.parseDevices(
        'List of devices attached\n'
        '127.0.0.1:39057\tdevice product:missi model:M2012K11AC device:missi\n'
        '192.168.1.8:37251\tdevice product:taro model:V2302A\n'
        '\n',
      );
      expect(devices, hasLength(2));
      expect(devices[0].$1, '127.0.0.1:39057');
      expect(devices[0].$2, 'M2012K11AC');
      expect(devices[1].$1, '192.168.1.8:37251');
      expect(devices[1].$2, 'V2302A');
    });

    test('过滤 unauthorized/offline 与 USB 无 model 行', () {
      final devices = AdbOps.parseDevices(
        'List of devices attached\n'
        'ABC123\tunauthorized transport_id:5\n'
        'emulator-5554\toffline\n'
        'ZY22XXXXXX\tdevice usb:1-1 product:foo\n'
        '\n',
      );
      expect(devices, hasLength(1));
      expect(devices[0].$1, 'ZY22XXXXXX');
      expect(devices[0].$2, ''); // 无 model 字段时留空
    });

    test('空输出与表头缺失', () {
      expect(AdbOps.parseDevices(''), isEmpty);
      expect(AdbOps.parseDevices('daemon not running; starting now\n'), isEmpty);
    });
  });
}
