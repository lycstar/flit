import '../../core/theme.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../services/shell.dart';

/// 外观与设备记忆(持久化到 $HOME/.flit/appearance.json)。
/// 应用启动时由组合根加载一次; 之后组件只读它、经 update() 写它。
class AppearancePreferences extends ChangeNotifier {
  double editorSize = 14;
  double terminalSize = 13;
  String editorTheme = 'dark'; // dark | light
  bool editorWrap = true; // 软换行(false = 长行横向滚动)
  bool editorCodeKeys = true; // 代码虚拟键盘(压制系统软键盘)
  bool adbPaired = false; // 曾完成无线配对，不代表系统仍保留授权
  String adbHost = '127.0.0.1'; // 最近一次 adb 连接的主机(本机/局域网)
  String adbConnectPort = ''; // 上次成功连接的端口(无线调试不重开就不变, 自动重连先试它)
  String runDevice = ''; // 最近一次热重载运行的设备 serial
  File? _file;
  Future<void>? _loading;
  Future<void> _saving = Future.value();
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    try {
      final status = await Shell.instance.bootstrapStatus();
      final home = status['home'] as String?;
      if (home == null || home.isEmpty) return;
      _file = File('$home/.flit/appearance.json');
      if (await _file!.exists()) {
        final data = jsonDecode(await _file!.readAsString()) as Map;
        editorSize = (data['editorSize'] as num? ?? 14).toDouble().clamp(
          12,
          20,
        );
        terminalSize = (data['terminalSize'] as num? ?? 13).toDouble().clamp(
          11,
          20,
        );
        editorTheme = data['editorTheme'] as String? ?? 'dark';
        editorWrap = data['editorWrap'] as bool? ?? true;
        editorCodeKeys = data['editorCodeKeys'] as bool? ?? true;
        adbPaired = data['adbPaired'] as bool? ?? false;
        adbHost = data['adbHost'] as String? ?? '127.0.0.1';
        adbConnectPort = data['adbConnectPort'] as String? ?? '';
        runDevice = data['runDevice'] as String? ?? '';
      }
      _applyTheme();
      notifyListeners();
    } catch (_) {
      /* Defaults remain usable if storage is unavailable. */
    }
  }

  Future<void> update({
    double? editor,
    double? terminal,
    String? theme,
    bool? wrap,
    bool? codeKeys,
    bool? adbPaired,
    String? adbHost,
    String? adbConnectPort,
    String? runDevice,
  }) async {
    await load();
    editorSize = editor ?? editorSize;
    terminalSize = terminal ?? terminalSize;
    this.adbPaired = adbPaired ?? this.adbPaired;
    this.adbHost = adbHost ?? this.adbHost;
    this.adbConnectPort = adbConnectPort ?? this.adbConnectPort;
    this.runDevice = runDevice ?? this.runDevice;
    if (theme != null && theme != editorTheme) {
      editorTheme = theme;
      _applyTheme();
    }
    editorWrap = wrap ?? editorWrap;
    editorCodeKeys = codeKeys ?? editorCodeKeys;
    notifyListeners();
    final data = jsonEncode({
      'editorSize': editorSize,
      'terminalSize': terminalSize,
      'editorTheme': editorTheme,
      'editorWrap': editorWrap,
      'editorCodeKeys': editorCodeKeys,
      'adbPaired': this.adbPaired,
      'adbHost': this.adbHost,
      'adbConnectPort': this.adbConnectPort,
      'runDevice': this.runDevice,
    });
    _saving = _saving.catchError((_) {}).then((_) async {
      if (_file == null) throw StateError('设置存储不可用');
      await _file!.parent.create(recursive: true);
      await _file!.writeAsString(data);
    });
    await _saving;
  }

  void _applyTheme() {
    CodeTheme.current = editorTheme == 'light'
        ? CodeTheme.light
        : CodeTheme.dark;
  }
}
