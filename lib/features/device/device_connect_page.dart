import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flit_device/flit_device.dart';
import 'package:provider/provider.dart';

import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../../services/adb_ops.dart';
import '../../services/adb_connection_method.dart';
import '../settings/appearance_preferences.dart';
import '../terminal/console_session.dart';
import '../terminal/terminal_host.dart';
import 'device_connection.dart';
import 'device_usb_guide.dart';
import 'device_pairing_guide_page.dart';

/// 状态 + 两种激活方式，详细步骤按需打开。无线配对服务独立于页面生命周期；
/// USB 激活直接连接回环地址，不依赖 Wi-Fi 或端口发现。
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
  AdbConnectionMethod? _connectingMethod;
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
    _handledPairing = _prefs.adbPairingRevision;
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
        _prefs.adbConnectPort.isNotEmpty &&
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
            adbPairingRevision: revision,
            adbConnectionMethod: AdbConnectionMethod.wireless,
            adbConnectPort:
                _prefs.adbHost == '127.0.0.1' &&
                    _prefs.adbConnectionMethod == AdbConnectionMethod.wireless
                ? _prefs.adbConnectPort
                : '',
          );
        } catch (_) {}
        if (!mounted) return false;
        _host.text = '127.0.0.1';
        await _connect(AdbConnectionMethod.wireless);
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
        await _connect(AdbConnectionMethod.wireless);
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
      title: const Text('设备连接'),
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
          _wirelessCard(),
          const SizedBox(height: 12),
          _usbCard(),
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
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.help_outline, size: 20),
            title: const Text('无线配对指南', style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              '通知样式、配对步骤与常见问题',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _showPairingGuide,
          ),
        ],
      ),
    ),
  );

  Future<void> _connect(AdbConnectionMethod method) async {
    if (_blocked || _connection.missing) return;
    setState(() {
      _pageError = null;
      _connectingMethod = method;
    });
    try {
      await _connection.autoConnect(method: method);
    } finally {
      if (mounted) setState(() => _connectingMethod = null);
    }
  }

  Future<void> _showPairingGuide() async {
    final start = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DevicePairingGuidePage(
          allowStart: !_blocked && !_connection.missing,
        ),
      ),
    );
    // 阅读指南或返回上一页不会启动服务；真实开始仍由同一入口串行处理。
    if (mounted && start == true) await _notificationPair();
  }

  Future<void> _showUsbGuide() async {
    final connect = await showDialog<bool>(
      context: context,
      builder: (_) => const DeviceUsbGuide(),
    );
    if (mounted && connect == true) await _connect(AdbConnectionMethod.usb);
  }

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? trailing,
  }) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _wirelessCard() => _methodCard(
    icon: Icons.wifi,
    title: '通过无线调试连接',
    subtitle: 'Android 11+ · Wi-Fi 下配对与连接',
    trailing: IconButton(
      tooltip: '无线调试设置',
      onPressed: _openSettings,
      icon: const Icon(Icons.settings_outlined, size: 20),
    ),
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: .12),
                foregroundColor: AppColors.accent,
              ),
              onPressed: _blocked || _connection.missing
                  ? null
                  : _showPairingGuide,
              child: const Text('通知配对'),
            ),
            FilledButton(
              onPressed: _blocked || _connection.missing
                  ? null
                  : () => _connect(AdbConnectionMethod.wireless),
              child: Text(
                _connectingMethod == AdbConnectionMethod.wireless
                    ? '扫描中…'
                    : '扫描并连接',
              ),
            ),
          ],
        ),
      ),
      if (_notificationActive || _pairingState == 'failed') ...[
        const SizedBox(height: 12),
        Text(
          _pairingMessage ?? '正在寻找配对端口…',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: _pairingState == 'failed'
                ? AppColors.danger
                : AppColors.textSecondary,
          ),
        ),
        if (_notificationActive)
          Row(
            children: [
              const Expanded(child: LinearProgressIndicator(minHeight: 2)),
              TextButton(onPressed: _stopPairing, child: const Text('取消配对')),
            ],
          ),
      ],
    ],
  );

  Widget _usbCard() => _methodCard(
    icon: Icons.usb,
    title: '通过电脑 USB 激活',
    subtitle: '电脑激活后连接，可拔掉数据线',
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            TextButton(onPressed: _showUsbGuide, child: const Text('查看步骤')),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: .12),
                foregroundColor: AppColors.accent,
              ),
              onPressed: _blocked || _connection.missing
                  ? null
                  : () => _connect(AdbConnectionMethod.usb),
              child: Text(
                _connectingMethod == AdbConnectionMethod.usb ? '连接中…' : '连接本机',
              ),
            ),
          ],
        ),
      ),
    ],
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
                    onPressed: _blocked
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
