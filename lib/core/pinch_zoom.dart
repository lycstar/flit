import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// 只在第二根手指落下时接管手势。单指滚动、点击输入和长按选择仍由子组件
/// 处理；缩放结束后继续消费剩余手指，避免抬指时误触键盘或滚动。
class PinchZoom extends StatelessWidget {
  const PinchZoom({
    super.key,
    required this.child,
    required this.onStart,
    required this.onScale,
    required this.onEnd,
  });
  final Widget child;

  /// 第二指落下的两指中点(PinchZoom 局部坐标)。
  final ValueChanged<Offset> onStart;

  /// 缩放比例(相对手势起点)与当前两指中点(局部坐标)。
  final void Function(double scale, Offset focal) onScale;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      _PinchRecognizer: GestureRecognizerFactoryWithHandlers<_PinchRecognizer>(
        () => _PinchRecognizer(),
        (instance) {
          void start(Offset focal) => onStart(_toLocal(context, focal));
          void rescale(double scale, Offset focal) =>
              onScale(scale, _toLocal(context, focal));
          instance
            ..onStart = start
            ..onScale = rescale
            ..onEnd = onEnd;
        },
      ),
    },
    child: child,
  );

  static Offset _toLocal(BuildContext context, Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null || !box.attached ? global : box.globalToLocal(global);
  }
}

class _PinchRecognizer extends OneSequenceGestureRecognizer {
  _PinchRecognizer() : super(supportedDevices: {PointerDeviceKind.touch});
  late ValueChanged<Offset> onStart;
  late void Function(double scale, Offset focal) onScale;
  late VoidCallback onEnd;
  final _points = <int, Offset>{};
  Offset _origin = Offset.zero;
  Offset _focal = Offset.zero;
  double _distance = 1;
  bool _claimed = false;
  bool _started = false;
  bool _ended = false;

  Offset get _midpoint {
    final pair = _points.values.take(2).toList();
    return (pair[0] + pair[1]) / 2;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _points[event.pointer] = event.position;
    if (_claimed) {
      resolvePointer(event.pointer, GestureDisposition.accepted);
    } else if (_points.length == 1) {
      _origin = event.position;
    } else if (_points.length == 2) {
      _focal = _midpoint;
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
      onStart(_focal);
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
        onScale(
          (_points.values.first - _points.values.last).distance / _distance,
          _focal = _midpoint,
        );
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
  String get debugDescription => 'two-finger zoom';
}
