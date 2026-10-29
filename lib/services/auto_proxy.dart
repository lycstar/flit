import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flit_env/flit_env.dart';

/// 自动代理: 跟随 Android 系统代理(单一开关, Dart 网络与终端环境两层同用)。
/// 地址来自系统设置(Wi-Fi 代理 / clash 仅代理模式), 原生在默认网络代理
/// 变化时经 onSystemProxyChanged 实时推送 —— 不重启 app 也能即时切换;
/// 未设置时开关打开也不生效。Dart 侧 HttpClient 立即覆盖; 终端里的
/// git/curl/apt/dart pub 在下一个新会话启动时拿到(PtyLauncher 注入)。
class AutoProxy extends ChangeNotifier {
  AutoProxy() {
    FlitEnv.onSystemProxyChanged(_updateAddress);
  }

  bool enabled = false; // 用户开关(默认关, 不改变直连现状)
  String? address; // 系统代理 host:port, null = 系统未设置
  bool _loaded = false;
  File? _file;

  /// 开关打开且系统有代理时才真正生效
  bool get active => enabled && address != null;

  /// 启动时加载: 持久化开关 + 探测系统代理地址(可多次调用刷新地址)
  Future<void> load() async {
    try {
      final addr = await FlitEnv.systemProxy();
      if (addr != address) {
        address = addr;
        applyToDart();
        notifyListeners();
      }
    } catch (_) {
      address = null;
    }
    if (_loaded) return;
    _loaded = true;
    try {
      final st = await FlitEnv.bootstrapStatus();
      final home = st['home'] as String? ?? '';
      if (home.isEmpty) return;
      final f = File('$home/.flit/proxy.json');
      _file = f;
      if (f.existsSync()) {
        final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        enabled = j['enabled'] == true;
      }
    } catch (_) {}
    notifyListeners();
  }

  void _updateAddress(String? addr) {
    if (addr == address) return;
    address = addr;
    applyToDart();
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    applyToDart();
    notifyListeners();
    try {
      _file?.parent.createSync(recursive: true);
      _file?.writeAsStringSync(jsonEncode({'enabled': v}));
    } catch (_) {}
  }

  /// Dart 侧: HttpOverrides 让全部 dart:io HttpClient 走代理
  void applyToDart() {
    HttpOverrides.global = active ? _ProxyOverrides(address!) : null;
  }

  /// 终端侧: PTY 环境变量(交互 bash 与流水线脚本都从这里继承)
  Map<String, String> envVars() {
    if (!active) return const {};
    final addr = 'http://$address';
    return {
      'http_proxy': addr,
      'https_proxy': addr,
      'HTTP_PROXY': addr,
      'HTTPS_PROXY': addr,
    };
  }
}

class _ProxyOverrides extends HttpOverrides {
  _ProxyOverrides(this.addr);
  final String addr;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..findProxy = (uri) => 'PROXY $addr';
}
