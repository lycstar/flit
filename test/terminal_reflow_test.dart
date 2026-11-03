import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  test(
    'resize reflows soft wraps, preserves hard breaks and cursor insertion',
    () {
      final terminal = Terminal()..resize(40, 12);
      const first = '0123456789abcdefghijklmnopqrstuvwxyz';
      terminal.write('$first\r\nsecond line\r\nprompt> ');
      final text = terminal.buffer.getText().trimRight();
      terminal.resize(16, 12);
      expect(terminal.buffer.getText().trimRight(), text);
      terminal.write('X');
      expect(terminal.buffer.getText().trimRight(), '$text X');
      terminal.resize(50, 12);
      expect(terminal.buffer.getText().trimRight(), '$text X');
      terminal.write('Y');
      expect(terminal.buffer.getText().trimRight(), '$text XY');
    },
  );
  for (final source in [
    'abcdefghijklmnopqrstuvwxyz0123456789',
    'a' * 16,
    'b' * 60,
    '你好世界，这是终端缩放测试 hello world',
  ]) {
    test(
      'active long line preserves insertion through repeated reflow: $source',
      () {
        final terminal = Terminal()..resize(60, 12);
        terminal.write(source);
        var expected = source;
        for (final width in [16, 50, 9, 60]) {
          terminal.resize(width, 12);
          expect(terminal.buffer.getText().trimRight(), expected);
          terminal.write('X');
          expected += 'X';
          expect(terminal.buffer.getText().trimRight(), expected);
        }
      },
    );
  }

  test('reflow retains a cursor editing in the middle of a long line', () {
    final terminal = Terminal()..resize(60, 12);
    const source = 'abcdefghijklmnopqrstuvwxyz0123456789';
    terminal.write('$source\x1b[10D');
    for (final size in [(16, 6), (50, 20), (9, 6), (60, 12)]) {
      terminal.resize(size.$1, size.$2);
    }
    terminal.write('X');
    expect(
      terminal.buffer.getText().trimRight(),
      source.replaceRange(26, 27, 'X'),
    );
  });
}
