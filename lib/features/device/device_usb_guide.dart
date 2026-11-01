import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flit_device/flit_device.dart';

import '../../core/theme.dart';
import '../../services/shell.dart';

/// 电脑上的命令只展示/复制，绝不交给手机终端执行。
/// 参考 Shizuku 的启动脚本形态：App 把内置 flit-usb.sh 写入自身外部 files
/// 目录，电脑执行一条 `adb shell sh <路径>`；脚本输出会说明结果，12+ 等
/// 不支持的系统回落到脚本/备用命令里的 `adb -d tcpip 5555`。
class DeviceUsbGuide extends StatefulWidget {
  const DeviceUsbGuide({super.key});

  @override
  State<DeviceUsbGuide> createState() => _DeviceUsbGuideState();
}

class _DeviceUsbGuideState extends State<DeviceUsbGuide> {
  static const _asset = 'assets/device/flit-usb.sh';
  bool _windows = true;
  bool _copied = false;
  bool _showFallback = false;
  String? _path;
  String? _error;

  String get _adb => _windows ? r'.\adb.exe' : './adb';

  /// 主命令：电脑只需执行这一条，脚本负责激活并输出结果说明。
  String? get _scriptCommand => _path == null ? null : '$_adb shell sh $_path';

  /// 备用命令：任何系统都可用，脚本写入失败或 Android 12+ 时使用。
  String get _fallbackCommands => '$_adb devices\n$_adb -d tcpip 5555';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final content = await rootBundle.loadString(_asset);
      final path = await FlitDevice.writeUsbScript(content);
      if (!mounted) return;
      setState(() => _path = path);
    } catch (_) {
      if (mounted) setState(() => _error = '激活脚本写入失败，请使用下方备用命令');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('通过电脑 USB 激活'),
    scrollable: true,
    content: SizedBox(
      width: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. 手机开启 USB 调试，用数据线连接电脑，并允许调试授权。'),
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
          const Text('3. 在电脑执行这一条命令（脚本会输出激活结果）：'),
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
          _CommandBox(
            command: _scriptCommand,
            emptyHint: _error ?? '正在准备激活脚本…',
            copied: _copied,
            onCopy: _scriptCommand == null ? null : _copy,
          ),
          const Text(
            '脚本输出 "TCP port set" 即已请求激活：拔插一次数据线，返回 Flit 点'
            '"已执行，连接本机"。输出 "Android 12+" 字样表示系统不允许设备端激'
            '活，请展开下方备用命令在电脑执行。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showFallback = !_showFallback),
            icon: Icon(
              _showFallback ? Icons.expand_less : Icons.expand_more,
              size: 16,
            ),
            label: const Text('备用：直接执行激活命令'),
          ),
          if (_showFallback) ...[
            _CommandBox(
              command: _fallbackCommands,
              emptyHint: '',
              copied: _copied,
              onCopy: _copy,
            ),
            const Text(
              '设备列表显示 device，激活命令显示 restarting in TCP mode port: 5555 '
              '后，返回 Flit 连接。若手机再次弹出授权，请允许后重试。',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            '连接成功后可拔线，通常无需 Wi-Fi。手机重启后需重新激活；部分厂商系统'
            '可能限制此方式。电脑只连接这一台手机。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TCP 调试可能同时监听网络接口。停用时接回电脑执行 $_adb -d usb；Flit 中'
            '"断开"仅断开客户端。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('关闭'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('已执行，连接本机'),
      ),
    ],
  );

  Future<void> _copy() async {
    final text = _scriptCommand ?? _fallbackCommands;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) setState(() => _copied = true);
    } catch (_) {
      if (mounted) setState(() => _error = '复制失败，请长按命令复制');
    }
  }
}

/// 命令展示框：命令为空时显示占位说明。
class _CommandBox extends StatelessWidget {
  const _CommandBox({
    required this.command,
    required this.emptyHint,
    required this.copied,
    required this.onCopy,
  });

  final String? command;
  final String emptyHint;
  final bool copied;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          command ?? emptyHint,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.8,
          ),
        ),
      ),
      if (command != null)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onCopy,
            icon: Icon(copied ? Icons.check : Icons.copy, size: 16),
            label: Text(copied ? '已复制' : '复制命令'),
          ),
        ),
    ],
  );
}
