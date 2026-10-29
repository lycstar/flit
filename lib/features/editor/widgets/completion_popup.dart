import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../completion/completion_engine.dart';

/// 桌面式补全浮层: 锚定在光标旁的纵向候选面板(优先显示在光标上方)。
/// 不抢焦点: 键盘事件(Esc/Tab/↑↓)由编辑器页的 Focus 处理, 这里只响应点选。
class CompletionPopup extends StatelessWidget {
  const CompletionPopup({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onDismiss,
    this.width = 300,
    this.maxRows = 5,
  });

  final List<CompletionItem> items;
  final int selectedIndex;
  final ValueChanged<CompletionItem> onSelected;
  final VoidCallback onDismiss;
  final double width;
  final int maxRows;

  double get height => items.length.clamp(1, maxRows) * 40.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: TextFieldTapRegion(
        onTapOutside: (_) => onDismiss(),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surface,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Scrollbar(
                thumbVisibility: items.length > maxRows,
                thickness: 3,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemExtent: 40,
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final selected = index == selectedIndex;
                    return InkWell(
                      canRequestFocus: false,
                      onTap: () => onSelected(item),
                      child: Container(
                        color: selected
                            ? AppColors.accent.withValues(alpha: .14)
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(
                              item.semantic == null
                                  ? Icons.text_fields
                                  : Icons.code,
                              size: 15,
                              color: item.semantic == null
                                  ? AppColors.textFaint
                                  : AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (item.detail?.isNotEmpty == true) ...[
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 110,
                                ),
                                child: Text(
                                  item.detail!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: AppColors.textFaint,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Text(
                              item.kind,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
