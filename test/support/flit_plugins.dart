import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 本地 plugin 通道的测试桩。
///
/// testWidgets 跑在假时钟里: 打到未 mock 通道的调用会等一个真实异步回复,
/// 假时钟永远不会推进它, 测试直到超时才失败(表现为"卡住")。凡是会启动
/// 会话(flit/work 保活)或持有语言服务(flit/lsp, 关闭工程时 dispose 必经)
/// 的测试都要装上这组桩; 需要特定行为的通道由测试自己再覆盖。
void mockFlitPlugins(TestDefaultBinaryMessenger messenger) {
  messenger.setMockMethodCallHandler(
    const MethodChannel('flit/work'),
    (_) async => true,
  );
  messenger.setMockMethodCallHandler(const MethodChannel('flit/lsp'), (
    call,
  ) async {
    // 语言服务不可用: start 返回 false, 客户端走"无法启动"分支安静结束
    switch (call.method) {
      case 'start':
        return false;
      case 'stop':
      case 'notify':
        return true;
    }
    return null;
  });
  messenger.setMockMethodCallHandler(
    const MethodChannel('flit/lspEvents'),
    (_) async => null,
  );
}
