import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/terminal/flutter_log_formatter.dart';

void main() {
  test('classifies complete lines independently of chunk boundaries', () {
    const raw = 'Launching lib/main.dart\r\n'
        'Running Gradle task assembleDebug\r\n'
        'Warning: check configuration\r\n'
        'Error: build failed\r\n'
        '  #0 preserve the stack\r\n'
        'application says error but is ordinary text\r\n'
        'Reloaded 2 of 100 libraries\r\n';
    final whole = FlutterLogFormatter();
    final expected = whole.call(raw) + whole.finish();
    final fragmented = FlutterLogFormatter();
    final output = StringBuffer();
    for (final unit in raw.split('')) {
      output.write(fragmented.call(unit));
    }
    output.write(fragmented.finish());
    expect(output.toString(), expected);
    expect(expected, contains('\x1b[36mLaunching'));
    expect(expected, contains('\r\n\r\n\x1b[36mRunning Gradle'));
    expect(expected, contains('\x1b[33mWarning:'));
    expect(expected, contains('\x1b[31mError:'));
    expect(expected, contains('\x1b[32mReloaded'));
    expect(expected, contains('\n  #0 preserve the stack\r\n'));
    expect(expected, contains('\napplication says error but is ordinary text\r\n'));
  });

  test('preserves ANSI output and progress, and flushes the final partial line', () {
    final formatter = FlutterLogFormatter();
    const colored = '\x1b[35mError: custom color\x1b[0m\r\n';
    expect(formatter.call(colored), colored);
    expect(formatter.call('10%\r20%'), '10%\r');
    expect(formatter.call('\r30%'), '20%\r');
    expect(formatter.finish(), '30%');
    expect(formatter.finish(), isEmpty);
    expect(formatter.call('Error: last line'), isEmpty);
    expect(formatter.finish(), '\x1b[31mError: last line\x1b[0m');
  });
}
