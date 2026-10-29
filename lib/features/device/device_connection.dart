import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flit_device/flit_device.dart';

import '../../services/adb_ops.dart';
import '../../services/shell.dart';
import '../settings/appearance_preferences.dart';
import '../terminal/console_session.dart';

/// Owns one serialized ADB action. Pairing history is never authorization state;
/// only `adb devices -l` decides whether a target is ready for use.
class DeviceConnection extends ChangeNotifier {
  DeviceConnection({
    required ProcessLauncher launcher,
    required AppearancePreferences preferences,
  }) : _launcher = launcher,
       _preferences = preferences;

  final ProcessLauncher _launcher;

  /// 配对/主机/端口记忆落在偏好里(应用级, 跨页面共享)
  final AppearancePreferences _preferences;

  /// 当前操作的控制台(临时会话, 只能 ✕): 没操作或被关掉后为 null,
  /// 面板回落到默认 bash——会话只在操作跑起来时才有。
  ConsoleSession? console;

  /// 每次操作开新控制台(替换上一个); 被 ✕ 关掉后自动置空
  ConsoleSession _openConsole() {
    final previous = console;
    final session = ConsoleSession(title: '设备连接', launcher: _launcher);
    session.addListener(() {
      if (session.disposed && identical(console, session)) {
        console = null;
        _notify();
      }
    });
    console = session;
    _notify();
    unawaited(previous?.close());
    return session;
  }

  /// 要写日志时的控制台: 当前的, 没有就开一个
  ConsoleSession get _log => console ?? _openConsole();
  List<AdbStatus> devices = const [];
  bool busy = false;
  bool refreshing = false;
  bool missing = false;
  String? readError;
  String? message;
  bool messageIsError = false;
  bool _closed = false;
  int _revision = 0;

  static String endpoint(String host, String port) {
    host = host.trim();
    if (host.isEmpty) host = '127.0.0.1';
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    final address = InternetAddress.tryParse(host);
    if (host.contains(':') && address?.type != InternetAddressType.IPv6 ||
        address == null &&
            !RegExp(
              r'^[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?$',
            ).hasMatch(host)) {
      throw const FormatException('请输入 IP 地址或主机名，不包含协议和端口');
    }
    final number = int.tryParse(port.trim());
    if (!RegExp(r'^\d+$').hasMatch(port.trim()) ||
        number == null ||
        number < 1 ||
        number > 65535) {
      throw const FormatException('端口必须在 1–65535 之间');
    }
    return '${address?.type == InternetAddressType.IPv6 ? '[$host]' : host}:$number';
  }

  void clearMessage() {
    if (busy || message == null) return;
    message = null;
    _notify();
  }

  Future<void> refresh() async {
    if (_closed || busy || refreshing) return;
    message = null;
    await _read();
  }

  Future<bool> _read() async {
    final revision = ++_revision;
    refreshing = true;
    _notify();
    try {
      final available = await Shell.instance.exec(
        '${terminalEnvSource}command -v adb',
        timeoutMs: 8000,
      );
      if (_closed || revision != _revision) return false;
      missing = available['exitCode'] == 1 || available['exitCode'] == 127;
      if (missing) {
        devices = const [];
        readError = null;
        return false;
      }
      if (available['exitCode'] != 0) {
        throw StateError('${available['output']}');
      }
      final result = await AdbOps.statuses();
      if (_closed || revision != _revision) return false;
      devices = result;
      readError = null;
      return true;
    } catch (error) {
      if (_closed || revision != _revision) return false;
      devices = const [];
      readError = '读取设备失败，请查看终端输出';
      _log.log.err('$readError: $error');
      return false;
    } finally {
      if (!_closed && revision == _revision) {
        refreshing = false;
        _notify();
      }
    }
  }

  Future<({int code, String output})> _run(String command) async {
    final c = _log;
    final output = StringBuffer();
    final subscription = c.textStream.listen(output.write);
    try {
      final code = await c.run(command, timeout: const Duration(seconds: 30));
      if (code == -1 && c.exitCode == -1 && !_closed) {
        throw StateError('ADB 启动失败，请检查开发环境');
      }
      return (code: code, output: output.toString());
    } finally {
      await subscription.cancel();
    }
  }

  Future<bool> _action(Future<bool> Function() action) async {
    if (_closed || busy) return false;
    ++_revision; // An earlier refresh must not overwrite this action's snapshot.
    refreshing = false;
    busy = true;
    message = null;
    messageIsError = false;
    _openConsole(); // 每个操作一个控制台
    try {
      return await action();
    } catch (error) {
      if (!_closed) {
        _log.log.err('$error');
        _result(
          error is FormatException ? error.message : '操作失败：$error。详细原因见终端。',
          error: true,
        );
      }
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> pair(String host, String port, String code) => _action(() async {
    final target = endpoint(host, port);
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      throw const FormatException('请填写 6 位配对码');
    }
    final result = await _run(
      'adb pair ${shQuote(target)} ${shQuote(code.trim())}',
    );
    if (_closed) return false;
    if (result.code != 0 || !result.output.contains('Successfully paired to')) {
      _result('配对失败：请保持系统配对码弹窗开启，核对配对端口与配对码后重试。详细原因见终端。', error: true);
      return false;
    }
    await _remember(host, paired: true);
    if (_closed) return false;
    _result('配对完成。请填写无线调试主页的连接端口；配对端口不能用于连接。');
    await _read();
    return true;
  });

  /// 进页自动连接: 已连→true; 未配对→false(页面留在配对流程); 没发现端口→false。
  Future<bool> autoConnect() => _action(() async {
    final outcome = await autoConnectAdb(
      console: _log,
      preferences: _preferences,
    );
    if (_closed) return false;
    switch (outcome) {
      case AdbAutoResult.connected:
        await _read();
        if (!_closed) _result('✓ 已自动连接本机无线调试');
        return true;
      case AdbAutoResult.needsPairing:
        _result('本机尚未配对：点「打开开发者选项」→「无线调试」→「使用配对码配对设备」，配对端口会自动填入，只需输入 6 位配对码。');
        return false;
      case AdbAutoResult.unavailable:
        _result('未发现本机无线调试端口：请确认「开发者选项 → 无线调试」已打开后重试', error: true);
        return false;
    }
  });

  Future<bool> connect(String host, String port) => _action(() async {
    final target = endpoint(host, port);
    final result = await _run('adb connect ${shQuote(target)}');
    if (_closed) return false;
    // Even exit code 0 can mean connection refused / authentication failed.
    final deadline = Stopwatch()..start();
    AdbStatus? device;
    for (var attempt = 0; attempt < 20; attempt++) {
      if (!await _read() || _closed) {
        if (!_closed) {
          _result(
            missing ? '无法确认连接状态，请先安装 ADB' : '✗ 无法确认连接状态：读取设备失败，请查看终端输出',
            error: true,
          );
        }
        return false;
      }
      device = devices.where((d) => d.serial == target).firstOrNull;
      if (device?.online == true) {
        await _remember(host);
        _result('✓ 已连接 $target');
        return true;
      }
      if (device?.state == 'unauthorized') break;
      if (result.code != 0 ||
          RegExp(
            r'failed to authenticate|cannot connect|failed to connect|unable to connect',
            caseSensitive: false,
          ).hasMatch(result.output)) {
        break;
      }
      if (attempt == 19 || deadline.elapsed >= const Duration(seconds: 10)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (_closed) return false;
    }
    final output = result.output.toLowerCase();
    _result(switch (device?.state) {
      'unauthorized' => '设备未授权：请在目标设备确认调试授权；无线调试请重新配对，再使用连接端口连接。',
      'offline' => '设备离线：请确认无线调试仍开启，再断开此设备并用当前连接端口重连。',
      _ when output.contains('authenticate') => 'ADB 认证失败：请在无线调试中重新配对，再连接。',
      _ when output.contains('refused') => '连接被拒绝：请开启无线调试，并使用主页上的连接端口。',
      _ when output.contains('timed out') || result.code == -1 =>
        '连接超时：请检查设备地址、网络和无线调试状态。',
      _ => '设备尚未上线，请查看终端输出并核对无线调试的连接端口',
    }, error: true);
    return false;
  });

  Future<bool> disconnect(String serial) => _action(() async {
    final result = await _run('adb disconnect ${shQuote(serial)}');
    if (_closed) return false;
    final read = await _read();
    if (_closed) return false;
    final ok =
        result.code == 0 && read && !devices.any((d) => d.serial == serial);
    _result(
      ok ? '已断开 $serial；配对授权仍保留。' : '无法确认设备已断开，请查看终端输出并刷新设备。',
      error: !ok,
    );
    return ok;
  });

  Future<void> _remember(String host, {bool? paired}) async {
    final preferences = _preferences;
    host = host.trim().isEmpty ? '127.0.0.1' : host.trim();
    try {
      await preferences.update(
        adbHost: host,
        adbPaired:
            paired ?? (preferences.adbHost == host && preferences.adbPaired),
      );
    } catch (error) {
      if (!_closed) _log.log.warn('连接结果已生效，但设备设置保存失败： $error');
    }
  }

  void _result(String text, {bool error = false}) {
    if (_closed) return;
    message = text;
    messageIsError = error;
    _notify();
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    ++_revision;
    unawaited(console?.close());
    super.dispose();
  }
}

enum AdbAutoResult { connected, needsPairing, unavailable }

/// 自动连接本机无线调试: 上次端口快试 → NSD 发现当前端口 → 逐个 adb connect。
/// 配对(授权)是永久的, 变的只是端口; 这里把"读端口-手输-连接"整个自动化。
/// 命令与结果写进调用方的 [console]; 端口记忆读写 [preferences]。
Future<AdbAutoResult> autoConnectAdb({
  required ConsoleSession console,
  required AppearancePreferences preferences,
}) async {
  final c = console;
  final prefs = preferences;
  StreamSubscription<String>? watch;
  var output = '';
  try {
    watch = c.textStream.listen((chunk) {
      output = (output + chunk).substring(
        output.length + chunk.length > 8192
            ? output.length + chunk.length - 8192
            : 0,
      );
    });
    String clean() => output.replaceAll('\r', '');

    /// `	device` 行 = 已授权就绪; unauthorized = 在广播但没配对
    Future<({bool ready, bool unauthorized})> deviceState() async {
      output = '';
      if (c.disposed) return (ready: false, unauthorized: false);
      await c.run('adb devices', timeout: const Duration(seconds: 20));
      final text = clean();
      return (
        ready: RegExp(r'^[\d.]+:\d+\tdevice$', multiLine: true).hasMatch(text),
        unauthorized: text.contains('\tunauthorized'),
      );
    }

    // 0) 已有就绪设备就直接用(自连/局域网都算)
    if ((await deviceState()).ready) return AdbAutoResult.connected;

    // 1) 上次成功过的端口: 无线调试不重开就不变, 命中即秒连
    final candidates = <String>[];
    final last = prefs.adbConnectPort.trim();
    if (last.isNotEmpty) candidates.add(last);
    // 2) NSD 发现当前端口(本机过滤在原生侧做)
    final found = await FlitDevice.discoverAdb(
      timeout: const Duration(seconds: 6),
    );
    for (final service in found) {
      if (!candidates.contains(service.port)) candidates.add(service.port);
    }

    var unauthorized = false;
    for (final port in candidates) {
      if (c.disposed) return AdbAutoResult.unavailable;
      output = '';
      await c.run(
        'adb connect 127.0.0.1:$port',
        timeout: const Duration(seconds: 15),
      );
      final text = clean();
      if (text.contains('unauthorized') ||
          text.contains('failed to authenticate')) {
        unauthorized = true;
        break;
      }
      final state = await deviceState();
      if (state.ready) {
        // 端口记忆是尽力而为: 存储不可用不影响"已连接"这个事实
        try {
          await prefs.update(
            adbConnectPort: port,
            adbHost: '127.0.0.1',
            adbPaired: true,
          );
        } catch (_) {}
        return AdbAutoResult.connected;
      }
      if (state.unauthorized) {
        unauthorized = true;
        break;
      }
    }
    if (unauthorized) return AdbAutoResult.needsPairing;
    // 端口在广播 = 无线调试开着, 连不上多半是没配对; 什么都不广播 = 没开
    return found.isEmpty
        ? AdbAutoResult.unavailable
        : AdbAutoResult.needsPairing;
  } catch (_) {
    return AdbAutoResult.unavailable;
  } finally {
    await watch?.cancel();
  }
}
