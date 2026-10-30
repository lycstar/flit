import 'package:flutter/material.dart';

import 'global_terminal_panel.dart';
import 'console_session.dart';
import '../../core/theme.dart';

/// 平板双栏模式的终端侧栏: 复用全局面板(有界高度自动填满),
/// 与底部坞互斥挂载 —— 全 app 仍只有一个 TerminalView, 不重复吞输入。
class TerminalSidePane extends StatelessWidget {
  const TerminalSidePane({
    super.key,
    this.running = false,
    this.session,
    this.sessionsBar,
    this.widthFraction = 0.36,
    this.minWidth = 320,
    this.maxWidth = 520,
  });

  final bool running;
  final ConsoleSession? session;
  final Widget? sessionsBar;
  final double widthFraction;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * widthFraction).clamp(
          minWidth,
          maxWidth,
        );
        return Container(
          width: width,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: GlobalTerminalPanel(
            expanded: true,
            session: session,
            sessionsBar: sessionsBar,
            onToggle: () {},
            running: running,
          ),
        );
      },
    );
  }
}
