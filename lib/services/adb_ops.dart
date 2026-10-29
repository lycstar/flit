import 'shell.dart';

/// adb 设备(serial + 型号)
typedef AdbDevice = (String serial, String model);

class AdbStatus {
  const AdbStatus(this.serial, this.state, this.model);
  final String serial, state, model;
  bool get online => state == 'device';
  String get label => switch (state) {
    'device' => '已连接',
    'unauthorized' => '未授权',
    'offline' => '离线',
    'authorizing' => '认证中',
    _ => state,
  };
}

/// adb 薄操作: 设备枚举(本机回环与局域网设备一视同仁, serial 即地址)。
class AdbOps {
  AdbOps._();

  /// Run targets include only devices that have completed authentication.
  static List<AdbDevice> parseDevices(String out) => [
    for (final device in parseStatuses(out))
      if (device.online) (device.serial, device.model),
  ];

  static List<AdbStatus> parseStatuses(String out) {
    final devices = <AdbStatus>[];
    var started = false;
    for (final raw in out.split('\n')) {
      final line = raw.trimRight();
      if (line.startsWith('List of devices attached')) {
        started = true;
        continue;
      }
      if (!started || line.trim().isEmpty) continue;
      final fields = line.trim().split(RegExp(r'\s+'));
      if (fields.length < 2 ||
          !{
            'device',
            'offline',
            'unauthorized',
            'authorizing',
            'recovery',
            'sideload',
            'bootloader',
            'no',
          }.contains(fields[1])) {
        continue;
      }
      var model = '';
      for (final f in fields.skip(2)) {
        if (f.startsWith('model:')) {
          model = f.substring(6);
          break;
        }
      }
      devices.add(
        AdbStatus(
          fields[0],
          fields[1] == 'no' ? 'no permissions' : fields[1],
          model,
        ),
      );
    }
    return devices;
  }

  /// 目标的友好名与类别:
  ///   127.0.0.1:端口 = 本机(无线调试自连)
  ///   其他 ip:端口   = 局域网设备
  ///   其余           = USB 连接的设备
  static (String name, String kind) describe(String serial, String model) {
    if (serial.startsWith('127.0.0.1:') ||
        serial.startsWith('[::1]:') ||
        serial.startsWith('localhost:')) {
      return (model.isEmpty ? '本机' : '本机 · $model', '本机');
    }
    if (serial.contains(':')) {
      return (model.isEmpty ? '局域网 ${serial.split(':').first}' : model, '局域网');
    }
    return (model.isEmpty ? serial : model, 'USB');
  }

  /// 当前在线设备(unauthorized/offline 不算)
  static Future<List<AdbDevice>> devices() async => [
    for (final device in await statuses())
      if (device.online) (device.serial, device.model),
  ];

  // Use the same SDK-first PATH as PTY actions and Flutter tasks. Otherwise a
  // second Termux adb can restart the shared server during status queries.
  static Future<List<AdbStatus>> statuses() async {
    final res = await Shell.instance.exec(
      '${terminalEnvSource}adb devices -l',
      timeoutMs: 20000,
    );
    if (res['exitCode'] != 0) {
      final output = (res['output'] as String? ?? '').trim();
      throw StateError(output.isEmpty ? '读取设备失败' : output);
    }
    final output = res['output'] as String? ?? '';
    if (!output.contains('List of devices attached')) {
      throw StateError('ADB 未返回设备列表：$output');
    }
    return parseStatuses(output);
  }
}
