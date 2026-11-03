import 'package:flit/l10n/strings.dart';
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
          SnackBar(
            content: Text(context.strings.unableToOpenBrowserVisitGithubCom),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.strings.failedToOpenBrowserP(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.strings.signInToGithub),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.strings.copyTheDeviceCodeAndAuthorizeIn,
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
        child: Text(
          widget.onCancel == null
              ? context.strings.later
              : context.strings.cancelSignIn,
        ),
      ),
      FilledButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.open_in_browser, size: 18),
        label: Text(context.strings.copyAndOpenBrowser),
      ),
    ],
  );
}
