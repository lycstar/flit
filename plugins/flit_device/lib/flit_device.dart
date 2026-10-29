import 'package:flutter/services.dart';

/// NSD 解析出的本机无线调试服务
class DiscoveredAdb {
  const DiscoveredAdb({required this.host, required this.port});
  final String host;
  final String port;
}

/// 本机调试设备的原生薄方法(通道 flit/device)。
class FlitDevice {
  FlitDevice._();

  static const channel = MethodChannel('flit/device');

  /// 无线调试的连接服务(常驻广播); 配对服务仅在系统配对弹窗开着时广播
  static const adbConnectService = '_adb-tls-connect._tcp';
  static const adbPairingService = '_adb-tls-pairing._tcp';

  /// 本机无线调试端口发现(NsdManager, 走系统 mDNS 应答, 不需要多播锁)。
  /// 只返回本机 adbd 正在监听的端口——同网段其它设备的广播在原生侧过滤。
  static Future<List<DiscoveredAdb>> discoverAdb({
    String service = adbConnectService,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      // Dart 侧也兜底超时: 测试里未 mock 的通道永不回复; 真机上原生超时是主闸
      final result = await channel
          .invokeMethod<List<dynamic>>('discoverAdb', {
            'service': service,
            'timeoutMs': timeout.inMilliseconds,
          })
          .timeout(timeout, onTimeout: () => null);
      return (result ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (e) => DiscoveredAdb(
              host: e['host']?.toString() ?? '',
              port: e['port']?.toString() ?? '',
            ),
          )
          .where((e) => e.port.isNotEmpty)
          .toList();
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  /// MIUI 等系统对后台/不可见时的网络限制: 是否已忽略电池优化
  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await channel.invokeMethod('isIgnoringBatteryOptimizations') == true;

  /// 跳转系统"忽略电池优化"确认框; true = 已经是忽略状态, 无需确认
  static Future<bool> requestIgnoreBatteryOptimizations() async =>
      await channel.invokeMethod('requestIgnoreBatteryOptimizations') == true;
}
