import 'package:flutter/material.dart';

import 'theme.dart';

/// Shared chrome for terminal controls and the in-app code keyboard.
class WorkbenchKey extends StatelessWidget {
  const WorkbenchKey({
    super.key,
    required this.label,
    required this.onPressed,
    this.active = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final icon = switch (label) {
      '↵' => Icons.keyboard_return,
      '⌫' => Icons.backspace_outlined,
      '空格' => Icons.space_bar,
      '⇧' => Icons.keyboard_capslock,
      _ => null,
    };
    final tooltip = switch (label) {
      '↵' => '换行',
      '⌫' => '退格',
      '⇧' => '大写',
      _ => label,
    };
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active
              ? AppColors.accent.withValues(alpha: .16)
              : AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: active
                  ? AppColors.accent.withValues(alpha: .5)
                  : AppColors.border,
            ),
          ),
          child: InkWell(
            canRequestFocus: false,
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 36,
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: 18,
                        color: active
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      )
                    : Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: label.length > 2 ? 11 : 13,
                          color: active
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkbenchButton extends StatelessWidget {
  const WorkbenchButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.active = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    isSelected: active,
    style: IconButton.styleFrom(
      foregroundColor: active ? AppColors.accent : AppColors.textSecondary,
      backgroundColor: active
          ? AppColors.accent.withValues(alpha: .12)
          : Colors.transparent,
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: Icon(icon, size: 19),
  );
}
