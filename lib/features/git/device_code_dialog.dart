import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/shell.dart';

/// Device Flow 授权码对话框: 复制授权码 → 浏览器授权; 登录结束(code 置空)自动关闭。
/// 返回键 = 稍后处理(登录在后台继续, 账户行可再「查看授权码」); [onCancel] 真正取消登录。
Future<void> showDeviceCodeDialog(
  BuildContext context,
  ValueListenable<String?> code, {
  Future<void> Function()? onCancel,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DeviceCodeDialog(code: code, onCancel: onCancel),
);

class _DeviceCodeDialog extends StatefulWidget {
  const _DeviceCodeDialog({required this.code, this.onCancel});
  final ValueListenable<String?> code;
  final Future<void> Function()? onCancel;
  @override
  State<_DeviceCodeDialog> createState() => _DeviceCodeDialogState();
}

class _DeviceCodeDialogState extends State<_DeviceCodeDialog> {
  @override
  void initState() {
    super.initState();
    widget.code.addListener(_changed);
  }

  void _changed() {
    if (widget.code.value == null && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.code.removeListener(_changed);
    super.dispose();
  }

  Future<void> _open() async {
    final code = widget.code.value;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    try {
      if (!await Shell.instance.openUrl('https://github.com/login/device') &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开浏览器，请访问 github.com/login/device')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开浏览器失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('登录 GitHub'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '复制设备授权码后，在浏览器中授权。完成后自动更新登录状态。',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SelectableText(
          widget.code.value ?? '',
          style: const TextStyle(
            fontSize: 26,
            fontFamily: 'monospace',
            color: AppColors.accent,
            letterSpacing: 2,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          widget.onCancel?.call();
          Navigator.pop(context);
        },
        child: Text(widget.onCancel == null ? '稍后处理' : '取消登录'),
      ),
      FilledButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.open_in_browser, size: 18),
        label: const Text('复制并打开浏览器'),
      ),
    ],
  );
}
