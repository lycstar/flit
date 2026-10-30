import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../installed_toolchain.dart';

/// 本地操作不依赖远程版本目录，断网时仍可切换与删除。
class InstalledToolchainTile extends StatelessWidget {
  const InstalledToolchainTile({
    super.key,
    required this.tool,
    required this.busy,
    required this.onChange,
    this.onRepair,
  });

  final InstalledToolchain tool;
  final bool busy;
  final Future<void> Function(InstalledToolchain tool, {bool delete}) onChange;
  final VoidCallback? onRepair;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(
      !tool.complete
          ? Icons.error_outline
          : tool.active
          ? Icons.check_circle_outline
          : Icons.folder_outlined,
      size: 20,
      color: !tool.complete
          ? AppColors.danger
          : tool.active
          ? AppColors.success
          : AppColors.textSecondary,
    ),
    title: Text(
      '${tool.title}${tool.active ? ' · 当前' : ''}',
      style: const TextStyle(fontSize: 13),
    ),
    subtitle: Text(
      '${tool.size} · ${tool.complete ? '已安装' : '安装不完整'}\n${tool.path}',
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
    trailing: PopupMenuButton<String>(
      enabled: !busy,
      tooltip: '管理版本',
      onSelected: (action) async {
        if (action == 'repair') {
          onRepair?.call();
          return;
        }
        if (action == 'select') {
          await onChange(tool, delete: false);
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('删除 ${tool.title}？'),
            content: const Text('依赖此版本的项目需重新安装后才能构建；删除基础必需版本后，需要补齐开发环境。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (confirmed == true) await onChange(tool, delete: true);
      },
      itemBuilder: (_) => [
        if (!tool.complete && onRepair != null)
          const PopupMenuItem(value: 'repair', child: Text('修复安装')),
        if (tool.isFlutter && !tool.active && tool.complete)
          const PopupMenuItem(value: 'select', child: Text('使用此版本')),
        PopupMenuItem(
          value: 'delete',
          enabled: !tool.active,
          child: Text(tool.active ? '先切换版本再删除' : '删除版本'),
        ),
      ],
    ),
  );
}
