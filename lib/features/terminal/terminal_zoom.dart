import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// 只在第二根手指落下时接管手势。单指滚动、点击输入和长按选择仍由 xterm
/// 处理；缩放结束后继续消费剩余手指，避免抬指时误触键盘或滚动。
class TerminalZoom extends StatelessWidget {
  const TerminalZoom({
    super.key,
    required this.child,
    required this.onStart,
    required this.onScale,
    required this.onEnd,
  });
  final Widget child;
  final VoidCallback onStart;
  final ValueChanged<double> onScale;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      _TerminalPinchRecognizer:
          GestureRecognizerFactoryWithHandlers<_TerminalPinchRecognizer>(
            () => _TerminalPinchRecognizer(),
            (instance) => instance
              ..onStart = onStart
              ..onScale = onScale
              ..onEnd = onEnd,
          ),
    },
    child: child,
  );
}

class _TerminalPinchRecognizer extends OneSequenceGestureRecognizer {
  _TerminalPinchRecognizer()
    : super(supportedDevices: {PointerDeviceKind.touch});
  late VoidCallback onStart;
  late ValueChanged<double> onScale;
  late VoidCallback onEnd;
  final _points = <int, Offset>{};
  Offset _origin = Offset.zero;
  double _distance = 1;
  bool _claimed = false;
  bool _started = false;
  bool _ended = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _points[event.pointer] = event.position;
    if (_claimed) {
      resolvePointer(event.pointer, GestureDisposition.accepted);
    } else if (_points.length == 1) {
      _origin = event.position;
    } else if (_points.length == 2) {
      _distance = (_points.values.first - _points.values.last).distance;
      if (_distance < 1) return;
      _claimed = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_claimed && !_started) {
      _started = true;
      onStart();
    }
  }

  void _end() {
    if (_started && !_ended) {
      _ended = true;
      onEnd();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_points.containsKey(event.pointer)) return;
    if (event is PointerMoveEvent) {
      _points[event.pointer] = event.position;
      if (_started && !_ended && _points.length >= 2) {
        final pair = _points.values.take(2).toList();
        onScale((pair[0] - pair[1]).distance / _distance);
      } else if (!_claimed &&
          (event.position - _origin).distance > kTouchSlop) {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _end();
      resolvePointer(event.pointer, GestureDisposition.rejected);
      if (_points.remove(event.pointer) != null) {
        stopTrackingPointer(event.pointer);
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    _end();
    if (_points.remove(pointer) != null) stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _claimed = _started = _ended = false;
    resolve(GestureDisposition.rejected);
  }

  @override
  String get debugDescription => 'terminal two-finger zoom';
}
