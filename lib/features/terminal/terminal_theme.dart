import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../core/theme.dart';

/// 全局终端统一外观: 工作台/编辑器渲染同一个 Terminal 实例, 外观定义也只有一份。
const flitTerminalStyle = TerminalStyle(
  fontSize: 13,
  fontFamily: 'JetBrainsMono',
);

const flitTerminalTheme = TerminalTheme(
  cursor: AppColors.accent,
  selection: Color(0x55264F78), // 半透明蓝灰: 文字在选区里仍然可读
  background: AppColors.bg,
  foreground: AppColors.textPrimary,
  black: Colors.black,
  red: AppColors.danger,
  green: AppColors.success,
  yellow: AppColors.warn,
  blue: AppColors.accent,
  magenta: Color(0xFFD2A8FF),
  cyan: Color(0xFFA5D6FF),
  white: AppColors.textPrimary,
  brightBlack: AppColors.textSecondary,
  brightRed: AppColors.danger,
  brightGreen: AppColors.success,
  brightYellow: AppColors.warn,
  brightBlue: AppColors.accent,
  brightMagenta: Color(0xFFD2A8FF),
  brightCyan: Color(0xFFA5D6FF),
  brightWhite: Colors.white,
  searchHitBackground: AppColors.divider,
  searchHitBackgroundCurrent: AppColors.accent,
  searchHitForeground: AppColors.bg,
);
