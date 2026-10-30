import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flit_device/flit_device.dart';
import 'package:provider/provider.dart';

import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../../services/adb_ops.dart';
import '../settings/appearance_preferences.dart';
import '../terminal/console_session.dart';
import '../terminal/terminal_host.dart';
import 'device_connection.dart';

/// 本机优先：扫描连接 + 通知配对。手动输入用于分屏或其他设备，独立于本机
/// 通知服务。页面只轮询服务状态；离开页面也不打断用户在系统窗口中的配对。
class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key, this.autoConnectOnOpen = true});
  final bool autoConnectOnOpen;
  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage>
    with WidgetsBindingObserver {
  late final DeviceConnection _connection;
  late final AppearancePreferences _prefs;
  late final TextEditingController _host;
  final _pairPort = TextEditingController();
  final _pairCode = TextEditingController();
  final _connPort = TextEditingController();
  bool _expanded = false;
  bool _pairDiscovering = false;
  bool _startingPairing = false;
  bool _readingPairing = false;
  bool _foreground = true;
  String _pairingState = 'idle';
  String? _pairingMessage;
  String? _pageError;
  int _handledPairing = 0;
  int _scanGeneration = 0;
  Timer? _poll;
  bool get _notificationActive =>
      {'searching', 'ready', 'pairing'}.contains(_pairingState);
  bool get _blocked =>
      _connection.busy || _notificationActive || _startingPairing;
  String get _hostname =>
      _host.text.trim().isEmpty ? '127.0.0.1' : _host.text.trim();
  bool get _local =>
      {'127.0.0.1', 'localhost', '::1', '[::1]'}.contains(_hostname);
  bool get _paired => _prefs.adbPaired && _prefs.adbHost == _hostname;

  @override
  void initState() {
    super.initState();
    _prefs = context.read<AppearancePreferences>();
    _host = TextEditingController(text: _prefs.adbHost);
    _connection = DeviceConnection(
      launcher: context.read<ProcessLauncher>(),
      preferences: _prefs,
    );
    _connection.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _connection.refresh();
    if (!mounted) return;
    final paired = await _readPairingStatus();
    if (mounted &&
        !paired &&
        widget.autoConnectOnOpen &&
        !_blocked &&
        !_connection.missing) {
      await _connection.autoConnect();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (_notificationActive && mounted && _foreground) {
      _poll = Timer(
        const Duration(seconds: 1),
        () => unawaited(_readPairingStatus()),
      );
    }
  }

  Future<bool> _readPairingStatus() async {
    if (_readingPairing) return false;
    _readingPairing = true;
    try {
      final status = await FlitDevice.pairingStatus();
      if (!mounted) return false;
      final state = status['state'] as String? ?? 'idle';
      final revision = status['revision'] as int? ?? 0;
      setState(() {
        _pairingState = state;
        _pairingMessage = status['message'] as String?;
      });
      if (state == 'success' &&
          revision > _handledPairing &&
          !_connection.busy) {
        _handledPairing = revision;
        try {
          await _prefs.update(
            adbHost: '127.0.0.1',
            adbPaired: true,
            adbConnectPort: _prefs.adbHost == '127.0.0.1'
                ? _prefs.adbConnectPort
                : '',
          );
        } catch (_) {}
        if (!mounted) return false;
        _host.text = '127.0.0.1';
        await _connection.autoConnect();
        return true;
      }
    } catch (error) {
      if (mounted && _notificationActive) {
        setState(() => _pageError = '无法读取配对状态，请返回后重试');
      }
    } finally {
      _readingPairing = false;
      if (mounted) _schedulePoll();
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(_connection.refresh());
      unawaited(_readPairingStatus());
    } else {
      _poll?.cancel();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    ++_scanGeneration;
    WidgetsBinding.instance.removeObserver(this);
    _connection.removeListener(_changed);
    _connection.dispose();
    for (final c in [_host, _pairPort, _pairCode, _connPort]) {
      c.dispose();
    }
    super.dispose();
  }

  void _error(Object error) {
    if (!mounted) return;
    setState(
      () => _pageError = error is PlatformException
          ? error.message ?? '系统操作失败'
          : '$error',
    );
  }

  Future<void> _openSettings() async {
    try {
      await FlitDevice.openWirelessSettings();
    } catch (error) {
      _error(error);
    }
  }

  Future<void> _notificationPair() async {
    if (_blocked) return;
    _connection.clearMessage();
    setState(() {
      _startingPairing = true;
      _pageError = null;
    });
    try {
      await FlitDevice.startPairing();
      if (!mounted) return;
      setState(() {
        _pairingState = 'searching';
        _pairingMessage = '打开系统配对码窗口，在通知中输入配对码';
      });
      _schedulePoll();
      await _openSettings();
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _startingPairing = false);
    }
  }

  Future<void> _stopPairing() async {
    try {
      await FlitDevice.stopPairing();
      if (mounted) {
        setState(() {
          _pairingState = 'idle';
          _pairingMessage = null;
        });
      }
      _poll?.cancel();
    } catch (error) {
      _error(error);
    }
  }

  Future<void> _pair() async {
    setState(() => _pageError = null);
    FocusScope.of(context).unfocus();
    final host = _hostname;
    final paired = await _connection.pair(host, _pairPort.text, _pairCode.text);
    if (paired && mounted) {
      _pairCode.clear();
      // 通知配对/自动扫描仅服务于本机；远程配对不能错误地连接 127.0.0.1。
      if (_local) {
        await _connection.autoConnect();
      } else if (_connPort.text.trim().isNotEmpty) {
        await _connection.connect(host, _connPort.text);
      }
    }
  }

  Future<void> _discoverPairPort() async {
    if (_blocked || _pairDiscovering || !_local) return;
    final generation = ++_scanGeneration;
    final host = _hostname;
    setState(() {
      _pairDiscovering = true;
      _pageError = null;
      _pairPort.clear();
    });
    try {
      final found = await FlitDevice.discoverAdb(
        service: FlitDevice.adbPairingService,
        timeout: const Duration(seconds: 12),
      );
      if (!mounted || generation != _scanGeneration || host != _hostname) {
        return;
      }
      setState(() {
        if (found.isEmpty) {
          _pageError = '未发现配对端口，请保持系统配对窗口开启';
        } else {
          _pairPort.text = found.first.port;
        }
      });
    } catch (error) {
      if (mounted && generation == _scanGeneration) _error(error);
    } finally {
      if (mounted && generation == _scanGeneration) {
        setState(() => _pairDiscovering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('连接设备'),
      actions: [
        IconButton(
          tooltip: '刷新设备',
          onPressed: _blocked || _connection.refreshing
              ? null
              : _connection.refresh,
          icon: const Icon(Icons.refresh, size: 20),
        ),
      ],
    ),
    body: TerminalHost(
      session: _connection.console,
      running: _connection.busy,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: PageList(
        children: [
          const SizedBox(height: 8),
          _deviceCard(),
          if (_pageError != null || _connection.message != null) ...[
            const SizedBox(height: 12),
            StatusNotice(
              _pageError ?? _connection.message!,
              error: _pageError != null || _connection.messageIsError,
            ),
          ],
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本机无线调试',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  '已配对直接连接，首次使用先配对。',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _blocked || _connection.missing
                        ? null
                        : () {
                            setState(() => _pageError = null);
                            unawaited(_connection.autoConnect());
                          },
                    icon: _connection.busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.radar, size: 18),
                    label: Text(_connection.busy ? '连接中…' : '扫描并连接'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: .12),
                      foregroundColor: AppColors.accent,
                    ),
                    onPressed: _blocked || _connection.missing
                        ? null
                        : _notificationPair,
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                    ),
                    label: const Text('通知配对'),
                  ),
                ),
                if (_notificationActive || _pairingState == 'failed') ...[
                  const SizedBox(height: 12),
                  Text(
                    _pairingMessage ?? '正在寻找配对端口…',
                    style: TextStyle(
                      fontSize: 12,
                      color: _pairingState == 'failed'
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (_notificationActive)
                    Row(
                      children: [
                        const Expanded(
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                        TextButton(
                          onPressed: _stopPairing,
                          child: const Text('取消配对'),
                        ),
                      ],
                    ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('无线调试设置'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              key: const PageStorageKey('manual-adb'),
              maintainState: true,
              title: const Text('手动连接 / 其他设备', style: TextStyle(fontSize: 13)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                TextField(
                  key: const PageStorageKey('adb-host-input'),
                  controller: _host,
                  enabled: !_blocked,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '设备地址',
                    hintText: '127.0.0.1',
                  ),
                  onChanged: (_) {
                    ++_scanGeneration;
                    _pairDiscovering = false;
                    _pairPort.clear();
                    _connection.clearMessage();
                    setState(() => _pageError = null);
                  },
                ),
                const SizedBox(height: 12),
                _numberField(_connPort, '连接端口'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _blocked || _connection.missing
                        ? null
                        : () {
                            setState(() => _pageError = null);
                            FocusScope.of(context).unfocus();
                            _connection.connect(_hostname, _connPort.text);
                          },
                    child: const Text('连接'),
                  ),
                ),
                const Divider(height: 28),
                if (_paired)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '有配对记录',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '手动配对时请分屏保留系统配对窗口。',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numberField(_pairPort, '配对端口')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(_pairCode, '配对码（6 位）', length: 6),
                    ),
                  ],
                ),
                if (_local)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _blocked || _pairDiscovering
                          ? null
                          : _discoverPairPort,
                      icon: const Icon(Icons.radar, size: 16),
                      label: Text(_pairDiscovering ? '扫描中…' : '扫描配对端口'),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _blocked || _connection.missing ? null : _pair,
                    child: const Text('配对'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text('连接帮助', style: TextStyle(fontSize: 13)),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Android 11 及以上：开启无线调试 → 使用配对码配对设备 → 下拉通知输入配对码。\n连接端口和配对端口不同；重新开启无线调试后请重新扫描。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () async {
                      try {
                        await FlitDevice.openNotificationSettings();
                      } catch (e) {
                        _error(e);
                      }
                    },
                    child: const Text('通知设置'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await FlitDevice.requestIgnoreBatteryOptimizations();
                      } catch (e) {
                        _error(e);
                      }
                    },
                    child: const Text('允许后台运行'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    int length = 5,
  }) => TextField(
    key: PageStorageKey('adb-input-$label'),
    controller: controller,
    enabled: !_blocked,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(length),
    ],
    decoration: InputDecoration(labelText: label),
  );
  Widget _deviceCard() => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.devices_outlined,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '设备状态',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${_connection.devices.where((d) => d.online).length} 台在线',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (_connection.refreshing)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 12),
        if (_connection.readError != null)
          StatusNotice(_connection.readError!, error: true)
        else if (_connection.missing)
          const StatusNotice('未找到 ADB，请在“开发环境”中安装 Android 工具链。', error: true)
        else if (_connection.devices.isEmpty)
          const Text(
            '暂无连接',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        for (final device in _connection.devices)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  device.online
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 18,
                  color: device.online ? AppColors.success : AppColors.warn,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AdbOps.describe(device.serial, device.model).$1),
                      const SizedBox(height: 4),
                      Text(
                        '${device.serial} · ${device.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (device.serial.contains(':') ||
                    device.serial.contains('._adb-tls-connect.'))
                  IconButton(
                    tooltip: '断开 ${device.serial}',
                    onPressed: _connection.busy
                        ? null
                        : () {
                            setState(() => _expanded = true);
                            _connection.disconnect(device.serial);
                          },
                    icon: const Icon(Icons.link_off, size: 20),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
