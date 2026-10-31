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
          .timeout(timeout + const Duration(seconds: 2));
      return (result ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (e) => DiscoveredAdb(
              host: e['host']?.toString() ?? '',
              port: e['port']?.toString() ?? '',
            ),
          )
          .where(
            (e) =>
                (int.tryParse(e.port) ?? 0) >= 1 &&
                (int.tryParse(e.port) ?? 0) <= 65535,
          )
          .toList();
    } on MissingPluginException {
      return const [];
    }
  }

  static Future<void> startPairing() async =>
      channel.invokeMethod('startPairing');
  static Future<void> stopPairing() async =>
      channel.invokeMethod('stopPairing');
  static Future<Map<String, dynamic>> pairingStatus() async =>
      Map<String, dynamic>.from(
        await channel.invokeMethod('pairingStatus') ?? const {},
      );
  static Future<void> openWirelessSettings() async =>
      channel.invokeMethod('openWirelessSettings');

  /// 指南只读取系统版本、应用通知和配对通知渠道的状态，不启动配对。
  /// 通知样式由厂商设置控制，Android 没有通用接口读取或切换它。
  static Future<Map<String, dynamic>> pairingReadiness() async =>
      Map<String, dynamic>.from(
        await channel.invokeMethod('pairingReadiness') ?? const {},
      );

  /// MIUI 等系统对后台/不可见时的网络限制: 是否已忽略电池优化
  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await channel.invokeMethod('isIgnoringBatteryOptimizations') == true;

  /// 跳转系统"忽略电池优化"确认框; true = 已经是忽略状态, 无需确认
  static Future<bool> requestIgnoreBatteryOptimizations() async =>
      await channel.invokeMethod('requestIgnoreBatteryOptimizations') == true;

  /// 深链到系统的应用通知设置页(开关直达, 不经过应用详情页)。
  /// targetSdk 28 下系统不为通知权限的运行时请求弹授权框, 只能引导用户手动开关。
  static Future<void> openNotificationSettings() async {
    await channel.invokeMethod('openNotificationSettings');
  }
}
