import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../installed_toolchain.dart';

class InstalledToolchainsSection extends StatelessWidget {
  const InstalledToolchainsSection({
    super.key,
    required this.tools,
    required this.busy,
    required this.onChange,
    required this.root,
  });

  final List<InstalledToolchain> tools;
  final bool busy;
  final String root;
  final Future<void> Function(InstalledToolchain tool, {bool delete}) onChange;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '已安装',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '$root\nFlutter 切换后对新会话生效。NDK 与 CMake 由项目指定版本。下载其他版本会保留现有版本。',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (tools.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('尚未安装工具链')),
        for (final tool in tools)
          ListTile(
            dense: true,
            leading: Icon(
              tool.active ? Icons.check_circle_outline : Icons.folder_outlined,
              size: 20,
              color: tool.active ? AppColors.success : AppColors.textSecondary,
            ),
            title: Text(
              '${tool.title}${tool.active ? ' · 当前' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${tool.size}${tool.complete ? '' : ' · 安装不完整，请重新下载'}\n${tool.path}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: PopupMenuButton<String>(
              enabled: !busy,
              tooltip: '管理版本',
              onSelected: (action) async {
                if (action == 'select') {
                  await onChange(tool, delete: false);
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('删除 ${tool.title}？'),
                    content: const Text(
                      '该版本的文件将被删除。依赖此版本的项目需重新安装后才能构建；删除基础必需版本后，需要补齐开发环境。',
                    ),
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
                if (tool.isFlutter && !tool.active && tool.complete)
                  const PopupMenuItem(value: 'select', child: Text('使用此版本')),
                PopupMenuItem(
                  value: 'delete',
                  enabled: !tool.active,
                  child: Text(tool.active ? '先切换版本再删除' : '删除版本'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
