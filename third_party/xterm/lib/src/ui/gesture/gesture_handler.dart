import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/core.dart';
import 'package:xterm/src/core/mouse/button.dart';
import 'package:xterm/src/core/mouse/button_state.dart';
import 'package:xterm/src/terminal_view.dart';
import 'package:xterm/src/ui/controller.dart';
import 'package:xterm/src/ui/gesture/gesture_detector.dart';
import 'package:xterm/src/ui/pointer_input.dart';
import 'package:xterm/src/ui/render.dart';

class TerminalGestureHandler extends StatefulWidget {
  const TerminalGestureHandler({
    super.key,
    required this.terminalView,
    required this.terminalController,
    this.child,
    this.onTapUp,
    this.onSingleTapUp,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.readOnly = false,
  });

  final TerminalViewState terminalView;

  final TerminalController terminalController;

  final Widget? child;

  final GestureTapUpCallback? onTapUp;

  final GestureTapUpCallback? onSingleTapUp;

  final GestureTapDownCallback? onTapDown;

  final GestureTapDownCallback? onSecondaryTapDown;

  final GestureTapUpCallback? onSecondaryTapUp;

  final GestureTapDownCallback? onTertiaryTapDown;

  final GestureTapUpCallback? onTertiaryTapUp;

  final bool readOnly;

  @override
  State<TerminalGestureHandler> createState() => _TerminalGestureHandlerState();
}

class _TerminalGestureHandlerState extends State<TerminalGestureHandler> {
  TerminalViewState get terminalView => widget.terminalView;

  RenderTerminal get renderTerminal => terminalView.renderTerminal;

  DragStartDetails? _lastDragStartDetails;

  /// 长按选择的起点, 固定为缓冲坐标(视口坐标会在滚动后漂移)
  CellOffset? _selectionBase;

  // ---- 长按选择的边缘自动滚屏(移动端选区跨屏的标配) ----
  Timer? _autoScrollTimer;
  Offset? _lastLongPressGlobal;

  /// 指针处于视口上下边缘 [zone] 内时按比例滚屏; 滚动后选区终点跟随
  /// 指针下的单元格延伸(手指停住也会持续滚, 直到离开边缘/松手)。
  void _updateAutoScroll() {
    final global = _lastLongPressGlobal;
    if (global == null) return _cancelAutoScroll();
    final box = renderTerminal;
    if (!box.attached) return _cancelAutoScroll();
    final local = box.globalToLocal(global);
    final h = box.size.height;
    const zone = 56.0;
    const maxSpeed = 900.0; // px/s
    var speed = 0.0;
    if (local.dy < zone) {
      speed = -((zone - local.dy) / zone) * maxSpeed;
    } else if (local.dy > h - zone) {
      speed = ((local.dy - (h - zone)) / zone) * maxSpeed;
    }
    if (speed == 0) return _cancelAutoScroll();
    if (_autoScrollTimer != null) {
      _autoScrollSpeed = speed;
      return;
    }
    _autoScrollSpeed = speed;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      widget.terminalView.scrollByPixels(_autoScrollSpeed * 0.05);
      final g = _lastLongPressGlobal;
      if (_selectionBase != null && g != null && box.attached) {
        renderTerminal.extendWordFrom(_selectionBase!, box.globalToLocal(g));
      }
    });
  }

  void _cancelAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  double _autoScrollSpeed = 0;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalGestureDetector(
      child: widget.child,
      onTapUp: widget.onTapUp,
      onSingleTapUp: onSingleTapUp,
      onTapDown: onTapDown,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp,
      onTertiaryTapDown: onSecondaryTapDown,
      onTertiaryTapUp: onSecondaryTapUp,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressUp: onLongPressUp,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDoubleTapDown: onDoubleTapDown,
    );
  }

  bool get _shouldSendTapEvent =>
      !widget.readOnly &&
      widget.terminalController.shouldSendPointerInput(PointerInput.tap);

  void _tapDown(
    GestureTapDownCallback? callback,
    TapDownDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap down event.
    var handled = false;
    if (_shouldSendTapEvent) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.down,
        details.localPosition,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void _tapUp(
    GestureTapUpCallback? callback,
    TapUpDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap up event.
    var handled = false;
    if (_shouldSendTapEvent) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.up,
        details.localPosition,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void onTapDown(TapDownDetails details) {
    // onTapDown is special, as it will always call the supplied callback.
    // The TerminalView depends on it to bring the terminal into focus.
    _tapDown(
      widget.onTapDown,
      details,
      TerminalMouseButton.left,
      forceCallback: true,
    );
  }

  void onSingleTapUp(TapUpDetails details) {
    _tapUp(widget.onSingleTapUp, details, TerminalMouseButton.left);
    // TerminalView uses this notification for focus/IME, even when the
    // application running in the terminal consumes mouse input.
    widget.onTapUp?.call(details);
  }

  void onSecondaryTapDown(TapDownDetails details) {
    _tapDown(widget.onSecondaryTapDown, details, TerminalMouseButton.right);
  }

  void onSecondaryTapUp(TapUpDetails details) {
    _tapUp(widget.onSecondaryTapUp, details, TerminalMouseButton.right);
  }

  void onTertiaryTapDown(TapDownDetails details) {
    _tapDown(widget.onTertiaryTapDown, details, TerminalMouseButton.middle);
  }

  void onTertiaryTapUp(TapUpDetails details) {
    _tapUp(widget.onTertiaryTapUp, details, TerminalMouseButton.right);
  }

  void onDoubleTapDown(TapDownDetails details) {
    renderTerminal.selectWord(details.localPosition);
  }

  void onLongPressStart(LongPressStartDetails details) {
    _lastLongPressGlobal = details.globalPosition;
    _selectionBase = renderTerminal.getCellOffset(details.localPosition);
    renderTerminal.selectWord(details.localPosition);
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _lastLongPressGlobal = details.globalPosition;
    renderTerminal.extendWordFrom(_selectionBase!, details.localPosition);
    _updateAutoScroll();
  }

  void onLongPressUp() {
    _cancelAutoScroll();
    _lastLongPressGlobal = null;
    _selectionBase = null;
  }

  void onDragStart(DragStartDetails details) {
    _lastDragStartDetails = details;

    details.kind == PointerDeviceKind.mouse
        ? renderTerminal.selectCharacters(details.localPosition)
        : renderTerminal.selectWord(details.localPosition);
  }

  void onDragUpdate(DragUpdateDetails details) {
    renderTerminal.selectCharacters(
      _lastDragStartDetails!.localPosition,
      details.localPosition,
    );
  }
}
