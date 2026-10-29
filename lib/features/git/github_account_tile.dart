import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import 'device_code_dialog.dart';
import 'github_account.dart';

/// 「GitHub 账户」一行: 状态 + 登录/退出。登录中弹授权码对话框, 失败用 SnackBar 报错。
/// 克隆页、设置页、版本控制面板共用——登录入口不再只藏在某个工程的抽屉里。
class GithubAccountTile extends StatefulWidget {
  const GithubAccountTile({super.key, this.dense = false, this.enabled = true});
  final bool dense;
  final bool enabled;

  @override
  State<GithubAccountTile> createState() => _GithubAccountTileState();
}

class _GithubAccountTileState extends State<GithubAccountTile> {
  late final GithubAccount _account;
  bool _dialogOpen = false;
  String? _shownError;

  @override
  void initState() {
    super.initState();
    _account = context.read<GithubAccount>();
    // 重建由 build 里的 watch 负责; 这两个监听只做副作用(报错、弹授权码)
    _account.addListener(_reportError);
    _account.deviceCode.addListener(_onCode);
    _account.refresh();
  }

  @override
  void dispose() {
    _account.removeListener(_reportError);
    _account.deviceCode.removeListener(_onCode);
    super.dispose();
  }

  void _reportError() {
    if (!mounted) return;
    final error = _account.error;
    if (error != null && error != _shownError) {
      _shownError = error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _onCode() {
    if (_account.deviceCode.value == null || _dialogOpen || !mounted) return;
    _showCode();
  }

  void _showCode() {
    _dialogOpen = true;
    showDeviceCodeDialog(
      context,
      _account.deviceCode,
      onCancel: _account.cancelLogin,
    ).whenComplete(() => _dialogOpen = false);
  }

  Future<void> _toggle() async {
    if (_account.signedIn) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('退出 GitHub 登录？'),
          content: const Text('将移除此设备上 github.com 的登录凭据。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('退出登录'),
            ),
          ],
        ),
      );
      if (ok == true) await _account.logout();
    } else {
      _shownError = null;
      await _account.login();
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<GithubAccount>();
    final busy = account.busy;
    final missing = account.auth == GithubAuth.missing;
    final status = switch (account.auth) {
      GithubAuth.missing => '未安装 gh · 在开发环境页完成 Flutter 阶段安装后可用',
      GithubAuth.signedOut => '未登录 · 私有仓库的克隆与推送需要登录',
      GithubAuth.credentialsSaved => '已登录 · git 凭据助手已接入',
    };
    final fontSize = widget.dense ? 12.0 : 14.0;
    return ValueListenableBuilder<String?>(
      valueListenable: account.deviceCode,
      builder: (context, code, _) => ListTile(
        dense: widget.dense,
        leading: Icon(
          Icons.key_outlined,
          size: widget.dense ? 18 : 22,
          color: AppColors.accent,
        ),
        title: Text('GitHub 账户', style: TextStyle(fontSize: fontSize)),
        subtitle: Text(
          busy ? (code == null ? '正在处理…' : '等待浏览器授权…') : status,
          style: TextStyle(fontSize: widget.dense ? 10 : 12),
        ),
        trailing: busy && code != null
            ? TextButton(onPressed: _showCode, child: const Text('查看授权码'))
            : TextButton(
                onPressed: widget.enabled && !busy && !missing ? _toggle : null,
                child: Text(account.signedIn ? '退出登录' : '登录'),
              ),
      ),
    );
  }
}
