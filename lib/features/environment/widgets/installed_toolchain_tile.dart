import 'package:flit/l10n/strings.dart';
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
      '${tool.title}${tool.active ? context.strings.currentSuffix : ''}',
      style: const TextStyle(fontSize: 13),
    ),
    subtitle: Text(
      '${tool.size} · ${tool.complete ? context.strings.installed : context.strings.installationIncomplete}\n${tool.path}',
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
    trailing: PopupMenuButton<String>(
      enabled: !busy,
      tooltip: context.strings.manageVersions,
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
            title: Text(context.strings.deleteP(tool.title)),
            content: Text(context.strings.projectsUsingThisVersionWillNeedIt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.strings.delete),
              ),
            ],
          ),
        );
        if (confirmed == true) await onChange(tool, delete: true);
      },
      itemBuilder: (_) => [
        if (!tool.complete && onRepair != null)
          PopupMenuItem(
            value: 'repair',
            child: Text(context.strings.repairInstallation),
          ),
        if (tool.isFlutter && !tool.active && tool.complete)
          PopupMenuItem(
            value: 'select',
            child: Text(context.strings.useThisVersion),
          ),
        PopupMenuItem(
          value: 'delete',
          enabled: !tool.active,
          child: Text(
            tool.active
                ? context.strings.switchVersionsBeforeDeleting
                : context.strings.deleteVersion,
          ),
        ),
      ],
    ),
  );
}
