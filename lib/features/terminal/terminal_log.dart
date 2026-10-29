import 'package:xterm/xterm.dart';

/// App-generated text bypasses the PTY's ONLCR processing. Keep CRLF conversion
/// here; raw PTY output must retain its original terminal control sequences.
class TerminalLog {
  TerminalLog(this.terminal);

  final Terminal terminal;
  bool _progressVisible = false;

  void line(String message) {
    if (_progressVisible || terminal.buffer.cursorX != 0) {
      terminal.write('\r\n');
    }
    _progressVisible = false;
    terminal.write('${message.replaceAll(RegExp(r'\r?\n'), '\r\n')}\r\n');
  }

  /// 语义色行: 成功绿 / 失败红 / 警示黄 / 通知青
  void ok(String m) => line('\x1b[1;32m$m\x1b[0m');
  void err(String m) => line('\x1b[1;31m$m\x1b[0m');
  void warn(String m) => line('\x1b[1;33m$m\x1b[0m');
  void info(String m) => line('\x1b[36m$m\x1b[0m');
  void dim(String m) => line('\x1b[2m$m\x1b[0m');

  void progress(String message) {
    if (!_progressVisible && terminal.buffer.cursorX != 0) {
      terminal.write('\r\n');
    }
    _progressVisible = true;
    terminal.write('\r\x1b[2K$message');
  }
}
