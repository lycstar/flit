import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Dart uses a stateful line lexer; configuration files use separate language rules.
class CodeHighlighter {
  CodeHighlighter._();

  /// 按文件扩展名选语言; 未识别的返回 null(纯文本, 不着色)
  static String? languageOf(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.dart')) return 'dart';
    if (p.endsWith('.yaml') || p.endsWith('.yml')) return 'yaml';
    if (p.endsWith('.json')) return 'json';
    if (p.endsWith('.xml') || p.endsWith('.html')) return 'xml';
    if (p.endsWith('.properties')) return 'config';
    if (p.endsWith('.gradle') || p.endsWith('.kts') || p.endsWith('.xml')) {
      return 'generic';
    }
    if (p.endsWith('.md')) return 'markdown';
    return null;
  }

  /// Preserves the entire source; a controller can supply a persistent Dart cache.
  static TextSpan build(
    String text,
    String? language, {
    TextStyle? base,
    DartHighlightCache? dartCache,
  }) {
    final root = (base ?? AppColors.mono).copyWith(color: CodeTheme.current.plain);
    if (language == null) {
      return TextSpan(text: text, style: root);
    }
    if (language == 'dart') {
      return TextSpan(
        style: root,
        children: (dartCache ?? DartHighlightCache()).highlight(text),
      );
    }
    final rules = _languages[language];
    if (rules == null) return TextSpan(text: text, style: root);

    final spans = <TextSpan>[];
    var last = 0;
    for (final m in rules.pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      var kind = _Kind.plain;
      for (final g in rules.groupOrder) {
        if (m.namedGroup(g) != null) {
          kind = _kindByName(g);
          break;
        }
      }
      spans.add(
        TextSpan(
          text: m[0],
          style: TextStyle(color: _color(kind)),
        ),
      );
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return TextSpan(children: spans, style: root);
  }

  static _Kind _kindByName(String g) => switch (g) {
    'comment' => _Kind.comment,
    'string' => _Kind.string,
    'number' => _Kind.number,
    'annotation' => _Kind.annotation,
    'keyword' => _Kind.keyword,
    'clazz' => _Kind.clazz,
    'key' => _Kind.key,
    'heading' => _Kind.heading,
    _ => _Kind.plain,
  };

  static Color _color(_Kind k) => switch (k) {
    _Kind.keyword => CodeTheme.current.keyword,
    _Kind.string => CodeTheme.current.string,
    _Kind.comment => CodeTheme.current.comment,
    _Kind.number => CodeTheme.current.number,
    _Kind.clazz => CodeTheme.current.clazz,
    _Kind.annotation => CodeTheme.current.annotation,
    _Kind.heading => CodeTheme.current.clazz,
    _Kind.key => CodeTheme.current.string,
    _Kind.plain => CodeTheme.current.plain,
  };

  /// 单语言规则表: 命名分组按 [groupOrder] 优先级判定着色类别
  static final _languages = <String, _LanguageRules>{
    'json': _LanguageRules(
      pattern: RegExp(
        r'(?<string>\x22(?:\\.|[^\x22\\])*\x22)|(?<number>-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b)|(?<keyword>\b(?:true|false|null)\b)',
      ),
      groupOrder: ['string', 'number', 'keyword'],
    ),
    'yaml': _LanguageRules(
      pattern: RegExp(
        r'(?<comment>(?:^|\s)#[^\n]*)|(?<string>\x22(?:\\.|[^\x22\\])*\x22|\x27[^\x27]*\x27)|(?<key>^[ \t]*[\w.$-]+:)|(?<number>\b\d+(?:\.\d+)?\b)|(?<keyword>\b(?:true|false|null)\b)',
        multiLine: true,
      ),
      groupOrder: ['comment', 'string', 'key', 'number', 'keyword'],
    ),
    'xml': _LanguageRules(
      pattern: RegExp(
        r'(?<comment><!--[\s\S]*?(?:-->|$))|(?<string>\x22[^\x22]*\x22|\x27[^\x27]*\x27)|(?<keyword></?[\w:.-]+)|(?<key>[\w:.-]+(?=\s*=))',
      ),
      groupOrder: ['comment', 'string', 'keyword', 'key'],
    ),
    'config': _LanguageRules(
      // yaml/properties/json: 注释 + 字符串 + 数字 + 键名(yaml 风格 key:)
      pattern: RegExp(
        r'(?<comment>(?://[^\n]*|#[^\n]*))'
        r'|(?<string>[\x22](?:\\.|[^\x22\\\n])*[\x22]|[\x27](?:\\.|[^\x27\\\n])*[\x27])'
        r'|(?<number>\b\d+(?:\.\d+)?\b)'
        r'|(?<key>^\s*[\w.$-]+:(?=\s))',
        multiLine: true,
      ),
      groupOrder: ['comment', 'string', 'number', 'key'],
    ),
    'generic': _LanguageRules(
      // gradle/kts/xml 及其他: 注释 + 字符串 + 数字
      pattern: RegExp(
        r'(?<comment>//[^\n]*|/\*[\s\S]*?\*/|<!--[\s\S]*?-->)'
        r'|(?<string>[\x22](?:\\.|[^\x22\\\n])*[\x22]|[\x27](?:\\.|[^\x27\\\n])*[\x27])'
        r'|(?<number>\b\d+(?:\.\d+)?\b)',
        multiLine: true,
      ),
      groupOrder: ['comment', 'string', 'number'],
    ),
    'markdown': _LanguageRules(
      pattern: RegExp(
        r'(?<comment>^#{1,6} .*$)'
        r'|(?<string>[\x60][^\x60\n]+[\x60])'
        r'|(?<keyword>^\s*[-*+] )',
        multiLine: true,
      ),
      groupOrder: ['comment', 'string', 'keyword'],
    ),
  };
}

enum _Kind {
  plain,
  keyword,
  string,
  comment,
  number,
  clazz,
  annotation,
  key,
  heading,
}

class _LanguageRules {
  const _LanguageRules({required this.pattern, required this.groupOrder});

  final RegExp pattern;
  final List<String> groupOrder;
}

/// Per-controller lexical cache. Reuses a line only when its incoming state also
/// matches, so editing a multiline comment/string invalidates following lines.
class DartHighlightCache {
  List<_LexedLine> _lines = [];

  List<TextSpan> highlight(String text) {
    final lines = text.split('\n');
    final next = <_LexedLine>[];
    var state = <_LexFrame>[];
    for (var i = 0; i < lines.length; i++) {
      final source = lines[i] + (i < lines.length - 1 ? '\n' : '');
      final key = state.map((f) => f.key).join('|');
      final old = i < _lines.length ? _lines[i] : null;
      final line = old != null && old.source == source && old.incoming == key
          ? old
          : _lexLine(source, state, key);
      next.add(line);
      state = line.outgoing.map((f) => f.copy()).toList();
    }
    _lines = next;
    return [for (final line in next) ...line.spans];
  }
}

class _LexFrame {
  _LexFrame(this.kind, {this.delimiter = '', this.raw = false, this.depth = 1});
  final String kind, delimiter;
  final bool raw;
  int depth;
  String get key => '$kind:$delimiter:$raw:$depth';
  _LexFrame copy() =>
      _LexFrame(kind, delimiter: delimiter, raw: raw, depth: depth);
}

class _LexedLine {
  _LexedLine(this.source, this.incoming, this.outgoing, this.spans);
  final String source, incoming;
  final List<_LexFrame> outgoing;
  final List<TextSpan> spans;
}

final _identifier = RegExp(r'[A-Za-z_$][\w$]*');
final _digit = RegExp(r'[0-9]');
final _numeric = RegExp(
  r'(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)',
);
final _dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

_LexedLine _lexLine(String source, List<_LexFrame> incoming, String key) {
  final stack = incoming.map((f) => f.copy()).toList();
  final spans = <TextSpan>[];
  var i = 0;
  void add(int start, int end, _Kind kind) {
    if (end > start) {
      spans.add(
        TextSpan(
          text: source.substring(start, end),
          style: kind == _Kind.plain
              ? null
              : TextStyle(color: CodeHighlighter._color(kind)),
        ),
      );
    }
  }

  while (i < source.length) {
    final frame = stack.isEmpty ? null : stack.last;
    if (frame?.kind == 'comment') {
      final start = i;
      while (i < source.length) {
        if (source.startsWith('/*', i)) {
          frame!.depth++;
          i += 2;
        } else if (source.startsWith('*/', i)) {
          i += 2;
          if (--frame!.depth == 0) {
            stack.removeLast();
            break;
          }
        } else {
          i++;
        }
      }
      add(start, i, _Kind.comment);
      continue;
    }
    if (frame?.kind == 'string') {
      final start = i;
      while (i < source.length) {
        if (source.startsWith(frame!.delimiter, i)) {
          i += frame.delimiter.length;
          stack.removeLast();
          break;
        }
        if (!frame.raw && source[i] == '\\') {
          i = (i + 2).clamp(0, source.length);
          continue;
        }
        if (!frame.raw && source[i] == r'$') break;
        if (source[i] == '\n' && frame.delimiter.length == 1) {
          stack.removeLast();
          i++;
          break;
        }
        i++;
      }
      add(start, i, _Kind.string);
      if (i < source.length &&
          stack.isNotEmpty &&
          identical(stack.last, frame) &&
          !frame!.raw &&
          source[i] == r'$') {
        final start = i++;
        if (i < source.length && source[i] == '{') {
          i++;
          stack.add(_LexFrame('interpolation'));
        } else {
          final match = _identifier.matchAsPrefix(source, i);
          if (match != null) i = match.end;
        }
        add(start, i, _Kind.annotation);
      }
      continue;
    }
    final start = i;
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end;
      add(start, i, _Kind.comment);
    } else if (source.startsWith('/*', i)) {
      i += 2;
      // Include the opener in this same token, including nested/unfinished comments.
      var depth = 1;
      while (i < source.length && depth > 0) {
        if (source.startsWith('/*', i)) {
          depth++;
          i += 2;
        } else if (source.startsWith('*/', i)) {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
      if (depth > 0) stack.add(_LexFrame('comment', depth: depth));
      add(start, i, _Kind.comment);
    } else {
      final raw =
          source[i] == 'r' &&
          i + 1 < source.length &&
          (source[i + 1] == '"' || source[i + 1] == "'");
      final quoteAt = raw ? i + 1 : i;
      final char = source[quoteAt];
      if (char == '"' || char == "'") {
        final triple = source.startsWith(char * 3, quoteAt);
        final delimiter = triple ? char * 3 : char;
        i = quoteAt + delimiter.length;
        stack.add(_LexFrame('string', delimiter: delimiter, raw: raw));
        // Merge opener with the next string fragment for compact spans.
        final contentStart = i;
        while (i < source.length) {
          if (source.startsWith(delimiter, i)) {
            i += delimiter.length;
            stack.removeLast();
            break;
          }
          if (!raw && source[i] == '\\') {
            i = (i + 2).clamp(0, source.length);
            continue;
          }
          if (!raw && source[i] == r'$') break;
          if (!triple && source[i] == '\n') {
            stack.removeLast();
            i++;
            break;
          }
          i++;
        }
        add(start, i, _Kind.string);
        // If interpolation immediately follows the opener, the string-state
        // branch consumes it on the next iteration.
        assert(i >= contentStart);
      } else if (char == '@') {
        i++;
        final match = _identifier.matchAsPrefix(source, i);
        if (match != null) i = match.end;
        add(start, i, _Kind.annotation);
      } else if (_digit.hasMatch(char)) {
        final match = _numeric.matchAsPrefix(source, i);
        i = match?.end ?? i + 1;
        add(start, i, _Kind.number);
      } else {
        final match = _identifier.matchAsPrefix(source, i);
        if (match != null) {
          i = match.end;
          final word = match[0]!;
          add(
            start,
            i,
            _dartKeywords.contains(word)
                ? _Kind.keyword
                : (word.codeUnitAt(0) >= 65 && word.codeUnitAt(0) <= 90)
                ? _Kind.clazz
                : _Kind.plain,
          );
        } else {
          if (frame?.kind == 'interpolation') {
            if (char == '{') frame!.depth++;
            if (char == '}' && --frame!.depth == 0) stack.removeLast();
          }
          i++;
          add(start, i, _Kind.plain);
        }
      }
    }
  }
  return _LexedLine(source, key, stack, spans);
}
