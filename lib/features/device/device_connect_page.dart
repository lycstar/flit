import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flit_device/flit_device.dart';
import 'package:provider/provider.dart';

import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../../services/adb_ops.dart';
import '../../services/shell.dart';
import '../settings/appearance_preferences.dart';
import '../terminal/console_session.dart';
import '../terminal/terminal_host.dart';
import 'device_connection.dart';

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key, this.autoConnectOnOpen = true});

  /// 测试缝: 打开页面即自动连接会带着 fake-clock 里永不结束的会话,
  /// 掐死后续交互; 测试构造时关掉, 自动连接本身有专属单测。
  final bool autoConnectOnOpen;

  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage>
    with WidgetsBindingObserver {
  late final DeviceConnection _connection;
  late final AppearancePreferences _prefs;
  late final TextEditingController _host;
  bool _pairDiscovering = false;
  bool _batteryIgnoring = true; // 查询失败按已忽略处理(不弹提示)
  final _pairPort = TextEditingController();
  final _pairCode = TextEditingController();
  final _connPort = TextEditingController();
  bool _expanded = false;

  bool get _paired => _prefs.adbPaired && _prefs.adbHost == _hostname;
  String get _hostname =>
      _host.text.trim().isEmpty ? '127.0.0.1' : _host.text.trim();

  @override
  void initState() {
    super.initState();
    _prefs = context.read<AppearancePreferences>();
    _connection = DeviceConnection(
      launcher: context.read<ProcessLauncher>(),
      preferences: _prefs,
    );
    _host = TextEditingController(text: _prefs.adbHost);
    WidgetsBinding.instance.addObserver(this);
    _connection.addListener(_changed);
    _initialize();
  }

  Future<void> _initialize() async {
    _batteryIgnoring = await FlitDevice.isIgnoringBatteryOptimizations()
        .catchError((_) => true);
    if (!mounted) return;
    await _connection.refresh();
    // 进页即自动连接: 已配对秒连; 未配对页面停在配对流程并给出引导
    if (widget.autoConnectOnOpen && mounted && !_connection.busy) {
      unawaited(_connection.autoConnect());
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _connection.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connection.removeListener(_changed);
    _connection.dispose();
    for (final controller in [_host, _pairPort, _pairCode, _connPort]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _pairStep(int n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          child: Text(
            '$n',
            style: const TextStyle(fontSize: 11, color: AppColors.accent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _openSettings() async {
    try {
      if (await Shell.instance.openSettings(
        'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
      )) {
        return;
      }
    } catch (_) {
      /* Some vendors do not expose this intent. */
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请在系统设置中手动打开开发者选项 → 无线调试')));
    }
  }

  Future<void> _pair() async {
    FocusScope.of(context).unfocus();
    setState(() => _expanded = true);
    final paired = await _connection.pair(
      _hostname,
      _pairPort.text,
      _pairCode.text,
    );
    if (paired && mounted) {
      _pairCode.clear();
      // 配对授权是永久的, 立刻自动发现连接端口并连上, 用户不用再抄端口
      unawaited(_connection.autoConnect());
    }
  }

  /// 系统配对弹窗开着时, 本机会广播 _adb-tls-pairing._tcp: 发现即自动填端口
  Future<void> _discoverPairPort() async {
    setState(() => _pairDiscovering = true);
    final found = await FlitDevice.discoverAdb(
      service: FlitDevice.adbPairingService,
      timeout: const Duration(seconds: 12),
    );
    if (!mounted) return;
    setState(() {
      _pairDiscovering = false;
      if (found.isNotEmpty) _pairPort.text = found.first.port;
    });
  }

  void _connect() {
    FocusScope.of(context).unfocus();
    setState(() => _expanded = true);
    _connection.connect(_hostname, _connPort.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('连接设备'),
      actions: [
        IconButton(
          tooltip: '刷新设备',
          onPressed: _connection.busy || _connection.refreshing
              ? null
              : _connection.refresh,
          icon: const Icon(Icons.refresh),
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
          const PageIntro('无线调试', '连接本机或同一网络的 Android 设备。首次使用先配对，再用连接端口连接。'),
          _deviceCard(),
          // 操作反馈放顶部: 页面长(自动连接卡片+两段表单), 底部通知会被视口裁掉
          if (_connection.message != null) ...[
            StatusNotice(
              _connection.message!,
              error: _connection.messageIsError,
            ),
            const SizedBox(height: 12),
          ],
          const SectionLabel('自动连接'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '自动发现本机无线调试的当前端口并连接，无需手输端口（无线调试需开启）。'
                  '未配对时会引导你完成配对，配对端口也会自动填入。',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _connection.busy || _connection.missing
                        ? null
                        : () => unawaited(_connection.autoConnect()),
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('自动连接本机'),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('设备地址'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _host,
                  enabled: !_connection.busy,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  onChanged: (_) {
                    _connection.clearMessage();
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: '设备地址',
                    hintText: '127.0.0.1',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '本机使用 127.0.0.1；其他设备使用无线调试页面显示的 IP 地址。',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                TextButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('打开开发者选项'),
                ),
              ],
            ),
          ),
          const SectionLabel('1 · 配对授权'),
          if (!_batteryIgnoring)
            Material(
              color: AppColors.warn.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.battery_alert,
                          size: 16,
                          color: AppColors.warn,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '部分系统（如 MIUI）会在应用切到后台时限制网络甚至冻结应用，导致自动发现端口失败。',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warn,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: () =>
                            FlitDevice.requestIgnoreBatteryOptimizations(),
                        child: const Text('关闭电池优化'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_paired) ...[
                  const Text(
                    '有配对记录',
                    style: TextStyle(color: AppColors.success),
                  ),
                  const SizedBox(height: 8),
                ],
                _pairStep(1, '打开「开发者选项 → 无线调试」，点按左侧整行进入详情页并开启（仅开右侧开关是错误的）。'),
                Row(
                  children: [
                    const SizedBox(width: 6),
                    FilledButton.tonal(
                      onPressed: _openSettings,
                      child: const Text('开发者选项'),
                    ),
                  ],
                ),
                _pairStep(2, '点「使用配对码配对设备」并保持系统弹窗开启 —— 回到 Flit 后配对端口会自动填入。'),
                _pairStep(3, '输入 6 位配对码，点「配对」，完成后自动连接。'),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _numberField(_pairPort, '配对端口')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(_pairCode, '配对码（6 位）', length: 6),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _pairDiscovering ? null : _discoverPairPort,
                  icon: _pairDiscovering
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.radar, size: 16),
                  label: Text(
                    _pairDiscovering ? '发现中…（保持系统配对弹窗开启）' : '自动发现配对端口',
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _connection.busy || _connection.missing
                        ? null
                        : _pair,
                    child: const Text('配对'),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('2 · 连接设备'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '使用「无线调试」主页的端口，与配对端口不同。重新开启无线调试后，端口可能变化。',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                _numberField(_connPort, '连接端口'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _connection.busy || _connection.missing
                        ? null
                        : _connect,
                    icon: const Icon(Icons.phonelink_setup, size: 18),
                    label: const Text('连接'),
                  ),
                ),
              ],
            ),
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
    controller: controller,
    enabled: !_connection.busy,
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
            '暂无设备。配对并连接后可查看设备状态。',
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
