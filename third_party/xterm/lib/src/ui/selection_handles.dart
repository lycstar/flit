import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:xterm/src/core/buffer/cell_offset.dart';
import 'package:xterm/src/core/buffer/line.dart';
import 'package:xterm/src/terminal.dart';
import 'package:xterm/src/terminal_view.dart';
import 'package:xterm/src/ui/controller.dart';
import 'package:xterm/src/ui/selection_mode.dart';

/// Selection endpoints remain draggable after the initial long press ends.
/// This layer sits outside the terminal gestures, so handles never send taps
/// to the PTY or request the keyboard.
class TerminalSelectionHandles extends StatefulWidget {
  const TerminalSelectionHandles({
    super.key,
    required this.view,
    required this.terminal,
    required this.controller,
    required this.scrollController,
    required this.child,
  });

  final TerminalViewState view;
  final Terminal terminal;
  final TerminalController controller;
  final ScrollController scrollController;
  final Widget child;

  @override
  State<TerminalSelectionHandles> createState() =>
      _TerminalSelectionHandlesState();
}

class _TerminalSelectionHandlesState extends State<TerminalSelectionHandles> {
  bool _refreshPending = false;
  Size? _size;
  Timer? _scrollTimer;
  CellAnchor? _fixed;
  bool _dragStart = false;
  Offset? _pointer;
  Offset _dragAdjustment = Offset.zero;

  void _listen(bool add, TerminalSelectionHandles target) {
    if (add) {
      target.terminal.addListener(_refresh);
    } else {
      target.terminal.removeListener(_refresh);
    }
    for (final source in <Listenable>[
      target.controller,
      target.scrollController,
    ]) {
      if (add) {
        source.addListener(_refresh);
      } else {
        source.removeListener(_refresh);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _listen(true, widget);
  }

  @override
  void didUpdateWidget(TerminalSelectionHandles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.terminal != widget.terminal ||
        oldWidget.scrollController != widget.scrollController) {
      _end();
      _listen(false, oldWidget);
      _listen(true, widget);
    }
    _refresh();
  }

  // Terminal resize and scrolling can notify during layout. Position handles
  // after the renderer has applied its new geometry, never during layout.
  void _refresh() {
    if (_refreshPending) return;
    _refreshPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPending = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _start(bool start, Offset global) {
    _end();
    final selection = widget.controller.selection?.normalized;
    if (selection == null) return;
    _dragStart = start;
    final render = widget.view.renderTerminal;
    final moving = start ? selection.begin : selection.end;
    _fixed = widget.terminal.buffer.createAnchorFromOffset(
      start ? selection.end : selection.begin,
    );
    // Retain the finger-to-endpoint offset to avoid a jump when grabbed.
    final boundary = render.localToGlobal(render.getOffset(moving)) +
        Offset(0, render.cellSize.height / 2);
    _dragAdjustment = boundary - global;
    _pointer = global;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final pointer = _pointer;
      if (pointer == null ||
          _fixed?.attached != true ||
          widget.controller.selection == null) {
        _end();
        return;
      }
      final render = widget.view.renderTerminal;
      final y = render.globalToLocal(pointer).dy;
      final zone = (render.size.height / 3).clamp(1.0, 40.0);
      final speed = y < zone
          ? -((zone - y) / zone).clamp(0.0, 1.0) * 24
          : y > render.size.height - zone
              ? ((y - render.size.height + zone) / zone).clamp(0.0, 1.0) * 24
              : 0.0;
      if (speed != 0) {
        widget.view.scrollByPixels(speed);
        _move(pointer);
      }
    });
  }

  void _move(Offset global) {
    _pointer = global;
    if (_fixed?.attached != true || widget.controller.selection == null) {
      _end();
      return;
    }
    final render = widget.view.renderTerminal;
    final local = render.globalToLocal(global + _dragAdjustment);
    final cell = render.getCellOffset(local);
    final cellOrigin = render.getOffset(cell);
    var x =
        cell.x + ((local.dx - cellOrigin.dx) / render.cellSize.width).round();
    x = x.clamp(0, widget.terminal.viewWidth);
    final line = widget.terminal.buffer.lines[cell.y];
    // Do not split a double-width character at its continuation cell.
    if (x > 0 && line.getWidth(x - 1) == 2) x--;
    final moving = CellOffset(x, cell.y);
    final fixed = _fixed!.offset;
    // Keep the two handles in order and retain a nonempty selection.
    if (_dragStart ? !moving.isBefore(fixed) : !moving.isAfter(fixed)) return;
    final buffer = widget.terminal.buffer;
    widget.controller.setSelection(
      buffer.createAnchorFromOffset(_dragStart ? moving : fixed),
      buffer.createAnchorFromOffset(_dragStart ? fixed : moving),
      mode: SelectionMode.line,
    );
  }

  void _end() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _fixed?.dispose();
    _fixed = null;
    _pointer = null;
  }

  @override
  void dispose() {
    _listen(false, widget);
    _end();
    super.dispose();
  }

  Widget _handle(bool start, CellOffset endpoint, Size size) {
    final render = widget.view.renderTerminal;
    final point =
        render.getOffset(endpoint) + Offset(0, render.cellSize.height);
    if (point.dy <= 0 || point.dy > size.height + 1) {
      return const SizedBox.shrink();
    }
    final controls = materialTextSelectionControls;
    final handleWidth = controls.getHandleSize(render.cellSize.height).width;
    // Point inward at the viewport edges so the visible grip stays reachable.
    final type = point.dx < handleWidth
        ? TextSelectionHandleType.right
        : point.dx > size.width - handleWidth
            ? TextSelectionHandleType.left
            : start
                ? TextSelectionHandleType.left
                : TextSelectionHandleType.right;
    final anchor = controls.getHandleAnchor(type, render.cellSize.height);
    final handleSize = controls.getHandleSize(render.cellSize.height);
    const targetSize = 44.0;
    final left = (point.dx - anchor.dx - (targetSize - handleSize.width) / 2)
        .clamp(0.0, (size.width - targetSize).clamp(0.0, double.infinity));
    final above = point.dy + handleSize.height > size.height;
    final handleTop = point.dy - (above ? handleSize.height : anchor.dy);
    final top = (handleTop - 8)
        .clamp(0.0, (size.height - targetSize).clamp(0.0, double.infinity));
    return Positioned(
      left: left,
      top: top,
      width: targetSize,
      height: targetSize,
      child: Semantics(
        label: start ? '选择起点' : '选择终点',
        child: GestureDetector(
          key: ValueKey(
              start ? 'terminal-selection-start' : 'terminal-selection-end'),
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (details) => _start(start, details.globalPosition),
          onPanUpdate: (details) => _move(details.globalPosition),
          onPanEnd: (_) => _end(),
          onPanCancel: _end,
          onTap: () {},
          child: Stack(
            children: [
              Positioned(
                left: point.dx - anchor.dx - left,
                top: handleTop - top,
                child: IgnorePointer(
                  child: Transform.flip(
                    flipY: above,
                    child: controls.buildHandle(
                        context, type, render.cellSize.height),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final layoutChanged = _size != size;
          _size = size;
          if (layoutChanged) _refresh();
          final selection = widget.controller.selection?.normalized;
          return Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (!layoutChanged &&
                  selection != null &&
                  !selection.isCollapsed &&
                  widget.controller.selectionMode == SelectionMode.line) ...[
                _handle(true, selection.begin, size),
                _handle(false, selection.end, size),
              ],
            ],
          );
        },
      );
}
