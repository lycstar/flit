import '../lsp/protocol.dart';

/// Local fallback and atomic application of LSP completion edits.
class CompletionEngine {
  CompletionEngine._();

  static const _wordChars =
      'abcdefghijklmnopqrstuvwxyz'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';

  /// 光标前正在输入的词前缀; 无前缀返回 ''
  static String prefixOf(String text, int offset) {
    offset = offset.clamp(0, text.length);
    var i = offset;
    while (i > 0 && _wordChars.contains(text[i - 1])) {
      i--;
    }
    return text.substring(i, offset);
  }

  /// 返回按相关度排序的候选(最多 [limit] 条)
  static List<CompletionItem> complete(
    String text,
    int offset, {
    int limit = 8,
    String? language = 'dart',
  }) {
    final prefix = prefixOf(text, offset);
    if (prefix.length < 2) return const [];

    final lower = prefix.toLowerCase();
    final docIds = <String>{};
    final idRe = RegExp(r'[A-Za-z_$][\w$]{2,}');
    for (final m in idRe.allMatches(text)) {
      docIds.add(m[0]!);
    }

    void collect(
      _Source source,
      Set<String> pool,
      List<_Scored> out, {
      bool substring = false,
    }) {
      for (final w in pool) {
        if (w == prefix) continue;
        final lw = w.toLowerCase();
        if (lw.startsWith(lower)) {
          out.add(_Scored(w, source, 0));
        } else if (substring && lw.contains(lower)) {
          out.add(_Scored(w, source, 1)); // 本文档标识符支持子串命中
        }
      }
    }

    final scored = <_Scored>[];
    collect(_Source.local, docIds, scored, substring: true);
    if (language == 'dart') {
      collect(_Source.symbol, _commonSymbols, scored);
      collect(_Source.keyword, _keywords, scored);
    }

    scored.sort((a, b) {
      // 排序: 来源(局部>符号>关键字) > 匹配度(前缀>子串) > 长度 > 字典序
      final bySource = a.source.index - b.source.index;
      if (bySource != 0) return bySource;
      final byRank = a.rank - b.rank;
      if (byRank != 0) return byRank;
      final byLen = a.word.length - b.word.length;
      if (byLen != 0) return byLen;
      return a.word.compareTo(b.word);
    });

    final seen = <String>{};
    final items = <CompletionItem>[];
    for (final s in scored) {
      if (!seen.add(s.word)) continue;
      items.add(
        CompletionItem(
          insert: s.word,
          label: s.word,
          kind: switch (s.source) {
            _Source.local => '本文档',
            _Source.symbol => '符号',
            _Source.keyword => '关键字',
          },
        ),
      );
      if (items.length >= limit) break;
    }
    return items;
  }

  /// 用候选替换光标前的词前缀, 返回新的 (文本, 光标位置)
  static (String, int) apply(String text, int offset, CompletionItem item) {
    if (offset < 0 || offset > text.length) {
      throw const FormatException('Invalid cursor');
    }
    final semantic = item.semantic;
    final start =
        semantic?.editOffset ?? offset - prefixOf(text, offset).length;
    final end = semantic?.editOffset == null
        ? offset
        : start + (semantic?.editLength ?? 0);
    final main = LspTextEdit(start: start, end: end, newText: item.insert);
    final edits = [main, ...?semantic?.additionalTextEdits]
      ..sort((a, b) => a.start.compareTo(b.start));
    LspTextEdit? previous;
    var cursor = start + main.newText.length;
    for (final edit in edits) {
      if (edit.start < 0 ||
          edit.end < edit.start ||
          edit.end > text.length ||
          (previous != null &&
              (edit.start < previous.end || edit.start == previous.start))) {
        throw const FormatException('Overlapping or invalid completion edits');
      }
      if (!identical(edit, main) && edit.end <= start) {
        cursor += edit.newText.length - (edit.end - edit.start);
      }
      previous = edit;
    }
    var result = text;
    for (final edit in edits.reversed) {
      result = result.replaceRange(edit.start, edit.end, edit.newText);
    }
    return (result, cursor);
  }
}

class CompletionItem {
  const CompletionItem({
    required this.insert,
    required this.label,
    required this.kind,
    this.detail,
    this.semantic,
  });
  factory CompletionItem.fromLsp(LspCompletionItem item) => CompletionItem(
    insert: item.insert,
    label: item.label,
    kind: switch (item.kind) {
      2 || 3 => '方法',
      4 || 7 || 8 => '类型',
      5 || 6 => '变量',
      9 => '模块',
      10 => '属性',
      14 => '关键字',
      _ => 'Dart',
    },
    detail: item.detail,
    semantic: item,
  );
  final String insert, label, kind;
  final String? detail;
  final LspCompletionItem? semantic;
}

enum _Source { local, symbol, keyword }

class _Scored {
  const _Scored(this.word, this.source, this.rank);
  final String word;
  final _Source source;
  final int rank;
}

const _keywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'if',
  'implements',
  'import',
  'in',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
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
  'while',
  'with',
  'yield',
};

const _commonSymbols = {
  // Flutter 组件
  'StatelessWidget', 'StatefulWidget', 'State', 'BuildContext', 'Widget',
  'Container', 'Column', 'Row', 'Stack', 'Text', 'Scaffold', 'AppBar',
  'Center', 'Padding', 'ListView', 'GridView', 'Expanded', 'Flexible',
  'SizedBox',
  'Spacer',
  'GestureDetector',
  'InkWell',
  'CircularProgressIndicator',
  'LinearProgressIndicator', 'BoxDecoration', 'BoxShadow', 'BorderRadius',
  'EdgeInsets', 'TextStyle', 'ThemeData', 'ColorScheme', 'MaterialApp',
  'Navigator',
  'Route',
  'MaterialPageRoute',
  'TextField',
  'TextEditingController',
  'IconButton', 'TextButton', 'FilledButton', 'FloatingActionButton',
  'AlertDialog', 'SnackBar', 'Divider', 'Card', 'ListTile', 'TabBar',
  'TabBarView', 'SingleChildScrollView', 'ClipRRect', 'DecoratedBox',
  // Dart 核心
  'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Iterable',
  'Future', 'Stream', 'DateTime', 'Duration', 'RegExp', 'print', 'override',
  // 常用成员/惯用法
  'setState', 'initState', 'dispose', 'build', 'context', 'child', 'children',
  'main', 'async', 'await',
};
