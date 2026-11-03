import 'package:flit/l10n/strings.dart';
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
          const SheetHandle(),
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
      title: Text(
        context.strings.deleteP576(name),
        style: const TextStyle(fontSize: 16),
      ),
      content: Text(
        context.strings.permanentlyDeleteTheSelectedFileOrDirectory,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(context.strings.delete),
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
      title: Text(context.strings.rename, style: TextStyle(fontSize: 16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(hintText: context.strings.name),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(context.strings.rename),
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
      title: Text(
        dir ? context.strings.newDirectory : context.strings.newFile,
        style: const TextStyle(fontSize: 16),
      ),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(hintText: dir ? 'widgets' : 'utils.dart'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(context.strings.create),
        ),
      ],
    ),
  );
}
