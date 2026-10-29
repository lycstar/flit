import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../../core/theme.dart';
import '../../core/workbench_controls.dart';

import 'pty_session.dart';
import 'console_session.dart';
import 'terminal_theme.dart';

/// Terminal chrome and input surface. Parent supplies bounded space; selection
/// actions float above the viewport and never change its row count.
class GlobalTerminalPanel extends StatefulWidget {
  const GlobalTerminalPanel({
    super.key,
    required this.expanded,
    required this.onToggle,
    this.running = false,
    this.height = 280,
    this.minHeight = 180,
    this.onFullscreen,
    this.fontSize = 12,
    this.fullscreen = false,
    this.onResize,
    this.focusNode,
    this.session,
    this.sessionsBar,
    this.consumeSafeArea = true,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final bool running;
  final double height;
  final double minHeight;
  final VoidCallback? onFullscreen;
  final double fontSize;
  final bool fullscreen;
  final ValueChanged<double>? onResize;
  final FocusNode? focusNode;
  final ConsoleSession? session;
  final Widget? sessionsBar; // 会话切换/控制条(面板头部下方一行)
  final bool consumeSafeArea;

  @override
  State<GlobalTerminalPanel> createState() => _GlobalTerminalPanelState();
}

class _GlobalTerminalPanelState extends State<GlobalTerminalPanel> {
  final _viewKey = GlobalKey<TerminalViewState>();
  PtySession? _workbench;

  /// 没指定会话时回落到工作台默认 bash(应用级, 来自 AppScope)
  ConsoleSession get _session =>
      widget.session ?? (_workbench ??= context.read<PtySession>());

  @override
  void initState() {
    super.initState();
    _ensureShell();
  }

  void _ensureShell() {
    final session = _session;
    if (session is PtySession) session.ensure();
  }

  @override
  void didUpdateWidget(covariant GlobalTerminalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        (widget.expanded && !oldWidget.expanded)) {
      _ensureShell();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // 会话换了自动改订阅; 重建由它负责, 这里不再手工 addListener
    listenable: _session,
    builder: (context, _) =>
        _session.disposed ? const SizedBox.shrink() : _panel(),
  );

  Widget _panel() {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: widget.consumeSafeArea,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bounded = constraints.maxHeight.isFinite;
            return Column(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (bounded && constraints.maxHeight < 44)
                  SizedBox(
                    height: constraints.maxHeight,
                    child: ClipRect(
                      child: OverflowBox(
                        minHeight: 44,
                        maxHeight: 44,
                        child: _header(),
                      ),
                    ),
                  )
                else
                  _header(),
                if (widget.expanded &&
                    widget.sessionsBar != null &&
                    (!bounded || constraints.maxHeight > 140))
                  widget.sessionsBar!,
                if (widget.expanded) ...[
                  if (bounded)
                    Expanded(child: _surface())
                  else
                    SizedBox(height: widget.height, child: _surface()),
                  // 按键条(ESC/CTRL/方向键)只对可输入的默认 shell 有意义
                  if (_session.interactive &&
                      (!bounded || constraints.maxHeight > 140))
                    _ExtraKeysBar(session: _session),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    Widget button(IconData icon, String tooltip, VoidCallback action) =>
        IconButton(
          tooltip: tooltip,
          onPressed: action,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 18, color: AppColors.textSecondary),
        );
    return ExcludeFocus(
      child: GestureDetector(
        onVerticalDragUpdate: widget.onResize == null
            ? null
            : (details) => widget.onResize!(details.delta.dy),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              if (widget.consumeSafeArea)
                button(
                  widget.expanded ? Icons.expand_more : Icons.expand_less,
                  widget.expanded ? '收起终端' : '展开终端',
                  widget.onToggle,
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.drag_handle,
                    size: 18,
                    color: AppColors.textFaint,
                  ),
                ),
              Icon(
                Icons.circle,
                size: 8,
                color: widget.running
                    ? AppColors.accent
                    : _session.alive
                    ? AppColors.success
                    : AppColors.warn,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_session.title} · ${_session.alive
                      ? '运行中'
                      : _session.exitCode == null
                      ? '就绪'
                      : '已结束'}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.expanded) ...[
                // 默认 shell 永远在; run 能停(⏹, 输出留着)能删; 临时只能删。
                // ✕ 在跑则终止再移除, 之后面板回落默认 shell
                if (_session.stoppable)
                  button(
                    Icons.stop_circle_outlined,
                    _session.stopRequested ? '正在停止…' : '停止当前任务',
                    _session.stopRequested ? () {} : () => _session.stop(),
                  ),
                if (_session.kind != SessionKind.shell)
                  button(
                    Icons.close,
                    _session.alive ? '终止并关闭' : '关闭',
                    () => _session.close(),
                  ),
                button(
                  Icons.delete_sweep_outlined,
                  '清空终端',
                  _session.clearScreen,
                ),
              ],
              if (widget.onFullscreen != null)
                button(
                  widget.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  widget.fullscreen ? '退出全屏终端' : '全屏终端',
                  widget.onFullscreen!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surface() {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) => TerminalView(
              _session.terminal,
              key: _viewKey,
              controller: _session.controller,
              focusNode: widget.focusNode,
              scrollController: _session.scrollController,
              textStyle: TerminalStyle(
                fontSize: widget.fontSize,
                fontFamily: 'JetBrainsMono',
              ),
              theme: flitTerminalTheme,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              deleteDetection: true,
              // run/temp 只读: 输出面板, 输入由按钮程序性写入(热重载 r/R)
              readOnly: !_session.interactive,
              // Keep the input client alive even in a very short landscape
              // viewport, without sending a zero-row size to the PTY.
              autoResize: constraints.maxHeight > widget.fontSize * 2,
            ),
          ),
        ),
        Positioned(
          // 钉在终端底部: 选择时顶部滚动历史不被遮挡(底部只盖会再生的提示符行)
          bottom: 4,
          left: 8,
          right: 8,
          child: AnimatedBuilder(
            animation: _session.controller,
            builder: (_, __) => _session.controller.selection == null
                ? const SizedBox.shrink()
                : ExcludeFocus(
                    child: Material(
                      elevation: 8,
                      color: AppColors.surface,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      clipBehavior: Clip.antiAlias,
                      child: _SelectionToolbar(session: _session),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 终端按键条: ESC / CTRL(锁存) / TAB / 方向键。软键盘没有的终端必需键。
class _ExtraKeysBar extends StatefulWidget {
  const _ExtraKeysBar({required this.session});
  final ConsoleSession session;

  @override
  State<_ExtraKeysBar> createState() => _ExtraKeysBarState();
}

class _ExtraKeysBarState extends State<_ExtraKeysBar> {
  void _send(String s) {
    widget.session.input(s);
  }

  void _toggleCtrl() {
    widget.session.toggleCtrl();
  }

  @override
  Widget build(BuildContext context) {
    Widget key(
      String label,
      VoidCallback action, {
      bool active = false,
      bool wide = false,
    }) => SizedBox(
      width: wide
          ? 74
          : label.length > 2
          ? 58
          : 44,
      child: WorkbenchKey(label: label, onPressed: action, active: active),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            key('ESC', () => _send('\x1b')),
            key('CTRL', _toggleCtrl, active: widget.session.ctrlArmed),
            key('TAB', () => _send('\t')),
            key('↑', () => _send('\x1b[A')),
            key('↓', () => _send('\x1b[B')),
            key('←', () => _send('\x1b[D')),
            key('→', () => _send('\x1b[C')),
            key('-', () => _send('-')),
            key('|', () => _send('|')),
            key('~', () => _send('~')),
            key('/', () => _send('/')),
            // IME 的回车会被 xterm 按 action 吞掉(newline action 不映射 Enter),
            // 按键条直接发 \r, 保证任何输入法下都能执行命令
            key('ENTER', () => _send('\r'), wide: true),
            // 长按选择后用工具条复制; 粘贴独立常驻(多数时候无选区也要粘贴)
            key('粘贴', () => widget.session.pasteClipboard(), wide: true),
          ],
        ),
      ),
    );
  }
}

/// 选中后浮现的操作条: 复制 / 全选 / 粘贴 / 取消选择。
/// 长按选词、按住拖动扩展选区；操作条不抢占终端焦点。
class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({required this.session});
  final ConsoleSession session;

  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget divider() => const SizedBox(
      width: 1,
      height: 22,
      child: ColoredBox(color: AppColors.border),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          action('复制', Icons.copy_outlined, () {
            final text = session.copySelection();
            if (text == null || text.isEmpty) return;
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已复制'),
                duration: Duration(seconds: 1),
              ),
            );
          }),
          divider(),
          action('全选', Icons.select_all, () {
            session.selectAll();
          }),
          // 只读会话不接受输入: 粘贴只对默认 shell 有意义
          if (session.interactive) ...[
            divider(),
            action('粘贴', Icons.paste, () {
              session.pasteClipboard();
            }),
          ],
          divider(),
          action('取消', Icons.close, () {
            session.controller.clearSelection();
          }),
        ],
      ),
    );
  }
}
