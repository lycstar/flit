import '../../core/theme.dart';
import '../../services/adb_connection_method.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../services/shell.dart';

/// 外观与设备记忆(持久化到 $HOME/.flit/appearance.json)。
/// 应用启动时由组合根加载一次; 之后组件只读它、经 update() 写它。
class AppearancePreferences extends ChangeNotifier {
  static const terminalMinSize = 9.0;
  static const terminalMaxSize = 28.0;
  static const terminalFonts = {
    'JetBrainsMono': 'JetBrains Mono',
    'monospace': '系统等宽字体',
  };
  double editorSize = 14;
  double terminalSize = 13;
  String terminalFont = 'JetBrainsMono';
  double terminalLineHeight = 1.2;
  String editorTheme = 'dark'; // dark | light
  bool editorWrap = true; // 软换行(false = 长行横向滚动)
  bool backgroundNoticeShown = false;
  bool adbPaired = false; // 曾完成无线配对，不代表系统仍保留授权
  String adbHost = '127.0.0.1'; // 最近一次 adb 连接的主机(本机/局域网)
  int adbPairingRevision = 0; // 已处理的通知配对结果，避免重新进页时重放
  AdbConnectionMethod adbConnectionMethod = AdbConnectionMethod.wireless;
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
        terminalSize = _terminalSize(
          (data['terminalSize'] as num? ?? 13).toDouble(),
        );
        terminalFont = _terminalFont(data['terminalFont'] as String?);
        terminalLineHeight = _terminalHeight(
          (data['terminalLineHeight'] as num? ?? 1.2).toDouble(),
        );
        editorTheme = data['editorTheme'] as String? ?? 'dark';
        editorWrap = data['editorWrap'] as bool? ?? true;
        backgroundNoticeShown = data['backgroundNoticeShown'] as bool? ?? false;
        adbPaired = data['adbPaired'] as bool? ?? false;
        adbHost = data['adbHost'] as String? ?? '127.0.0.1';
        adbConnectPort = data['adbConnectPort'] as String? ?? '';
        adbPairingRevision = data['adbPairingRevision'] as int? ?? 0;
        adbConnectionMethod = AdbConnectionMethod.values.byName(
          data['adbConnectionMethod'] == 'usb' ? 'usb' : 'wireless',
        );
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
    String? terminalFont,
    double? terminalLineHeight,
    String? theme,
    bool? wrap,
    bool? backgroundNoticeShown,
    bool? adbPaired,
    String? adbHost,
    String? adbConnectPort,
    AdbConnectionMethod? adbConnectionMethod,
    int? adbPairingRevision,
    String? runDevice,
  }) async {
    await load();
    editorSize = editor ?? editorSize;
    terminalSize = _terminalSize(terminal ?? terminalSize);
    if (terminalFont != null) this.terminalFont = _terminalFont(terminalFont);
    this.terminalLineHeight = _terminalHeight(
      terminalLineHeight ?? this.terminalLineHeight,
    );
    this.backgroundNoticeShown =
        backgroundNoticeShown ?? this.backgroundNoticeShown;
    this.adbPaired = adbPaired ?? this.adbPaired;
    this.adbHost = adbHost ?? this.adbHost;
    this.adbConnectPort = adbConnectPort ?? this.adbConnectPort;
    this.adbPairingRevision = adbPairingRevision ?? this.adbPairingRevision;
    this.adbConnectionMethod = adbConnectionMethod ?? this.adbConnectionMethod;
    this.runDevice = runDevice ?? this.runDevice;
    if (theme != null && theme != editorTheme) {
      editorTheme = theme;
      _applyTheme();
    }
    editorWrap = wrap ?? editorWrap;
    notifyListeners();
    final data = jsonEncode({
      'editorSize': editorSize,
      'terminalSize': terminalSize,
      'terminalFont': this.terminalFont,
      'terminalLineHeight': this.terminalLineHeight,
      'editorTheme': editorTheme,
      'editorWrap': editorWrap,
      'backgroundNoticeShown': this.backgroundNoticeShown,
      'adbPaired': this.adbPaired,
      'adbHost': this.adbHost,
      'adbConnectPort': this.adbConnectPort,
      'adbPairingRevision': this.adbPairingRevision,
      'adbConnectionMethod': this.adbConnectionMethod.name,
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

  static double _terminalSize(double value) =>
      value.isFinite ? value.clamp(terminalMinSize, terminalMaxSize) : 13;
  static double _terminalHeight(double value) =>
      value.isFinite ? value.clamp(1.0, 2.0) : 1.2;
  static String _terminalFont(String? value) =>
      terminalFonts.containsKey(value) ? value! : 'JetBrainsMono';
}
