import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'global_terminal_panel.dart';
import 'console_session.dart';
import '../../core/theme.dart';

/// Shared page layout. Scaffold consumes IME insets once; this host uses only
/// its remaining constraints for docked and fullscreen terminal sizing.
class TerminalHost extends StatefulWidget {
  const TerminalHost({
    super.key,
    required this.child,
    required this.expanded,
    required this.onToggle,
    this.running = false,
    this.preferredHeight = 300,
    this.hideContentWithKeyboard = false,
    this.session,
    this.sessionsBar,
    this.footer,
  });

  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;
  final bool running;
  final double preferredHeight;
  final bool hideContentWithKeyboard;
  final ConsoleSession? session;
  final Widget? sessionsBar; // 会话切换/控制条
  final Widget? footer;

  @override
  State<TerminalHost> createState() => _TerminalHostState();
}

class _TerminalHostState extends State<TerminalHost> with RouteAware {
  final _panelKey = GlobalKey();
  final _focus = FocusNode(debugLabel: 'terminal');

  /// Only the visible page may resize the shared terminal / PTY.
  late RouteObserver<PageRoute<dynamic>> _routes;
  PageRoute<dynamic>? _route;
  LocalHistoryEntry? _fullscreenEntry;
  bool _active = true;
  bool _fullscreen = false;
  double? _dockHeight;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routes = context.read<RouteObserver<PageRoute<dynamic>>>();
    final route = ModalRoute.of(context);
    if (route != _route && route is PageRoute<dynamic>) {
      _routes.unsubscribe(this);
      _route = route;
      _routes.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _focus.unfocus();
    setState(() => _active = false);
  }

  @override
  void didPopNext() => setState(() => _active = true);

  @override
  void didUpdateWidget(covariant TerminalHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded && !widget.expanded && _fullscreen) {
      _fullscreenEntry?.remove();
    }
  }

  void _toggleExpanded() {
    if (_fullscreen) {
      _fullscreenEntry?.remove();
      if (widget.expanded) widget.onToggle();
    } else {
      widget.onToggle();
    }
  }

  void _toggleFullscreen() {
    if (_fullscreen) {
      _fullscreenEntry?.remove();
      return;
    }
    final transferKeyboard = View.of(context).viewInsets.bottom > 0;
    if (!_focus.hasFocus) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _fullscreen = true);
    _fullscreenEntry = LocalHistoryEntry(
      onRemove: () {
        _fullscreenEntry = null;
        if (mounted) setState(() => _fullscreen = false);
      },
    );
    ModalRoute.of(context)?.addLocalHistoryEntry(_fullscreenEntry!);
    if (transferKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _fullscreen && _active) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _routes.unsubscribe(this);
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    // The route owns its LocalHistoryEntry and removes it on disposal.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scaffold removes the consumed inset from the body's MediaQuery.
        // Read visibility from the view; sizing still uses constraints only.
        final keyboard = View.of(context).viewInsets.bottom > 0;
        final available = constraints.maxHeight;
        if (widget.footer != null) return _workbench(available, keyboard);
        final expanded = widget.expanded || _fullscreen;
        final fill =
            _fullscreen ||
            (keyboard &&
                _focus.hasFocus &&
                expanded &&
                (widget.hideContentWithKeyboard || available < 260));
        final maxDock = math.max(0.0, available * .7);
        final preferred = _dockHeight ?? widget.preferredHeight;
        final collapsedHeight =
            44.0 + math.max(12.0, MediaQuery.paddingOf(context).bottom);
        final height = fill
            ? available
            : !expanded
            ? math.min(collapsedHeight, available)
            : preferred.clamp(math.min(150.0, maxDock), maxDock).toDouble();
        return Stack(
          children: [
            Positioned.fill(
              bottom: _active && !fill ? height : 0,
              child: Offstage(offstage: fill, child: widget.child),
            ),
            if (_active)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: height,
                child: GlobalTerminalPanel(
                  key: _panelKey,
                  focusNode: _focus,
                  session: widget.session,
                  sessionsBar: widget.sessionsBar,
                  expanded: expanded,
                  onToggle: _toggleExpanded,
                  running: widget.running,
                  fullscreen: _fullscreen,
                  onFullscreen: _toggleFullscreen,
                  onResize: expanded && !fill
                      ? (delta) => setState(() {
                          _dockHeight = (height - delta).clamp(
                            math.min(150.0, maxDock),
                            maxDock,
                          );
                        })
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _workbench(double available, bool keyboard) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final footerHeight = 44.0 + bottom;
    final room = math.max(0.0, available - footerHeight);
    final expanded = widget.expanded || _fullscreen;
    final fill = _fullscreen || (keyboard && _focus.hasFocus && room < 260);
    final maxPanel = math.max(0.0, room - (fill ? 0 : 44));
    final terminalHeight = fill
        ? room
        : (_dockHeight ?? widget.preferredHeight)
              .clamp(0.0, maxPanel)
              .toDouble();
    final panelHeight = expanded ? terminalHeight : 0.0;
    final total = math.min(available, footerHeight + panelHeight);
    return Stack(
      children: [
        Positioned.fill(
          bottom: _active && !fill ? total : 0,
          child: Offstage(offstage: fill, child: widget.child),
        ),
        if (_active)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: total,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Offstage(
                      offstage: !expanded,
                      child: GlobalTerminalPanel(
                        key: _panelKey,
                        focusNode: _focus,
                        session: widget.session,
                        sessionsBar: widget.sessionsBar,
                        expanded: true,
                        onToggle: _toggleExpanded,
                        running: widget.running,
                        fullscreen: _fullscreen,
                        consumeSafeArea: false,
                        onFullscreen: _toggleFullscreen,
                        onResize: !fill
                            ? (delta) => setState(() {
                                _dockHeight = (terminalHeight - delta).clamp(
                                  0.0,
                                  maxPanel,
                                );
                              })
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: math.min(footerHeight, available),
                    child: SafeArea(top: false, child: widget.footer!),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
