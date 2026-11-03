import 'package:flit/l10n/strings.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flit_device/flit_device.dart';

import '../../services/adb_ops.dart';
import '../../services/adb_connection_method.dart';
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
    final session = ConsoleSession(
      title: strings.deviceConnection,
      launcher: _launcher,
    );
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
      throw FormatException(strings.enterAnIpAddressOrHostnameWithout);
    }
    final number = int.tryParse(port.trim());
    if (!RegExp(r'^\d+$').hasMatch(port.trim()) ||
        number == null ||
        number < 1 ||
        number > 65535) {
      throw FormatException(strings.portMustBeBetweenAnd);
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
      readError = strings.unableToReadDevicesSeeTerminalOutput;
      _log.log.err('$readError: $error');
      return false;
    } finally {
      if (!_closed && revision == _revision) {
        refreshing = false;
        _notify();
      }
    }
  }

  Future<({int code, String output})> _run(
    String command, {
    String? displayCommand,
  }) async {
    final c = _log;
    final output = StringBuffer();
    final subscription = c.textStream.listen(output.write);
    try {
      final code = await c.run(
        command,
        displayCommand: displayCommand,
        timeout: const Duration(seconds: 30),
      );
      if (code == -1 && c.exitCode == -1 && !_closed) {
        throw StateError(strings.adbFailedToStartCheckTheDevelopment);
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
          error is FormatException
              ? error.message
              : strings.operationFailedPSeeTerminalForDetails(error),
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
      throw FormatException(strings.enterADigitPairingCode);
    }
    final result = await _run(
      'adb pair ${shQuote(target)} ${shQuote(code.trim())}',
      displayCommand: 'adb pair ${shQuote(target)} ******',
    );
    if (_closed) return false;
    if (result.code != 0 || !result.output.contains('Successfully paired to')) {
      _result(strings.pairingFailedKeepTheSystemPairingDialog, error: true);
      return false;
    }
    await _remember(host, paired: true);
    if (_closed) return false;
    _result(strings.pairedSuccessfully);
    await _read();
    return true;
  });

  /// 进页沿用上次成功方式；无线卡片显式指定 wireless，避免复用 USB 端口。
  Future<bool> autoConnect({AdbConnectionMethod? method}) {
    final selected = method ?? _preferences.adbConnectionMethod;
    if (selected == AdbConnectionMethod.usb) return connectUsb();
    return _action(() async {
      final current = _log;
      final outcome = await autoConnectAdb(
        console: current,
        preferences: _preferences,
        method: selected,
      );
      if (_closed || current.disposed || current.stopRequested) return false;
      switch (outcome) {
        case AdbAutoResult.connected:
          final verified = await _read();
          if (_closed || current.disposed || current.stopRequested) {
            return false;
          }
          if (!verified ||
              !devices.any((d) => _matchesMethod(d, selected) && d.online)) {
            _result(strings.unableToConfirmDeviceIsOnlineRefresh, error: true);
            return false;
          }
          _result(strings.connectedToLocalWirelessDebugging);
          return true;
        case AdbAutoResult.needsAuthorization:
          _result(strings.allowUsbDebuggingOnThePhoneThen, error: true);
          return false;
        case AdbAutoResult.needsPairing:
          _result(strings.pairingRequiredTapNotificationPairing);
          return false;
        case AdbAutoResult.failed:
          _result(
            strings.connectionFailedCheckLogsOrConnectManually,
            error: true,
          );
          return false;
        case AdbAutoResult.unavailable:
          _result(strings.noWirelessPortFoundScanAgainEnter, error: true);
          return false;
      }
    });
  }

  /// 不扫描端口、不发配对命令，也不在手机内执行电脑端的 tcpip 命令。
  /// 只有 127.0.0.1:5555 被确认在线，才记住 USB 激活方式。
  Future<bool> connectUsb() =>
      connect('127.0.0.1', adbUsbPort, method: AdbConnectionMethod.usb);

  Future<String> checkUsb({required bool Function() cancelled}) async {
    if (_closed || cancelled() || busy) return 'waiting';
    ++_revision;
    refreshing = false;
    busy = true;
    _notify();
    try {
      var current = await AdbOps.statuses();
      if (_closed || cancelled()) return 'waiting';
      var device = current
          .where((d) => d.serial == '127.0.0.1:5555')
          .firstOrNull;
      if (device == null ||
          (!device.online && device.state != 'unauthorized')) {
        await Shell.instance.exec(
          '${terminalEnvSource}adb connect 127.0.0.1:5555',
          timeoutMs: 5000,
        );
        if (_closed || cancelled()) return 'waiting';
        current = await AdbOps.statuses();
        if (_closed || cancelled()) return 'waiting';
        device = current.where((d) => d.serial == '127.0.0.1:5555').firstOrNull;
      }
      devices = current;
      if (device?.online == true) {
        await _remember(
          '127.0.0.1',
          paired: false,
          port: adbUsbPort,
          method: AdbConnectionMethod.usb,
        );
        if (_closed || cancelled()) return 'waiting';
        _result(strings.connectedLocallyUsbActivatedYouCanUnplug);
        return 'connected';
      }
      return device?.state == 'unauthorized' ? 'unauthorized' : 'waiting';
    } catch (_) {
      return 'failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> connect(
    String host,
    String port, {
    AdbConnectionMethod method = AdbConnectionMethod.wireless,
  }) => _action(() async {
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
            missing
                ? strings.unableToConfirmConnectionInstallAdbFirst
                : strings.unableToConfirmConnectionFailedToRead,
            error: true,
          );
        }
        return false;
      }
      device = devices.where((d) => d.serial == target).firstOrNull;
      if (device?.online == true) {
        await _remember(
          host,
          paired: method == AdbConnectionMethod.wireless,
          method: method,
          port: int.parse(port.trim()).toString(),
        );
        _result(
          method == AdbConnectionMethod.usb
              ? strings.connectedLocallyUsbActivatedYouCanUnplug
              : strings.connectedToP(target),
        );
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
    if (method == AdbConnectionMethod.usb) {
      _result(switch (device?.state) {
        'unauthorized' => strings.deviceUnauthorizedAllowUsbDebuggingOnThe,
        'offline' => strings.localAdbIsOfflineRunTheActivation,
        _ when output.contains('authenticate') =>
          strings.adbAuthenticationFailedConfirmUsbDebuggingAuthorization,
        _ when output.contains('refused') =>
          strings.notActivatedConnectViaUsbAndRun,
        _ => strings.unableToConnectToLocalPortCheck,
      }, error: true);
      return false;
    }
    _result(switch (device?.state) {
      'unauthorized' =>
        strings.deviceUnauthorizedConfirmAuthorizationOnTheTarget,
      'offline' => strings.deviceOfflineEnableWirelessDebuggingThenDisconnect,
      _ when output.contains('authenticate') =>
        strings.adbAuthenticationFailedPairAgainInWireless,
      _ when output.contains('refused') =>
        strings.connectionRefusedEnableWirelessDebuggingAndUse,
      _ when output.contains('timed out') || result.code == -1 =>
        strings.connectionTimedOutCheckTheAddressNetwork,
      _ => strings.deviceIsNotOnlineCheckTerminalOutput,
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
      ok
          ? strings.disconnectedFromPPairingAuthorizationIsRetained(serial)
          : strings.unableToConfirmDisconnectionCheckTerminalOutput,
      error: !ok,
    );
    return ok;
  });

  Future<void> _remember(
    String host, {
    bool? paired,
    String? port,
    AdbConnectionMethod method = AdbConnectionMethod.wireless,
  }) async {
    final preferences = _preferences;
    host = host.trim().isEmpty ? '127.0.0.1' : host.trim();
    try {
      await preferences.update(
        adbHost: host,
        adbConnectionMethod: method,
        adbConnectPort:
            port ??
            (host == preferences.adbHost &&
                    method == preferences.adbConnectionMethod
                ? preferences.adbConnectPort
                : ''),
        adbPaired:
            paired ?? (preferences.adbHost == host && preferences.adbPaired),
      );
    } catch (error) {
      if (!_closed) {
        _log.log.warn(strings.connectedButFailedToSaveDeviceSettings(error));
      }
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

bool _isLocalAdbDevice(AdbStatus device) =>
    RegExp(r'^(127\.0\.0\.1|localhost|\[::1\]):\d+$').hasMatch(device.serial);

bool _matchesMethod(AdbStatus device, AdbConnectionMethod method) =>
    method == AdbConnectionMethod.usb
    ? device.serial == '127.0.0.1:$adbUsbPort'
    : _isLocalAdbDevice(device) && !device.serial.endsWith(':$adbUsbPort');

enum AdbAutoResult {
  connected,
  needsPairing,
  needsAuthorization,
  unavailable,
  failed,
}

/// 本机连接只认可回环地址的目标设备。缓存端口先尝试，失败再发现；
/// 发现服务不代表已配对，端口拒绝也不代表认证失败。
Future<AdbAutoResult> autoConnectAdb({
  required ConsoleSession console,
  required AppearancePreferences preferences,
  AdbConnectionMethod? method,
}) async {
  final selected = method ?? preferences.adbConnectionMethod;
  final authRequired = selected == AdbConnectionMethod.usb
      ? AdbAutoResult.needsAuthorization
      : AdbAutoResult.needsPairing;
  final c = console;
  bool cancelled() => c.disposed || c.stopRequested;
  Future<({int code, String output})> run(String command) async {
    if (cancelled()) return (code: -1, output: '');
    final output = StringBuffer();
    final subscription = c.textStream.listen(output.write);
    try {
      final code = await c.run(command, timeout: const Duration(seconds: 12));
      return (code: code, output: output.toString().replaceAll('\r', ''));
    } finally {
      await subscription.cancel();
    }
  }

  Future<List<AdbStatus>> devices() async {
    final result = await run('adb devices');
    if (result.code != 0 ||
        !result.output.contains('List of devices attached')) {
      throw StateError(strings.unableToReadAdbDeviceStatus);
    }
    return AdbOps.parseStatuses(result.output);
  }

  Future<AdbAutoResult> connect(String port) async {
    final target = '127.0.0.1:$port';
    final result = await run('adb connect $target');
    if (cancelled()) return AdbAutoResult.unavailable;
    if (result.output.toLowerCase().contains('failed to authenticate')) {
      return authRequired;
    }
    final failed =
        result.code != 0 ||
        RegExp(
          r'cannot connect|failed to connect|unable to connect|refused',
          caseSensitive: false,
        ).hasMatch(result.output);
    for (var i = 0; i < (failed ? 1 : 6); i++) {
      if (cancelled()) return AdbAutoResult.unavailable;
      final targetState = (await devices())
          .where((d) => d.serial == target)
          .firstOrNull;
      if (cancelled()) return AdbAutoResult.unavailable;
      if (targetState?.online == true) {
        try {
          await preferences.update(
            adbHost: '127.0.0.1',
            adbConnectPort: port,
            adbPaired: selected == AdbConnectionMethod.wireless,
            adbConnectionMethod: selected,
          );
        } catch (_) {}
        return AdbAutoResult.connected;
      }
      if (targetState?.state == 'unauthorized') {
        return authRequired;
      }
      if (i < 5 && !failed) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    return AdbAutoResult.failed;
  }

  try {
    final initial = await devices();
    if (cancelled()) return AdbAutoResult.unavailable;
    if (initial.any((d) => _matchesMethod(d, selected) && d.online)) {
      final device = initial.firstWhere(
        (d) => _matchesMethod(d, selected) && d.online,
      );
      try {
        await preferences.update(
          adbHost: '127.0.0.1',
          adbConnectPort: device.serial.split(':').last,
          adbConnectionMethod: selected,
        );
      } catch (_) {}
      return AdbAutoResult.connected;
    }
    // USB 激活没有 mDNS 服务；失败也不切换到无线配对流程。
    if (selected == AdbConnectionMethod.usb) {
      return await connect(adbUsbPort);
    }
    final tried = <String>{};
    var unauthorized = false;
    final last = preferences.adbConnectPort.trim();
    if (preferences.adbConnectionMethod == selected &&
        preferences.adbHost == '127.0.0.1' &&
        RegExp(r'^\d+$').hasMatch(last) &&
        (int.tryParse(last) ?? 0) >= 1 &&
        (int.tryParse(last) ?? 0) <= 65535) {
      tried.add(last);
      c.log.info(strings.tryingPreviousConnectionPortP(last));
      final result = await connect(last);
      if (cancelled()) return AdbAutoResult.unavailable;
      if (result == AdbAutoResult.connected) return result;
      unauthorized = result == AdbAutoResult.needsPairing;
    }
    if (cancelled()) return AdbAutoResult.unavailable;
    c.log.info(strings.scanningLocalWirelessDebuggingPorts);
    final found = await FlitDevice.discoverAdb(
      timeout: const Duration(seconds: 8),
    );
    if (cancelled()) return AdbAutoResult.unavailable;
    for (final service in found) {
      if (!tried.add(service.port)) continue;
      c.log.info(strings.foundConnectionPortP(service.port));
      final result = await connect(service.port);
      if (cancelled()) return AdbAutoResult.unavailable;
      if (result == AdbAutoResult.connected) return result;
      unauthorized |= result == AdbAutoResult.needsPairing;
    }
    if (unauthorized) return authRequired;
    return found.isEmpty ? AdbAutoResult.unavailable : AdbAutoResult.failed;
  } catch (error) {
    if (!cancelled()) c.log.err(strings.scanOrConnectionFailedP(error));
    return AdbAutoResult.failed;
  }
}
