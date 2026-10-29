import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/workbench_controls.dart';
import '../controller/code_controller.dart';

/// Single compact row sharing one surface with the terminal above.
/// Run/build actions live in the app bar (EditorRunControls).
class EditorDockToolbar extends StatelessWidget {
  const EditorDockToolbar({
    super.key,
    required this.controller,
    required this.previewAvailable,
    required this.showPreview,
    required this.terminalExpanded,
    required this.canEdit,
    required this.onCode,
    required this.onPreview,
    required this.onTerminal,
    this.docPreviewAvailable = false,
    this.docPreviewOn = false,
    this.docPreviewLabel = 'MD',
    this.onDocPreview,
  });

  final CodeController controller;
  final bool previewAvailable, showPreview, terminalExpanded, canEdit;
  final VoidCallback onCode, onPreview, onTerminal;

  /// 当前缓冲是 markdown 时出现, 切编辑缓冲 ↔ 渲染预览
  final bool docPreviewAvailable, docPreviewOn;
  final String docPreviewLabel;
  final VoidCallback? onDocPreview;

  Widget _tab(String label, bool selected, VoidCallback action) => TextButton(
    onPressed: action,
    style: TextButton.styleFrom(
      foregroundColor: selected ? AppColors.accent : AppColors.textSecondary,
      backgroundColor: selected
          ? AppColors.accent.withValues(alpha: .12)
          : Colors.transparent,
      minimumSize: const Size(46, 36),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    child: ExcludeFocus(
      child: Material(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                _tab('代码', !showPreview && !docPreviewOn, onCode),
                if (docPreviewAvailable)
                  _tab(docPreviewLabel, docPreviewOn, onDocPreview ?? () {}),
                if (previewAvailable) _tab('预览', showPreview, onPreview),
                const SizedBox(width: 4),
                WorkbenchButton(
                  icon: Icons.terminal,
                  tooltip: terminalExpanded ? '收起终端' : '展开终端',
                  active: terminalExpanded,
                  onPressed: onTerminal,
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: controller,
                  builder: (_, __) => Row(
                    children: [
                      WorkbenchButton(
                        icon: Icons.undo,
                        tooltip: '撤销',
                        onPressed: canEdit && controller.canUndo
                            ? controller.undo
                            : null,
                      ),
                      WorkbenchButton(
                        icon: Icons.redo,
                        tooltip: '重做',
                        onPressed: canEdit && controller.canRedo
                            ? controller.redo
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
