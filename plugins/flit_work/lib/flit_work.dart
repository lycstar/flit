import 'package:flutter/services.dart';

/// 终端/构建保活(通道 flit/work): 有存活会话时申请前台服务(MIUI 等系统会
/// 冻结后台应用, 长构建与终端会话会被杀), 全部结束即释放。
/// 引用计数跨会话/页面共享; 通道失败静默(保活尽力而为, 不阻塞工作)。
class WorkKeepAlive {
  WorkKeepAlive._();

  static const channel = MethodChannel('flit/work');

  static int _refs = 0;

  static Future<void> acquire([String title = 'Flit 工作中']) async {
    // 计数只记会话数, 与通道成败无关: 失败若回退计数, 配对的 release
    // 会把别的会话的保活提前关掉
    _refs++;
    if (_refs > 1) return;
    try {
      await channel.invokeMethod('start', {'title': title});
    } catch (_) {}
  }

  static Future<void> release() async {
    if (_refs == 0) return;
    _refs--;
    if (_refs > 0) return;
    try {
      await channel.invokeMethod('stop');
    } catch (_) {}
  }
}
