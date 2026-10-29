import 'package:flutter/services.dart';

/// Termux 运行环境的原生薄方法(通道 flit/env)。
/// 交互终端与流式任务走 flutter_pty, 不经过这里。
class FlitEnv {
  FlitEnv._();

  static const channel = MethodChannel('flit/env');

  /// {bootstrapped, prefix, home, tz}
  static Future<Map<dynamic, dynamic>> bootstrapStatus() async =>
      await channel.invokeMethod('bootstrapStatus') as Map<dynamic, dynamic>;

  /// 原生全量解压 bootstrap 到 $PREFIX; 失败以 PlatformException 带出原始错误
  static Future<bool> deployBootstrap(String zipPath) async =>
      await channel.invokeMethod('deployBootstrap', {'zipPath': zipPath}) ==
      true;

  /// 系统代理地址(host:port); 未设置返回 null
  static Future<String?> systemProxy() async =>
      await channel.invokeMethod('systemProxy') as String?;

  /// 默认网络的代理变化时原生推送最新地址(null = 已取消); 只有一个监听者
  static void onSystemProxyChanged(void Function(String? address) listener) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onSystemProxyChanged') {
        listener(call.arguments as String?);
      }
      return null;
    });
  }

  /// 一次性执行(bash -c, 管道式), 返回 {exitCode, output}
  static Future<Map<dynamic, dynamic>> exec(
    String cmd, {
    int timeoutMs = 120000,
  }) async =>
      await channel.invokeMethod('exec', {'cmd': cmd, 'timeoutMs': timeoutMs})
          as Map<dynamic, dynamic>;

  /// 文件 sha256(原生分块计算); 读失败返回空串
  static Future<String> sha256(String path) async =>
      await channel.invokeMethod('sha256', {'path': path}) as String;

  /// 唤起系统浏览器(终端进程无法自己打开 Intent)
  static Future<bool> openUrl(String url) async =>
      await channel.invokeMethod('openUrl', {'url': url}) == true;

  /// 直达系统设置页(action 见 android.provider.Settings)
  static Future<bool> openSettings(String action) async =>
      await channel.invokeMethod('openSettings', {'action': action}) == true;
}
