import 'package:flutter/material.dart';

/// Material 3 窗口尺寸类: 按 MediaQuery 宽度划档, 不按设备类型判断
/// (平板竖屏 600-840 走 medium, 与手机同布局; 横屏大屏 ≥840 才展开双栏)。
enum WindowSize { compact, medium, expanded }

WindowSize windowSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 840) return WindowSize.expanded;
  if (width >= 600) return WindowSize.medium;
  return WindowSize.compact;
}
