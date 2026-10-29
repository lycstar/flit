import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/terminal/pty_session.dart';
import 'package:flit/features/terminal/terminal_log.dart';
import 'package:xterm/xterm.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app logs return to column zero after prompts and multiline errors', () {
    final terminal = Terminal()..resize(80, 24);
    final log = TerminalLog(terminal);
    terminal.write('shell prompt> ');
    log.line('下载开始');
    log.line('first error\nsecond error\r\nthird error');
    expect(terminal.buffer.lines[1].getText().trimRight(), '下载开始');
    expect(terminal.buffer.lines[2].getText().trimRight(), 'first error');
    expect(terminal.buffer.lines[3].getText().trimRight(), 'second error');
    expect(terminal.buffer.lines[4].getText().trimRight(), 'third error');
    expect(terminal.buffer.cursorX, 0);
    expect(terminal.buffer.cursorY, 5);
  });

  test('progress replaces one row and the next log starts below it', () {
    final terminal = Terminal()..resize(80, 24);
    final log = TerminalLog(terminal);
    log.line('下载开始');
    log.progress('下载 10% (12MB)');
    log.progress('下载 20%');
    log.line('下载完成');
    log.line('下一步');
    expect(terminal.buffer.lines[1].getText().trimRight(), '下载 20%');
    expect(terminal.buffer.lines[2].getText().trimRight(), '下载完成');
    expect(terminal.buffer.lines[3].getText().trimRight(), '下一步');
    expect(terminal.buffer.cursorX, 0);
  });

  test('missing bootstrap stays out of the terminal', () async {
    var probes = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      probes++;
      return {'prefix': '/missing-bootstrap', 'home': '/missing-home'};
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('flit/env'),
        null,
      ),
    );
    final session = PtySession(launcher: noProcess);
    await Future.wait([session.ensure(), session.ensure()]);
    await session.ensure(); // A later page mount must also remain quiet.
    final lines = session.terminal.buffer.lines;
    final text = [
      for (var i = 0; i < lines.length; i++) lines[i].getText(),
    ].join('\n');
    expect('环境未初始化'.allMatches(text).length, 0);
    expect(probes, 2); // Later requests still probe, allowing install recovery.
    expect(session.alive, false);
  });
}
