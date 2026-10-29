import 'package:flutter/services.dart';

/// 官方 dart language-server 的进程传输(通道 flit/lsp)。
/// 原生只负责拉起进程与收发 JSON-RPC 帧; 握手、文档同步等协议语义在 LspClient。
class FlitLsp {
  FlitLsp._();

  static const channel = MethodChannel('flit/lsp');
  static const events = EventChannel('flit/lspEvents');

  /// 拉起分析器(工作目录 = 工程根); session 标识这一代进程, 通知流按它过滤
  static Future<bool> start({
    required String rootPath,
    required int session,
  }) async =>
      await channel.invokeMethod<bool>('start', {
            'rootPath': rootPath,
            'session': session,
          }) ==
          true;

  /// 发请求, 返回响应 JSON; 进程不在或超时(原生 25s)返回 null
  static Future<String?> request(String method, String paramsJson) =>
      channel.invokeMethod<String>('request', {
        'method': method,
        'params': paramsJson,
      });

  /// 发通知; false = 进程已不在
  static Future<bool> notify(String method, String paramsJson) async =>
      await channel.invokeMethod<bool>('notify', {
            'method': method,
            'params': paramsJson,
          }) ==
          true;

  /// 结束进程; 通道不可用时静默
  static Future<void> stop() =>
      channel.invokeMethod('stop').catchError((_) => null);

  /// 服务端通知(publishDiagnostics 等)与 flit/serverExited, 每条带 flitSession
  static Stream<dynamic> get notifications => events.receiveBroadcastStream();
}
