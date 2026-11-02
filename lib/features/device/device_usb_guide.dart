import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/shell.dart';
import 'device_connection.dart';

class DeviceUsbGuide extends StatefulWidget {
  const DeviceUsbGuide({super.key, required this.connection});
  final DeviceConnection connection;

  @override
  State<DeviceUsbGuide> createState() => _DeviceUsbGuideState();
}

class _DeviceUsbGuideState extends State<DeviceUsbGuide>
    with WidgetsBindingObserver {
  bool _windows = true;
  bool _copied = false;
  bool _checking = false;
  bool _foreground = true;
  bool _timedOut = false;
  String _status = 'waiting';
  String? _error;
  Timer? _timer;
  Timer? _expiry;
  int _generation = 0;

  String get _adb => _windows ? r'.\adb.exe' : './adb';
  String get _command => '$_adb -d tcpip 5555';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimeout();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _generation++;
      _timer?.cancel();
    } else {
      _check();
    }
  }

  Future<void> _check({bool restart = false}) async {
    if (!mounted || !_foreground || _checking || _status == 'connected') return;
    _timer?.cancel();
    if (restart) {
      _timedOut = false;
      _startTimeout();
    }
    if (_timedOut) return;
    final generation = _generation;
    setState(() => _checking = true);
    final result = await widget.connection.checkUsb(
      cancelled: () =>
          !mounted || !_foreground || _timedOut || generation != _generation,
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (_foreground && !_timedOut && generation == _generation) {
        _status = result;
      }
    });
    if (_status == 'connected') _expiry?.cancel();
    if (_foreground && !_timedOut && _status != 'connected') {
      _timer = Timer(const Duration(seconds: 2), _check);
    }
  }

  void _startTimeout() {
    _expiry?.cancel();
    _expiry = Timer(const Duration(minutes: 2), () {
      _timer?.cancel();
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _message => _status == 'connected'
      ? '已连接本机，可以拔掉数据线。'
      : _timedOut
      ? '等待超时，请检查电脑命令输出，然后重新连接。'
      : switch (_status) {
          'unauthorized' => '请在手机上允许 USB 调试授权，Flit 会自动继续连接。',
          'failed' => '无法读取 ADB 状态，请检查开发环境；正在重试…',
          _ => '等待电脑激活… Flit 会自动连接本机。',
        };

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('通过电脑 USB 激活'),
    scrollable: true,
    content: SizedBox(
      width: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. 手机开启 USB 调试，用数据线连接电脑，并允许调试授权。电脑只连接这一台手机。'),
          const SizedBox(height: 16),
          const Text('2. 电脑下载并解压 Platform Tools，在解压目录打开终端。'),
          TextButton.icon(
            onPressed: () async {
              try {
                if (!await Shell.instance.openUrl(
                  'https://developer.android.com/tools/releases/platform-tools',
                )) {
                  throw StateError('无法打开下载页面');
                }
              } catch (_) {
                if (mounted) {
                  setState(
                    () => _error =
                        '请在电脑访问 developer.android.com/tools/releases/platform-tools',
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Platform Tools 官网'),
          ),
          const SizedBox(height: 8),
          const Text('3. 在电脑执行这一条命令，然后保持此引导打开，等待连接。'),
          const SizedBox(height: 8),
          DropdownButtonFormField<bool>(
            isExpanded: true,
            initialValue: _windows,
            decoration: const InputDecoration(labelText: '电脑系统'),
            items: const [
              DropdownMenuItem(
                value: true,
                child: Text('Windows · PowerShell'),
              ),
              DropdownMenuItem(value: false, child: Text('macOS / Linux')),
            ],
            onChanged: (value) => setState(() {
              _windows = value ?? true;
              _copied = false;
            }),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _command,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.8,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: _command));
                  if (mounted) setState(() => _copied = true);
                } catch (_) {
                  if (mounted) setState(() => _error = '复制失败，请长按命令复制');
                }
              },
              icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
              label: Text(_copied ? '已复制' : '复制命令'),
            ),
          ),
          const Text(
            '电脑显示 restarting in TCP mode port: 5555 后，Flit 会尝试连接。若手机再次弹出调试授权，请允许。',
          ),
          const SizedBox(height: 16),
          Text(_message),
          if (_error != null) Text(_error!),
          const SizedBox(height: 16),
          const Text('自动等待最多 2 分钟，退出引导即停止。之后仍可在设备页点“连接本机”。手机重启后通常需要重新激活。'),
          const SizedBox(height: 8),
          Text('TCP 调试可能同时监听网络接口。停用时接回电脑执行 $_adb -d usb；Flit 中“断开”仅断开客户端。'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(_status == 'connected' ? '完成' : '关闭'),
      ),
      if (_status != 'connected')
        FilledButton(
          onPressed: _checking ? null : () => _check(restart: true),
          child: Text(_timedOut ? '重新连接' : '立即连接'),
        ),
    ],
  );
}
