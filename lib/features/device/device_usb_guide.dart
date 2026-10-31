import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/shell.dart';

/// 电脑上的命令只展示/复制，绝不交给手机终端执行。
/// -d 限定 USB 设备，避免误操作电脑上已有的网络 ADB 连接。
class DeviceUsbGuide extends StatefulWidget {
  const DeviceUsbGuide({super.key});

  @override
  State<DeviceUsbGuide> createState() => _DeviceUsbGuideState();
}

class _DeviceUsbGuideState extends State<DeviceUsbGuide> {
  bool _windows = true;
  bool _copied = false;
  String? _error;
  String get _adb => _windows ? r'.\adb.exe' : './adb';
  String get _commands => '$_adb devices\n$_adb -d tcpip 5555';

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
          const Text('3. 在电脑依次执行：'),
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
              _commands,
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
                  await Clipboard.setData(ClipboardData(text: _commands));
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
            '设备列表显示 device，激活命令显示 restarting in TCP mode port: 5555 后，返回 Flit 连接。若手机再次弹出授权，请允许后重试。',
          ),
          const SizedBox(height: 16),
          const Text(
            '连接成功后可拔线，通常无需 Wi-Fi。手机重启后需重新激活；部分厂商系统可能限制此方式。电脑只连接这一台手机。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TCP 调试可能同时监听网络接口。停用时接回电脑执行 $_adb -d usb；Flit 中“断开”仅断开客户端。',
            style: const TextStyle(
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
}
