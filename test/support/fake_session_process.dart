import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flit/features/terminal/console_session.dart';

class FakeProcess implements SessionProcess {
  final chunks = StreamController<Uint8List>();
  final exited = Completer<int>();
  final writes = <String>[];
  bool stopOnInterrupt = true;
  @override
  Stream<List<int>> get output => chunks.stream;
  @override
  Future<int> get exitCode => exited.future;
  void emit(String text) => chunks.add(Uint8List.fromList(utf8.encode(text)));
  Future<void> finish([int code = 0]) async {
    if (!exited.isCompleted) exited.complete(code);
    await chunks.close();
  }

  @override
  void write(Uint8List data) {
    final text = utf8.decode(data);
    writes.add(text);
    if (text == '\x03' && stopOnInterrupt) unawaited(finish(130));
  }

  @override
  void resize(int rows, int columns) {}
  @override
  void kill() => unawaited(finish(137));
}

/// 启动器: 每次启动都交出同一个假进程(测试随后 emit/finish 驱动它)。
ProcessLauncher launching(FakeProcess process) =>
    ({
      required command,
      required workingDirectory,
      required rows,
      required columns,
    }) async => process;

/// 会话在本测试里从不启动进程; 真被调用就是测试写错了。
Future<SessionProcess> noProcess({
  required String? command,
  required String? workingDirectory,
  required int rows,
  required int columns,
}) async => throw StateError('this session must not start a process');
