import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../workspace/editor_tabs.dart';
import '../../workspace/project_documents.dart';
import '../file_kind.dart';
import 'file_dialogs.dart';

/// 顶栏第二行: 打开项 tab 条。样式与终端会话条同款(30 高 chip, 选中项 12% 强调色底);
/// ✕ 只在当前项上(省宽度), 长按给关闭/关闭其他; 同名文件带上一级目录区分。
class EditorFileTabs extends StatefulWidget {
  const EditorFileTabs({
    super.key,
    required this.onSelect,
    required this.onClose,
    required this.onCloseOthers,
  });

  final void Function(OpenItem item) onSelect;
  final void Function(OpenItem item) onClose;
  final void Function(OpenItem item) onCloseOthers;

  static const height = 36.0;

  @override
  State<EditorFileTabs> createState() => _EditorFileTabsState();
}

class _EditorFileTabsState extends State<EditorFileTabs> {
  late final EditorTabs tabs = context.read<EditorTabs>();
  late final ProjectDocuments documents = context.read<ProjectDocuments>();
  final _selectedKey = GlobalKey();
  OpenItem? _revealed;

  /// 当前项变了就滚进可视区(切 tab/新开文件都在末尾或屏外)
  void _revealSelected() {
    final current = tabs.current;
    if (current == null || identical(_revealed, current)) return;
    _revealed = current;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _selectedKey.currentContext;
      if (context != null && mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }

  Map<OpenItem, String> _labels(List<OpenItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.name] = (counts[item.name] ?? 0) + 1;
    }
    return {
      for (final item in items)
        item: (counts[item.name] ?? 0) > 1 ? _withParent(item.path) : item.name,
    };
  }

  static String _withParent(String path) {
    final parts = path.split('/');
    return parts.length < 2 ? path : '${parts[parts.length - 2]}/${parts.last}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([tabs, documents]),
    builder: (context, _) {
      final items = tabs.items;
      final labels = _labels(items);
      _revealSelected();
      return ExcludeFocus(
        child: Material(
          color: AppColors.surface,
          child: SizedBox(
            width: double.infinity,
            height: EditorFileTabs.height,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                children: [
                  for (final item in items) _chip(context, item, labels[item]!),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _chip(BuildContext context, OpenItem item, String label) {
    final selected = identical(tabs.current, item);
    final dirty = item is CodeTab && item.document.dirty;
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    final icon = switch (item) {
      FileTab(kind: FileKind.image) => Icons.image_outlined,
      FileTab() => Icons.insert_drive_file_outlined,
      CodeTab() => null,
    };
    return Padding(
      key: selected ? _selectedKey : null,
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              canRequestFocus: false,
              borderRadius: BorderRadius.circular(6),
              onTap: () => widget.onSelect(item),
              onLongPress: () => showActionMenu(context, [
                ('close', Icons.close, '关闭', () => widget.onClose(item)),
                (
                  'others',
                  Icons.clear_all,
                  '关闭其他',
                  () => widget.onCloseOthers(item),
                ),
              ]),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: color,
                      ),
                    ),
                    if (dirty) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (selected)
              Tooltip(
                message: '关闭 $label',
                child: InkWell(
                  canRequestFocus: false,
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => widget.onClose(item),
                  child: SizedBox(
                    width: 22,
                    height: 30,
                    child: Icon(Icons.close, size: 13, color: color),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
