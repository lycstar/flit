import 'package:flutter/material.dart';

import '../../../core/theme.dart';

typedef MenuAction = (String, IconData, String, VoidCallback);

/// 文件管理通用底部操作菜单
Future<void> showActionMenu(BuildContext context, List<MenuAction> items) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (_, icon, label, onTap) in items)
            ListTile(
              dense: true,
              leading: Icon(icon, size: 18, color: AppColors.textSecondary),
              title: Text(label, style: const TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

/// 删除确认(不可恢复)
Future<bool> confirmDeleteDialog(BuildContext context, String name) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('删除「$name」？', style: const TextStyle(fontSize: 16)),
      content: const Text(
        '将永久删除所选文件或目录及其内容，此操作无法撤销。',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return yes ?? false;
}

/// 重命名输入框; 返回 null = 取消
Future<String?> renameDialog(BuildContext context, String oldName) {
  final ctrl = TextEditingController(text: oldName);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('重命名', style: TextStyle(fontSize: 16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(hintText: '名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('重命名'),
        ),
      ],
    ),
  );
}

/// 新建文件/文件夹输入框; 返回 null = 取消
Future<String?> createDialog(BuildContext context, {required bool dir}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(dir ? '新建目录' : '新建文件', style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(hintText: dir ? 'widgets' : 'utils.dart'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('创建'),
        ),
      ],
    ),
  );
}
