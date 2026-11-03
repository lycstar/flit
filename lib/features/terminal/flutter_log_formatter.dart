/// Presentation only: original PTY text remains available to protocol parsers.
/// Buffer complete lines so split UTF-8 chunks cannot change classification.
class FlutterLogFormatter {
  String _pending = '';
  bool _hasOutput = false;

  static String color(String text, String code) =>
      text.contains('\x1b') ? text : '\x1b[${code}m$text\x1b[0m';

  static final _error = RegExp(
    r'^(?:E/|Error:|FAILURE:|\[ERROR\]|══╡ EXCEPTION|Unhandled [Ee]xception|Exception caught)|: error: ',
  );
  static final _warning = RegExp(
    r'^(?:W/|Warning:|warning:|\[WARNING\]|w: )|: warning: ',
  );
  static final _stage = RegExp(
    r'^(?:Launching |Running Gradle task |Building |Installing |Syncing files to device |Performing hot reload|Performing hot restart|Waiting for connection from debug service)',
  );
  static final _success = RegExp(
    r'^(?:✓ |√ |Built |Reloaded \d|Restarted application|BUILD SUCCESSFUL)',
  );

  String call(String chunk) {
    _pending += chunk;
    final result = StringBuffer();
    int end;
    while ((end = _pending.indexOf('\n')) >= 0) {
      final line = _pending.substring(0, end);
      _pending = _pending.substring(end + 1);
      result.write(_line(line));
      result.write('\n');
    }
    // Preserve terminal progress/spinner updates without waiting for a newline.
    // Finish the carriage return too; a trailing CR may be half of CRLF.
    final carriage = _pending == '\r'
        ? -1
        : _pending.endsWith('\r')
        ? _pending.lastIndexOf('\r', _pending.length - 2)
        : _pending.lastIndexOf('\r');
    if (carriage >= 0) {
      result.write(_pending.substring(0, carriage + 1));
      _pending = _pending.substring(carriage + 1);
    }
    return result.toString();
  }

  String _line(String line) {
    if (line.endsWith('\r')) {
      return '${_line(line.substring(0, line.length - 1))}\r';
    }
    final stage = _stage.hasMatch(line);
    final separator = stage && _hasOutput ? '\r\n' : '';
    if (line.trim().isNotEmpty) _hasOutput = true;
    final text = _error.hasMatch(line)
        ? color(line, '31')
        : _warning.hasMatch(line)
        ? color(line, '33')
        : _success.hasMatch(line)
        ? color(line, '32')
        : stage
        ? color(line, '36')
        : line;
    return '$separator$text';
  }

  String finish() {
    final text = _pending;
    _pending = '';
    return text.isEmpty ? '' : _line(text);
  }
}
